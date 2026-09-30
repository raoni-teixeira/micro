// R9 — Liga-desliga, histerese e o comparador
// Revisão 2026/2, alinhada à aula 9 (controle liga-desliga, histerese e
// comparação analógica). Usa o conversor do R5, a base de 5 ms por interrupção
// do R7 e o display do R4. Sem relé: o aquecedor está em RC1 (CH3-3).
//
// Seis tarefas com nota (8,0), previsões P1–P6 da aula 9 (2,0) e duas
// extensões sem nota no fim.
//
// Compilação:  typst compile R9-liga-desliga.typ
//              typst compile --input gab=1 R9-liga-desliga.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R9 — Liga-desliga, histerese e o comparador",
  subtitulo: "A regra mais simples do mundo, o que ela cobra, e um vigia que não depende do programa",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}
// Célula de tabela: vazia para o aluno, preenchida no gabarito.
#let g(x) = if gab { x } else { [] }

#objetivos[
  - Medir as taxas de aquecimento e de resfriamento da planta, que decidem todo o resto.
  - Ver a regra sem histerese comutar a cada amostra, e contar o que isso custa.
  - Medir as duas grandezas do liga-desliga — amplitude e acionamentos por hora — e o compromisso entre elas.
  - Reconhecer que a histerese não pode ser menor que o degrau do conversor.
  - Usar o comparador C1 como vigia de sobretemperatura, que corta o aquecedor com o laço principal travado.
]

#kit[
  #tab(columns: (auto, 1fr),
    [Chave], [Posição],
    [CH2-1 (LCD)], [ON],
    [CH1-7 (TEMP)], [ON — LM35 em RA0/AN0, que é também a entrada inversora de C1],
    [CH1-1, CH1-5 e CH1-6], [OFF — também chegam a RA0],
    [CH3-3 (HEATER, RC1)], [ON],
    [CH3-5 (COOLER, RC2)], [ON, exceto na Tarefa 5],
    [CH5 (relés)], [*Todas em OFF* — não há relé na bancada],
    [Demais chaves de CH3 e SWITCHS], [OFF],
  )
]

#atencao[
  *A medida leva mais tempo que a montagem.* A Tarefa 1 precisa começar com a
  planta fria, e cada regime seguinte leva de 10 a 15 minutos. Grave, anote o
  instante no cronômetro e escreva as respostas enquanto o sistema roda.
]

#perigo[
  O resistor de aquecimento chega a dezenas de graus. Não encoste nele; o LM35
  fica ao lado dele, e é ali que o dedo não deve ir.
]

*Pontuação.* As seis tarefas somam 8,0. As previsões P1 a P6 da aula 9,
preenchidas antes da sessão, valem 2,0: 0,3 cada nas quatro primeiras e 0,4 nas
duas últimas. A nota de cada tarefa e de cada previsão está na margem. A seção
_Se sobrar tempo_ não vale nota.

= Previsões — entregues no início da sessão

As mesmas perguntas do fim da aula 9. Quem trouxe a folha preenchida copia aqui
as respostas; a nota é do raciocínio, não do número.

#prevista(nota: "0,3 pt")[
  *P1.* Com o aquecedor a 100% a partir da temperatura ambiente, qual taxa de
  aquecimento você espera, em graus por minuto? Diga qual palpite de massa
  térmica usou.
  #resp(n: 2)[$a = P slash (m c)$. Com 3 W e, por exemplo, 200 g de alumínio e cimento ($m c approx 180$ J/°C): ≈ 1 °C/min. Vale qualquer palpite coerente e declarado.]
]

#prevista(nota: "0,3 pt")[
  *P2.* Com $h = 0,5$ °C e as suas taxas, quantos acionamentos por hora prevê?
  #resp(n: 1)[$T_"ciclo" = 2h slash a + 2h slash b$, e $60 slash T_"ciclo"$ ciclos por hora, cada um com duas comutações. Com $a = 0,8$ e $b = 0,4$ °C/min: 16 ciclos por hora.]
]

#prevista(nota: "0,3 pt")[
  *P3.* A amplitude medida vai ser maior, igual ou menor que 1 °C? Justifique.
  #resp(n: 1)[Maior: depois que o aquecedor desliga, o calor já entregue continua chegando ao sensor (sobressinal), e o mesmo ao ligar.]
]

#prevista(nota: "0,3 pt")[
  *P4.* Com $h = 0,2$ °C, o que acontece com cada uma das duas medidas? Há um
  efeito que a conta simples não prevê.
  #resp(n: 2)[A conta prevê 2,5 vezes mais comutações e amplitude menor. Mas $2h = 0,4$ °C é menor que um degrau do conversor (0,49 °C): os limiares caem em códigos vizinhos, a histerese efetiva fica quase a mesma, e o tempo mínimo limita as comutações.]
]

#prevista(nota: "0,4 pt")[
  *P5.* Com a ventoinha desligada, qual das duas taxas muda, e o que isso faz com a
  razão cíclica do ciclo limite?
  #resp(n: 2)[Muda $b$, o resfriamento, que fica mais lento. A fração do tempo com o aquecedor ligado é $b slash (a + b)$: diminui, e o ciclo fica mais longo.]
]

#prevista(nota: "0,4 pt")[
  *P6.* O comparador C1 vai vigiar o LM35 contra `CVREF`, na faixa baixa, com a
  escada nos 5 V. Qual o degrau da referência, em mV e em graus? Que limiar você
  programaria, e o que acontece com o corte do aquecedor se o firmware travar?
  #resp(n: 2)[5 V / 24 = 208 mV, ou 20,8 °C por degrau. Degrau 2 = 417 mV = 41,7 °C, logo acima do alvo de 40 °C. Com o laço travado, a interrupção do comparador ainda corta o aquecedor; só não cortaria se as interrupções estivessem desligadas.]
]

= O programa

Um programa só, com quatro modos escolhidos por `MODO` e regravado entre as
tarefas. A cada 100 ms ele lê o LM35 (10 amostras por segundo, como na aula 9),
decide o aquecedor e escreve no display:

#align(center)[#box(inset: 6pt, stroke: 0.5pt, text(font: "DejaVu Sans Mono", size: 9pt)[
  T=40.2 LIGADO #linebreak()
  N=017 39.1-41.3
])]

Na primeira linha, a temperatura e o estado do aquecedor. Na segunda, o número
de comutações e a menor e a maior temperatura desde a primeira comutação — o
regime.

```c
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>
#include "lcd.h"

#define MODO        1         /* 0 sem histerese, 1 termostato, 2 degrau, 3 travado */
#define ALVO_D    400         /* 40,0 graus                                          */
#define H_D         5         /* histerese: 0,5 grau para cada lado (Tarefa 4: 2)    */
#define MIN_MS  30000u        /* tempo minimo em cada estado (MODO 1)                */
#define PROTECAO    0         /* 1 na Tarefa 6: C1 vigia o LM35                      */
#define PRECARGA_5MS 45536u   /* 5 ms a 250 ns (R7)                                  */

volatile uint16_t ms = 0;     /* relogio de 16 bits, em ms: da a volta em 65,5 s */
volatile uint8_t  protegido = 0;

void __interrupt() tratar(void)
{
    if (INTCONbits.TMR0IF) {                  /* base de 5 ms */
        INTCONbits.TMR0IF = 0;
        TMR0H = (uint8_t)(PRECARGA_5MS >> 8);
        TMR0L = (uint8_t)(PRECARGA_5MS & 0xFF);
        ms += 5u;
    }
    if (PIR2bits.CMIF) {                      /* a saida de C1 mudou */
        uint8_t c = CMCON;                    /* leitura obrigatoria */
        PIR2bits.CMIF = 0;
        if ((c & 0x40u) == 0u) {              /* C1OUT = 0: LM35 acima de CVREF */
            LATCbits.LATC1 = 0;               /* corta o aquecedor */
            LATDbits.LATD0 = 0;               /* acende o LED de protecao */
            protegido = 1;
        }
    }
}

static uint16_t ms_ler(void)                  /* 16 bits: le ate concordar (R7) */
{
    uint16_t a, b;
    do { a = ms; b = ms; } while (a != b);
    return a;
}

static int16_t temperatura_decimos(void)      /* conversor do R5 */
{
    ADCON0bits.GO = 1;
    while (ADCON0bits.GO) { }
    uint16_t c = ((uint16_t)ADRESH << 8) | ADRESL;
    return (int16_t)(((uint32_t)c * 625UL) >> 7);
}

static void mostrar(int16_t t, uint8_t aq, uint16_t n, int16_t tmin, int16_t tmax)
{
    lcd_posicao(0, 0);
    lcd_texto("T=");  lcd_decimos(t);
    lcd_texto(aq ? " LIGADO " : " deslig ");
    lcd_posicao(1, 0);
    lcd_texto("N=");  lcd_numero(n, 3);  lcd_texto(" ");
    if (n != 0u) { lcd_decimos(tmin); lcd_texto("-"); lcd_decimos(tmax); }
    else         { lcd_texto("--.---.-"); }
}

void main(void)
{
    uint8_t  aquecendo = 0;
    uint16_t desde = 0, ultima = 0, comutacoes = 0;
    int16_t  t, tmin = 9999, tmax = -9999;

    TRISAbits.TRISA0 = 1;
    ADCON1 = 0x0E;  ADCON2 = 0b10010101;  ADCON0 = 0x01;   /* so AN0 (R5) */
    LATCbits.LATC1 = 0;  TRISCbits.TRISC1 = 0;             /* aquecedor    */
    LATCbits.LATC2 = 1;  TRISCbits.TRISC2 = 0;             /* ventoinha    */
    LATDbits.LATD0 = 1;  TRISDbits.TRISD0 = 0;             /* LED apagado  */
    lcd_iniciar();

    TMR0H = (uint8_t)(PRECARGA_5MS >> 8);  TMR0L = (uint8_t)(PRECARGA_5MS & 0xFF);
    T0CON = 0x88;  INTCONbits.TMR0IF = 0;  INTCONbits.TMR0IE = 1;
#if PROTECAO
    CVRCON = 0b10100010;          /* ligada, faixa baixa, fonte VDD, degrau 2 */
    CMCON  = 0b00000110;          /* CM = 110: C1 compara RA0 com CVREF       */
    __delay_us(10);               /* o comparador estabiliza                  */
    (void)CMCON;  PIR2bits.CMIF = 0;
    PIE2bits.CMIE = 1;  INTCONbits.PEIE = 1;
#endif
    INTCONbits.GIE = 1;

#if MODO == 3
    LATCbits.LATC1 = 1;           /* o "defeito": aquecedor ligado...  */
    while (1) { }                 /* ...e o laco principal travado     */
#endif

    for (;;) {
        uint16_t agora = ms_ler();
        if ((uint16_t)(agora - ultima) < 100u) { continue; }   /* 10 amostras/s */
        ultima = agora;
        t = temperatura_decimos();

        uint8_t antes = aquecendo;
#if MODO == 0
        aquecendo = (t < ALVO_D);                 /* a regra mais simples do mundo */
#elif MODO == 2
        aquecendo = 1;                            /* degrau: 100 %                  */
#else
        if ((uint16_t)(agora - desde) >= MIN_MS) {    /* tempo minimo (aula 9) */
            if (aquecendo && t > ALVO_D + H_D)       { aquecendo = 0; }
            else if (!aquecendo && t < ALVO_D - H_D) { aquecendo = 1; }
        }
#endif
        if (aquecendo != antes) { comutacoes++;  desde = agora; }
        if (protegido)          { aquecendo = 0; }
        LATCbits.LATC1 = aquecendo;

        if (comutacoes != 0u) {
            if (t < tmin) { tmin = t; }
            if (t > tmax) { tmax = t; }
        }
        mostrar(t, aquecendo, comutacoes, tmin, tmax);
    }
}
```

#nota[
  O programa reúne peças de quatro roteiros: o conversor do R5, a base de 5 ms e a
  leitura de 16 bits do R7, o display do R4, e a regra com histerese e tempo
  mínimo da aula 9. A conta `(uint16_t)(agora - desde)` é a da aula 9: o relógio
  dá a volta em 65,5 s, e a subtração sem sinal cancela a volta.
]

= Parte 1 — a planta

#tarefa(nota: "1,5 pt")[
  *Tarefa 1.* Com a planta *fria*, grave com `MODO` 2 (aquecedor sempre ligado) e
  dispare o cronômetro. Anote a temperatura a cada 2 minutos até passar de 42 °C.
  Depois desligue CH3-3 e anote o resfriamento por mais 6 minutos.

  #tab(columns: (auto, 1fr, 1fr, 1fr, 1fr, 1fr),
    [t (min)], [0], [2], [4], [6], [8],
    [Aquecendo (°C)], [], [], [], [], [],
    [Resfriando (°C)], [], [], [], [—], [—],
  )

  $a$ (aquecimento, perto de 40 °C): #lacuna(largura: 2.5cm) °C/min #h(1fr)
  $b$ (resfriamento, perto de 40 °C): #lacuna(largura: 2.5cm) °C/min

  (a) A taxa de aquecimento é constante? Por quê? Confere com a P1?
  #resp(n: 2)[Não: diminui com o tempo, porque a perda para o ambiente cresce com a temperatura. O que interessa para o ciclo limite são as taxas perto do alvo, não as do começo.]

  (b) Com essas taxas e $h = 0,5$ °C, quanto dura um ciclo limite, e quantos
  acionamentos por hora você espera? (Refaça a P2 com os números medidos.)
  #resp(n: 2)[$T_"ciclo" = 1 slash a + 1 slash b$ minutos; ciclos por hora $= 60 slash T_"ciclo"$. Com $a = 0,8$ e $b = 0,4$: 3,75 min, 16 ciclos, 32 comutações por hora.]
]

= Parte 2 — a regra sem histerese

#tarefa(nota: "1,0 pt")[
  *Tarefa 2.* Religue CH3-3. Quando a temperatura estiver perto de 40 °C, grave
  com `MODO` 0 e observe por 1 minuto, contando pelo `N` do display.

  #tab(columns: (1fr, 3cm),
    [Comutações em 1 min], g[dezenas a centenas],
    [Extrapolado para 1 hora], g[milhares a dezenas de milhares],
  )

  Por que a regra comuta tanto, se ela está "correta"?
  #resp(n: 2)[Perto do alvo a leitura alterna entre dois códigos vizinhos por ruído de um degrau, e a regra acompanha cada amostra: até uma comutação a cada 100 ms. A regra faz o que foi pedido; o pedido estava mal formulado.]
]

= Parte 3 — o termostato, medido

#tarefa(nota: "2,0 pt")[
  *Tarefa 3.* Grave com `MODO` 1, $h = 0,5$ °C e tempo mínimo de 30 s. Deixe rodar
  *15 minutos* a partir da primeira comutação.

  #tab(columns: (1fr, 3cm),
    [Menor e maior temperatura no regime (°C)], [],
    [Amplitude (°C)], g[maior que 1,0],
    [Comutações em 15 min], [],
    [Acionamentos por hora (extrapolado)], [],
    [Previsto na Tarefa 1(b)], [],
  )

  (a) A amplitude medida é maior que $2h$ = 1,0 °C? De onde vem a diferença?
  Confere com a P3?
  #resp(n: 2)[Maior: é $2h$ mais o sobressinal e o subsinal. Depois que o aquecedor desliga, o calor já entregue continua chegando ao sensor; ao religar, a planta demora a reverter.]

  (b) Os acionamentos por hora conferem com a previsão da Tarefa 1(b)? Se não,
  qual das hipóteses da conta falhou?
  #resp(n: 2)[Da mesma ordem. A conta supõe taxas constantes e amplitude igual a $2h$; o sobressinal alarga a faixa percorrida e deixa o ciclo mais longo, com menos acionamentos que o previsto.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 4.* Troque `H_D` para 2 ($h = 0,2$ °C) e repita por 10 minutos.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [$h = 0,5$], [$h = 0,2$],
    [Amplitude (°C)], [], [],
    [Acionamentos por hora], [], [],
  )

  A amplitude caiu na proporção de $h$? E os acionamentos subiram 2,5 vezes?
  Explique com o degrau do conversor. Confere com a P4?
  #resp(n: 3)[Não na proporção. $2h = 0,4$ °C é menor que um degrau (0,49 °C): os limiares 39,8 e 40,2 caem em códigos vizinhos, e a histerese efetiva fica perto de um degrau de cada lado — quase a mesma de antes. O tempo mínimo de 30 s também limita as comutações. A qualidade do controle está limitada pela medida, não pelo algoritmo.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 5.* Volte `H_D` para 5, desligue CH3-5 (ventoinha) e repita por 10
  minutos.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Com ventoinha], [Sem ventoinha],
    [Acionamentos por hora], [], [],
    [Fração do tempo com o aquecedor ligado], [], [],
  )

  Qual taxa mudou, e por que a fração do tempo ligado mudou nesse sentido? Confere
  com a P5?
  #resp(n: 2)[Mudou $b$: sem ventoinha a planta esfria mais devagar. A fração ligada é $b slash (a + b)$ e diminui; o ciclo fica mais longo, com menos acionamentos por hora.]
]

= Parte 4 — o vigia em silício

#tarefa(nota: "1,5 pt")[
  *Tarefa 6.* Religue CH3-5. Com a planta perto de 40 °C, grave com `MODO` 3 e
  `PROTECAO` 1. O programa liga o aquecedor e trava o laço principal num
  `while (1)` — o display congela. Acompanhe o LED de RD0 e a tensão em RC1 com o
  multímetro.

  #tab(columns: (1fr, 3cm),
    [Limiar programado em `CVREF` (mV e °C)], g[417 mV, 41,7 °C],
    [O LED de proteção acendeu?], g[sim, após alguns minutos],
    [Tensão em RC1 depois do corte], g[≈ 0 V],
  )

  (a) O laço principal está travado. Quem cortou o aquecedor, e por que isso
  funcionou?
  #resp(n: 2)[O tratamento de interrupção, chamado por `CMIF` quando a saída de C1 mudou. O comparador decide sozinho, continuamente, e a interrupção não depende do laço.]

  (b) Por que o limiar é 41,7 °C, e não os 45 °C que um projetista escolheria?
  Confere com a P6?
  #resp(n: 2)[A escada de `CVREF` tem degraus de 208 mV, ou 20,8 °C: os limiares possíveis são 0; 20,8; 41,7 e 62,5 °C. O mais próximo acima do alvo é 41,7. O vigia serve para proteção, não para controle fino.]

  (c) Em que situação este vigia *não* protegeria? O que tornaria a proteção
  independente do firmware?
  #resp(n: 2)[Se as interrupções estivessem desligadas (`GIE` = 0), ou se o tratamento travasse. Independência de verdade exige um caminho de hardware: a saída do comparador (C1OUT em RA4) cortando o acionamento por uma porta lógica, sem instrução nenhuma.]
]

#conceito[
  *O conversor mede, o comparador vigia.* O termostato usa o conversor, porque
  precisa do valor na tela e de um alvo em qualquer temperatura. O comparador entra
  por cima, com um limiar grosseiro e fixo, que funciona mesmo quando o programa
  não funciona.
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.3fr),
  [Sintoma], [Causa provável],
  [Temperatura absurda ou fixa], [CH1-1, CH1-5 ou CH1-6 em ON, disputando RA0; ou `ADCON1` sem AN0 analógico],
  [Aquecedor nunca liga], [CH3-3 em OFF, ou `TRISC1` em entrada],
  [O tempo mínimo nunca se cumpre], [Subtração com sinal, ou `agora > desde + MIN`: o relógio de 16 bits dá a volta],
  [Programa preso logo com `PROTECAO` 1], [`CMIF` limpo sem ler `CMCON` antes: o sinalizador volta na hora],
  [A proteção nunca atua], [`PEIE` em 0 (o comparador é periférico), ou `CMCON` ainda em `0x07`],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1 a 6, com as respostas escritas nelas.

  Responda também: melhorar a amplitude piora os acionamentos por hora, e
  vice-versa. Com os seus números, qual $h$ você escolheria para um aquecedor
  acionado por relé, e qual para um acionado por MOSFET? Por quê?
  #resp(n: 3)[Relé: $h$ maior, para poupar o contato, que tem vida contada em operações. MOSFET: $h$ no piso de um grau (dois degraus do conversor), porque a comutação não desgasta nada — e abaixo disso a medida não acompanha.]
]

#criterio[
  Previsões P1 a P4: 0,3 cada; P5 e P6: 0,4 cada. Total 2,0, pelo raciocínio.

  Tarefa 1 (taxas): 1,5. Tarefa 2 (sem histerese): 1,0. Tarefa 3 (as duas
  medidas): 2,0. Tarefa 4 ($h$ = 0,2): 1,0. Tarefa 5 (sem ventoinha): 1,0.
  Tarefa 6 (o vigia): 1,5.

  Na Tarefa 4, a resposta completa nomeia o degrau do conversor. "A histerese
  ficou pequena demais" sem o número vale metade.
]

= Se sobrar tempo

#opcional[
  *E1 — o limiar no pino.* Troque `CVRCON` para `0b11100010` (`CVROE` = 1): a
  referência sai em RA2. Meça com o multímetro e compare com os 417 mV previstos.
  #resp(n: 1)[Perto de 417 mV; a diferença vem da própria alimentação, que é a fonte da escada.]
]

#opcional[
  *E2 — sem tempo mínimo.* Com `MODO` 1, troque `MIN_MS` para 0 e repita a Tarefa
  4. O que muda nos acionamentos por hora?
  #resp(n: 1)[Sobem: sem o tempo mínimo, só a histerese — quase um degrau — segura a comutação, e o ruído passa a derrubá-la de vez em quando.]
]

#nota[
  No R10: a serial. O termostato de hoje passa a contar a sua história a um
  computador, e a história vira dado. As taxas e as duas medidas de hoje voltam no
  encontro 13, quando o liga-desliga for comparado com o controle proporcional —
  e no TP, o termostato inteiro.
]
