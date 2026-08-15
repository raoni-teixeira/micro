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
      align(right)[Roteiro 9],
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
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 9 — Análise comparativa de estratégias de controle]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa("Objetivos desta sessão", rgb("#555555"), cinza, [
  Ao final desta sessão o grupo deve ser capaz de:

  1. Formular previsões de comportamento a partir do modelo da planta;
  2. Coletar e comparar séries temporais de quatro estratégias de controle;
  3. Identificar o defeito característico de cada estratégia;
  4. Explicar divergências entre o previsto e o medido.
])

#v(0.6em)

= Como esta sessão funciona

Esta aula tem formato diferente das anteriores. O código já existe: o firmware de referência implementa as quatro estratégias, selecionáveis pela tecla `C` ou pelo comando serial `e`.

O trabalho de vocês é *prever, medir e explicar*.

#importante[
  *A previsão vale nota, e o acerto não.*

  Cada previsão deve ser entregue ao professor *antes* da coleta correspondente. O professor rubrica a folha e libera o experimento.

  Uma previsão errada, com raciocínio explícito, vale nota integral. Uma previsão certa sem justificativa, não. Previsão preenchida depois da medida vale zero — e é identificável.
]

#conceito[
  O objetivo não é descobrir qual controlador é o melhor. É construir o hábito de formular expectativa antes de observar — que é o que separa medir de tatear.

  Quando a previsão falha, você aprendeu algo sobre o sistema. Quando acerta sem ter raciocinado, não aprendeu nada.
]

= Recordando a planta

#figure(
  table(
    columns: (1fr, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Propriedade],
      text(fill: white, weight: "bold")[Consequência],
    ),
    [Aquecedor injeta calor], [Ação rápida e forte],
    [Ventoinha remove calor], [Ação mais lenta],
    [Ambiente remove sozinho], [Existe perda mesmo sem atuação],
    [Sensor junto à resistência], [Mede o aquecedor antes do ar: atraso],
    [Ruído de $approx 0,5$ #sym.degree\C], [Limite físico de discriminação],
  ),
  caption: [Propriedades da planta térmica do XM118.],
) <tab-planta>

Todas foram medidas por vocês nos Roteiros 4, 5 e 6. As previsões devem se apoiar nelas.

= Protocolo de coleta

Para *cada* estratégia, o procedimento é o mesmo:

+ Escrever a previsão e submetê-la ao professor.
+ Levar o sistema à temperatura ambiente (ventoinha em máximo, aquecedor desligado).
+ Selecionar a estratégia e o setpoint de 35,0 #sym.degree\C.
+ Registrar *8 minutos* de telemetria em arquivo.
+ Traçar a curva e extrair as métricas.

#figure(
  table(
    columns: (1fr, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Métrica],
      text(fill: white, weight: "bold")[Como obter],
    ),
    [Tempo de subida], [Do início até cruzar o setpoint pela primeira vez],
    [Sobressinal], [Maior temperatura atingida, menos o setpoint],
    [Erro em regime], [Média dos últimos 2 min, menos o setpoint],
    [Amplitude da oscilação], [Pico a pico nos últimos 2 min],
    [Chaveamentos], [Mudanças de ação nos últimos 2 min],
  ),
  caption: [Métricas a extrair de cada série temporal.],
) <tab-metricas>

= Estratégia 1 — Liga/desliga

#previsao[
  *P1* — Antes de coletar, responda:

  (a) A temperatura vai estabilizar ou oscilar? Se oscilar, com que amplitude?

  (b) Quantos chaveamentos você espera nos últimos 2 minutos?

  (c) Qual propriedade da @tab-planta sustenta sua resposta?

  #resposta(n: 4)

  #align(right)[Rubrica do professor: #box(width: 3cm, stroke: (bottom: 0.4pt))]
]

#tarefa[
  Colete e preencha:

  #table(
    columns: (1.4fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    [Tempo de subida], [],
    [Sobressinal], [],
    [Erro em regime], [],
    [Amplitude da oscilação], [],
    [Chaveamentos em 2 min], [],
  )
]

/ 1.1: Confronte com a previsão P1. O que divergiu? Por quê? #resposta(n: 3)

= Estratégia 2 — Histerese

#previsao[
  *P2* — Com banda morta de 2,0 #sym.degree\C:

  (a) A amplitude da oscilação será igual, maior ou menor que a banda?

  (b) O erro em regime será maior ou menor que no liga/desliga?

  #resposta(n: 4)

  #align(right)[Rubrica do professor: #box(width: 3cm, stroke: (bottom: 0.4pt))]
]

#tarefa[
  Colete e preencha as mesmas cinco métricas.

  #table(
    columns: (1.4fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    [Tempo de subida], [],
    [Sobressinal], [],
    [Erro em regime], [],
    [Amplitude da oscilação], [],
    [Chaveamentos em 2 min], [],
  )
]

/ 2.1: A amplitude excedeu a banda morta? Em quanto? Qual propriedade da planta explica o excesso? #resposta(n: 3)

= Estratégia 3 — Proporcional

O esforço passa a ser contínuo: $u = K_p e$, saturado entre 0 e 255.

#previsao[
  *P3* — Esta é a previsão central da sessão.

  (a) A temperatura vai estabilizar *exatamente* no setpoint? Justifique pensando no que acontece com o esforço à medida que o erro diminui.

  (b) Se não estabilizar no setpoint, ficará acima ou abaixo? Por quê?

  #resposta(n: 5)

  #align(right)[Rubrica do professor: #box(width: 3cm, stroke: (bottom: 0.4pt))]
]

#tarefa[
  Colete com $K_p = 96$ e repita com $K_p = 192$.

  #table(
    columns: (1.4fr, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Métrica],
      text(fill: white, weight: "bold")[$K_p = 96$],
      text(fill: white, weight: "bold")[$K_p = 192$],
    ),
    [Tempo de subida], [], [],
    [Sobressinal], [], [],
    [Erro em regime], [], [],
    [Amplitude da oscilação], [], [],
  )
]

/ 3.1: Houve erro em regime permanente? De quanto? #resposta(n: 2)

/ 3.2: Dobrar o ganho reduziu o erro? Reduziu à metade? Algo piorou junto? #resposta(n: 3)

#conceito[
  No proporcional, o esforço é proporcional ao erro. Se o erro fosse zero, o esforço seria zero — e sem esforço o sistema perde calor para o ambiente e esfria.

  Logo o equilíbrio ocorre onde o esforço compensa exatamente as perdas, o que exige erro *diferente de zero*. O erro em regime não é defeito de implementação: é consequência estrutural da lei de controle.
]

= Estratégia 4 — PI

Acrescenta-se o acúmulo do erro ao longo do tempo: $u = K_p e + K_i integral e$.

#previsao[
  *P4* —

  (a) O termo integral elimina o erro em regime? Por quê?

  (b) Que problema novo pode surgir quando o atuador satura por muito tempo?

  #resposta(n: 4)

  #align(right)[Rubrica do professor: #box(width: 3cm, stroke: (bottom: 0.4pt))]
]

#tarefa[
  Colete duas séries: uma com o limite do acumulador ativo, outra com o limite removido (partindo de temperatura bem abaixo do setpoint, para forçar saturação prolongada).
]

/ 4.1: Com o limite ativo, o erro em regime foi eliminado? #resposta(n: 2)

/ 4.2: Sem o limite, o que aconteceu na primeira aproximação ao setpoint? Descreva a curva. #resposta(n: 3)

#conceito[
  Enquanto o atuador está saturado, o erro persiste e o acumulador continua crescendo — sem que isso produza qualquer efeito adicional, porque o atuador já está no máximo.

  Quando o erro finalmente inverte de sinal, o acumulador inflado mantém o esforço por muito tempo, gerando sobressinal grande. É o fenômeno de _windup_, e a limitação explícita do acumulador é a defesa mais simples contra ele.
]

= Síntese

#tarefa[
  *5.1* — Consolide as quatro estratégias em uma tabela e trace as quatro curvas em um mesmo gráfico.

  #table(
    columns: (1fr, auto, auto, auto, auto),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    table.header(
      text(fill: white, weight: "bold")[Métrica],
      text(fill: white, weight: "bold")[Liga/desl.],
      text(fill: white, weight: "bold")[Histerese],
      text(fill: white, weight: "bold")[Prop.],
      text(fill: white, weight: "bold")[PI],
    ),
    [Tempo de subida], [], [], [], [],
    [Sobressinal], [], [], [], [],
    [Erro em regime], [], [], [], [],
    [Amplitude], [], [], [], [],
    [Chaveamentos], [], [], [], [],
  )
]

/ 5.2: Cada estratégia resolve um defeito da anterior e introduz um novo. Complete a cadeia, em uma frase por estratégia. #resposta(n: 4)

/ 5.3: Para um forno industrial que não pode ultrapassar a temperatura alvo em hipótese alguma, qual estratégia você escolheria? E para um sistema de proteção que precisa atuar em milissegundos? Justifique. #resposta(n: 4)

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
    [0,3], [As quatro previsões entregues e rubricadas *antes* da coleta, com mecanismo explicitado],
    [0,3], [Dados coletados, tabelas preenchidas e gráficos legíveis],
    [0,4], [Confronto entre previsão e medida, com explicação das divergências],
  ),
  caption: [Distribuição do ponto do Roteiro 9.],
)

#observacao[
  O maior peso está no confronto, não na coleta nem no acerto. Um grupo que previu errado nas quatro estratégias, percebeu os erros e explicou as causas recebe nota integral.
]

= Para a próxima sessão

#tarefa[
  Vocês passaram nove sessões trabalhando com uma caixa azul de dois quilos, com relés, DB9 e fonte chaveada.

  Traga escrito: em uma frase, o que exatamente é "o microcontrolador" nesse conjunto?
]
