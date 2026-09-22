/* =========================================================================
 * lcd.c - display alfanumerico HD44780 no XM118
 * ========================================================================= */

#include <xc.h>
#include "lcd.h"

#ifndef _XTAL_FREQ
#define _XTAL_FREQ 16000000UL       /* 16 MHz: o bootloader e quem manda */
#endif

/* =======================================================================
 * O pulso de habilitacao.
 *
 * O display nao le o barramento quando o valor aparece nos fios: ele le na
 * borda de descida de E. Os dois atrasos existem por motivos diferentes.
 * ======================================================================= */
static void lcd_pulso(void)
{
    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);     /* largura minima do pulso        */
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);     /* intervalo minimo ate o proximo */
}

/* =======================================================================
 * Meio byte no barramento.
 *
 * Le LATD e nao PORTD: LATD devolve o que o programa escreveu, PORTD
 * devolve o nivel eletrico do pino. Com carga nos quatro bits baixos, a
 * leitura-modificacao-escrita por PORTD apaga bits que ninguem pediu.
 * ======================================================================= */
#if LCD_BITS == 4
static void lcd_nibble(uint8_t valor)
{
    LCD_DADOS_LAT = (uint8_t)((LCD_DADOS_LAT & 0x0Fu) | (valor & 0xF0u));
    lcd_pulso();
}
#endif

/* =======================================================================
 * Ler o controlador.
 *
 * Aqui - e SO aqui - PORTD esta certo e LATD estaria errado. E a mesma
 * regra da funcao acima, lida ao contrario: la se queria o que o programa
 * escreveu, e o latch responde; aqui se quer o que OUTRO circuito colocou
 * no fio, e o latch nao sabe de nada. Ler LATD devolveria o nibble que nos
 * mesmos mandamos da ultima vez.
 *
 * Quem decorou "sempre LAT" erra exatamente nesta funcao.
 * ======================================================================= */
#if LCD_LER_OCUPADO

static uint8_t lcd_pronto = 0;      /* 1 depois que o modo esta definido */

uint8_t lcd_estado(void)
{
    uint8_t v;
#if LCD_BITS == 4
    uint8_t alto, baixo;
#endif

    /* Barramento vira entrada ANTES de pedir leitura. */
#if LCD_BITS == 4
    LCD_DADOS_TRIS |= 0xF0u;
#else
    LCD_DADOS_TRIS = 0xFFu;
#endif

    LCD_RS_LAT = 0;                 /* registrador de instrucao */
    LCD_RW_LAT = 1;                 /* leitura                  */
    __delay_us(LCD_T_PULSO_US);

#if LCD_BITS == 4
    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);
    alto = (uint8_t)(LCD_DADOS_PORT & 0xF0u);   /* amostra com E alto */
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);

    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);
    baixo = (uint8_t)((LCD_DADOS_PORT & 0xF0u) >> 4);
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);

    v = (uint8_t)(alto | baixo);
#else
    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);
    v = (uint8_t)LCD_DADOS_PORT;
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);
#endif

    /* Devolve o barramento ANTES de reconfigurar o TRIS.
       Nesta placa o modulo ja soltou os fios, porque ele so os dirige
       enquanto E esta alto - e E ja desceu. A ordem e disciplina, nao
       correcao de um defeito ativo: a alternativa e dois circuitos
       dirigindo o mesmo fio, a unica falha deste driver que estraga
       hardware em vez de produzir caractere errado. */
    LCD_RW_LAT = 0;
#if LCD_BITS == 4
    LCD_DADOS_TRIS &= 0x0Fu;
#else
    LCD_DADOS_TRIS = 0x00u;
#endif

    return v;
}

/* Espera o indicador de ocupado baixar - o tempo REAL do modulo, e nao o
   pior caso da folha de dados. O teto existe para o caso de a leitura nao
   funcionar (R/W no terra em outra placa): melhor um display errado do que
   um programa travado. */
static void lcd_esperar(void)
{
    uint16_t guarda = 0;

    while ((lcd_estado() & 0x80u) != 0u) {
        if (++guarda >= LCD_MAX_CONSULTAS) {
            break;
        }
    }
}
#endif /* LCD_LER_OCUPADO */

/* =======================================================================
 * Um byte, comando ou dado.
 *
 * A espera de execucao vale por BYTE, e nao por nibble: o controlador so
 * comeca a executar quando o segundo nibble chega. Poe-la dentro de
 * lcd_pulso dobraria o custo da interface inteira.
 * ======================================================================= */
static void lcd_byte(uint8_t valor, uint8_t eh_dado, uint8_t lento)
{
    LCD_RS_LAT = eh_dado ? 1 : 0;
    LCD_RW_LAT = 0;                 /* escrita: explicito, nunca flutuando */

#if LCD_BITS == 4
    lcd_nibble(valor);
    lcd_nibble((uint8_t)(valor << 4));
#else
    LCD_DADOS_LAT = valor;
    lcd_pulso();
#endif

#if LCD_LER_OCUPADO
    if (lcd_pronto) {
        lcd_esperar();              /* pergunta */
        return;
    }
#endif
    __delay_us(LCD_T_COMANDO_US);   /* espera as cegas */
    if (lento) {
        __delay_ms(LCD_T_LENTO_MS);
    }
}

void lcd_comando(uint8_t c)
{
    lcd_byte(c, 0, (uint8_t)((c == 0x01u || c == 0x02u) ? 1u : 0u));
}

void lcd_dado(uint8_t d)
{
    lcd_byte(d, 1, 0);
}

/* =======================================================================
 * Inicializacao.
 *
 * Reiniciar o microcontrolador NAO reinicia o display. Ele pode estar em
 * um de tres estados: oito bits; quatro bits esperando o nibble alto;
 * quatro bits esperando o nibble baixo. Tres pulsos de 0x30 levam os tres
 * ao mesmo lugar - e duas repeticoes NAO bastam.
 *
 * Os atrasos desta funcao continuam sendo cegos por NECESSIDADE, e nao por
 * limitacao de hardware: enquanto o modo nao esta definido, o controlador
 * nao esta num estado conhecido e uma leitura de dois nibbles nao
 * significa nada. So depois do function set e que da para perguntar.
 *
 * O R4 pede que voce remova uma das repeticoes e teste energizando e
 * dando reset.
 * ======================================================================= */
void lcd_iniciar(void)
{
    /* LAT antes de TRIS: encontro 2. Vale tambem para o R/W - se ele ficar
       flutuando, o modulo nao sabe se esta sendo lido ou escrito, e o
       display funciona ou nao conforme o dia. */
    LCD_RS_LAT = 0;
    LCD_E_LAT  = 0;
    LCD_RW_LAT = 0;
#if LCD_BITS == 4
    LCD_DADOS_LAT = (uint8_t)(LCD_DADOS_LAT & 0x0Fu);
#else
    LCD_DADOS_LAT = 0x00;
#endif

    LCD_RS_TRIS = 0;
    LCD_E_TRIS  = 0;
    LCD_RW_TRIS = 0;
#if LCD_BITS == 4
    LCD_DADOS_TRIS &= 0x0Fu;         /* so os quatro bits altos viram saida */
#else
    LCD_DADOS_TRIS = 0x00;
#endif

    __delay_ms(LCD_T_ENERGIA_MS);    /* e para a ALIMENTACAO, nao para o display */

#if LCD_BITS == 4
    lcd_nibble(0x30); __delay_ms(5);     /* o byte de lixo pode ser 0x03 */
    lcd_nibble(0x30); __delay_us(150);
    lcd_nibble(0x30); __delay_us(150);
    lcd_nibble(0x20);                    /* a partir daqui, quatro bits  */
    __delay_us(LCD_T_COMANDO_US);
    lcd_comando(0x28);                   /* 4 bits, 2 linhas, matriz 5x8 */
#else
    lcd_comando(0x30); __delay_ms(5);
    lcd_comando(0x30); __delay_us(150);
    lcd_comando(0x30); __delay_us(150);
    lcd_comando(0x38);                   /* 8 bits, 2 linhas, matriz 5x8 */
#endif

#if LCD_LER_OCUPADO
    lcd_pronto = 1;                      /* daqui em diante, perguntar    */
#endif

    lcd_comando(0x0C);                   /* display ligado, sem cursor   */
    lcd_comando(0x06);                   /* avanco automatico do cursor  */
    lcd_comando(0x01);                   /* limpar                       */
}

/* ================================================================= texto */
void lcd_limpar(void)
{
    lcd_comando(0x01);
}

/* Linha 1 comeca em 0x00 e linha 2 em 0x40 - nao em 0x10.
   O endereco e da memoria do controlador, nao da posicao na tela. */
void lcd_posicao(uint8_t linha, uint8_t coluna)
{
    uint8_t base = (linha == 0u) ? 0x00u : 0x40u;
    lcd_comando((uint8_t)(0x80u | (base + coluna)));
}

void lcd_texto(const char *s)
{
    while (*s != '\0') {
        lcd_dado((uint8_t)(*s++));
    }
}

/* =======================================================================
 * Numero com LARGURA FIXA.
 *
 * O display nao apaga nada. Escrever "9" onde havia "37" deixa o "7" no
 * lugar. Largura constante, completada com espaco, e a correcao que o
 * resto do semestre usa.
 * ======================================================================= */
void lcd_numero(uint16_t v, uint8_t largura)
{
    char buf[6];
    uint8_t n = 0;

    do {
        buf[n++] = (char)('0' + (v % 10u));
        v /= 10u;
    } while (v != 0u && n < (uint8_t)sizeof(buf));

    while (largura > n) {                 /* preenche a esquerda */
        lcd_dado(' ');
        largura--;
    }
    while (n != 0u) {
        lcd_dado((uint8_t) buf[--n]);
    }
}

/* 253 -> "25.3" ; -47 -> "-4.7" */
void lcd_decimos(int16_t d)
{
    if (d < 0) {
        lcd_dado('-');
        if (d == INT16_MIN) {             /* -(-32768) nao cabe em int16 */
            d = INT16_MAX;
        } else {
            d = (int16_t)(-d);
        }
    }
    lcd_numero((uint16_t)(d / 10), 2);
    lcd_dado('.');
    lcd_dado((uint8_t)('0' + (d % 10)));
}
