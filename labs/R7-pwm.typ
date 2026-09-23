// R7 — PWM: o pino, a carga e o limite do módulo
// Revisão 2026/2, alinhada à aula 6 (modulação por largura de pulso). Usa o
// Timer1 e a janela de 1 s do R6 para medir a rotação.
//
// Seis tarefas com nota (8,0), previsões P1–P5 da aula 6 (2,0) e três extensões
// sem nota no fim. O aquecedor fica de fora: ele é acionado por relé, e relé não
// faz PWM (aula 6).
//
// Compilação:  typst compile R7-pwm.typ
//              typst compile --input gab=1 R7-pwm.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R7 — PWM: o pino, a carga e o limite do módulo",
  subtitulo: "Período, razão cíclica e resolução medidos, e o que a ventoinha e o buzzer fazem com eles",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}

#objetivos[
  - Medir período, frequência e razão cíclica do PWM, e confrontá-los com `PR2` e o divisor do Timer2.
  - Distinguir o sinal no pino do microcontrolador do sinal na carga, através do driver.
  - Medir a razão cíclica de partida e de parada da ventoinha pela rotação, contada com o Timer1.
  - Trocar frequência por resolução, e ouvir o resultado.
  - Reconhecer os limites do módulo: os 100% que não cabem e a frequência mínima.
]

#kit[
  #tab(columns: (auto, 1fr),
    [CH2-1 (LCD)], [ON — mostra a razão cíclica, a configuração e a contagem],
    [CH5-3 e CH5-4], [OFF, obrigatoriamente],
    [Chaves SWITCHS (PORTB)], [OFF],
    [CH3-5 (COOLER)], [ON — ventoinha em RC2, a saída do CCP1],
    [CH3-2 (SPEED)], [ON — tacômetro em RC0, contado pelo Timer1 como no R6],
    [CH3-6 (BUZZER)], [OFF — só entra na Parte 5, no lugar do cooler],
    [CH3-3, CH3-4 e CH3-7], [OFF],
    [Botões], [`INT0` (SW12, RB0) sobe 10%, `INT1` (SW13, RB1) desce 10%, `INT2` (SW14, RB2) troca a configuração],
  )

  Com CH3-2 em ON, *não pressione o botão de RC0*: ele aterra o tacômetro. Os
  registradores estão na *folha de referência dos temporizadores*.
]

#perigo[
  O ponto de teste `COOLER` chega a 12 V. Mantenha a garra de terra de *todas* as
  pontas de prova no mesmo terra do kit, e nunca a prenda no ponto de teste.
]

*Pontuação.* As seis tarefas somam 8,0, e as previsões P1 a P5 da aula 6,
preenchidas antes da sessão, valem 2,0. A nota de cada tarefa e de cada previsão
está na margem, ao lado dela. A seção _Se sobrar tempo_, no fim, não vale nota:
é para quem terminar antes.

#bancada[
  *Osciloscópio:* ponta de prova em 10#sym.times e compensada, *acoplamento DC*,
  filtro de largura de banda desligado, disparo na borda de subida do canal 1.
  Em acoplamento AC a onda quadrada vira uma rampa.
]

= Previsões — entregues no início da sessão

As mesmas perguntas do fim da aula 6. Quem trouxe a folha preenchida copia aqui
as respostas; a nota é do raciocínio, não do número.

#prevista(nota: "0,4 pt")[
  *P1.* Com `PR2` = 255 e divisor 16, qual frequência você espera medir no pino
  do cooler?
  #resp(n: 1)[$256 dot.c 250 "ns" dot.c 16 = 1024$ µs, ou 976,6 Hz.]
]

#prevista(nota: "0,4 pt")[
  *P2.* Variando a razão cíclica de 0 a 100% em passos de 10%, em qual passo o
  rotor começa a girar? Justifique pelo torque de partida.
  #resp(n: 2)[Num passo intermediário, tipicamente entre 20% e 40%: abaixo dele, o torque médio não vence o atrito estático. O número exato é da bancada.]
]

#prevista(nota: "0,4 pt")[
  *P3.* Depois de partir, reduzindo a razão cíclica, o rotor para no mesmo valor
  em que partiu?
  #resp(n: 2)[Não: para num valor menor. Em movimento, o atrito dinâmico é menor que o estático e a inércia ajuda. É uma histerese mecânica.]
]

#prevista(nota: "0,4 pt")[
  *P4.* Com 50%, o que se ouve no cooler a 977 Hz? E a 20 kHz?
  #resp(n: 2)[A 977 Hz, um apito na frequência do PWM — magnetostrição do enrolamento, com rotação estável. A 20 kHz, nada: está acima da audição.]
]

#prevista(nota: "0,4 pt")[
  *P5.* Pedindo 100% com `PR2` = 255, o que aparece no osciloscópio? E com `PR2`
  = 199?
  #resp(n: 2)[Com 255, a saída fica alta quase todo o período, com um pulso baixo de um passo — 1 µs a cada 1024 µs com divisor 16, ou 62,5 ns a cada 64 µs com 1:1 —, porque a razão tem dez bits e o período tem 1024 passos. Com 199, o período tem 800 passos, a razão pode passar dele, e a saída fica alta sem interrupção.]
]

= O programa

Um programa só, para a sessão inteira. Ele gera o PWM no CCP1 (RC2), conta o
tacômetro no Timer1 durante janelas de 1 s do Timer0 — como no R6 — e mostra
tudo no display. `INT2` percorre quatro configurações do Timer2:

#tab(columns: (auto, auto, auto, auto, auto),
  [`C`], [`PR2`], [Divisor], [Frequência], [Resolução],
  [0], [255], [1:16], [#if gab [976,6 Hz]], [#if gab [10 bits]],
  [1], [255], [1:4], [#if gab [3,906 kHz]], [#if gab [10 bits]],
  [2], [255], [1:1], [#if gab [15,63 kHz]], [#if gab [10 bits]],
  [3], [199], [1:1], [#if gab [20,00 kHz]], [#if gab [9,6 bits]],
)

Complete as duas últimas colunas antes de gravar: é a conta da aula 6.

```c
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>
#include "lcd.h"

#define JANELA  49911u                /* 1 s: 65536 - 15625, divisor 1:256 (R6) */

static const uint8_t pr2_cfg[4]   = { 255, 255, 255, 199 };
static const uint8_t t2con_cfg[4] = { 0x06, 0x05, 0x04, 0x04 };  /* 1:16, 1:4, 1:1, 1:1 */

static void pwm_iniciar(void)         /* na ordem da folha de dados (aula 6) */
{
    PR2    = pr2_cfg[0];              /* 1. periodo */
    CCPR1L = 0;                       /* 2. razao inicial: 0 % */
    LATCbits.LATC2   = 0;             /* 3. pino como saida */
    TRISCbits.TRISC2 = 0;
    T2CON   = t2con_cfg[0];           /* 4. Timer2 ligado */
    CCP1CON = 0x0C;                   /* 5. modo PWM, saida simples */
}

static void pwm_razao(uint16_t razao)           /* 0 a 1023 */
{
    if (razao > 1023u) {
        razao = 1023u;
    }
    CCPR1L  = (uint8_t)(razao >> 2);
    CCP1CON = (uint8_t)((CCP1CON & 0xCF) | (uint8_t)((razao & 0x03u) << 4));
}

/* passo de 0 a 10 -> razao em passos do periodo atual: 4 * (PR2 + 1) */
static uint16_t razao_do_passo(uint8_t passo, uint8_t c)
{
    return (uint16_t)((uint32_t)passo * 4u * ((uint16_t)pr2_cfg[c] + 1u) / 10u);
}

static void mostrar(uint8_t passo, uint8_t c, uint16_t pulsos)
{
    lcd_posicao(0, 0);
    lcd_texto("D=");  lcd_numero((uint16_t)passo * 10u, 3);
    lcd_texto("%  C=");  lcd_numero(c, 1);
    lcd_posicao(1, 0);
    lcd_texto("N=");  lcd_numero(pulsos, 5);  lcd_texto(" /s");
}

void main(void)
{
    uint8_t  passo = 5, c = 0;
    uint8_t  a0 = 1, a1 = 1, a2 = 1;  /* estado anterior dos botoes */
    uint16_t pulsos = 0;

    ADCON1 = 0x0F;                    /* RB0-RB2 e RE0-RE1 digitais */
    TRISB |= 0x07;                    /* botoes INT0, INT1, INT2 */
    TRISCbits.TRISC0 = 1;             /* RC0 = T13CKI: tacometro */

    lcd_iniciar();
    pwm_iniciar();
    pwm_razao(razao_do_passo(passo, c));

    TMR1H = 0;  TMR1L = 0;
    T1CON = 0x83;                     /* 16 bits, 1:1, sincronizado, pino RC0 */
    TMR0H = (uint8_t)(JANELA >> 8);  TMR0L = (uint8_t)(JANELA & 0xFF);
    T0CON = 0x87;                     /* 16 bits, interno, 1:256 */
    INTCONbits.TMR0IF = 0;

    for (;;) {
        uint8_t b;

        b = PORTBbits.RB0;            /* INT0: sobe 10 % */
        if (b != a0) {
            if (b == 0u && passo < 10u) { passo++; pwm_razao(razao_do_passo(passo, c)); }
            a0 = b;  __delay_ms(20);  /* espera o repique passar */
        }
        b = PORTBbits.RB1;            /* INT1: desce 10 % */
        if (b != a1) {
            if (b == 0u && passo > 0u) { passo--; pwm_razao(razao_do_passo(passo, c)); }
            a1 = b;  __delay_ms(20);
        }
        b = PORTBbits.RB2;            /* INT2: proxima configuracao do Timer2 */
        if (b != a2) {
            if (b == 0u) {
                c = (uint8_t)((c + 1u) % 4u);
                PR2   = pr2_cfg[c];
                T2CON = t2con_cfg[c];
                pwm_razao(razao_do_passo(passo, c));
            }
            a2 = b;  __delay_ms(20);
        }

        if (INTCONbits.TMR0IF) {      /* fechou a janela de 1 s */
            INTCONbits.TMR0IF = 0;
            TMR0H = (uint8_t)(JANELA >> 8);  TMR0L = (uint8_t)(JANELA & 0xFF);

            uint8_t lo = TMR1L;
            pulsos = ((uint16_t)TMR1H << 8) | lo;
            TMR1H = 0;  TMR1L = 0;

            mostrar(passo, c, pulsos);
        }
    }
}
```

#nota[
  `razao_do_passo` escala a razão pelo período da configuração atual, e por isso
  "50%" continua sendo 50% quando `PR2` muda. Com `PR2` = 255, o passo 10 pede
  1024, e `pwm_razao` corta em 1023 — é a Tarefa 5.
]

= Parte 1 — o PWM no pino

#tarefa(nota: "2,0 pt")[
  *Tarefa 1.* Configuração `C=0`. Meça RC2 no conector de PORTC e varie a razão
  cíclica com `INT0` e `INT1`.

  Frequência prevista em P1: #lacuna(largura: 3cm) #h(1fr) Medida: #lacuna(largura: 3cm)

  #tab(columns: (auto, 1fr, 1fr, 1fr),
    [Razão nominal], [$t_"alto"$ medido], [Período medido], [Razão medida],
    [20%], [#if gab [≈ 204 µs]], [#if gab [1024 µs]], [],
    [50%], [#if gab [512 µs]], [#if gab [1024 µs]], [],
    [80%], [#if gab [≈ 819 µs]], [#if gab [1024 µs]], [],
  )

  Agora fixe 50% e percorra as configurações com `INT2`:

  #tab(columns: (auto, 1fr, 1fr),
    [`C`], [Frequência medida], [Razão medida],
    [0], [], [#if gab [50%]],
    [1], [], [#if gab [50%]],
    [2], [], [#if gab [50%]],
    [3], [], [#if gab [50%]],
  )

  (a) O período mudou quando você mudou a razão cíclica? E a razão, quando mudou
  a configuração?
  #resp(n: 1)[Não e não. Período vem de `PR2` e do divisor; razão vem de `CCPR1L` e dos dois bits de `CCP1CON`. São botões independentes.]

  (b) A frequência medida confere com a tabela? Se divergir, o erro está em `PR2`,
  no divisor, ou na hipótese sobre $F_"osc"$? Um desvio de exatamente 25% nas
  quatro linhas aponta para qual deles?
  #resp(n: 2)[Confere dentro da tolerância do cristal. Um fator constante nas quatro linhas não pode ser `PR2` nem divisor, que mudam de linha para linha: é o relógio. 25% é a razão 20/16.]

  (c) De `C=0` a `C=2` a frequência subiu dezesseis vezes sem perder resolução. De
  `C=2` a `C=3` ela subiu só 28%, e perdeu resolução. Por quê?
  #resp(n: 2)[O divisor só muda o tamanho do passo, e os 1024 passos continuam no período. Para passar de 15,6 kHz é preciso diminuir `PR2`, e cada passo a menos em `PR2` são quatro passos a menos de razão: $log_2 800 approx 9,6$ bits.]
]

#divergencia[
  *O núcleo roda a 16 MHz, e não a 48 MHz.* Os bits de configuração gravados com o
  bootloader dão 48 MHz ao periférico USB e 16 MHz à CPU; o `#pragma config` da
  aplicação é ignorado. Isso foi descoberto por medição, não por leitura: uma
  onda programada para 300 ms mediu 375 ms, e o fator de 1,25 revelou o relógio
  verdadeiro. A alínea (b) é o mesmo raciocínio.
]

= Parte 2 — o pino contra a carga

#tarefa(nota: "1,0 pt")[
  *Tarefa 2.* `C=0`, razão 50%. Canal 1 em RC2; canal 2 no ponto de teste
  `COOLER`, depois do driver ULN2803. Antes de ligar o canal 2: as duas ondas
  terão a mesma amplitude? A mesma fase?
  #lacuna(largura: 100%)

  Desenhe as duas formas de onda, uma sobre a outra, com as escalas anotadas.

  #v(9em)

  #tab(columns: (1fr, 3cm, 3cm),
    [], [RC2], [`COOLER`],
    [Nível baixo], [#if gab [≈ 0 V]], [#if gab [≈ 0,8–1 V]],
    [Nível alto], [#if gab [≈ 5 V]], [#if gab [≈ 12 V]],
  )

  (a) As ondas estão em fase ou invertidas? Explique pelo funcionamento do driver.
  #resp(n: 3)[Invertidas. O ULN2803 tem saída em coletor aberto: com a entrada em nível alto, o transistor conduz e puxa a saída para perto do terra. A ventoinha fica entre a saída e os 12 V, então ela é energizada quando o ponto de teste está *baixo*.]

  (b) Aparece algum pico na borda em que a saída sobe? De onde ele vem?
  #resp(n: 2)[Sim: a ventoinha é indutiva e, quando o transistor corta, a corrente não para de uma vez. O pico é limitado pelo diodo interno do ULN2803 ligado ao comum — o mesmo papel do diodo de retorno do encontro 8.]
]

#conceito[
  "Pino em nível alto" e "carga energizada" são afirmações diferentes, e a
  diferença está no driver. Todo driver de potência faz alguma transformação
  desse tipo — inversão, deslocamento de nível, atraso — e conhecer a do seu é
  parte do projeto, não detalhe de montagem.
]

= Parte 3 — a partida e a parada do rotor

#tarefa(nota: "2,0 pt")[
  *Tarefa 3.* `C=0`. Parta de 0% e suba de 10 em 10% com `INT0`, esperando o `N`
  estabilizar em cada passo. Depois desça de 100% a 0% com `INT1`.

  #tab(columns: (auto, 1fr, 1fr, 1fr, 1fr),
    [Razão], [Subindo: gira?], [Subindo: `N`], [Descendo: gira?], [Descendo: `N`],
    [0%], [], [], [], [],
    [10%], [], [], [], [],
    [20%], [], [], [], [],
    [30%], [], [], [], [],
    [40%], [], [], [], [],
    [50%], [], [], [], [],
    [60%], [], [], [], [],
    [70%], [], [], [], [],
    [80%], [], [], [], [],
    [90%], [], [], [], [],
    [100%], [], [], [], [],
  )

  (a) Em que razão o rotor partiu? Em que razão parou? Confere com P2 e P3?
  Explique a diferença.
  #resp(n: 3)[Parte numa razão maior do que aquela em que para. Para sair do repouso é preciso vencer o atrito estático, maior que o dinâmico; em movimento, a inércia do rotor ajuda. O intervalo entre os dois valores é uma histerese mecânica.]

  (b) A rotação é proporcional à razão cíclica? Use a coluna `N`.
  #resp(n: 2)[Não: há uma zona morta abaixo da partida e a curva satura perto do máximo. Proporcional só num trecho do meio — o que importa para o controle do encontro 13.]
]

#divergencia[
  O tacômetro de uma ventoinha de três fios é alimentado pela mesma linha que o
  PWM chaveia. Durante o tempo desligado ele pode ficar sem alimentação, e o sinal
  em `SPEED` pode ganhar pulsos falsos na frequência do PWM — ou perder os
  verdadeiros. *Olhe `SPEED` no osciloscópio em 50%* antes de confiar no `N` das
  razões intermediárias. Se o sinal estiver picotado, registre isso na tabela: a
  contagem certa de um sinal errado continua errada.
]

#docente[
  Não verificado na bancada ainda. Se o sinal de `SPEED` vier picotado, a
  coluna `N` da Tarefa 3 vale como observação da divergência, e a nota fica no
  "gira?" e nas alíneas. Em 100% o sinal é limpo, e o `N` dali serve de
  referência (é a medida da Tarefa 4 do R6).
]

= Parte 4 — frequência contra resolução, de ouvido

#tarefa(nota: "1,0 pt")[
  *Tarefa 4.* Razão em 50%. Aproxime o ouvido do cooler e percorra as quatro
  configurações.

  #tab(columns: (auto, 1fr, 1fr),
    [`C`], [O que se ouve], [`N` (rotação)],
    [0 — 977 Hz], [], [],
    [1 — 3,9 kHz], [], [],
    [2 — 15,6 kHz], [], [],
    [3 — 20 kHz], [], [],
  )

  (a) Confere com a P4? De onde vem o som, se a rotação não muda?
  #resp(n: 2)[Apito na frequência do PWM até 15,6 kHz (fraco, no limite da audição); a 20 kHz, silêncio. É magnetostrição do enrolamento: o chaveamento se ouve, a rotação não muda.]

  (b) Qual configuração você escolheria para a ventoinha do termostato, e o que
  ela custa?
  #resp(n: 2)[`C=3`, 20 kHz: silenciosa, ao custo de 0,4 bit de resolução (800 passos em vez de 1024) — irrelevante para uma ventoinha.]
]

= Parte 5 — os limites do módulo

#tarefa(nota: "1,0 pt")[
  *Tarefa 5.* Leve a razão a 100% (`D=100`). Em `C=2` e depois em `C=3`, amplie a
  base de tempo do osciloscópio até ver o início de cada período.

  #tab(columns: (auto, 1fr),
    [`C`], [O que aparece no início do período],
    [2 (`PR2` = 255)], [#if gab [pulso baixo de 62,5 ns a cada 64 µs]],
    [3 (`PR2` = 199)], [#if gab [nada: saída alta contínua]],
  )

  Confere com a P5? Por que um e não o outro?
  #resp(n: 3)[Com `PR2` = 255, o período tem $4 dot.c 256 = 1024$ passos, e a razão de dez bits vai só até 1023: sobra um passo baixo. Com `PR2` = 199, o período tem 800 passos, `razao_do_passo` pede 800, e uma razão maior ou igual ao período mantém a saída alta.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 6.* Desligue CH3-5 e ligue CH3-6 (BUZZER). Sem regravar nada, ouça as
  quatro configurações com 50%, e depois varie a razão cíclica em `C=0`.

  (a) O que muda no som quando se troca a configuração? E quando se troca a razão?
  #resp(n: 2)[A configuração muda a altura (a nota), porque muda a frequência. A razão muda o volume e o timbre, mas não a nota: o período é o mesmo.]

  (b) O lá de 440 Hz tocado no O1 é possível com o módulo? E o de 880 Hz? Se algum
  for, dê `PR2` e o divisor. Qual é o primeiro lá possível?
  #resp(n: 3)[Nenhum dos dois: a menor frequência é 976,6 Hz. 440 Hz exigiria $"PR2" + 1 approx 568$ com divisor 16, e 880 Hz exigiria 284 — os dois passam de 256. O primeiro lá possível é 1760 Hz: divisor 16, `PR2` = 141, 1760,6 Hz.]
]

#conceito[
  O módulo de PWM foi feito para controlar potência, onde frequências de
  quilohertz são o normal. Para notas graves, ele não serve, e a saída volta a
  ser o software — que alcança qualquer frequência, mas ocupa o processador. A
  interrupção do encontro 7 resolve isso.
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.3fr),
  [Sintoma], [Causa provável],
  [Onda com bordas arredondadas], [Ponta em 1#sym.times ou não compensada],
  [Onda quadrada vira rampa], [Acoplamento AC no canal],
  [Nenhum sinal em RC2], [`TRISC2` em entrada, Timer2 desligado, ou `CCP1CON` fora de `0x0C`],
  [A razão cíclica não muda], [Escreveu em `CCPR1H`, que é só leitura no modo PWM],
  [Os botões não respondem], [`ADCON1` não é `0x0F`: RB0–RB2 são AN12, AN10 e AN8 (R5)],
  [Display com lixo], [`ADCON1` deixa RE0/RE1 analógicos (AN5 e AN6)],
  [`N` sempre zero], [CH3-2 em OFF, `TRISC0` em saída, ou `TMR1CS = 0`],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1, 3, 4 e 5; o desenho da Tarefa 2 com escalas.

  Responda também:

  (a) No R6, o Timer2 não apareceu; aqui ele não conta nada que o programa leia.
  O que o processador faz para manter a onda no pino?
  #resp(n: 2)[Nada, depois da configuração. Ele só escreve a razão quando o botão muda; o Timer2 e o comparador repetem a forma de onda sozinhos.]

  (b) Tempo, eventos, forma de onda: qual temporizador fez cada coisa entre o R6 e
  o R7, e qual deles dependeu do laço?
  #resp(n: 2)[Timer0 mediu tempo e dependeu do laço para a recarga. Timer1 contou eventos e o Timer2 gerou a onda, os dois sem o laço.]
]

#criterio[
  Previsões P1 a P5: 0,4 cada, 2,0 no total, pelo raciocínio.

  Tarefa 1 (PWM no pino, quatro configurações): 2,0. Tarefa 2 (pino contra
  carga): 1,0. Tarefa 3 (partida e parada): 2,0. Tarefa 4 (frequência e ruído):
  1,0. Tarefa 5 (os 100%): 1,0. Tarefa 6 (buzzer e frequência mínima): 1,0.

  Na Tarefa 2, a resposta completa nomeia o coletor aberto. Dizer "o driver
  inverte" sem dizer por quê vale metade. Na Tarefa 5, a nota está na contagem de
  passos — 1024 contra 1023 —, não na descrição da tela.

  As extensões E1 a E3 não pontuam.
]

= Se sobrar tempo

#opcional[
  *E1 — a rampa sem espera.* Troque o controle por botões pela rampa da aula 6:
  a cada estouro de 10 ms do Timer0 (pré-carga `0x63C0`), a razão sobe ou desce
  4 unidades. Com o buzzer desligado e o cooler ligado, observe a rotação
  acompanhando a rampa.
  #resp(n: 1)[A rotação segue a rampa com atraso — a inércia do rotor, a mesma que torna o PWM uma média.]
]

#opcional[
  *E2 — a contagem limpa.* Em 50%, compare o `N` com a frequência de `SPEED` no
  osciloscópio. Se o tacômetro estiver picotado pelo PWM, a contagem de 100%
  continua valendo como referência? Por quê?
  #resp(n: 1)[Sim: em 100% (ou quase) o tacômetro fica alimentado o tempo todo, e o sinal volta a ser limpo.]
]

#opcional[
  *E3 — o segundo canal.* O CCP2 usa o mesmo Timer2. Configure `CCP2CON = 0x0C` e
  uma razão diferente em `CCPR2L`, e meça RC1 com as chaves CH3-3 e CH3-4 em OFF — o
  CCP2 só sai em RC1 se o `CCP2MX` do bootloader o puser lá.
  As duas saídas têm a mesma frequência? A mesma razão?
  #resp(n: 1)[Mesma frequência, obrigatoriamente; razões independentes.]
]

#nota[
  No R8: a interrupção, por inteiro — o repique que o R6 revelou, tratado de
  verdade, e o lá de 440 Hz que o módulo não alcança, tocado por um temporizador
  enquanto o display é atualizado.
]
