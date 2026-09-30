// R6 — Temporizadores: medir e contar
// Versão simplificada: cinco tarefas, uma regravação na parte da ventoinha,
// janela de 1 s entregue pronta. Previsões P1–P5 valem 2,0; tarefas, 8,0.
//
// Compilação:  typst compile R6-temporizadores.typ                 (aluno)
//              typst compile --input gab=1 R6-temporizadores.typ   (gabarito)

#import "estilo.typ": *

#show: conf.with(
  titulo: "R6 — Temporizadores: medir e contar",
  subtitulo: "O mesmo contador marca o tempo e conta as voltas do rotor, sem o processador",
  modo: "roteiro",
)

// Rótulo de margem com a pontuação ("TAREFA · 1,6 pt").
#let tarefa_pts(pts, c) = _caixa_margem("Tarefa · " + pts + " pt", c)
#let prev_pts(pts, c) = _caixa_margem("Previsão · " + pts + " pt", c)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}
// Célula de tabela: vazia para o aluno, preenchida no gabarito.
#let g(x) = if gab { x } else { [] }
// Código com lacunas: "@CHAVE@" vira "______" no aluno e o valor no gabarito.
#let codigo(src, pares) = {
  let s = src
  for (k, v) in pares { s = s.replace("@" + k + "@", if gab { v } else { "________" }) }
  raw(s, block: true, lang: "c")
}

#objetivos[
  - Programar um intervalo no Timer0 e medir no osciloscópio o intervalo que ele realmente produz.
  - Medir quanto a volta do laço atrasa um relógio feito por consulta ao indicador.
  - Contar eventos externos com o Timer1, sem o processador, e reconhecer o repique na contagem.
  - Medir a rotação da ventoinha e comparar a contagem por hardware com a contagem por software.
]

#kit[
  #tab(columns: (auto, 1fr),
    [Chave], [Posição],
    [CH2-1 (LCD)], [ON — o display do R4 mostra as contagens],
    [CH5-3 e CH5-4], [OFF, obrigatoriamente],
    [Chaves SWITCHS (PORTB)], [OFF],
    [CH3-1 (tacômetro em RC0)], [OFF na Parte 2; ON nas Partes 3 e 4],
    [CH3-5 (COOLER, RC2)], [OFF na Parte 2; ON nas Partes 3 e 4],
    [Demais chaves de CH3], [OFF],
  )
]

#atencao[
  Com CH3-1 em ON, não pressione o botão de RC0: ele aterra o sinal do
  tacômetro.
]

#perigo[
  Garra de terra do osciloscópio no GND do kit. Os pontos de 12 V (COOLER,
  HEATER, LAMP) nunca recebem a garra; a ponta de prova pode tocá-los.
]

#bancada[
  Osciloscópio: ponta em 10× e compensada, acoplamento DC, disparo na borda de
  subida do canal 1.
]

*Pontuação.* As cinco tarefas valem 1,6 cada e somam 8,0. As previsões P1 a P5,
preenchidas antes da sessão, valem 0,4 cada e somam 2,0. A nota da previsão é
do raciocínio, não do número. A seção _Se sobrar tempo_ não vale nota.

#docente[
  *Antes da sessão:* (1) qual botão chega a RC0 — o O1 registrou SW2, e a seção
  PUSH BUTTONS tem um marcado TMR1 (SW10); (2) se RC0 tem pull-up com CH3-1 em
  OFF; (3) quantos pulsos por volta o tacômetro entrega, para escrever no
  quadro; (4) a frequência em SPEED e o nível mais curto do sinal. A tarefa de
  8 ms da Tarefa 5 precisa ser *maior* que esse nível; se não for, aumente-a.
  Distribua o projeto da Parte 2 já montado com `lcd.c` e `lcd.h`.
]

= Previsões — entregues no início da sessão

#prev_pts("0,4")[
  *P1.* O Timer0 vai marcar 10 ms, e um pino vai ser invertido a cada estouro.
  Que período você espera medir nesse pino?
  #resp(n: 1)[20 ms (50 Hz): cada estouro inverte o pino, e um período tem duas inversões.]
]

#prev_pts("0,4")[
  *P2.* O laço que consulta o indicador vai ganhar uma tarefa de 7 ms. O período
  do pino muda? Para quanto?
  #resp(n: 2)[Muda. O indicador só é visto nas voltas do laço, a cada 7 ms: o estouro de 10 ms é notado em 14 ms. Meio período de 14 ms, período de 28 ms.]
]

#prev_pts("0,4")[
  *P3.* Um botão com pull-up (solto = 1) em RC0, e o Timer1 contando bordas de
  subida. O contador incrementa ao apertar ou ao soltar? Depois de dez apertos,
  quanto ele mostra?
  #resp(n: 2)[Ao soltar: a subida é a volta para 1. Dez, se o contato fosse ideal; o raciocínio que antecipa o repique vale a nota cheia.]
]

#prev_pts("0,4")[
  *P4.* A ventoinha gira a cerca de 3000 rpm, e o tacômetro dá dois pulsos por
  volta. Quantos pulsos o Timer1 conta numa janela de 1 s?
  #resp(n: 1)[3000/60 = 50 voltas/s; × 2 = 100 pulsos.]
]

#prev_pts("0,4")[
  *P5.* O mesmo programa conta os pulsos duas vezes: pelo Timer1 e por software,
  olhando RC0 a cada volta do laço. O laço vai ganhar uma tarefa de 8 ms. Qual
  das duas contagens muda, e para mais ou para menos?
  #resp(n: 2)[Só a do software, e para menos. A 100 Hz cada nível dura cerca de 5 ms: com o laço olhando a cada 8 ms, níveis inteiros passam sem ser vistos. O Timer1 não depende do laço.]
]

= Parte 1 — o Timer0 como relógio

#let prog1 = ```
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>

#define PRECARGA @P@  /* 10 ms, 250 ns cada */
/* #define TAREFA() __delay_ms(7)   Tarefa 2 */

static void t0_recarregar(void)
{
    TMR0H = (uint8_t)(PRECARGA >> 8);  /* buffer */
    TMR0L = (uint8_t)(PRECARGA & 0xFF);
}

void main(void)
{
    ADCON1 = 0x0F;
    LATDbits.LATD0   = 1;    /* LAT antes de TRIS */
    TRISDbits.TRISD0 = 0;

    t0_recarregar();
    T0CON = @C@;
    INTCONbits.TMR0IF = 0;

    for (;;) {
        if (INTCONbits.TMR0IF) {     /* 10 ms? */
            INTCONbits.TMR0IF = 0;   /* zerar e' nosso */
            t0_recarregar();
            LATDbits.LATD0 ^= 1;
        }
        /* TAREFA(); */
    }
}
```.text

#tarefa_pts("1,6")[
  *Tarefa 1.* O programa abaixo inverte RD0 a cada estouro do Timer0. Preencha
  `T0CON` e a pré-carga para um intervalo de 10 ms, com fonte interna, 16 bits e
  sem divisor.

  #codigo(prog1, (P: "25536u", C: "0b10001000"))

  #tab(columns: 9,
    [bit], [7], [6], [5], [4], [3], [2], [1], [0],
    [nome], [TMR0ON], [T08BIT], [T0CS], [T0SE], [PSA], [T0PS2], [T0PS1], [T0PS0],
    [valor], ..(if gab { ([1], [0], [0], [0], [1], [0], [0], [0]) } else { range(8).map(_ => []) }),
  )

  Pré-carga: #if gab [65 536 − 10 ms / 250 ns = 65 536 − 40 000 = 25 536 (0x63C0)] else [#lacuna(largura: 5cm)]

  Meça RD0 no conector de PORTD:

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Previsto (P1)], [Medido],
    [Período em RD0], [], g[≈ 20 ms],
    [Frequência], [], g[≈ 50 Hz],
  )
]

#tarefa_pts("1,6")[
  *Tarefa 2.* Descomente as duas linhas de `TAREFA()`, grave e meça.

  #tab(columns: (1fr, 3cm, 3cm),
    [Tarefa no laço], [Previsto (P2)], [Período medido],
    [7 ms], [], g[≈ 28 ms],
  )

  Escreva o meio período em função do intervalo programado (10 ms) e da duração
  $L$ de uma volta do laço.
  #resp(n: 2)[Meio período = ⌈10 ms / $L$⌉ · $L$. Com $L$ ≈ 7 ms: 2 · 7 = 14 ms. O intervalo é arredondado para cima até um múltiplo da volta do laço.]
]

#conceito[
  O temporizador contou 10 ms exatos. Quem errou foi a recarga, que acontece no
  instante da consulta, e não no instante do estouro. A saída é o hardware
  chamar o programa no instante do estouro — a interrupção, que a extensão E1
  mostra funcionando e o R8 explica por inteiro.
]

= Parte 2 — o contador que não sabe o que é tempo

O programa desta parte e das seguintes é um só, e vem pronto no projeto da
página do curso, junto com o `lcd.c` do R4. O Timer1 conta bordas de subida em RC0, e o Timer0 marca
janelas de 1 s. No fim de cada janela, o display mostra o que o Timer1 contou
(N), o que o software contou olhando o mesmo pino (S), o total acumulado (T) e o
número de janelas (J).

```c
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>
#include "lcd.h"

#define JANELA 49911u  /* 65536 - 16 MHz/4/256 */
/* #define TAREFA() __delay_ms(8)   Tarefa 5 */

static void janela_recarregar(void)
{
    TMR0H = (uint8_t)(JANELA >> 8);
    TMR0L = (uint8_t)(JANELA & 0xFF);
}

/* N = Timer1, S = software, T = total, J = janelas */
static void mostrar(uint16_t n, uint16_t s,
                    uint16_t t, uint16_t j)
{
    lcd_posicao(0, 0);
    lcd_texto("N="); lcd_numero(n, 5);
    lcd_texto(" S="); lcd_numero(s, 5);
    lcd_posicao(1, 0);
    lcd_texto("T="); lcd_numero(t, 5);
    lcd_texto(" J="); lcd_numero(j, 5);
}

void main(void)
{
    uint16_t n = 0, s = 0, total = 0, janelas = 0;
    uint8_t antes = 1;         /* nivel anterior de RC0 */

    ADCON1  = 0x0F;            /* tudo digital (LCD em RE) */
    CCP1CON = 0x00;            /* RC2 como pino comum */

    /* o tacografo tambem chega a RA4 (T0CKI):
       RA4 fica entrada para nao aterrar o sinal */
    LATAbits.LATA4   = 0;
    TRISAbits.TRISA4 = 1;

    LATCbits.LATC2   = 1;      /* LAT antes de TRIS */
    TRISCbits.TRISC2 = 0;      /* ventoinha ligada */
    TRISCbits.TRISC0 = 1;      /* RC0 = T13CKI */
    lcd_iniciar();

    TMR1H = 0; TMR1L = 0;
    T1CON = 0x83;              /* 16 bits, 1:1, RC0 */
    janela_recarregar();
    T0CON = 0x87;              /* 16 bits, 1:256 */
    INTCONbits.TMR0IF = 0;

    for (;;) {
        uint8_t agora = PORTCbits.RC0;   /* software */
        if (antes == 0u && agora == 1u) s++;
        antes = agora;

        if (INTCONbits.TMR0IF) {   /* fechou 1 s */
            INTCONbits.TMR0IF = 0;
            janela_recarregar();
            uint8_t lo = TMR1L;    /* baixo primeiro */
            n = ((uint16_t)TMR1H << 8) | lo;
            TMR1H = 0; TMR1L = 0;  /* nova janela */
            total += n;  janelas++;
            mostrar(n, s, total, janelas);
            s = 0;
        }
        /* TAREFA(); */
    }
}
```

#tarefa_pts("1,6")[
  *Tarefa 3.* Com CH3-1 e CH3-5 em OFF, grave o programa. Aperte o botão de RC0
  devagar, uma vez, e observe em que momento o T muda. Depois zere o kit, aperte
  dez vezes e registre o total.

  #tab(columns: (1fr, 3cm),
    [Apertos], [10],
    [T contado pelo Timer1], g[> 10, varia],
  )

  (a) O contador incrementou ao apertar ou ao soltar? Confere com a P3?
  #resp(n: 1)[Ao soltar: é a borda de subida, com pull-up.]

  (b) Por que o total passa de dez?
  #resp(n: 2)[Repique: o contato ricocheteia e produz várias subidas por aperto. O Timer1 conta todas, porque é rápido e não depende do laço.]
]

#conceito[
  O hardware não errou: o sinal é que não era o que parecia. Um contador rápido
  e exato revela o repique que um laço lento esconderia. O tratamento do repique
  é assunto do R8.
]

= Parte 3 — contar as voltas

#tarefa_pts("1,6")[
  *Tarefa 4.* Ligue CH3-1 e CH3-5: a ventoinha gira em plena rotação, e o
  tacômetro chega a RC0. Espere a rotação estabilizar, meça a frequência no
  ponto de teste SPEED e anote o display com o laço vazio.

  #tab(columns: (1fr, 3.5cm),
    [Previsão de N (P4)], [],
    [Frequência em SPEED (osciloscópio)], g[≈ 100 Hz],
    [N no display], g[≈ 100],
    [S no display], g[≈ N],
    [Pulsos por volta (no quadro)], [],
    [Rotação, em rpm], g[N · 60 / pulsos por volta],
  )

  N e a frequência medida deveriam ser iguais. Por quê?
  #resp(n: 2)[N é o número de pulsos em 1 s, que é a definição de frequência em hertz. A diferença de uma contagem vem da janela não estar alinhada com os pulsos.]
]

= Parte 4 — hardware contra software

#tarefa_pts("1,6")[
  *Tarefa 5.* Com a ventoinha girando, descomente as duas linhas de `TAREFA()`
  (8 ms), grave e compare com os valores da Tarefa 4.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Laço vazio (Tarefa 4)], [Tarefa de 8 ms],
    [N (Timer1)], [], g[≈ 100],
    [S (software)], [], g[bem menor que N],
  )

  Por que S caiu e N não? Use o período do sinal e a duração da volta do laço.
  #resp(n: 3)[O software só vê uma subida se olhar o pino uma vez no nível baixo e de novo no alto. A 100 Hz cada nível dura cerca de 5 ms; com uma olhada a cada 8 ms, níveis inteiros passam sem ser vistos. O Timer1 conta no hardware, sem depender de o programa olhar.]
]

#conceito[
  O Timer1 não perdeu nada porque ele não depende de o programa olhar. O
  software perdeu porque contar, para ele, é olhar — e ele estava ocupado. É o
  mesmo argumento da Parte 1, agora com eventos no lugar de tempo: o que o
  hardware faz sozinho não sofre com o que o laço faz.
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.4fr),
  [Sintoma], [Causa provável],
  [Período em RD0 maior que o programado], [É a Tarefa 2: a recarga espera a volta do laço],
  [N sempre zero], [CH3-1 em OFF, ou TRISC0 em saída],
  [N conta sem nada ligado], [RC0 sem pull-up: pino flutuando],
  [Display com lixo], [Falta `ADCON1 = 0x0F`: RE0/RE1 analógicos (AN5 e AN6)],
  [Contagem cresce sem parar entre janelas], [Faltou zerar TMR1H e TMR1L no fim da janela],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1 a 5, com as respostas escritas nelas.
]

= Se sobrar tempo

#semnota[
  *E1 — a deriva, por interrupção.* Refaça a Tarefa 2 com a recarga dentro de
  uma função que o hardware chama no estouro:

  ```c
  void __interrupt() tratar(void)
  {
      if (INTCONbits.TMR0IF) {
          INTCONbits.TMR0IF = 0;
          t0_recarregar();
          LATDbits.LATD0 ^= 1;
      }
  }
  ```

  No `main`, antes do laço: `INTCONbits.TMR0IE = 1; INTCONbits.GIE = 1;`, e o
  laço fica só com `TAREFA();`. Meça o período com a tarefa de 7 ms.
]

#semnota[
  *E2 — a conta da janela.* Confira os valores que o programa da Parte 2 trouxe
  prontos: `JANELA = 49911u` e `T0CON = 0x87`, para 1 s com divisor 1:256. O
  divisor 1:64 também serviria? Se servir, troque para `T0CON = 0x85` e
  `JANELA = 3036u` e confira que J continua subindo uma vez por segundo.
  #resp(n: 2)[1:256 → 64 µs por contagem; 1 s / 64 µs = 15 625; 65 536 − 15 625 = 49 911. Com 1:64 → 16 µs; 62 500 contagens, ainda cabe em 16 bits: 65 536 − 62 500 = 3036. 1:32 não serviria (125 000 > 65 536).]
]

#nota[
  No R7: o PWM. O Timer2 gerando a onda sozinho, e a ventoinha que parte numa
  razão cíclica e para em outra — contada pelo mesmo Timer1 de hoje. O ponto
  medido na Tarefa 4, em plena rotação, é o primeiro da curva.
]
