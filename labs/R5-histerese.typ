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
      align(right)[Roteiro 5],
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
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 5 — Controle liga/desliga e histerese]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa("Objetivos desta sessão", rgb("#555555"), cinza, [
  Ao final desta sessão o grupo deve ser capaz de:

  1. Implementar controle liga/desliga sobre uma planta térmica real;
  2. Identificar o chaveamento excessivo e relacioná-lo ao ruído de medição;
  3. Implementar histerese e dimensionar a banda morta;
  4. Explicar por que o controlador com histerese tem memória de estado.
])

#v(0.6em)

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [CH1-7 (TEMP)], [ON],
    [CH1-1 e CH1-5], [OFF],
    [CH2-1 (LCD)], [ON],
    [*CH3-3 (AQUECEDOR)*], [*ON*],
    [CH3-4 (LAMP)], [OFF — disputa RC1],
    [*CH3-5 (VENTILADOR)*], [*ON*],
    [CH3-6 e CH3-7], [OFF — disputam RC2],
    [SWITCHS], [Todas em OFF],
  )
]

#importante[
  A partir desta sessão o kit *aquece de verdade*. A resistência atinge temperatura desconfortável ao toque. Não encoste nela durante os ensaios e evite deixar o aquecedor ligado sem supervisão.
]

= A planta

O conjunto térmico do XM118 não é o caso simétrico dos livros:

- o *aquecedor* injeta calor quando acionado;
- a *ventoinha* remove calor quando acionada;
- o *ambiente* remove calor o tempo todo, sem ser comandado;
- o *sensor* está montado junto à resistência — mede o aquecedor antes de medir o ar.

#conceito[
  Essas quatro propriedades não são detalhes do PIC. São a estrutura do problema, e explicam quase tudo o que você vai observar hoje: por que aquecer é mais rápido que resfriar, e por que a temperatura continua subindo depois de o aquecedor desligar.
]

= Parte 1 — Liga/desliga puro

#previsao[
  *1.1* — Considere a regra mais simples possível:

  ```c
  if (temperatura < setpoint)      liga_aquecedor();
  else if (temperatura > setpoint) liga_ventoinha();
  else                             desliga_tudo();
  ```

  Antes de implementar, responda:

  (a) O que acontecerá quando a temperatura chegar *perto* do setpoint?

  (b) Com que frequência você espera que os atuadores mudem de estado nessa região?

  #resposta(n: 3)
]

#tarefa[
  *1.2* — Implemente a regra acima com setpoint de 30,0 #sym.degree\C. Mostre no LCD a temperatura, o setpoint e o estado atual (aquecendo, resfriando, ocioso).
]

/ 1.3: Descreva o comportamento observado quando a temperatura se aproxima de 30 #sym.degree\C. #resposta(n: 2)

#tarefa[
  *1.4* — Conte quantas vezes o estado muda em um intervalo de 30 segundos, com a temperatura estabilizada perto do setpoint.

  Sugestão: incremente um contador a cada mudança de estado e mostre no LCD.

  Contagem obtida: #box(width: 4cm, stroke: (bottom: 0.4pt))
]

/ 1.5: Relacione esse número com o ruído de medição observado no Roteiro 4. Por que o ruído provoca chaveamento? #resposta(n: 3)

#observacao[
  Um relé mecânico tem vida útil da ordem de $10^5$ operações. Com a taxa de chaveamento que você acaba de medir, estime em quanto tempo esse limite seria atingido.

  Estimativa: #box(width: 5cm, stroke: (bottom: 0.4pt))
]

= Parte 2 — Histerese

A correção consiste em separar o limiar de *ligar* do limiar de *desligar*:

#figure(
  table(
    columns: (1.4fr, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Estado atual],
      text(fill: white, weight: "bold")[Transição],
    ),
    [Ocioso], [Aquece se $T < S - h/2$; resfria se $T > S + h/2$],
    [Aquecendo], [Volta a ocioso quando $T >= S$],
    [Resfriando], [Volta a ocioso quando $T <= S$],
  ),
  caption: [Regras de transição com histerese. $S$ é o setpoint e $h$ a banda morta.],
) <tab-histerese>

#tarefa[
  *2.1* — Implemente a histerese com $h = 2,0$ #sym.degree\C, usando uma variável de estado.
]

/ 2.2: Repita a contagem do item 1.4 com a histerese ativa. Quantas mudanças de estado em 30 segundos? #resposta()

/ 2.3: Por qual fator o chaveamento foi reduzido? #resposta()

#conceito[
  O controlador com histerese não é uma função da temperatura: é uma *máquina de estados*. Para a mesma temperatura de 30,0 #sym.degree\C, a saída pode ser "aquecendo" ou "ocioso", dependendo de onde o sistema esteve antes.

  Essa memória é justamente o que quebra o ciclo de chaveamento — e é o mesmo princípio do disjuntor com retardo e do termostato de geladeira.
]

= Parte 3 — Dimensionamento da banda

#previsao[
  *3.1* — O que acontece se a banda morta for muito *estreita* (por exemplo, 0,2 #sym.degree\C)? E se for muito *larga* (por exemplo, 10 #sym.degree\C)?

  Preveja antes de testar.

  #resposta(n: 3)
]

#tarefa[
  *3.2* — Teste as três bandas e registre.

  #table(
    columns: (auto, 1fr, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Banda],
      text(fill: white, weight: "bold")[Chaveamentos / 30 s],
      text(fill: white, weight: "bold")[Amplitude da oscilação],
      text(fill: white, weight: "bold")[Período da oscilação],
    ),
    [0,2 #sym.degree\C], [], [], [],
    [2,0 #sym.degree\C], [], [], [],
    [10,0 #sym.degree\C], [], [], [],
  )
]

/ 3.3: Existe uma banda "ótima"? De que depende a escolha? #resposta(n: 3)

= Parte 4 — Assimetria da planta

#tarefa[
  *4.1* — Com o sistema estabilizado, force uma perturbação e cronometre.

  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    [Tempo para subir de 30 a 35 #sym.degree\C (aquecedor)], [],
    [Tempo para descer de 35 a 30 #sym.degree\C (ventoinha)], [],
    [Tempo para descer de 35 a 30 #sym.degree\C (sem ventoinha)], [],
  )
]

/ 4.2: Aquecer e resfriar levam o mesmo tempo? Explique a diferença com base na descrição da planta. #resposta(n: 3)

/ 4.3: Após o aquecedor desligar, a temperatura para de subir imediatamente? O que isso indica sobre a posição do sensor? #resposta(n: 3)

= Teste de aceitação

#quadro Controle liga/desliga puro funcionando, com contagem de chaveamentos.

#quadro Histerese implementada, com redução mensurável de chaveamento.

#quadro LCD mostrando temperatura, setpoint e estado.

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
    [0,2], [Previsão 1.1 registrada antes da implementação],
    [0,2], [Contagens 1.4 e 2.2, com a relação estabelecida em 1.5],
    [0,2], [Tabela 3.2 completa e resposta 3.3],
    [0,2], [Respostas 4.2 e 4.3 sobre a assimetria],
  ),
  caption: [Distribuição do ponto do Roteiro 5.],
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
    [Nada aquece], [CH3-3 em OFF, ou RC1 não configurado como saída],
    [Ventoinha sempre ligada], [Estado inicial não definido no reset],
    [Histerese sem efeito], [Comparação feita sem variável de estado],
    [Temperatura sobe sem parar], [Lógica invertida: aquecedor no ramo errado],
    [Sistema oscila mesmo com banda larga], [Ventoinha e aquecedor ligados juntos],
  ),
  caption: [Diagnóstico rápido do Roteiro 5.],
)

= Para a próxima sessão

#tarefa[
  Hoje o atuador só tem dois estados: ligado e desligado.

  Traga escrito: como você faria para o aquecedor funcionar com *meia potência*? O microcontrolador só consegue colocar o pino em 0 V ou 5 V — não existe valor intermediário.
]
