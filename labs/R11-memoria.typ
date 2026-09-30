// R11 — A memória que sobrevive
// Revisão 2026/2, alinhada à aula 11 (I²C e memória não volátil). Parte 1: a
// memória interna guarda o alvo. Parte 2: a memória externa, por I²C, medida no
// osciloscópio. É a peça que falta para a Parte 2 do TP.
//
// Seis tarefas com nota (8,0), previsões P1–P5 da aula 11 (2,0) e duas extensões
// sem nota no fim.
//
// Compilação:  typst compile R11-memoria.typ
//              typst compile --input gab=1 R11-memoria.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R11 — A memória que sobrevive",
  subtitulo: "O alvo que volta depois de desligar, e o barramento de dois fios que o leva para fora do chip",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}
// Célula de tabela: vazia para o aluno, preenchida no gabarito.
#let g(x) = if gab { x } else { [] }

#objetivos[
  - Guardar o alvo na memória não volátil interna e reconhecer uma memória que nunca foi gravada.
  - Decidir quando gravar, com a conta da vida útil da memória.
  - Medir no osciloscópio uma transação I²C: a subida lenta, o reconhecimento e o byte de controle.
  - Comparar escrita byte a byte e por página, e memória interna com externa.
]

#kit[
  #tab(columns: (auto, 1fr),
    [Chave], [Posição],
    [CH2-1 (LCD)], [ON],
    [Botões], [`INT0` (SW12, RB0) sobe 0,5 °C e `INT1` (SW13, RB1) desce — *só na Parte 1*],
    [Chave da memória I²C], [ON *só na Parte 2* — confirme qual é no seu kit],
    [CH5 (relés), SWITCHS e CH3], [OFF],
  )

  *RB0 e RB1 têm dois donos* (aula 11): na Parte 1 são os botões; na Parte 2 são
  SDA e SCL do barramento. Não aperte os botões durante a Parte 2.
]

#docente[
  *Antes da sessão:* qual a peça de memória externa (24C02, 24C04 ou 24C16), se a
  placa já tem resistores de elevação em SDA e SCL, e qual chave conecta a memória
  ao barramento. O programa usa o chip 000, endereços abaixo de 256 e páginas de 8
  bytes alinhadas em 16, o que funciona nas três peças.
]

#atencao[
  *Este roteiro grava memória de verdade, e memória se gasta.* Use o endereço que
  o professor indicar para o seu grupo, e nunca deixe um programa gravando num laço.
]

*Pontuação.* As seis tarefas somam 8,0. As previsões P1 a P5 da aula 11, preenchidas
antes da sessão, valem 0,4 cada. A nota de cada tarefa e de cada previsão está na
margem. A seção _Se sobrar tempo_ não vale nota.

= Previsões — entregues no início da sessão

#prevista(nota: "0,4 pt")[
  *P1.* Escreva o alvo na memória, desligue a placa, ligue de novo. O que espera
  ver no display no primeiro segundo?
  #resp(n: 2)[O alvo gravado, lido na inicialização. E, na primeiríssima vez, o valor padrão: uma memória nunca gravada lê `0xFF`, e o programa precisa reconhecer isso.]
]

#prevista(nota: "0,4 pt")[
  *P2.* No osciloscópio, o tempo de subida de SDA é igual ao de descida?
  #resp(n: 1)[Não: a descida é feita por um transistor e é rápida; a subida é um resistor carregando a capacitância da linha, e é lenta.]
]

#prevista(nota: "0,4 pt")[
  *P3.* Gravando oito bytes um a um e depois os mesmos oito por página, que razão
  entre os dois tempos você espera?
  #resp(n: 1)[Perto de 8: cada gravação custa um ciclo interno de ≈ 5 ms, e a página grava os oito num ciclo só.]
]

#prevista(nota: "0,4 pt")[
  *P4.* Se o programa gravasse o alvo a cada volta do laço, em quanto tempo a
  posição se esgotaria?
  #resp(n: 2)[A interna suporta da ordem de 100 000 escritas, e cada uma leva ≈ 4 ms: 400 s, menos de sete minutos. Por isso não se deixa rodando.]
]

#prevista(nota: "0,4 pt")[
  *P5.* Uma escrita na memória interna e uma na externa: qual é mais rápida, e por
  quê?
  #resp(n: 2)[Da mesma ordem: as duas gastam alguns milissegundos no ciclo de gravação. A externa soma a transação de ≈ 0,4 ms no barramento, mas descobre pelo reconhecimento quando terminou, em vez de esperar o pior caso.]
]

= Parte 1 — a memória interna

O alvo fica em três bytes a partir de `ENDERECO`: um *marcador* (`0xA5`) e os dois
bytes do alvo em décimos. Sem o marcador, o programa não teria como distinguir
um alvo gravado de uma memória apagada, que lê `0xFF` em toda posição.

```c
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>
#include "lcd.h"

#define ENDERECO      0x10u     /* o professor indica um por grupo          */
#define MARCADOR      0xA5u
#define ALVO_PADRAO   400       /* 40,0 graus                                */
#define QUIETO_MS     3000u     /* grava depois de 3 s sem mexer (Tarefa 2) */

/* ---- memoria interna (aula 11) ---- */
static uint8_t eeprom_ler(uint8_t end)
{
    EEADR = end;
    EECON1bits.EEPGD = 0;  EECON1bits.CFGS = 0;
    EECON1bits.RD = 1;
    return EEDATA;
}

static void eeprom_escrever(uint8_t end, uint8_t dado)
{
    EEADR = end;  EEDATA = dado;
    EECON1bits.EEPGD = 0;  EECON1bits.CFGS = 0;
    EECON1bits.WREN = 1;
    uint8_t salvo = INTCONbits.GIE;
    INTCONbits.GIE = 0;                 /* a fechadura nao pode ser interrompida */
    EECON2 = 0x55;
    EECON2 = 0xAA;
    EECON1bits.WR = 1;
    INTCONbits.GIE = salvo;
    while (EECON1bits.WR) { }           /* cerca de 4 ms */
    EECON1bits.WREN = 0;
}

static int16_t alvo_ler(void)
{
    if (eeprom_ler(ENDERECO) != MARCADOR) {
        return ALVO_PADRAO;             /* nunca gravada: 0xFF */
    }
    return (int16_t)(((uint16_t)eeprom_ler(ENDERECO + 1u) << 8)
                     | eeprom_ler(ENDERECO + 2u));
}

static void alvo_gravar(int16_t alvo)
{
    LATEbits.LATE2 = 1;                 /* marca a gravacao no osciloscopio */
    eeprom_escrever(ENDERECO + 1u, (uint8_t)((uint16_t)alvo >> 8));
    eeprom_escrever(ENDERECO + 2u, (uint8_t)alvo);
    eeprom_escrever(ENDERECO, MARCADOR);    /* por ultimo: so vale se o resto foi */
    LATEbits.LATE2 = 0;
}
```

O programa principal reaproveita a base de 5 ms e o filtro de repique do R7, agora
para os dois botões, e mostra o alvo e o número de gravações:

```c
/* do R7: tratamento com base de 5 ms e filtro de confirmacao para RB0 e RB1,
   que produz os eventos 'subir' e 'descer'; e ms_ler(). */

void main(void)
{
    int16_t  alvo;
    uint16_t gravacoes = 0, ultimo_toque = 0;
    uint8_t  pendente = 0;

    ADCON1 = 0x0F;                      /* RB0/RB1 e RE digitais */
    LATEbits.LATE2 = 0;  TRISEbits.TRISE2 = 0;
    lcd_iniciar();
    base_e_botoes_iniciar();            /* R7 */

    alvo = alvo_ler();                  /* o primeiro segundo da P1 */

    for (;;) {
        if (subir)  { subir = 0;  if (alvo < 500) { alvo += 5; }  pendente = 1;  ultimo_toque = ms_ler(); }
        if (descer) { descer = 0; if (alvo > 300) { alvo -= 5; }  pendente = 1;  ultimo_toque = ms_ler(); }

        if (pendente && (uint16_t)(ms_ler() - ultimo_toque) >= QUIETO_MS) {
            alvo_gravar(alvo);          /* so quando o alvo parou de mudar */
            gravacoes++;
            pendente = 0;
        }

        lcd_posicao(0, 0);  lcd_texto("Alvo ");  lcd_decimos(alvo);
        lcd_posicao(1, 0);  lcd_texto("Gravacoes ");  lcd_numero(gravacoes, 4);
    }
}
```

#tarefa(nota: "1,5 pt")[
  *Tarefa 1.* Grave o programa e anote o alvo que aparece. Mude o alvo para 42,5 °C
  pelos botões, espere o contador de gravações subir, desligue a placa e ligue de
  novo.

  #tab(columns: (1fr, 3cm),
    [Alvo na primeira vez que o programa rodou], g[40,0 (padrão)],
    [Alvo depois de desligar e ligar], g[42,5],
    [Previsão (P1)], [],
  )

  (a) Por que o primeiro alvo foi o padrão, e não um número qualquer?
  #resp(n: 2)[A posição nunca tinha sido gravada e lia `0xFF`. Sem o marcador `0xA5`, o programa leria `0xFFFF` como alvo — −0,1 °C, com sinal — e aqueceria até lá, ou seja, nunca.]

  (b) Por que o marcador é o *último* byte gravado?
  #resp(n: 2)[Se a energia cair no meio, o marcador ainda não foi escrito e o alvo parcial é ignorado. Gravando o marcador primeiro, um alvo pela metade seria aceito como válido.]
]

#tarefa(nota: "1,5 pt")[
  *Tarefa 2.* Meça RE2 no osciloscópio durante uma gravação. Depois aperte o botão
  dez vezes seguidas, rápido, e veja quantas gravações o contador registra.

  #tab(columns: (1fr, 3cm),
    [Duração de uma gravação do alvo (3 bytes)], g[≈ 12 ms],
    [Gravações depois de dez toques rápidos], g[1],
  )

  (a) Com 100 000 escritas por posição, quanto tempo duraria a memória se o
  programa gravasse a cada toque, para um usuário que ajusta o alvo 20 vezes por
  dia? E a cada volta do laço (P4)?
  #resp(n: 2)[A cada toque: 100 000 / 20 = 5 000 dias, cerca de 14 anos. A cada volta do laço, com ≈ 4 ms por escrita: 400 s, menos de sete minutos.]

  (b) O que a espera de 3 s sem mexer compra, e o que ela arrisca?
  #resp(n: 2)[Compra uma gravação por ajuste, em vez de uma por toque. Arrisca perder o último ajuste se a energia cair nesses 3 s — um risco pequeno e conhecido.]
]

= Parte 2 — a memória externa, por dois fios

Solte os botões, ligue a chave da memória I²C e grave o programa de teste. Ele
repete a cada 2 s o teste escolhido em `TESTE`, com RE2 em nível alto enquanto a
operação dura.

```c
#define MEM   0xA0u     /* 1010 000 0: familia, chip 000, escrita */
#define TESTE 1         /* 1: um byte; 2: oito um a um; 3: oito por pagina; 4: endereco errado */

static void i2c_iniciar(void)
{
    TRISBbits.TRISB0 = 1;  TRISBbits.TRISB1 = 1;    /* o modulo assume SDA e SCL */
    SSPSTAT = 0x80;                                 /* 100 kHz                   */
    SSPADD  = 39;                                   /* 16 MHz / (4 x 100 kHz) - 1 */
    SSPCON1 = 0x28;                                 /* ligado, mestre I2C        */
    SSPCON2 = 0x00;
}
static void i2c_ocioso(void)  { while ((SSPCON2 & 0x1F) || (SSPSTAT & 0x04)) { } }
static void i2c_start(void)   { i2c_ocioso(); SSPCON2bits.SEN  = 1; while (SSPCON2bits.SEN)  { } }
static void i2c_restart(void) { i2c_ocioso(); SSPCON2bits.RSEN = 1; while (SSPCON2bits.RSEN) { } }
static void i2c_stop(void)    { i2c_ocioso(); SSPCON2bits.PEN  = 1; while (SSPCON2bits.PEN)  { } }

static uint8_t i2c_escrever(uint8_t b)      /* devolve 1 se houve reconhecimento */
{
    i2c_ocioso();  SSPBUF = b;
    while (SSPSTAT & 0x01) { }
    i2c_ocioso();
    return (uint8_t)!SSPCON2bits.ACKSTAT;
}

static uint8_t i2c_ler_ultimo(void)         /* le um byte e responde sem ACK */
{
    i2c_ocioso();  SSPCON2bits.RCEN = 1;
    while (!(SSPSTAT & 0x01)) { }
    uint8_t b = SSPBUF;
    SSPCON2bits.ACKDT = 1;  SSPCON2bits.ACKEN = 1;
    while (SSPCON2bits.ACKEN) { }
    return b;
}

static void mem_esperar(void)               /* pergunta, em vez de esperar 5 ms */
{
    for (;;) {
        i2c_start();
        uint8_t ack = i2c_escrever(MEM);
        i2c_stop();
        if (ack) { return; }
    }
}

static void mem_escrever(uint8_t end, const uint8_t *d, uint8_t n)  /* n <= 8 */
{
    i2c_start();
    i2c_escrever(MEM);  i2c_escrever(end);
    for (uint8_t i = 0; i < n; i++) { i2c_escrever(d[i]); }
    i2c_stop();
    mem_esperar();
}

static uint8_t mem_ler(uint8_t end)
{
    i2c_start();
    i2c_escrever(MEM);  i2c_escrever(end);
    i2c_restart();                          /* start repetido: uma transacao so */
    i2c_escrever(MEM | 1u);
    uint8_t b = i2c_ler_ultimo();
    i2c_stop();
    return b;
}
```

```c
#define END_EXT 0x20u   /* multiplo de 16: a pagina nao da a volta */

void main(void)
{
    const uint8_t d[8] = { 1, 2, 3, 4, 5, 6, 7, 8 };

    ADCON1 = 0x0F;                      /* RB0/RB1 digitais: o PBADEN volta a importar */
    LATEbits.LATE2 = 0;  TRISEbits.TRISE2 = 0;
    lcd_iniciar();
    i2c_iniciar();

    for (;;) {
        uint8_t lido = 0;
        LATEbits.LATE2 = 1;             /* a largura do pulso e o tempo da operacao */
#if TESTE == 1
        mem_escrever(END_EXT, d, 1);
        lido = mem_ler(END_EXT);
#elif TESTE == 2
        for (uint8_t i = 0; i < 8u; i++) { mem_escrever(END_EXT + i, &d[i], 1); }
#elif TESTE == 3
        mem_escrever(END_EXT, d, 8);
#else
        i2c_start();                    /* o erro numero um: 0x50 sem deslocar */
        i2c_escrever(0x50);  i2c_escrever(END_EXT);
        i2c_restart();
        i2c_escrever(0x51);
        lido = i2c_ler_ultimo();
        i2c_stop();
#endif
        LATEbits.LATE2 = 0;
        lcd_posicao(0, 0);  lcd_texto("Lido: ");  lcd_numero(lido, 3);
        __delay_ms(2000);               /* aqui pode: o programa so repete o teste */
    }
}
```

#tarefa(nota: "1,5 pt")[
  *Tarefa 3.* Com `TESTE` 1 (escreve um byte e o lê de volta), canal 1 em SCL e
  canal 2 em SDA, dispare pela descida de SDA com SCL em alto — a condição de
  início.

  #tab(columns: (1fr, 3cm),
    [Primeiro byte depois do início (leia na tela)], g[`0xA0`],
    [Tempo de subida de SDA (10% a 90%)], g[≈ 1 µs],
    [Tempo de descida de SDA], g[≈ dezenas de ns],
    [Previsão (P2)], [],
  )

  (a) Onde está o reconhecimento na tela, e quem o produz?
  #resp(n: 2)[No nono pulso de SCL depois de cada byte: SDA baixa, puxada pela memória. O mestre soltou a linha; se ninguém a puxasse, ela ficaria alta — sem reconhecimento.]

  (b) Por que a subida é lenta e a descida rápida?
  #resp(n: 2)[Dreno aberto: ninguém empurra a linha para cima. A descida é um transistor; a subida é o resistor de elevação carregando a capacitância da linha, uma curva RC.]
]

#tarefa(nota: "1,5 pt")[
  *Tarefa 4.* Meça a largura do pulso em RE2 com `TESTE` 2 (oito bytes, um por
  transação) e com `TESTE` 3 (os mesmos oito numa página).

  #tab(columns: (1fr, 3cm),
    [Oito bytes um a um], g[≈ 30 a 40 ms],
    [Oito bytes numa página], g[≈ 4 a 5 ms],
    [Razão], g[≈ 8],
    [Previsão (P3)], [],
  )

  (a) Por que a razão é perto de 8?
  #resp(n: 2)[Cada transação dispara um ciclo interno de gravação de alguns milissegundos; a página grava os oito bytes num ciclo só. O tempo no barramento (≈ 0,1 ms por byte) quase não pesa.]

  (b) O programa grava a página a partir de um endereço múltiplo de 16. O que
  aconteceria começando no endereço 14?
  #resp(n: 2)[O contador de endereço dá a volta dentro da página: os bytes que passassem do fim sobrescreveriam o começo da mesma página, e não iriam para a seguinte.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 5.* Compare a gravação de um byte na memória interna (Tarefa 2, dividida
  por três) com a de um byte na externa (`TESTE` 1).

  #tab(columns: (1fr, 3cm),
    [Um byte na interna], g[≈ 4 ms],
    [Um byte na externa], g[≈ 3 a 5 ms],
    [Previsão (P5)], [],
  )

  Por que a externa não é muito mais lenta, apesar do barramento?
  #resp(n: 2)[A transação no barramento custa ≈ 0,4 ms; o resto é o ciclo de gravação, que existe nas duas. E a externa pergunta pelo reconhecimento quando terminou, em vez de esperar o pior caso.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 6.* Grave com `TESTE` 4: o programa envia `0x50` como byte de controle —
  o endereço de sete bits da memória, sem deslocar.

  O que a tela mostra no nono pulso de SCL? O que o display mostra como byte lido?
  #lacuna(largura: 100%)

  Explique o erro e o valor certo.
  #resp(n: 2)[SDA fica alta no nono pulso: sem reconhecimento, ninguém respondeu. `0x50` é o dispositivo `0x28` em modo de escrita, que não existe. O endereço de sete bits (`0x50`) precisa ser deslocado uma casa e somado ao bit de sentido: `0xA0` para escrever, `0xA1` para ler.]
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.3fr),
  [Sintoma], [Causa provável],
  [Alvo absurdo na primeira vez], [Faltou conferir o marcador: a memória apagada lê `0xFF`],
  [A gravação nunca termina], [Interrupção entre `0x55` e `0xAA`: faltou desligar `GIE`],
  [Nenhum reconhecimento no barramento], [Chave da memória em OFF, sem resistor de elevação, ou endereço sem deslocar],
  [Programa preso em `mem_esperar`], [A memória não responde nunca: mesma causa da linha anterior],
  [Os botões mexem no barramento], [RB0/RB1 são SDA/SCL: botões só na Parte 1],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1 a 6, com as respostas escritas nelas, e a captura da
  Tarefa 3 com o byte `0xA0` identificado bit a bit.
]

#criterio[
  Previsões P1 a P5: 0,4 cada, pelo raciocínio.

  Tarefa 1 (memória interna e marcador): 1,5. Tarefa 2 (quando gravar e vida útil):
  1,5. Tarefa 3 (a transação no osciloscópio): 1,5. Tarefa 4 (página): 1,5.
  Tarefa 5 (interna contra externa): 1,0. Tarefa 6 (o endereço errado): 1,0.

  Na Tarefa 1(b), a resposta completa fala de energia caindo no meio da gravação.
  Na Tarefa 6, dizer "o endereço estava errado" sem o deslocamento vale metade.
]

= Se sobrar tempo

#opcional[
  *E1 — o alvo em dois lugares.* Grave o alvo também na memória externa e, na
  inicialização, compare as duas cópias. Se discordarem, qual você usa?
  #resp(n: 1)[A que tiver marcador válido; se as duas tiverem, a mais recente — o que exige gravar também um contador de versão.]
]

#opcional[
  *E2 — o custo de perguntar.* Troque `mem_esperar` por `__delay_ms(5)` e meça de
  novo a Tarefa 4. Quanto tempo a pergunta economizava?
  #resp(n: 1)[A diferença entre os 5 ms do pior caso e o tempo real de gravação da sua peça, a cada transação.]
]

#nota[
  No TP, parte 2, o alvo sobrevive a desligar. No R13, a memória guarda os ganhos
  e os coeficientes que o grupo vai aprender a partir dos dados do R10.
]
