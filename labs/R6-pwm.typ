#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge

// ---------- configurações de página ----------
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Microcontroladores — Prática],
      align(right)[Roteiro 6],
    )
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira — DENE/UFMT],
      align(right)[#context counter(page).display("1")],
    )
  ],
)

#show heading: set block(below: 1.4em, above: 1.8em)

// ---------- tipografia ----------
#set text(font: "Linux Libertine", size: 11pt, lang: "pt")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#show raw.where(block: true): it => block(
  width: 100%,
  fill: luma(247),
  stroke: 0.5pt + luma(210),
  inset: 8pt,
  radius: 3pt,
)[#it]

// ---------- cores ----------
#let azul     = rgb("#003366")
#let destaque = rgb("#1a6bad")
#let cinza    = luma(245)
#let vermelho = rgb("#b04020")
#let verde    = rgb("#1a6b1a")
#let roxo     = rgb("#5a0080")
#let laranja  = rgb("#805000")

// ---------- ambientes ----------
#let caixa(titulo, cor-borda, cor-fundo, corpo) = block(
  width: 100%,
  fill: cor-fundo,
  stroke: (left: 3pt + cor-borda),
  inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt),
  radius: (right: 3pt),
  breakable: true,
)[
  #text(weight: "bold", fill: cor-borda)[#titulo] \
  #corpo
]

#let conceito(corpo)   = caixa("Conceito central", azul, rgb("#eef3fa"), corpo)
#let bancada(corpo)    = caixa("Configuração de bancada", destaque, rgb("#f0f6ff"), corpo)
#let importante(corpo) = caixa("⚠ Atenção", vermelho, rgb("#fff5f0"), corpo)
#let tarefa(corpo)     = caixa("Tarefa", verde, rgb("#f0faf0"), corpo)
#let previsao(corpo)   = caixa("✎ Previsão — registre ANTES de gravar", roxo, rgb("#f5f0ff"), corpo)
#let observacao(corpo) = caixa("Observação", laranja, rgb("#fff8ee"), corpo)
#let manual(corpo)     = caixa("📕 Divergência do manual", laranja, rgb("#fff8ee"), corpo)

// ---------- utilidades ----------
#let quadro = box(width: 9pt, height: 9pt, stroke: 0.6pt + luma(90), radius: 1pt)
#let resposta(n: 1) = for _ in range(n) [ #v(0.9em) #line(length: 100%, stroke: 0.4pt + luma(170)) ]
#block(width: 100%, fill: azul, inset: (x: 16pt, y: 20pt), radius: 4pt)[
  \
  #text(fill: white, size: 18pt, weight: "bold")[Microcontroladores]
  \
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 6 — Timers e PWM]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa("Objetivos desta sessão", rgb("#555555"), cinza, [
  Ao final desta sessão o grupo deve ser capaz de:

  1. Configurar o Timer2 e os módulos CCP em modo PWM;
  2. Calcular período e frequência do PWM a partir de `PR2` e do prescaler;
  3. Medir duty cycle e frequência no osciloscópio;
  4. Distinguir o sinal no pino do microcontrolador do sinal na carga.
])

#v(0.6em)

#importante[
  *Sessão com osciloscópio.* É uma das duas aulas do semestre com instrumentação. Reserve tempo para as medidas — elas são o centro do roteiro, não um complemento.
]

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [CH1-7 (TEMP)], [ON],
    [CH2-1 (LCD)], [ON],
    [CH3-3 (AQUECEDOR)], [ON],
    [CH3-5 (VENTILADOR)], [ON],
    [CH3-4, CH3-6, CH3-7], [OFF],
    [SWITCHS], [Todas em OFF],
  )

  *Osciloscópio:* ponta de prova em 10#sym.times, *acoplamento DC*, escala vertical em 1 ou 2 V/div, filtro de largura de banda *desligado*. Terra em qualquer GND dos conectores de porta. Compense a ponta antes de começar.

  Em acoplamento AC a onda quadrada vira dente de serra; em 100 mV/div o sinal sai da tela.
]

= Fundamento

== Meia potência com um pino digital

O pino só assume 0 V ou 5 V. Não existe valor intermediário.

A solução é *chavear rápido*: se o pino fica metade do tempo em 5 V e metade em 0 V, e o chaveamento é muito mais rápido que a resposta da carga, a carga se comporta como se recebesse metade da potência.

A fração de tempo em nível alto chama-se *duty cycle*.

#conceito[
  O PWM não gera tensão intermediária. Ele explora o fato de que a carga — um motor com inércia mecânica, uma resistência com inércia térmica — não consegue responder a cada pulso individualmente e reage à média.

  Se a carga fosse rápida o bastante para seguir os pulsos, o PWM não funcionaria.
]

== Período do PWM

Com o Timer2 como base de tempo:

$ T_"PWM" = ("PR2" + 1) times 4 times T_"osc" times "prescaler" $

Com $F_"osc" = 16$ MHz e $"PR2" = 255$:

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Prescaler],
      text(fill: white, weight: "bold")[Período],
      text(fill: white, weight: "bold")[Frequência],
    ),
    [1:1],  [64,0 #sym.mu s],   [15,6 kHz],
    [1:4],  [256,0 #sym.mu s],  [3,9 kHz],
    [1:16], [1024,0 #sym.mu s], [977 Hz],
  ),
  caption: [Frequências de PWM disponíveis com `PR2` = 255.],
) <tab-pwm-freq>

#manual[
  *O clock da CPU é 16 MHz, não 48 MHz.*

  Os config bits gravados junto com o bootloader definem uma árvore
  de clock em que o periférico USB recebe 48 MHz e a CPU recebe
  16 MHz. Os `#pragma config` da aplicação são ignorados.

  Isso foi descoberto por medição, não por leitura de documentação:
  uma onda quadrada programada para 300 ms mediu 375 ms no
  osciloscópio, e o fator de 1,25 revelou o clock verdadeiro.
]

/ 6.1: Verifique a primeira linha da tabela refazendo a conta. Mostre o desenvolvimento. #resposta(n: 3)

== Onde vai o duty

O valor de duty tem 10 bits, repartidos entre dois registradores: os 8 bits altos em `CCPR1L` e os 2 baixos em `CCP1CON<5:4>`.

Nesta sessão usaremos apenas os 8 bits altos, o que dá resolução suficiente e simplifica o código.

= Parte 1 — Medidas no pino

Grave o firmware `r6_pwm_osciloscopio.c`. Controles: *INT0 (SW12)* avança o duty; *INT1 (SW13)* avança a frequência. Os LEDs mostram o duty em barra.

#tarefa[
  *1.1* — Meça na *saída do microcontrolador*: conector PORTC, pino RC2.

  Mantenha a frequência em 977 Hz e varie o duty.

  #table(
    columns: (auto, 1fr, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Duty nominal],
      text(fill: white, weight: "bold")[$t_"alto"$],
      text(fill: white, weight: "bold")[Período],
      text(fill: white, weight: "bold")[Duty medido],
    ),
    [25%],  [], [], [],
    [50%],  [], [], [],
    [75%],  [], [], [],
  )
]

/ 1.2: O período mudou quando você alterou o duty? Isso era esperado? #resposta(n: 2)

#previsao[
  *1.3* — Agora você vai mudar a *frequência*, mantendo o duty em 50%.

  Antes de fazer: a fração de tempo em nível alto vai mudar? Justifique.

  #resposta(n: 2)
]

#tarefa[
  *1.4* — Meça nas três frequências, com duty fixo em 50%.

  #table(
    columns: (auto, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Prescaler],
      text(fill: white, weight: "bold")[Frequência medida],
      text(fill: white, weight: "bold")[Duty medido],
    ),
    [1:16], [], [],
    [1:4],  [], [],
    [1:1],  [], [],
  )
]

/ 1.5: Compare com a @tab-pwm-freq. Os valores batem? Se houver desvio, ele é sistemático ou aleatório? #resposta(n: 2)

#conceito[
  Duty e frequência são *graus de liberdade independentes*. Um controla quanta potência chega à carga; o outro controla a granularidade do chaveamento. Confundir os dois é erro comum em projeto de acionamento.
]

= Parte 2 — Pino contra carga

Esta é a medida mais importante da sessão.

#previsao[
  *2.1* — Você vai medir simultaneamente o pino RC2 do PIC e a saída do driver ULN2803, que aciona a ventoinha.

  Antes de ligar: as duas formas de onda serão iguais? Terão a mesma amplitude? A mesma fase?

  #resposta(n: 3)
]

#tarefa[
  *2.2* — Configure os dois canais:

  - *Canal 1:* RC2 no conector PORTC
  - *Canal 2:* test point da ventoinha, após o ULN2803
  - Duty em 50%, frequência em 977 Hz, CH3-5 em ON

  Desenhe as duas formas de onda em escala, uma sobre a outra.
]

#v(6em)
#line(length: 100%, stroke: 0.4pt + luma(170))
#v(6em)
#line(length: 100%, stroke: 0.4pt + luma(170))

/ 2.3: As duas ondas têm a mesma amplitude? Qual o nível de tensão de cada uma? #resposta(n: 2)

/ 2.4: Estão em fase ou invertidas? Explique com base no funcionamento do ULN2803. #resposta(n: 3)

#conceito[
  O ULN2803 tem saída *open-collector*: quando a entrada está em nível alto, o transistor conduz e puxa a saída para o terra. A carga fica entre a saída e os $+12$ V.

  Isso significa que "pino do microcontrolador em nível alto" e "carga energizada" são afirmações diferentes — e a diferença aparece na tela.

  Todo driver de potência introduz alguma transformação desse tipo. Conhecer a do seu driver é parte do projeto, não detalhe de implementação.
]

= Parte 3 — Aplicação ao termostato

#tarefa[
  *3.1* — Substitua o controle liga/desliga do Roteiro 5 por atuação proporcional:

  ```c
  erro    = setpoint - temperatura;          /* décimos de grau */
  esforco = (erro * KP) / ESCALA_GANHO;
  ```

  com `KP = 96` e `ESCALA_GANHO = 64` como ponto de partida.

  O esforço positivo aciona o aquecedor; negativo, a ventoinha. Sature em 0 e 255.
]

#previsao[
  *3.2* — Com controle proporcional, a temperatura vai estabilizar *exatamente* no setpoint?

  Responda antes de rodar, e justifique em termos do que acontece com o esforço quando o erro diminui.

  #resposta(n: 3)
]

/ 3.3: O que de fato aconteceu? Em que temperatura o sistema estabilizou? #resposta(n: 2)

/ 3.4: Se houve diferença em relação ao setpoint, quanto foi? Aumente `KP` para 192 e repita. A diferença diminuiu? Algo piorou? #resposta(n: 3)

#observacao[
  O comportamento observado em 3.3 e 3.4 é o assunto central do Roteiro 9. Guarde os números.
]

= Teste de aceitação

#quadro Tabelas 1.1 e 1.4 preenchidas com medidas do osciloscópio.

#quadro Desenho 2.2 das duas formas de onda, com escalas anotadas.

#quadro Termostato com atuação proporcional funcionando.

= Entrega e critério

#figure(
  table(
    columns: (auto, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Peso],
      text(fill: white, weight: "bold")[Item],
    ),
    [0,2], [Teste de aceitação aprovado],
    [0,2], [Cálculo 6.1 e comparação 1.5 com os valores medidos],
    [0,2], [Previsão 1.3 e previsão 2.1, registradas antes das medidas],
    [0,2], [Respostas 2.3 e 2.4 sobre o driver],
    [0,2], [Previsão 3.2 e respostas 3.3 e 3.4],
  ),
  caption: [Distribuição do ponto do Roteiro 6.],
)

= Armadilhas frequentes

#figure(
  table(
    columns: (1.1fr, 1.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Sintoma],
      text(fill: white, weight: "bold")[Causa provável],
    ),
    [Onda com bordas arredondadas], [Ponta de prova em 1#sym.times ou não compensada],
    [Nenhum sinal no pino], [Timer2 desligado, ou `CCPxCON` fora do modo PWM],
    [Duty não muda], [Escreveu em `CCPR1H` no lugar de `CCPR1L`],
    [Sinal instável na tela], [Trigger mal ajustado; use borda de subida no canal 1],
    [Ruído no chaveamento da carga], [Normal: é o motor. Registre como observação],
    [Aquecedor sempre ligado], [`CCP2MX` fora de ON: CCP2 não está em RC1],
  ),
  caption: [Diagnóstico rápido do Roteiro 6.],
)

= Para a próxima sessão

#tarefa[
  Seu programa hoje usa `__delay_ms()` para esperar entre as leituras. Durante essa espera, o processador não faz absolutamente nada.

  Traga escrito: se você precisasse, ao mesmo tempo, ler o sensor a cada 200 ms, atualizar o LCD a cada 300 ms e verificar um botão a cada 10 ms — como faria isso com `__delay_ms()`?
]
