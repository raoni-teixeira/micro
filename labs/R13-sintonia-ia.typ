// R13 — Sintonia e IA: do dado ao coeficiente
// Revisão 2026/2, alinhada à aula 13 (controle embarcado: do liga-desliga ao PI,
// e onde entra IA). O treino roda no Colab (code/R13-colab.ipynb), com a
// telemetria gravada pelo próprio grupo; o microcontrolador só executa o que foi
// aprendido, em inteiros.
//
// Seis tarefas com nota (8,0), previsões P1–P5 da aula 13 (2,0) e duas extensões.
// As Tarefas 1 e 2 são feitas antes da sessão, no Colab.
//
// Compilação:  typst compile R13-sintonia-ia.typ
//              typst compile --input gab=1 R13-sintonia-ia.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R13 — Sintonia e IA: do dado ao coeficiente",
  subtitulo: "Identificar a planta, sintonizar no simulador, aprender com a telemetria, e executar em inteiros",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}
// Célula de tabela: vazia para o aluno, preenchida no gabarito.
#let g(x) = if gab { x } else { [] }
#let colab = "https://colab.research.google.com/github/raoni-teixeira/micro/blob/main/code/R13-colab.ipynb"

#objetivos[
  - Identificar a planta a partir do degrau registrado no R10, e saber o que dez minutos de dado medem bem e mal.
  - Sintonizar o PI num simulador que reproduz a quantização e a aritmética do firmware.
  - Rotular dados de telemetria e treinar dois modelos da potência de regime: uma reta e uma rede 2-3-1.
  - Quantizar o modelo em Q8, verificar, e executar no microcontrolador como antecipação somada ao PI.
]

#kit[
  #tab(columns: (auto, 1fr),
    [Chave], [Posição],
    [CH1-7 (TEMP)], [ON; CH1-1, CH1-5 e CH1-6 em OFF],
    [CH2-1 (LCD)], [ON],
    [CH3-3 (HEATER, RC1 = CCP2)], [ON — o aquecedor agora é PWM],
    [CH3-5 (COOLER, RC2)], [ON, em nível fixo: a planta precisa ser a mesma do R10],
    [CH4-6 e CH4-8 (RS232)], [ON; CH4-5, CH4-7 e CH5 em OFF],
  )

  *No computador:* o `registrar.py` do R10, e uma conta Google para o Colab. O
  notebook abre direto pelo link
  #link(colab)[#raw("colab.research.google.com/…/code/R13-colab.ipynb")].
]

#atencao[
  *Traga o `degrau.csv` do R10.* Sem ele não há planta para identificar, e as
  Tarefas 1 e 2 — feitas antes da sessão — valem 3,0 pontos. A planta leva mais de
  vinte minutos para chegar ao alvo: na sessão, o PI da Tarefa 3 é a primeira
  coisa a gravar.
]

*Pontuação.* As seis tarefas somam 8,0; as Tarefas 1 e 2 são entregues no início
da sessão. As previsões P1 a P5 da aula 13 valem 0,4 cada. A seção _Se sobrar
tempo_ não vale nota.

= Previsões — entregues no início da sessão

#prevista(nota: "0,4 pt")[
  *P1.* Do registro do degrau, estime a taxa de aquecimento inicial e a constante
  de tempo, antes de ajustar qualquer modelo.
  #resp(n: 2)[A taxa sai da inclinação do começo da curva, perto de 1 °C/min. A constante de tempo, de dezenas de minutos — e é justamente a que dez minutos de degrau medem mal.]
]

#prevista(nota: "0,4 pt")[
  *P2.* Com $K_p$ sozinho, em que temperatura o sistema estabiliza?
  #resp(n: 2)[Abaixo do alvo: o proporcional precisa de erro para produzir saída. Em equilíbrio, $K_p dot.c e$ iguala a potência que mantém a planta, e o erro é essa potência dividida por $K_p$.]
]

#prevista(nota: "0,4 pt")[
  *P3.* O integral sem proteção contra saturação: quanto de sobressinal?
  #resp(n: 1)[Vários graus: o integrador soma erro durante todo o aquecimento com a saída presa em 100%, e esse acúmulo passa do alvo. No simulador, da ordem de 5 a 7 °C.]
]

#prevista(nota: "0,4 pt")[
  *P4.* Estabilizado no alvo, quantas amostras seguidas o conversor devolve o mesmo
  código? O que isso diz sobre derivar a medida?
  #resp(n: 2)[Dezenas: a temperatura muda centésimos de grau por segundo, e o degrau vale 0,488 °C. A derivada é zero quase sempre e um salto de vez em quando — ruído, e por isso o derivativo não entra.]
]

#prevista(nota: "0,4 pt")[
  *P5.* Comparando o PI com o liga-desliga do R9: amplitude e acionamentos — qual
  melhorou mais?
  #resp(n: 1)[Os acionamentos deixam de existir: o PWM comuta, mas sem desgaste. A amplitude cai de alguns graus para uma fração de grau.]
]

= Antes da sessão — no Colab

Abra o notebook, rode as etapas A e B com o seu `degrau.csv`, e traga as
respostas.

#tarefa(nota: "1,5 pt")[
  *Tarefa 1 — identificar a planta (etapa A).*

  #tab(columns: (1fr, 3cm),
    [$G$ (°C, com incerteza)], [],
    [$tau$ (min, com incerteza)], [],
    [$theta$ (s)], [],
    [Taxa inicial $G slash tau$ (°C/min)], [],
  )

  (a) Qual das três grandezas tem a menor incerteza relativa? Por quê?
  #resp(n: 2)[A taxa inicial $G slash tau$, e o atraso. Com dez minutos de degrau e $tau$ de dezenas de minutos, a curva mal começa a achatar: o ajuste vê uma rampa, cuja inclinação é $G slash tau$, e não consegue separar $G$ de $tau$.]

  (b) Confere com a P1?
  #resp(n: 1)[A taxa inicial costuma conferir; a constante de tempo, só em ordem de grandeza.]
]

#tarefa(nota: "1,5 pt")[
  *Tarefa 2 — sintonizar no simulador (etapa B).*

  #tab(columns: (1fr, 3cm),
    [`KP_Q8` e `KI_Q8` escolhidos], [],
    [P sozinho: temperatura final (°C)], [],
    [PI sem proteção: sobressinal (°C)], [],
    [PI com proteção: sobressinal (°C)], [],
  )

  (a) Por que o simulador arredonda a temperatura para o degrau do conversor antes
  de entregá-la ao controle?
  #resp(n: 2)[Porque o firmware só vê o código do conversor. Sem a quantização, o simulador aprovaria ganhos — e um derivativo — que na bancada reagem a saltos de 0,488 °C como se fossem sinal.]

  (b) Confere com a P2 e a P3? De onde vem a diferença entre as duas versões do PI?
  #resp(n: 2)[O P para abaixo do alvo, pela conta da P2. O PI sem proteção acumula erro durante toda a saturação do aquecimento e passa do alvo; o com proteção só integra fora da saturação.]
]

= O firmware

O controle usa os ganhos e o modelo que o notebook exporta em `modelo.h`. O
aquecedor passa a ser PWM no CCP2 (RC1), a 976,6 Hz com 10 bits — a planta
térmica não vê a frequência (aula 8). Base de tempo, fila da serial, recepção de
comandos e `enviar_u32` vêm do R10; `temperatura_decimos` do R5; o display do R4.

```c
#include "modelo.h"               /* KP_Q8, KI_Q8, FF_TIPO e o modelo */
#define ANTIWINDUP 1

static int32_t integral = 0;

static int16_t satura16(int32_t v)
{
    if (v >  32767) { return  32767; }
    if (v < -32768) { return -32768; }
    return (int16_t)v;
}

static int16_t inferir(const int16_t x[2])        /* rede 2-3-1 em Q8 (aula 13) */
{
    int16_t h[3];
    for (uint8_t j = 0; j < 3u; j++) {
        int32_t acc = (int32_t)b1[j] << 8;
        for (uint8_t i = 0; i < 2u; i++) { acc += (int32_t)W1[j][i] * x[i]; }
        acc >>= 8;
        h[j] = (acc > 0) ? satura16(acc) : 0;     /* max(0, .) */
    }
    int32_t s = (int32_t)b2 << 8;
    for (uint8_t j = 0; j < 3u; j++) { s += (int32_t)W2[j] * h[j]; }
    return satura16(s >> 8);
}

static int16_t antecipacao(int16_t t_d, int16_t alvo_d)
{
#if FF_TIPO == 1                                   /* reta */
    return (int16_t)(FF_B + (((int32_t)FF_A_Q8 * (alvo_d - TAMB_D)) >> 8));
#elif FF_TIPO == 2                                 /* rede */
    int16_t x[2];
    x[0] = (int16_t)(((int32_t)(t_d - 250) * 256) / 250);     /* (T - 25)/25 */
    x[1] = (int16_t)(((int32_t)(alvo_d - t_d) * 256) / 100);  /* e/10        */
    return (int16_t)(((int32_t)inferir(x) * 1023) >> 8);
#else
    return 0;
#endif
}

/* Uma vez por segundo. Devolve a saida (0..1023) e a antecipacao usada. */
static uint16_t controlar(int16_t t_d, int16_t alvo_d, int16_t *ff)
{
    int16_t e = alvo_d - t_d;                      /* decimos */
    *ff = antecipacao(t_d, alvo_d);
    int32_t u = *ff + (((int32_t)KP_Q8 * e + (int32_t)KI_Q8 * integral) >> 8);
    if (u > 1023)   { u = 1023; }
    else if (u < 0) { u = 0; }
#if ANTIWINDUP
    else            { integral += e; }             /* so fora da saturacao */
#else
    integral += e;
#endif
    return (uint16_t)u;
}

static void aquecedor_iniciar(void)                /* CCP2 em RC1, aula 8 */
{
    PR2 = 255;  CCPR2L = 0;
    LATCbits.LATC1 = 0;  TRISCbits.TRISC1 = 0;
    T2CON   = 0x06;                                /* 976,6 Hz, 10 bits */
    CCP2CON = 0x0C;
}

static void aquecedor(uint16_t u)
{
    CCPR2L  = (uint8_t)(u >> 2);
    CCP2CON = (uint8_t)((CCP2CON & 0xCF) | (uint8_t)((u & 0x03u) << 4));
}
```

A cada segundo o laço lê a temperatura, chama `controlar`, escreve o aquecedor e
envia a linha `t_ms,temp_d,alvo_d,u,ff`. O alvo muda pela serial com `A400`,
`A450`, como no R10. O `registrar.py` do R10 grava o arquivo sem mudança: o
cabeçalho dele diz `aquecedor,comutacoes`, e o notebook renomeia as colunas.

= Na sessão — a bancada e o Colab

#tarefa(nota: "1,5 pt")[
  *Tarefa 3 — o PI na bancada.* Com os ganhos da Tarefa 2, `FF_TIPO` 0 e
  `ANTIWINDUP` 1, grave e rode o `registrar.py` gravando `pi.csv`. Com a planta
  partindo do ambiente e o alvo em 40,0 °C, deixe *15 minutos* depois de chegar ao
  alvo; então envie `A450` e deixe mais 15 minutos.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Simulador], [Bancada],
    [Tempo para chegar a 40 °C (min)], [], [],
    [Sobressinal (°C)], [], [],
    [Amplitude em regime a 40 °C (°C)], [], [],
    [Mesmo código, em sequência, no regime (amostras)], [—], [],
  )

  (a) O simulador acertou? Onde errou, e qual grandeza da Tarefa 1 explica o erro?
  #resp(n: 2)[Acerta o começo, que depende da taxa inicial; erra o fim e o regime, que dependem de $G$ e $tau$ separados — as grandezas que dez minutos de degrau mediam mal.]

  (b) Confere com a P4?
  #resp(n: 1)[Dezenas de amostras seguidas com o mesmo código: derivar isso daria zero quase sempre e um salto de vez em quando.]
]

#tarefa(nota: "1,5 pt")[
  *Tarefa 4 — aprender com a telemetria (etapas C e D).* Suba o `pi.csv` no
  notebook e rode as etapas C e D.

  #tab(columns: (1fr, 3cm),
    [Amostras em regime (rotuladas)], [],
    [Erro da reta (%)], [],
    [Erro da rede (%)], [],
    [$G = 1 slash c_1$ pela reta (°C)], [],
    [$G$ pela Tarefa 1 (°C)], [],
    [Maior peso da rede, e se cabe em Q8], [],
  )

  (a) Por que só as amostras de regime entram no treino?
  #resp(n: 2)[A rede aprende a saída que *mantém* a planta parada. Durante o aquecimento a saída está no máximo com qualquer temperatura, e ensinaria exatamente a coisa errada. Rotular não é gravar.]

  (b) A reta ou a rede? Por quê, nesta planta? E o que é o coeficiente da reta?
  #resp(n: 3)[A reta, com dois parâmetros contra treze: nesta faixa, a potência de regime é proporcional a $T - T_"amb"$, e uma reta a descreve inteira. O coeficiente é $1 slash G$: a reta aprendida é o ganho da planta, e mede $G$ melhor que os dez minutos de degrau.]

  Baixe o `modelo.h`, com `FF_TIPO` do modelo vencedor.
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 5 — a antecipação na bancada.* Com o novo `modelo.h`, grave, envie
  `A400`, espere estabilizar e envie `A450`. Compare com o mesmo degrau de alvo da
  Tarefa 3.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [PI (Tarefa 3)], [PI + antecipação],
    [Tempo de 40 a 45 °C, até ±0,5 °C (min)], [], [],
    [Sobressinal (°C)], [], [],
  )

  O que a antecipação fez, e o que ela *não* pode fazer?
  #resp(n: 2)[Entrega de saída a potência de regime do alvo novo, e o PI só corrige o resto: menos erro acumulado, menos sobressinal. Não acelera a descida: acima do alvo a única ação é desligar — a autoridade é de um lado só.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 6 — o custo e o balanço.* Com `FF_TIPO` 2, ponha `LATE2 = 1` antes de
  `controlar` e `LATE2 = 0` depois, e meça o pulso.

  #tab(columns: (1fr, 3cm),
    [Tempo de `controlar` com a rede], g[≈ 100 a 150 µs],
    [Em ciclos de máquina], g[≈ 500],
  )

  (a) A inferência cabe? Compare com a tela e com o conversor.
  #resp(n: 1)[Folgada: cerca de um décimo de uma atualização de tela, uma vez por segundo. O que não cabe no chip é o treino.]

  (b) P5: compare com o R9 a amplitude e os acionamentos.
  #resp(n: 2)[Amplitude de uma fração de grau contra alguns graus; acionamentos mecânicos deixam de existir. O preço é a complexidade: um modelo, uma sintonia e dados — onde o liga-desliga tinha dois `if`.]
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.3fr),
  [Sintoma], [Causa provável],
  [Aquecedor não responde], [CCP2 não está em RC1 (`CCP2MX`), ou CH3-3 em OFF],
  [Sobressinal enorme], [`ANTIWINDUP` 0, ou ganhos de outra planta],
  [O controle empurra para o lado errado], [Estouro na conta: produtos em 16 bits em vez de 32],
  [Notebook não acha o arquivo], [Nome diferente de `degrau.csv` ou `pi.csv`, ou upload não feito],
  [Poucas amostras em regime], [Tempo de menos no alvo: a planta precisa de minutos parada],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1 a 6, o `pi.csv`, o `modelo.h` e o gráfico da etapa D.
]

#criterio[
  Previsões P1 a P5: 0,4 cada.

  Tarefa 1 (identificação): 1,5 — a nota está na alínea (a). Tarefa 2 (sintonia):
  1,5. Tarefa 3 (PI na bancada): 1,5. Tarefa 4 (rotular e treinar): 1,5 — a
  resposta completa da alínea (b) diz que o coeficiente da reta é $1 slash G$.
  Tarefa 5 (antecipação): 1,0. Tarefa 6 (custo e balanço): 1,0.
]

= Se sobrar tempo

#opcional[
  *E1 — os coeficientes na memória.* Grave os ganhos e o modelo na memória não
  volátil (R11) e leia-os ao ligar, em vez de compilá-los.
  #resp(n: 1)[Treze parâmetros da rede mais os ganhos: menos de 32 bytes, com marcador, como o alvo do R11.]
]

#opcional[
  *E2 — a rede em `int8`.* No notebook, quantize em 8 bits em vez de 16 e
  resimule. O controle piora? Quanto a inferência ganharia no PIC18, que multiplica
  8 × 8 em uma instrução?
  #resp(n: 1)[Nesta planta, quase nada piora: o gargalo é o degrau do conversor. A inferência cairia para cerca de um terço dos ciclos.]
]

#nota[
  No TP, parte 2, estes ganhos — e, se o grupo quiser, este modelo — controlam o
  termostato inteiro.
]
