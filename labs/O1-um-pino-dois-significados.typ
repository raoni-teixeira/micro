
#let primaria = rgb("#1c3f6e")
#let secundaria = rgb("#b8621b")

#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  header: context {
    grid(
      columns: (1fr, auto),
      text(8.5pt, fill: primaria, weight: "semibold")[Microcontroladores],
      text(8.5pt, fill: secundaria)[Oficina 1 — Um pino, dois significados],
    )
    v(-7pt)
    line(length: 100%, stroke: 0.6pt + primaria)
  },
  footer: context {
    line(length: 100%, stroke: 0.6pt + secundaria)
    v(-3pt)
    grid(
      columns: (1fr, auto),
      text(8.5pt, fill: primaria)[Raoni F. S. Teixeira],
      text(8.5pt, fill: secundaria)[#counter(page).display("1")],
    )
  },
)

#set text(font: "Libertinus Serif", size: 10.5pt, lang: "pt")
#set par(justify: true, leading: 0.62em)
#set heading(numbering: "1.1")
#show figure: set block(breakable: true)

#show heading.where(level: 1): it => block(above: 1.3em, below: 0.7em)[
  #text(fill: primaria, size: 13pt, weight: "bold")[#it]
]
#show heading.where(level: 2): it => block(above: 1.0em, below: 0.5em)[
  #text(fill: primaria.darken(10%), size: 11pt, weight: "bold")[#it]
]

#show raw.where(block: true): it => block(
  width: 100%, fill: rgb("#f5f6f8"), stroke: (left: 3pt + primaria),
  inset: (x: 10pt, y: 8pt), radius: (right: 3pt), breakable: true,
  text(size: 8.8pt, it),
)
#show raw.where(block: false): it => box(
  fill: rgb("#eef0f3"), inset: (x: 3pt, y: 1pt), radius: 2pt, text(size: 9.3pt, it),
)

#let caixa(titulo, cor, corpo) = block(
  width: 100%, fill: cor.lighten(90%), stroke: (left: 3pt + cor),
  inset: (x: 10pt, y: 8pt), radius: (right: 3pt), breakable: true,
  above: 0.9em, below: 0.9em,
)[
  #text(size: 9pt, weight: "bold", fill: cor.darken(15%))[#upper(titulo)]
  #v(-5pt)
  #corpo
]

#let objetivos(corpo)   = caixa("Objetivos", primaria, corpo)
#let atencao(corpo)     = caixa("Atenção", rgb("#b8860b"), corpo)
#let perigo(corpo)      = caixa("Perigo", rgb("#b02020"), corpo)
#let nota(corpo)        = caixa("Nota", rgb("#4a5568"), corpo)
#let tarefa(corpo)      = caixa("Tarefa", rgb("#2f6b4f"), corpo)
#let experimento(corpo) = caixa("Experimento", rgb("#1a6f7a"), corpo)
#let conceito(corpo)    = caixa("Conceito", rgb("#5b3a8e"), corpo)
#let bancada(corpo)     = caixa("Bancada", rgb("#6b5334"), corpo)
#let chaves(corpo)      = caixa("Chaves", rgb("#8a4a1a"), corpo)
#let semnota(corpo)     = caixa("Sem nota", rgb("#5a6570"), corpo)
#let previsao(corpo)    = caixa("Previsão — antes de energizar", secundaria, corpo)
#let divergencia(corpo) = caixa("Divergência — verificar antes do uso", rgb("#c0392b"), corpo)
#let codigo(corpo)      = caixa("Escreva o código", rgb("#0f5a5e"), corpo)

#let tabela(..args) = table(
  stroke: (x, y) => if y == 0 { (bottom: 0.8pt + primaria) } else { (bottom: 0.3pt + rgb("#c9ced6")) },
  fill: (_, y) => if y == 0 { primaria.lighten(88%) } else if calc.odd(y) { rgb("#f5f6f8") },
  inset: (x: 7pt, y: 5pt),
  ..args
)

#let lacuna = box(width: 1fr, baseline: 2pt, line(length: 100%, stroke: 0.5pt + rgb("#98a0ac")))

#let parte(rotulo, titulo) = block(width: 100%, above: 1.7em, below: 0.9em)[
  #line(length: 100%, stroke: 1pt + secundaria)
  #v(-2pt)
  #text(size: 8.5pt, fill: secundaria, weight: "bold")[#upper(rotulo)]
  #v(-7pt)
  #text(size: 15pt, fill: primaria, weight: "bold")[#titulo]
]

// ============================= título ================================
#align(center)[
  #text(size: 17pt, weight: "bold", fill: primaria)[Oficina 1 — Um pino, dois significados]
  #v(-8pt)
  #text(size: 10.5pt, fill: secundaria)[O painel de atuadores e a melodia no buzzer · PIC18F4550 · 16 MHz]
  #v(-4pt)
  #text(size: 9pt)[Microcontroladores — DENE/UFMT]
]
#v(0.6em)

#semnota[
  Esta oficina *não vale nota*. Ela existe para que os erros aconteçam aqui e não
  no primeiro roteiro avaliado. Quebre o programa de propósito, meça errado,
  recompile. Traga o registro preenchido: ele será discutido em sala, não
  corrigido.
]

#nota[
  *O que a Aula 2 já resolveu, e não será reexplicado aqui:* o núcleo a 16 MHz e
  $T_"cy" = 250$ ns; a ordem `LAT` antes de `TRIS`; a contagem de ciclos; a
  calibração de `atraso_unidades` e a conversão de nota para $N$.

  Hoje nada disso é construído de novo. Tudo é *medido*, em um lugar onde o
  simulador não alcança: onde há um transdutor, um motor e um filamento
  incandescente ligados ao mesmo tipo de pino.
]

#objetivos[
  - Configurar as chaves DIP que decidem qual atuador está ligado a um pino, e
    reconhecer que o programa não tem como consultá-las.
  - Estabelecer, por observação, que *frequência* e *razão cíclica* de um sinal
    quadrado controlam grandezas distintas, e que cada carga responde a uma delas.
  - Ouvir o transitório que a ordem `TRIS` antes de `LAT` produz.
  - Medir a afinação real da melodia da Aula 2 e diagnosticar o erro pela sua
    assinatura.
]

#bancada[
  *Duas horas, sete etapas.* Se o tempo apertar, o corte é na etapa 3 — nunca na
  6, que é o experimento central, nem na 7, que fecha a Aula 2.

  #tabela(
    columns: (0.06fr, 0.66fr, 0.16fr),
    [], [*Etapa*], [*Tempo*],
    [1], [Bancada, chaves e previsão], [15 min],
    [2], [Programa base e verificação do relógio], [15 min],
    [3], [A lâmpada e o tique do buzzer], [10 min],
    [4], [`LAT` antes de `TRIS`, agora audível], [10 min],
    [5], [O mesmo sinal, dois significados — passagem no buzzer], [20 min],
    [6], [O mesmo sinal, dois significados — passagem no cooler], [25 min],
    [7], [A melodia, com afinador], [20 min],
  )

  *Por bancada:* kit XM118 com fonte, cabo USB, computador com MPLAB X e XC8,
  aplicativo #emph[Bootloader PIC18/XM118] v2.8, cronômetro e um celular com
  afinador cromático.
]

// =====================================================================
= Antes de energizar


#atencao[
  *Não pressione SW2 nem SW3* durante toda a sessão: elas estão ligadas a RC0 e
  RC1, que hoje são saídas, e pressioná-las aterra a saída.

  A *lâmpada* fica ligada por no máximo 30 segundos por vez, e não se toca nela
  depois de desligar.

  *Buzzer:* pulsos de no máximo 300 ms, com pausa. Doze bancadas com som contínuo
  tornam a sala inutilizável.
]

#nota[
  *Gravação.* O MPLAB X compila em modo #emph[No Tool] e não grava. Pressione
  *SW9* — não SW1, como diz o manual — e, dentro de 4 a 5 segundos, envie o `.hex`
  pelo aplicativo do bootloader. Se a janela passar, repita.
]

// =====================================================================
= Previsão

#previsao[
  Preencha *antes de energizar*, sem consultar a bancada ao lado. Uma frase por
  linha basta. Previsão errada não é problema; previsão ausente transforma o
  experimento em demonstração.
]

#tabela(
  columns: (0.44fr, 1fr, 0.12fr),
  [*Pergunta*], [*Previsão e justificativa*], [*Confere?*],
  [P1. Com `LATC2 = 1` fixo, o buzzer emite som contínuo?], [], [],
  [P2. Num sinal quadrado, mudar a *frequência* afeta o quê no buzzer? E no
   cooler?], [], [],
  [P3. E mudar a *razão cíclica*, isto é, a proporção entre ligado e desligado?], [], [],
  [P4. Invertendo a ordem para `TRIS` antes de `LAT`, o que você espera *ouvir*
   no instante do #emph[reset]?], [], [],
  [P5. A Aula 2 previu a melodia em décimos de µs com $+33$ cents de erro, igual
   em todas as notas. O que você espera medir com o afinador?], [], [],
)

// =====================================================================
= O painel: um pino, vários atuadores

O PIC18F4550 tem 35 pinos de entrada e saída. A XM118 tem mais periféricos do que
isso, e a solução do fabricante foi rotear vários deles para o *mesmo* pino,
deixando a escolha para um banco de chaves DIP.

#tabela(
  columns: (0.18fr, 0.2fr, 0.16fr, 1fr),
  [*Chave*], [*Atuador*], [*Pino*], [*Observação*],
  [CH3-2], [SPEED], [RC0], [Realimentação do tacógrafo — é entrada, não saída],
  [CH3-3], [HEATER], [RC1], [Resistência de aquecimento; entra no Roteiro 6],
  [CH3-4], [LAMP], [RC1], [Lâmpada de 12 V — usada hoje],
  [CH3-5], [COOLER], [RC2], [Ventoinha — usada na etapa 6],
  [CH3-6], [BUZZER], [RC2], [Buzzer — usado nas etapas 3, 5 e 7],
  [CH3-7], [DAC IN], [RC2], [Mantenha desligada o semestre inteiro],
)

#conceito[
  Leia a tabela pela coluna de *pino*, não pela de atuador. RC1 aceita o aquecedor
  ou a lâmpada; RC2 aceita o cooler, o buzzer ou o DAC. Nunca dois ao mesmo tempo.

  A consequência organiza a sessão inteira: `LATCbits.LATC2 = 1` não significa
  "ligar o buzzer" nem "ligar o cooler". Significa *colocar o pino RC2 em nível
  alto*. O que acontece no mundo depende de uma chave mecânica que o programa não
  lê, não controla e não tem como consultar.

  É a camada 4 da Aula 2, §2.7 — a única que nenhuma ferramenta conhece — e hoje
  ela está na sua mão. Por isso os nomes no código de hoje são de pino.
]

#chaves[
  *Configuração inicial.* Confira uma a uma antes de energizar:

  #table(
    columns: (auto, auto, auto, auto, auto, auto),
    stroke: 0.3pt + rgb("#c9ced6"),
    inset: (x: 6pt, y: 4pt),
    [*CH3-2*], [*CH3-3*], [*CH3-4*], [*CH3-5*], [*CH3-6*], [*CH3-7*],
    [OFF], [OFF], [ON], [OFF], [ON], [OFF],
    [SPEED], [HEATER], [LAMP], [COOLER], [BUZZER], [DAC],
  )

  Lâmpada em RC1, buzzer em RC2. Aquecedor e cooler desconectados.
]

// =====================================================================
= O programa base e a verificação do relógio

```c
#define _XTAL_FREQ 16000000UL   /* nucleo a 16 MHz — Aula 2, §2.5 */

#include <xc.h>
#include <stdint.h>

#define LEDS_LAT   LATD               /* barra de 8 LEDs — pinos fixos  */
#define LEDS_TRIS  TRISD
#define RC1_LAT    LATCbits.LATC1     /* HEATER (CH3-3) ou LAMP (CH3-4) */
#define RC1_TRIS   TRISCbits.TRISC1
#define RC2_LAT    LATCbits.LATC2     /* COOLER, BUZZER ou DAC          */
#define RC2_TRIS   TRISCbits.TRISC2

static void saidas_init(void)
{
    LEDS_LAT = 0x00;  RC1_LAT = 0;  RC2_LAT = 0;   /* 1) estado seguro */
    LEDS_TRIS = 0x00; RC1_TRIS = 0; RC2_TRIS = 0;  /* 2) so entao saida */
}

void main(void)
{
    saidas_init();
    while (1) {
        /* os experimentos entram aqui, um de cada vez */
    }
}
```

#tarefa[
  *A primeira medição da sessão.* Ponha no laço principal:

  ```c
  LEDS_LAT = 0xFF;  __delay_ms(500);
  LEDS_LAT = 0x00;  __delay_ms(500);
  ```

  Cronometre *20 piscadas completas* e divida por 20.

  #tabela(
    columns: (0.5fr, 0.25fr, 0.25fr),
    [*Grandeza*], [*Esperado*], [*Medido*],
    [Tempo de 20 piscadas], [20,0 s], [],
    [Período de uma piscada], [1,00 s], [],
  )
]

#atencao[
  Se o período não bater dentro de uns poucos por cento, pare aqui: `_XTAL_FREQ`
  está errado, e *nenhuma* medida do resto da sessão vai fechar. Com
  `48000000UL`, os atrasos saem três vezes mais longos e as notas saem três vezes
  mais graves.

  Esta é a primeira coisa a verificar em qualquer anomalia de tempo, o semestre
  inteiro.
]

// =====================================================================
= A lâmpada e o tique do buzzer

#tarefa[
  *A lâmpada.* No laço principal, `RC1_LAT = 1; __delay_ms(10000); RC1_LAT = 0;`

  Quanto tempo o filamento leva para apagar completamente depois que o pino vai a
  zero? #lacuna
]

#experimento[
  A lâmpada não apaga no instante do comando. Esse atraso entre *comandar* e
  *observar o efeito* reaparece, muito mais lento, quando o aquecedor da mesma
  linha RC1 precisar elevar a temperatura do sensor. É a razão de existir do
  controle com histerese, no Roteiro 9.
]

#tarefa[
  *O buzzer com nível constante.* `RC2_LAT = 1; __delay_ms(3000); RC2_LAT = 0;`

  Escute com atenção e confronte com a previsão P1. Descreva exatamente o que
  ouviu: #lacuna
]

#conceito[
  O que se ouve é um *tique* curto no instante da subida, e depois silêncio.

  Há dois componentes vendidos com o mesmo nome e o mesmo aspecto. O buzzer
  *ativo* tem um oscilador dentro: aplique nível alto e ele apita, na frequência
  que o fabricante escolheu — você liga e desliga o som, não escolhe a nota. O
  buzzer *passivo* é apenas um transdutor: converte em movimento a tensão que
  recebe.

  O XM118 traz um buzzer passivo. Nível alto empurra a membrana para um lado; ela
  vai até lá, para, e fica parada. Uma membrana parada não move ar, e o tique é o
  deslocamento único.

  Isso não aparece na folha de dados do microcontrolador nem no código: aparece no
  ouvido, em um segundo de teste. E é dele que depende a etapa 7 — com um buzzer
  ativo, *quem comporia a melodia seria o fabricante*, não o firmware.
]

// =====================================================================
= `LAT` antes de `TRIS`, agora audível

Na Aula 2 vocês viram esta regra reduzida a dois opcodes, e observaram no
simulador que o LED apaga na instrução do `TRIS`. Com um LED o transitório é
invisível. Aqui não é.

#experimento[
  Inverta os dois blocos de `saidas_init`:

  ```c
  static void saidas_init(void)
  {
      LEDS_TRIS = 0x00; RC1_TRIS = 0; RC2_TRIS = 0;  /* saida ANTES ...   */
      LEDS_LAT = 0x00;  RC1_LAT = 0;  RC2_LAT = 0;   /* ... do estado     */
  }
  ```

  Grave e pressione o #emph[reset] *várias vezes seguidas*, prestando atenção ao
  buzzer e à lâmpada. Depois volte à ordem original e repita.

  O que muda? #lacuna
]

#conceito[
  No #emph[reset] todo pino nasce como entrada, e o conteúdo de `LAT` é
  indefinido. Enquanto o pino é entrada, `LAT` não chega ao mundo. Escrever
  `TRIS = 0` habilita a saída, e nesse instante o pino passa a refletir o que
  estiver em `LAT` — que, na versão invertida, ainda não foi escrito.

  Com um LED o transitório é invisível; com o buzzer é audível; com um motor ou
  uma resistência de aquecimento é mecânico e térmico. *A regra não mudou entre a
  aula e a bancada. O que mudou foi a consequência de quebrá-la.*
]

// =====================================================================
= O mesmo sinal, dois significados

Este é o experimento central, e ele tem uma exigência: *o código não muda entre as
duas passagens.* Nem uma linha. O que muda é uma chave.

#tarefa[
  Substitua o laço principal pelo bloco abaixo. Os LEDs indicam qual rodada está
  em execução.

  ```c
  while (1) {
      /* Rodada 1 — 1 kHz, 50%  (referencia) */
      LEDS_LAT = 0x01;
      for (uint16_t i = 0; i < 4000; i++) {
          RC2_LAT = 1; __delay_us(500);
          RC2_LAT = 0; __delay_us(500);
      }
      LEDS_LAT = 0x00; __delay_ms(1500);

      /* Rodada 2 — 2 kHz, 50% */
      LEDS_LAT = 0x02;
      for (uint16_t i = 0; i < 8000; i++) {
          RC2_LAT = 1; __delay_us(250);
          RC2_LAT = 0; __delay_us(250);
      }
      LEDS_LAT = 0x00; __delay_ms(1500);

      /* Rodada 3 — 5 kHz, 50% */
      LEDS_LAT = 0x04;
      for (uint16_t i = 0; i < 20000; i++) {
          RC2_LAT = 1; __delay_us(100);
          RC2_LAT = 0; __delay_us(100);
      }
      LEDS_LAT = 0x00; __delay_ms(1500);

      /* Rodada 4 — 1 kHz, 10% */
      LEDS_LAT = 0x08;
      for (uint16_t i = 0; i < 4000; i++) {
          RC2_LAT = 1; __delay_us(100);
          RC2_LAT = 0; __delay_us(900);
      }
      LEDS_LAT = 0x00; __delay_ms(1500);

      /* Rodada 5 — 1 kHz, 90% */
      LEDS_LAT = 0x10;
      for (uint16_t i = 0; i < 4000; i++) {
          RC2_LAT = 1; __delay_us(900);
          RC2_LAT = 0; __delay_us(100);
      }
      LEDS_LAT = 0x00; __delay_ms(1500);
  }
  ```
]

#experimento[
  *Passagem 1 — buzzer.* Com CH3-6 ON e CH3-5 OFF, ouça o ciclo inteiro duas vezes
  e preencha a coluna do buzzer.

  *Passagem 2 — cooler.* Desligue a placa. Troque *apenas duas chaves*: CH3-6 para
  OFF, CH3-5 para ON. Religue. *Não regrave nada.* Observe o ciclo inteiro duas
  vezes e preencha a coluna do cooler.
]

#tabela(
  columns: (0.14fr, 0.2fr, 0.16fr, 0.5fr, 0.5fr),
  [*Rodada*], [*Frequência*], [*Razão cíclica*], [*Buzzer (som)*], [*Cooler (velocidade)*],
  [1], [1 kHz], [50%], [], [],
  [2], [2 kHz], [50%], [], [],
  [3], [5 kHz], [50%], [], [],
  [4], [1 kHz], [10%], [], [],
  [5], [1 kHz], [90%], [], [],
)

#tarefa[
  Compare as rodadas em dois grupos e responda por escrito:

  + *Rodadas 1, 2 e 3* mantêm a razão cíclica em 50% e variam a frequência. O que
    mudou no buzzer? O que mudou no cooler?
  + *Rodadas 1, 4 e 5* mantêm a frequência em 1 kHz e variam a razão cíclica. O
    que mudou no buzzer? O que mudou no cooler?
  + O microcontrolador executou exatamente o mesmo programa nas duas passagens. O
    que, então, decidiu o significado do sinal?
]

#conceito[
  #table(
    columns: (auto, auto, auto),
    stroke: 0.3pt + rgb("#c9ced6"),
    inset: (x: 7pt, y: 5pt),
    [], [*Muda a frequência*], [*Muda a razão cíclica*],
    [*Buzzer*], [o tom muda], [o tom *não* muda],
    [*Cooler*], [a velocidade *não* muda], [a velocidade muda],
  )

  Frequência e razão cíclica são dois parâmetros *independentes* do mesmo sinal, e
  cada carga responde a um deles. O buzzer converte a alternância em som e ignora
  quanto tempo o sinal passa em cada nível. O cooler tem inércia mecânica demais
  para seguir uma alternância de milissegundos: ele integra o sinal e responde à
  energia média, isto é, à razão cíclica.

  O programa não sabe de nada disso. Ele coloca RC2 em nível alto e baixo em
  ritmos diferentes; o significado físico foi decidido por uma chave DIP.
]

#nota[
  Guardem os nomes, porque a partir do Roteiro 3 eles aparecem o tempo todo: a
  proporção entre ligado e desligado é a *razão cíclica* (#emph[duty cycle]), e o
  par frequência-fixa-com-razão-variável é a *modulação por largura de pulso*,
  PWM. Trocar os dois é o erro mais comum do Roteiro 3, e vocês acabaram de
  separá-los por observação.
]

#tarefa[
  *Ainda com o cooler conectado*, três perguntas de fechamento:

  + Para mudar a velocidade do cooler neste programa, basta alterar um número em
    tempo de execução, ou é preciso reescrever e regravar?
  + Enquanto o laço da rodada 5 executa, o que mais o microcontrolador está
    fazendo?
  + Some os atrasos: quanto tempo de processador sobra, por segundo, para ler um
    sensor de temperatura e decidir alguma coisa?
]

#conceito[
  As respostas convergem. O laço ocupa *cem por cento* do tempo do processador, e
  a razão cíclica está congelada dentro de chamadas de `__delay_us` — no código
  compilado, não numa variável que um controlador possa ajustar.

  Um termostato precisa exatamente das duas coisas que faltam: variar a razão
  cíclica em função da temperatura lida, e fazer isso *sem* parar de executar o
  resto do programa. É o problema que o Roteiro 3 resolve, transferindo a geração
  do sinal para um periférico que trabalha sozinho. O módulo chama-se CCP1, e ele
  vive justamente no RC2 — quando ele assumir, o buzzer sai da CH3-6 em definitivo.
]

#chaves[
  *Antes da etapa 7,* volte: CH3-6 ON (buzzer), CH3-5 OFF (cooler).
]

// =====================================================================
= A melodia, com afinador

A Aula 2 fez a previsão, o simulador tocou. Falta a placa.

#tarefa[
  Grave `melodia_centesimos.hex` e depois `melodia_decimos.hex` — os dois já
  compilados, com a tabela de $N$ da Aula 2, §6.7. Aponte o afinador cromático e
  anote o desvio em cents de *três* notas.

  #tabela(
    columns: (0.2fr, 0.2fr, 0.3fr, 0.3fr),
    [*Nota*], [*$f$ alvo*], [*Centésimos: cents*], [*Décimos: cents*],
    [dó₄],  [261,63 Hz], [], [],
    [sol₄], [392,00 Hz], [], [],
    [dó₅],  [523,25 Hz], [], [],
  )

  Três notas bastam: uma no grave, uma no meio e uma uma oitava acima da
  primeira. É o mínimo para distinguir um erro uniforme de um que cresce.
]

#experimento[
  *O diagnóstico.* Compare a *forma* dos seus três números com as duas assinaturas
  da Aula 2, §6.9:

  #table(
    columns: (auto, auto),
    stroke: 0.3pt + rgb("#c9ced6"),
    inset: (x: 7pt, y: 5pt),
    [*Erro uniforme nas três notas*], [a constante $b$ está errada],
    [*Erro que cresce com a altura*], [há sobrecarga fixa por meio período],
  )

  Qual das duas você mediu, em cada versão? #lacuna

  Se as duas coisas estiverem acontecendo ao mesmo tempo, diga como você
  reconheceu isso nos números.
]

#nota[
  *Uma pergunta de sobra, para quem terminar antes.* Troque a inversão do pino por
  uma razão cíclica de 10% — o mesmo período, mas pulso curto. A nota continua a
  mesma? E o timbre?

  A resposta liga esta etapa à etapa 6: a frequência decide a nota, a razão cíclica
  decide o conteúdo harmônico. Um pulso de 50% é a onda quadrada, que tem apenas
  harmônicos ímpares e soa mais "cheia"; um pulso estreito soa mais fino e mais
  fraco.
]

// =====================================================================
= Registro

Entregue esta folha no fim da sessão, com todas as lacunas preenchidas, inclusive
as que divergiram da previsão. *Não apague a previsão original* — escreva ao lado
o que faltava no raciocínio.

#tabela(
  columns: (0.06fr, 0.64fr, 0.3fr),
  [], [*Item*], [*Conferido*],
  [1], [Período medido das 20 piscadas, e conclusão sobre `_XTAL_FREQ`], [],
  [2], [Descrição do que se ouve com `RC2_LAT = 1` constante], [],
  [3], [O que muda no #emph[reset] ao inverter `LAT` e `TRIS`], [],
  [4], [Tabela das cinco rodadas, nas duas passagens], [],
  [5], [Resposta às três perguntas de fechamento da etapa 6], [],
  [6], [Desvio em cents das três notas, nas duas versões], [],
  [7], [Diagnóstico: constante errada, sobrecarga, ou as duas], [],
)

#semnota[
  *O que se leva daqui.* Um pino não tem significado. Ele tem um nível de tensão e
  uma taxa de variação. O significado está no que você pendurou nele — e essa
  informação não existe em nenhum arquivo que o compilador possa ler.
]
