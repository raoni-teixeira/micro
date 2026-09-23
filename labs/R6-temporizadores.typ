// R6 — Temporizadores: medir e contar
// Revisão 2026/2, alinhada à aula 5 (temporizadores) e à folha de referência
// dos temporizadores. Sem PWM: ele é o assunto da aula 6.
//
// Seis tarefas com nota (8,0), previsões P1–P6 da aula 5 (2,0) e três extensões
// sem nota no fim.
//
// Compilação:  typst compile R6-temporizadores.typ
//              typst compile --input gab=1 R6-temporizadores.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R6 — Temporizadores: medir e contar",
  subtitulo: "O mesmo contador marca o tempo e conta as voltas do rotor, sem o processador",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}

#objetivos[
  - Programar um intervalo no Timer0 pela pré-carga, e medir no osciloscópio o intervalo que ele realmente produz.
  - Medir a deriva do intervalo consultado no laço, e prevê-la pela duração da volta do laço.
  - Contar eventos externos com o Timer1, sem o processador, e reconhecer o repique na contagem.
  - Medir a rotação do cooler pelo tacômetro, e comparar a contagem por hardware com a contagem por software.
]

#kit[
  #tab(columns: (auto, 1fr),
    [CH2-1 (LCD)], [ON — o display do R4 mostra as contagens],
    [CH5-3 e CH5-4], [OFF, obrigatoriamente],
    [Chaves SWITCHS (PORTB)], [OFF],
    [CH3-5 (COOLER)], [OFF na Parte 2; ON nas Partes 3 e 4 — ventoinha em RC2, ligada em nível fixo],
    [CH3-2 (SPEED)], [OFF na Parte 2; ON nas Partes 3 e 4 — tacômetro em RC0, a entrada T13CKI do Timer1],
    [CH3-3, CH3-4, CH3-6 e CH3-7], [OFF],
  )

  *A verificar antes da sessão:* qual botão chega a RC0 — o O1 registrou SW2, e a
  seção `PUSH BUTTONS` tem um botão marcado `TMR1` (SW10) —, se RC0 tem resistor de
  pull-up com CH3-2 em OFF, e quantos pulsos por volta o tacômetro entrega
  (ventoinhas de computador costumam dar dois). Os registradores estão na *folha
  de referência dos temporizadores*, na página do curso.
]

#atencao[
  Com CH3-2 em ON, *não pressione o botão de RC0*: ele aterra o sinal do
  tacômetro.
]

*Pontuação.* As seis tarefas somam 8,0, e as previsões P1 a P6 da aula 5,
preenchidas antes da sessão, valem 2,0. A nota de cada tarefa e de cada previsão
está na margem, ao lado dela. A seção _Se sobrar tempo_, no fim, não vale nota:
é para quem terminar antes.

#bancada[
  *Osciloscópio:* ponta de prova em 10#sym.times e compensada, *acoplamento DC*,
  disparo na borda de subida do canal 1.
]

= Previsões — entregues no início da sessão

As mesmas perguntas do fim da aula 5. Quem trouxe a folha preenchida copia aqui
as respostas; a nota é do raciocínio, não do número.

#prevista(nota: "0,3 pt")[
  *P1.* O Timer0 vai marcar 10 ms, e um pino vai ser invertido a cada estouro.
  Que período você espera medir nesse pino?
  #resp(n: 1)[20 ms, ou 50 Hz: cada estouro é meia onda.]
]

#prevista(nota: "0,3 pt")[
  *P2.* O laço que consulta o indicador vai ganhar uma tarefa de 3 ms. O período
  do pino muda? E com uma tarefa de 7 ms?
  #resp(n: 2)[Muda. O estouro só é visto na primeira consulta depois de 10 ms: meio período de 12 ms (período 24 ms) com 3 ms, e de 14 ms (período 28 ms) com 7 ms.]
]

#prevista(nota: "0,3 pt")[
  *P3.* Um botão com pull-up (solto = 1) em RC0, e o Timer1 contando bordas de
  subida. O contador incrementa ao apertar ou ao soltar? Depois de dez apertos,
  quanto ele mostra?
  #resp(n: 2)[Ao soltar: a subida é a volta a 1. E raramente dez — o contato repica, e cada repique é uma borda a mais.]
]

#prevista(nota: "0,3 pt")[
  *P4.* A ventoinha gira a cerca de 3000 rpm e o tacômetro dá dois pulsos por
  volta. Quantos pulsos o Timer1 conta numa janela de 1 s?
  #resp(n: 1)[$3000 slash 60 dot.c 2 = 100$ pulsos.]
]

#prevista(nota: "0,4 pt")[
  *P5.* O mesmo programa conta os pulsos duas vezes: pelo Timer1 e por software,
  olhando RC0 a cada volta do laço. O laço vai ganhar uma tarefa de 20 ms. Qual
  das duas contagens muda, e para mais ou para menos?
  #resp(n: 2)[Só a de software, e para menos: ela olha o pino a cada 20 ms, e pulsos de 10 ms de período passam entre duas olhadas. O Timer1 conta cada borda no hardware, qualquer que seja o laço.]
]

#prevista(nota: "0,4 pt")[
  *P6.* Calcule `T0CON` e a pré-carga para uma janela de 1 s com divisor 1:256.
  O divisor 1:64 também serviria?
  #resp(n: 2)[15 625 contagens de 64 µs: pré-carga 49 911 = `0xC2F7`, `T0CON = 0x87`. Com 1:64, 62 500 contagens de 16 µs, pré-carga 3 036 = `0x0BDC`, `T0CON = 0x85` — também exata e com passo mais fino.]
]

= Parte 1 — o Timer0 como relógio

Na aula 5, o relógio por consulta ao indicador marcou 50 em 60 s. Aqui o mesmo
defeito aparece em milissegundos, e dá para medir no osciloscópio.

#tarefa(nota: "1,0 pt")[
  *Tarefa 1.* O programa abaixo inverte RD0 a cada estouro do Timer0. Preencha
  `T0CON` e a pré-carga para um intervalo de *10 ms*, com fonte interna e sem
  divisor. O display fica fora deste programa.

  ```c
  #define _XTAL_FREQ 16000000UL
  #include <xc.h>
  #include <stdint.h>

  #define PRECARGA  ______u          /* 10 ms a 250 ns por contagem */
  /* #define TAREFA()  __delay_ms(3)    -- Tarefa 2 */

  static void t0_recarregar(void)
  {
      TMR0H = (uint8_t)(PRECARGA >> 8);    /* alto primeiro: vai para o buffer */
      TMR0L = (uint8_t)(PRECARGA & 0xFF);  /* esta escrita transfere os dois   */
  }

  void main(void)
  {
      ADCON1 = 0x0F;                  /* R5: tudo digital na primeira linha */
      LATDbits.LATD0   = 1;
      TRISDbits.TRISD0 = 0;

      t0_recarregar();
      T0CON = 0b________;
      INTCONbits.TMR0IF = 0;

      for (;;) {
          if (INTCONbits.TMR0IF) {    /* passaram 10 ms? */
              INTCONbits.TMR0IF = 0;  /* o hardware nao zera o indicador */
              t0_recarregar();
              LATDbits.LATD0 ^= 1;
          }
          /* TAREFA(); */
      }
  }
  ```

  #tab(columns: 9,
    [bit], [7], [6], [5], [4], [3], [2], [1], [0],
    [nome], [`TMR0ON`], [`T08BIT`], [`T0CS`], [`T0SE`], [`PSA`], [`T0PS2`], [`T0PS1`], [`T0PS0`],
    [valor], ..(if gab { ([1], [0], [0], [0], [1], [0], [0], [0]) } else { range(8).map(_ => []) }),
  )

  Pré-carga: #if gab [65 536 − 40 000 = 25 536 = `0x63C0`; `T0CON = 0x88`] else [#lacuna(largura: 6cm)]

  Meça RD0 no conector de PORTD:

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Previsto (P1)], [Medido],
    [Período da onda em RD0], [#if gab [20 ms]], [],
    [Frequência], [#if gab [50 Hz]], [],
  )

  Por que o período é o *dobro* do intervalo do temporizador?
  #resp(n: 1)[Cada estouro inverte o pino uma vez; um período completo tem duas inversões, logo dois intervalos de 10 ms.]
]

#resposta[
  O `T0CON = 0x88` se lê: ligado, 16 bits, fonte interna, divisor desviado.
  `T0SE` e `T0PS` não importam aqui — o primeiro só vale com fonte externa, o
  segundo só com `PSA = 0` —, e qualquer valor neles é aceito se o aluno disser
  isso.
]

#tarefa(nota: "1,5 pt")[
  *Tarefa 2.* Agora o laço ganha uma tarefa. Descomente as duas linhas de
  `TAREFA()`, grave com 3 ms e depois com 7 ms, e meça.

  #tab(columns: (1fr, 3cm, 3cm),
    [Tarefa no laço], [Previsto (P2)], [Período medido],
    [3 ms], [#if gab [24 ms]], [],
    [7 ms], [#if gab [28 ms]], [],
  )

  (a) Escreva o meio período em função do intervalo programado (10 ms) e da
  duração $L$ de uma volta do laço.
  #resp(n: 2)[As consultas caem em múltiplos de $L$ depois da recarga, e o estouro é visto pela primeira consulta que chega em 10 ms ou depois: meio período $= ceil(10 "ms" slash L) dot.c L$. Com 3 ms, 12 ms; com 7 ms, 14 ms.]

  (b) Qual duração de tarefa, entre 1 e 10 ms, faria o período voltar a 20 ms? Isso
  corrige o programa?
  #resp(n: 2)[Qualquer divisor de 10 ms: 1, 2, 2,5, 5 ou 10 ms. Não corrige: é coincidência, e desaparece na primeira linha acrescentada ao laço. O intervalo continua dependendo do laço.]
]

#conceito[
  O temporizador contou 10 ms exatos. Quem errou foi a *recarga*, que acontece
  no instante da consulta, e não no instante do estouro. O intervalo fica
  arredondado para cima até um múltiplo da volta do laço, e o osciloscópio mostra
  isso como um número, não como uma impressão.

  A saída é deixar o hardware chamar o programa no instante do estouro — a
  interrupção, que a extensão E1 mostra funcionando e o R8 explica por inteiro.
]

= Parte 2 — o contador que não sabe o que é tempo

O programa desta parte e das seguintes é um só. O Timer1 conta bordas de subida
em RC0 e o Timer0 marca janelas de 1 s. No fim de cada janela, o display mostra
o que o Timer1 contou (`N`), o que o software contou olhando o mesmo pino (`S`),
o total acumulado (`T`) e o número de janelas (`J`). Compile-o junto com o
`lcd.c` do R4.

```c
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>
#include "lcd.h"

#define JANELA  ______u               /* 1 s com divisor 1:256 -- Tarefa 6 */
/* #define TAREFA()  __delay_ms(20)      -- Tarefa 5 */

static void janela_recarregar(void)
{
    TMR0H = (uint8_t)(JANELA >> 8);
    TMR0L = (uint8_t)(JANELA & 0xFF);
}

static void mostrar(uint16_t n, uint16_t s, uint16_t t, uint16_t j)
{
    lcd_posicao(0, 0);
    lcd_texto("N=");  lcd_numero(n, 5);  lcd_texto(" S=");  lcd_numero(s, 5);
    lcd_posicao(1, 0);
    lcd_texto("T=");  lcd_numero(t, 5);  lcd_texto(" J=");  lcd_numero(j, 5);
}

void main(void)
{
    uint16_t n = 0, s = 0, total = 0, janelas = 0;
    uint8_t  antes = 1;               /* nivel anterior de RC0, para o software */

    ADCON1 = 0x0F;                    /* RE0-RE1 (display) digitais */
    LATCbits.LATC2   = 1;             /* ventoinha ligada em nivel fixo (CH3-5) */
    TRISCbits.TRISC2 = 0;
    TRISCbits.TRISC0 = 1;             /* RC0 = T13CKI: botao ou tacometro */

    lcd_iniciar();

    TMR1H = 0;  TMR1L = 0;
    T1CON = 0x83;                     /* 16 bits, 1:1, sincronizado, pino RC0 */

    janela_recarregar();
    T0CON = 0b________;               /* 16 bits, interno, 1:256 -- Tarefa 6 */
    INTCONbits.TMR0IF = 0;

    for (;;) {
        uint8_t agora = PORTCbits.RC0;          /* contagem por software:   */
        if (antes == 0u && agora == 1u) {       /* uma subida vista no laco */
            s++;
        }
        antes = agora;

        if (INTCONbits.TMR0IF) {                /* fechou a janela de 1 s */
            INTCONbits.TMR0IF = 0;
            janela_recarregar();

            uint8_t lo = TMR1L;                 /* baixo primeiro: congela o alto */
            n = ((uint16_t)TMR1H << 8) | lo;
            TMR1H = 0;  TMR1L = 0;              /* nova janela */

            total += n;
            janelas++;
            mostrar(n, s, total, janelas);
            s = 0;
        }
        /* TAREFA(); */
    }
}
```

#tarefa(nota: "1,5 pt")[
  *Tarefa 3.* Com CH3-2 e CH3-5 em OFF, grave o programa (a janela de 1 s é a da
  P6). Aperte o botão de RC0 devagar, uma vez, e observe *em que momento* o `T`
  muda. Depois aperte dez vezes e registre o total, três rodadas.

  #tab(columns: (1fr, 2.4cm, 2.4cm, 2.4cm),
    [], [Rodada 1], [Rodada 2], [Rodada 3],
    [Apertos], [10], [10], [10],
    [`T` contado pelo Timer1], [], [], [],
  )

  (a) O contador incrementou ao apertar ou ao soltar? Confere com a P3?
  #resp(n: 1)[Ao soltar: o Timer1 conta bordas de subida, e com pull-up a subida é a volta a 1.]

  (b) Por que o total passa de dez, e por que muda de uma rodada para outra?
  #resp(n: 2)[O contato repica: fecha e abre várias vezes em poucos milissegundos, e o contador — fiel — conta cada subida. O número de repiques depende de como o dedo apertou, e por isso varia.]
]

#conceito[
  O hardware não errou: o sinal é que não era o que parecia. Um contador rápido e
  exato revela o repique que um laço lento esconderia. O tratamento do repique é
  assunto do R8.
]

= Parte 3 — contar as voltas

#tarefa(nota: "1,5 pt")[
  *Tarefa 4.* Ligue CH3-5 e CH3-2: a ventoinha gira em plena rotação, e o
  tacômetro chega a RC0. Espere a rotação estabilizar e meça a frequência do
  sinal no ponto de teste `SPEED`.

  #tab(columns: (1fr, 3cm),
    [Previsão de `N` (P4)], [],
    [Frequência em `SPEED` (osciloscópio)], [],
    [`N` no display (pulsos em 1 s)], [],
    [Pulsos por volta (verificado na bancada)], [],
    [Rotação, em rpm], [],
  )

  (a) `N` e a frequência medida deveriam ser iguais. Por quê?
  #resp(n: 1)[`N` é o número de bordas de subida contadas em 1 s, e isso é, por definição, a frequência em hertz.]

  (b) Por que o Timer1, e não o Timer0, que também conta pulsos externos?
  #resp(n: 1)[Porque o tacômetro chega a RC0, que é T13CKI, a entrada do Timer1. A entrada do Timer0 é RA4 (T0CKI). O pino decide o temporizador.]
]

= Parte 4 — hardware contra software

Com o laço vazio, a contagem por software (`S`) acompanha a do Timer1 (`N`). A
pergunta é o que acontece quando o laço tem outra coisa para fazer.

#tarefa(nota: "1,5 pt")[
  *Tarefa 5.* Com a ventoinha girando, anote `N` e `S` com o laço vazio. Depois
  descomente as duas linhas de `TAREFA()` (20 ms) e anote de novo.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Laço vazio], [Tarefa de 20 ms],
    [`N` (Timer1)], [], [],
    [`S` (software)], [], [],
  )

  (a) Qual das duas mudou? Confere com a P5?
  #resp(n: 1)[Só `S`. `N` fica igual.]

  (b) Explique o valor de `S` com a tarefa, a partir do período do sinal e da
  duração da volta do laço.
  #resp(n: 3)[O software só vê o pino uma vez a cada ≈ 20 ms. Um sinal de ≈ 100 Hz tem período de 10 ms: entre duas olhadas passam dois pulsos, e o software só conta uma subida quando uma olhada pega nível baixo e a seguinte pega nível alto. O resultado depende da relação entre as duas frequências, e fica muito abaixo de `N` — pode até ficar perto de zero.]

  (c) Com a tarefa de 20 ms, a janela de 1 s continua medindo 1 s? Por quê?
  #resp(n: 2)[Continua, por coincidência: 20 ms divide 1000 ms, e a consulta que vê o estouro cai quase em cima dele. Com uma tarefa de 30 ms, a janela passaria a 1,02 s — a deriva da Parte 1.]
]

#conceito[
  O Timer1 não perdeu nada porque ele não depende de o programa olhar. O
  software perdeu porque contar, para ele, é olhar — e ele estava ocupado. É o
  mesmo argumento do relógio da aula 5, agora com eventos no lugar de tempo:
  o que o hardware faz sozinho não sofre com o que o laço faz.
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 6.* A janela de 1 s é o instrumento das Partes 2 a 4. Verifique-a.

  (a) Escreva os valores que você usou (P6):

  `JANELA` = #if gab [`49911u` (`0xC2F7`)] else [#lacuna(largura: 3cm)] #h(1fr)
  `T0CON` = #if gab [`0b10000111` (`0x87`)] else [#lacuna(largura: 3cm)]

  (b) Com o laço vazio, zere o kit, dispare um cronômetro no mesmo instante e leia
  `J` depois de 60 s pelo cronômetro.

  `J` após 60 s: #lacuna(largura: 3cm)

  (c) A diferença, se houver, está dentro do que o seu tempo de reação explica?
  #resp(n: 2)[Sim: `J` deve dar 60, com ±1 pela partida manual do cronômetro. O erro da janela é de microssegundos por segundo com o laço vazio.]
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.3fr),
  [Sintoma], [Causa provável],
  [Período em RD0 maior que o programado], [É a Tarefa 2: a recarga espera a volta do laço],
  [Janela com duração errada], [`TMR0L` escrito antes de `TMR0H`: o byte alto vem do valor anterior],
  [`N` sempre zero], [CH3-2 em OFF, `TRISC0` em saída, ou `TMR1CS = 0`],
  [`N` conta sem nada ligado], [RC0 sem pull-up: pino flutuando],
  [Display com lixo], [`ADCON1` deixa RE0/RE1 analógicos (AN5 e AN6)],
  [Contagem cresce sem parar entre janelas], [Faltou zerar `TMR1H` e `TMR1L` no fim da janela],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1 a 6.

  Responda também:

  (a) Na Parte 1, o Timer0 contou certo e o pino errou. Explique onde estava o
  erro, em termos de *quando* a recarga acontece.
  #resp(n: 2)[A recarga acontece na consulta, não no estouro. O tempo entre os dois é perdido a cada intervalo, e o intervalo fica arredondado para um múltiplo da volta do laço.]

  (b) Neste roteiro, o Timer0 mediu tempo e o Timer1 contou eventos. O que o
  processador fez em cada caso?
  #resp(n: 2)[Timer0: o processador consultou o indicador e recarregou, e é aí que entra o erro. Timer1: nada durante a contagem; só leu o total no fim da janela.]
]

#criterio[
  Previsões P1 a P4: 0,3 cada. P5 e P6: 0,4 cada. Total 2,0, pelo raciocínio.

  Tarefa 1 (`T0CON`, pré-carga e medida): 1,0. Tarefa 2 (deriva prevista e
  medida): 1,5 — a nota está na fórmula da alínea (a), não em acertar o número.
  Tarefa 3 (botão e repique): 1,5. Tarefa 4 (tacômetro): 1,5. Tarefa 5
  (hardware contra software): 1,5. Tarefa 6 (janela de 1 s): 1,0.

  Na Tarefa 5, a resposta completa explica `S` pela amostragem — o software só
  vê o pino uma vez por volta do laço. Dizer "o software é mais lento" vale
  metade.

  As extensões E1 a E3 não pontuam.
]

= Se sobrar tempo

#opcional[
  *E1 — a mesma deriva, por interrupção.* Refaça a Tarefa 2 com a recarga dentro
  de uma função que o hardware chama no estouro, como na aula 5:

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
  #resp(n: 1)[20 ms de novo, qualquer que seja a tarefa: a recarga acontece microssegundos depois do estouro. O mecanismo é o assunto do R8.]
]

#opcional[
  *E2 — o Timer0 como contador.* Se algum botão alcançar RA4 (T0CKI) — ou um
  botão avulso na protoboard, entre RA4 e o terra, com pull-up de 10 kΩ —, conte
  os apertos com o Timer0 em 8 bits (`T0CON = 0xE8`) e mostre `TMR0L` nos LEDs.
  Troque para a borda de descida (`T0CON = 0xF8`): o momento da contagem muda?
  #resp(n: 1)[Muda: com `T0SE = 1` a contagem acontece ao apertar. O repique continua.]
]

#opcional[
  *E3 — a janela com divisor 1:64.* Troque para `T0CON = 0x85` e `JANELA` =
  `3036u`. A janela continua de 1 s? O que se ganha com o passo de 16 µs?
  #resp(n: 1)[Continua exata. O passo menor permite ajustar a pré-carga com resolução de 16 µs em vez de 64 µs — útil para compensar os ciclos da recarga.]
]

#nota[
  No R7: o PWM. O Timer2 gerando a onda sozinho, a ventoinha que parte numa razão
  cíclica e para em outra — contada pelo mesmo Timer1 de hoje —, e o limite de
  frequência do módulo, ouvido no buzzer. No R8, a interrupção, e o repique da
  Tarefa 3 tratado de verdade.
]
