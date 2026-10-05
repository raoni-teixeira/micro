/* =========================================================================
 * teste_lcd.c - casos de teste do driver HD44780, rodando no PC
 *
 *     cd teste && make
 *
 * O lcd.c e compilado com gcc contra a "placa" lcd_port_test.c, que
 * registra cada chamada de porta com um relogio virtual. Cada caso abaixo
 * confere uma regra da folha de dados do HD44780; quando falha, imprime o
 * registro para mostrar ONDE a sequencia saiu errada.
 *
 * O Makefile roda tudo em quatro configuracoes: 4 e 8 bits, com e sem
 * leitura do indicador de ocupado.
 *
 * Tempos da folha de dados (HD44780U, Vcc = 4,5-5,5 V, fosc = 270 kHz):
 *   energizacao ate o 1o acesso  > 40 ms (pior caso, Vcc = 2,7 V)
 *   apos o 1o 0x3                > 4,1 ms
 *   apos o 2o 0x3                > 100 us
 *   comando comum / dado         37 us
 *   limpar (0x01), inicio (0x02) 1,52 ms
 * ========================================================================= */

#include <stdio.h>
#include <string.h>
#include "lcd.h"

#define T_ENERGIA_US   40000u
#define T_1O_0X3_US     4100u
#define T_2O_0X3_US      100u
#define T_COMANDO_US      37u
#define T_LENTO_US      1520u

/* --------------------------------------------------- mini-arcabouco */
static int falhas_caso;
static int casos, casos_falhos;

#define CHECA(cond, ...)                                              \
    do {                                                              \
        if (!(cond)) {                                                \
            printf("    FALHOU (linha %d): ", __LINE__);              \
            printf(__VA_ARGS__);                                      \
            printf("\n");                                             \
            falhas_caso++;                                            \
        }                                                             \
    } while (0)

static void reiniciar(void)
{
    lcd_teste_limpar();
    lcd_teste_ocupado(0);
    lcd_teste_t_us = 0;
}

static void rodar(const char *nome, void (*caso)(void))
{
    falhas_caso = 0;
    reiniciar();
    caso();
    casos++;
    if (falhas_caso != 0) {
        casos_falhos++;
        printf("  [FALHA] %s\n  registro:\n", nome);
        lcd_teste_imprimir();
    } else {
        printf("  [ ok  ] %s\n", nome);
    }
}

#define RODAR(caso) rodar(#caso, caso)

/* ------------------------------------------- leitura do registro */

/* Pulsos de E em ordem (indices no registro). */
static int pulsos(uint32_t *idx, int max)
{
    int n = 0;
    uint32_t i;
    for (i = 0; i < lcd_teste_n && n < max; i++) {
        if (lcd_teste_ev[i].tipo == EV_PULSO) {
            idx[n++] = i;
        }
    }
    return n;
}

/* Um byte que chegou ao controlador. */
typedef struct {
    uint8_t  rs;
    uint8_t  valor;
    uint32_t ev_ini, ev_fim;    /* indice do 1o e do ultimo pulso */
} byte_t;

/* Remonta os bytes a partir dos pulsos, pulando os 'pular' primeiros
   (os nibbles soltos da inicializacao). Em 4 bits, os dois nibbles de um
   byte precisam ter o MESMO RS - senao o controlador recebe meio comando
   e meio dado. */
static int bytes(int pular, byte_t *out, int max)
{
    uint32_t p[LCD_TESTE_MAX_EV];
    int np = pulsos(p, (int)LCD_TESTE_MAX_EV);
    int n = 0, i;

#if LCD_BITS == 4
    for (i = pular; i + 1 < np && n < max; i += 2) {
        const lcd_ev_t *a = &lcd_teste_ev[p[i]];
        const lcd_ev_t *b = &lcd_teste_ev[p[i + 1]];
        CHECA(a->rs == b->rs,
              "RS mudou entre os dois nibbles do byte %d (eventos %u e %u)",
              n, (unsigned)p[i], (unsigned)p[i + 1]);
        out[n].rs     = a->rs;
        out[n].valor  = (uint8_t)((a->valor & 0xF0u) | ((b->valor >> 4) & 0x0Fu));
        out[n].ev_ini = p[i];
        out[n].ev_fim = p[i + 1];
        n++;
    }
    CHECA(((np - pular) % 2) == 0,
          "numero impar de nibbles depois da inicializacao: o controlador "
          "ficou esperando o nibble baixo");
#else
    for (i = pular; i < np && n < max; i++) {
        const lcd_ev_t *a = &lcd_teste_ev[p[i]];
        out[n].rs     = a->rs;
        out[n].valor  = (uint8_t)a->valor;
        out[n].ev_ini = p[i];
        out[n].ev_fim = p[i];
        n++;
    }
#endif
    return n;
}

/* Texto que chegou como DADO (RS = 1). */
static void texto(char *s, int max)
{
    byte_t b[64];
    int n = bytes(0, b, 64), i, k = 0;
    for (i = 0; i < n && k < max - 1; i++) {
        if (b[i].rs) {
            s[k++] = (char)b[i].valor;
        }
    }
    s[k] = '\0';
}

/* Pulsos soltos da inicializacao: 0x3 x3 (+ 0x2 em 4 bits). */
#if LCD_BITS == 4
#define PULSOS_INICIAIS 4
#else
#define PULSOS_INICIAIS 3
#endif

static int lento(const byte_t *b)
{
    return b->rs == 0u && (b->valor == 0x01u || (b->valor & 0xFEu) == 0x02u);
}

/* Entre o fim de um byte e o inicio do proximo, o controlador precisa
   ter terminado: OU passou o tempo de execucao, OU o driver perguntou. */
static void checa_tempos(const byte_t *b, int n)
{
    int i;
    for (i = 0; i + 1 < n; i++) {
        uint32_t fim  = lcd_teste_ev[b[i].ev_fim].t_us + LCD_T_PULSO_US;  /* descida de E */
        uint32_t prox = lcd_teste_ev[b[i + 1].ev_ini].t_us;
        uint32_t exig = lento(&b[i]) ? T_LENTO_US : T_COMANDO_US;
        uint32_t k;
        int perguntou = 0;

        for (k = b[i].ev_fim; k < b[i + 1].ev_ini; k++) {
            if (lcd_teste_ev[k].tipo == EV_LER) {
                perguntou = 1;
            }
        }
        CHECA(perguntou || prox - fim >= exig,
              "byte %d (RS=%u, 0x%02X): proximo acesso %u us depois, "
              "a folha de dados exige %u us",
              i, b[i].rs, b[i].valor, (unsigned)(prox - fim), (unsigned)exig);
    }
}

/* ============================================================ CASOS */

/* --------------------------------------------------- inicializacao */

static void init_configura_pinos_primeiro(void)
{
    lcd_iniciar();
    CHECA(lcd_teste_n > 0 && lcd_teste_ev[0].tipo == EV_INIT,
          "a primeira coisa do lcd_iniciar deve ser lcd_port_init");
}

static void init_espera_energizacao(void)
{
    uint32_t p[8];
    lcd_iniciar();
    CHECA(pulsos(p, 8) > 0, "nenhum pulso de E");
    CHECA(lcd_teste_ev[p[0]].t_us >= T_ENERGIA_US,
          "1o pulso em %u us; a folha de dados pede > %u us apos energizar",
          (unsigned)lcd_teste_ev[p[0]].t_us, (unsigned)T_ENERGIA_US);
}

static void init_tres_vezes_0x3(void)
{
    uint32_t p[8];
    int i;
    lcd_iniciar();
    CHECA(pulsos(p, 8) >= 3, "menos de 3 pulsos");
    for (i = 0; i < 3; i++) {
        const lcd_ev_t *e = &lcd_teste_ev[p[i]];
        CHECA((e->valor & 0xF0u) == 0x30u,
              "pulso %d levou 0x%X no nibble alto; deveria ser 0x3",
              i + 1, (unsigned)(e->valor >> 4));
        CHECA(e->rs == 0, "pulso %d com RS = 1; e comando, RS = 0", i + 1);
    }
}

static void init_intervalos_entre_0x3(void)
{
    uint32_t p[8];
    uint32_t d1, d2, d3;
    lcd_iniciar();
    CHECA(pulsos(p, 8) >= 4, "menos de 4 pulsos");
    d1 = lcd_teste_ev[p[1]].t_us - lcd_teste_ev[p[0]].t_us - LCD_T_PULSO_US;
    d2 = lcd_teste_ev[p[2]].t_us - lcd_teste_ev[p[1]].t_us - LCD_T_PULSO_US;
    d3 = lcd_teste_ev[p[3]].t_us - lcd_teste_ev[p[2]].t_us - LCD_T_PULSO_US;
    CHECA(d1 >= T_1O_0X3_US, "apos o 1o 0x3: %u us, exige > %u us",
          (unsigned)d1, (unsigned)T_1O_0X3_US);
    CHECA(d2 >= T_2O_0X3_US, "apos o 2o 0x3: %u us, exige > %u us",
          (unsigned)d2, (unsigned)T_2O_0X3_US);
    CHECA(d3 >= T_COMANDO_US, "apos o 3o 0x3: %u us, exige > %u us",
          (unsigned)d3, (unsigned)T_COMANDO_US);
}

static void init_define_modo(void)
{
    uint32_t p[8];
    lcd_iniciar();
    CHECA(pulsos(p, 8) >= 4, "menos de 4 pulsos");
#if LCD_BITS == 4
    CHECA((lcd_teste_ev[p[3]].valor & 0xF0u) == 0x20u,
          "4o pulso deveria ser o nibble 0x2 (passa a 4 bits), foi 0x%X",
          (unsigned)(lcd_teste_ev[p[3]].valor >> 4));
#else
    CHECA(lcd_teste_ev[p[3]].valor == 0x38u,
          "4o pulso deveria ser 0x38 (8 bits, 2 linhas, 5x8), foi 0x%02X",
          (unsigned)lcd_teste_ev[p[3]].valor);
#endif
}

static void init_sequencia_de_comandos(void)
{
#if LCD_BITS == 4
    static const uint8_t esperado[] = { 0x28, 0x0C, 0x06, 0x01 };
#else
    static const uint8_t esperado[] = { 0x38, 0x0C, 0x06, 0x01 };
#endif
    byte_t b[16];
    int n, i;
    lcd_iniciar();
    n = bytes(PULSOS_INICIAIS, b, 16);
    CHECA(n == 4, "esperava 4 comandos apos o modo, vieram %d", n);
    for (i = 0; i < n && i < 4; i++) {
        CHECA(b[i].rs == 0 && b[i].valor == esperado[i],
              "comando %d: esperava 0x%02X (RS=0), veio 0x%02X (RS=%u)",
              i, esperado[i], b[i].valor, b[i].rs);
    }
}

static void init_tempos_entre_comandos(void)
{
    byte_t b[16];
    int n;
    lcd_iniciar();
    lcd_dado('x');      /* para medir tambem o tempo do ultimo (0x01) */
    n = bytes(PULSOS_INICIAIS, b, 16);
    checa_tempos(b, n);
}

static void init_cada_pulso_tem_dado_novo(void)
{
    uint32_t i;
    int tem_dado = 0;
    lcd_iniciar();
    for (i = 0; i < lcd_teste_n; i++) {
        if (lcd_teste_ev[i].tipo == EV_DADOS) {
            tem_dado = 1;
        } else if (lcd_teste_ev[i].tipo == EV_PULSO) {
            CHECA(tem_dado,
                  "pulso de E no evento %u sem colocar dado no barramento "
                  "antes: E deve subir com RS e dados ja estaveis",
                  (unsigned)i);
            tem_dado = 0;
        }
    }
}

#if LCD_LER_OCUPADO
static void init_nao_le_antes_do_modo(void)
{
    byte_t b[16];
    uint32_t i;
    lcd_iniciar();
    CHECA(bytes(PULSOS_INICIAIS, b, 16) >= 1, "sem function set");
    for (i = 0; i <= b[0].ev_fim; i++) {
        CHECA(lcd_teste_ev[i].tipo != EV_LER,
              "leitura no evento %u, antes do function set: o modo do "
              "controlador ainda e desconhecido", (unsigned)i);
    }
}
#endif

/* ----------------------------------------------- escrita no display */

static void dado_vai_com_rs_1(void)
{
    byte_t b[4];
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_dado('A');
    CHECA(bytes(0, b, 4) == 1, "lcd_dado deveria mandar 1 byte");
    CHECA(b[0].rs == 1 && b[0].valor == 'A',
          "esperava 'A' (0x41) com RS=1, veio 0x%02X com RS=%u",
          b[0].valor, b[0].rs);
}

static void comando_vai_com_rs_0(void)
{
    byte_t b[4];
    lcd_iniciar();
    lcd_dado('A');                  /* deixa RS = 1 de proposito */
    lcd_teste_limpar();
    lcd_comando(0x0E);
    CHECA(bytes(0, b, 4) == 1, "lcd_comando deveria mandar 1 byte");
    CHECA(b[0].rs == 0 && b[0].valor == 0x0E,
          "esperava 0x0E com RS=0, veio 0x%02X com RS=%u",
          b[0].valor, b[0].rs);
}

#if LCD_BITS == 4
static void nibble_alto_primeiro(void)
{
    uint32_t p[4];
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_dado(0xA5);
    CHECA(pulsos(p, 4) == 2, "um byte em 4 bits sao 2 pulsos");
    CHECA(lcd_teste_ev[p[0]].valor == 0xA0u && lcd_teste_ev[p[1]].valor == 0x50u,
          "0xA5 deveria sair como 0xA e depois 0x5 em D7-D4, saiu 0x%X, 0x%X",
          (unsigned)(lcd_teste_ev[p[0]].valor >> 4),
          (unsigned)(lcd_teste_ev[p[1]].valor >> 4));
}
#endif

static void limpar_espera_o_tempo_longo(void)
{
    byte_t b[4];
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_limpar();
    lcd_dado('x');
    CHECA(bytes(0, b, 4) == 2, "esperava 2 bytes");
    CHECA(b[0].valor == 0x01 && b[0].rs == 0, "lcd_limpar deveria mandar 0x01");
    checa_tempos(b, 2);
}

static void posicao_enderecos(void)
{
    static const struct { uint8_t l, c, cmd; } t[] = {
        { 0, 0, 0x80 }, { 0, 15, 0x8F }, { 1, 0, 0xC0 }, { 1, 5, 0xC5 },
    };
    byte_t b[8];
    unsigned i;
    lcd_iniciar();
    for (i = 0; i < sizeof t / sizeof t[0]; i++) {
        lcd_teste_limpar();
        lcd_posicao(t[i].l, t[i].c);
        CHECA(bytes(0, b, 8) == 1 && b[0].rs == 0 && b[0].valor == t[i].cmd,
              "lcd_posicao(%u, %u): esperava 0x%02X, veio 0x%02X "
              "(linha 2 comeca em 0x40, nao em 0x10)",
              t[i].l, t[i].c, t[i].cmd, b[0].valor);
    }
}

static void texto_sai_inteiro(void)
{
    char s[32];
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_texto("Oi, LCD!");
    texto(s, sizeof s);
    CHECA(strcmp(s, "Oi, LCD!") == 0, "esperava \"Oi, LCD!\", veio \"%s\"", s);
}

static void numero_largura_fixa(void)
{
    static const struct { uint16_t v; uint8_t larg; const char *s; } t[] = {
        { 7, 3, "  7" }, { 0, 1, "0" }, { 1234, 2, "1234" },
        { 65535, 5, "65535" }, { 42, 0, "42" },
    };
    char s[32];
    unsigned i;
    lcd_iniciar();
    for (i = 0; i < sizeof t / sizeof t[0]; i++) {
        lcd_teste_limpar();
        lcd_numero(t[i].v, t[i].larg);
        texto(s, sizeof s);
        CHECA(strcmp(s, t[i].s) == 0, "lcd_numero(%u, %u): esperava \"%s\", veio \"%s\"",
              t[i].v, t[i].larg, t[i].s, s);
    }
}

static void decimos_com_sinal(void)
{
    static const struct { int16_t d; const char *s; } t[] = {
        { 253, "25.3" }, { -47, "-4.7" }, { 5, " 0.5" }, { 0, " 0.0" },
        { 1000, "100.0" },
        { INT16_MIN, "-3276.7" },   /* satura: -(-32768) nao cabe em int16 */
    };
    char s[32];
    unsigned i;
    lcd_iniciar();
    for (i = 0; i < sizeof t / sizeof t[0]; i++) {
        lcd_teste_limpar();
        lcd_decimos(t[i].d);
        texto(s, sizeof s);
        CHECA(strcmp(s, t[i].s) == 0, "lcd_decimos(%d): esperava \"%s\", veio \"%s\"",
              t[i].d, t[i].s, s);
    }
}

/* ------------------------------------------- indicador de ocupado */
#if LCD_LER_OCUPADO

#if LCD_BITS == 4
#define LEITURAS_POR_ESTADO 2u
#else
#define LEITURAS_POR_ESTADO 1u
#endif

static void ocupado_pergunta_ate_liberar(void)
{
    uint32_t i;
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_teste_ocupado(3);
    lcd_comando(0x0C);
    CHECA(lcd_teste_leituras == 4u * LEITURAS_POR_ESTADO,
          "display ocupado por 3 consultas: esperava %u leituras, houve %u",
          (unsigned)(4u * LEITURAS_POR_ESTADO), (unsigned)lcd_teste_leituras);
    for (i = 0; i < lcd_teste_n; i++) {
        CHECA(lcd_teste_ev[i].tipo != EV_ESPERA,
              "espera as cegas no evento %u: com leitura do ocupado, "
              "perguntar e esperar e pagar duas vezes", (unsigned)i);
        CHECA(lcd_teste_ev[i].tipo != EV_LER || lcd_teste_ev[i].rs == 0,
              "leitura de estado com RS = 1 no evento %u: le a RAM, "
              "nao o indicador", (unsigned)i);
    }
}

static void ocupado_tem_teto(void)
{
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_teste_ocupado(LCD_TESTE_SEMPRE_OCUPADO);
    lcd_comando(0x0C);              /* precisa VOLTAR */
    CHECA(lcd_teste_leituras == LCD_MAX_CONSULTAS * LEITURAS_POR_ESTADO,
          "display que nunca libera: esperava desistir apos %u leituras, "
          "houve %u", (unsigned)(LCD_MAX_CONSULTAS * LEITURAS_POR_ESTADO),
          (unsigned)lcd_teste_leituras);
    lcd_teste_limpar();             /* nao imprime 40 mil eventos */
}

static void ocupado_estado_le_os_dois_nibbles(void)
{
    uint8_t v;
    lcd_iniciar();
    lcd_teste_limpar();
    lcd_teste_ocupado(1);
    v = lcd_estado();
    CHECA(v == 0x80u, "lcd_estado com display ocupado: esperava 0x80, veio 0x%02X", v);
    CHECA(lcd_teste_leituras == LEITURAS_POR_ESTADO,
          "lcd_estado deveria fazer %u leitura(s), fez %u",
          (unsigned)LEITURAS_POR_ESTADO, (unsigned)lcd_teste_leituras);
}
#endif /* LCD_LER_OCUPADO */

/* ============================================================== main */
int main(void)
{
    printf("LCD_BITS = %d, LCD_LER_OCUPADO = %d\n", LCD_BITS, LCD_LER_OCUPADO);

    RODAR(init_configura_pinos_primeiro);
    RODAR(init_espera_energizacao);
    RODAR(init_tres_vezes_0x3);
    RODAR(init_intervalos_entre_0x3);
    RODAR(init_define_modo);
    RODAR(init_sequencia_de_comandos);
    RODAR(init_tempos_entre_comandos);
    RODAR(init_cada_pulso_tem_dado_novo);
#if LCD_LER_OCUPADO
    RODAR(init_nao_le_antes_do_modo);
#endif

    RODAR(dado_vai_com_rs_1);
    RODAR(comando_vai_com_rs_0);
#if LCD_BITS == 4
    RODAR(nibble_alto_primeiro);
#endif
    RODAR(limpar_espera_o_tempo_longo);
    RODAR(posicao_enderecos);
    RODAR(texto_sai_inteiro);
    RODAR(numero_largura_fixa);
    RODAR(decimos_com_sinal);

#if LCD_LER_OCUPADO
    RODAR(ocupado_pergunta_ate_liberar);
    RODAR(ocupado_tem_teto);
    RODAR(ocupado_estado_le_os_dois_nibbles);
#endif

    printf("%d casos, %d falharam\n\n", casos, casos_falhos);
    return casos_falhos != 0;
}
