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
      align(right)[Roteiro 1],
    )
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira · Rodolfo Quadros — DENE/UFMT],
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
#block(
  width: 100%,
  fill: azul,
  inset: (x: 16pt, y: 20pt),
  radius: 4pt,
)[
  \
  #text(fill: white, size: 18pt, weight: "bold")[Microcontroladores]
  \
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 1 — Bits e máscaras]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · Rodolfo Quadros · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa(
  "Objetivos desta sessão",
  rgb("#555555"),
  cinza,
  [
    Ao final desta sessão o grupo deve ser capaz de:

    1. Operar bits individuais de um registrador sem alterar os vizinhos;
    2. Usar os operadores `&`, `|`, `^`, `~`, `<<` e `>>` com propósito definido;
    3. Explicar o que é uma máscara de bits e por que ela existe;
    4. Justificar por que os LEDs do kit acendem com nível lógico baixo.
  ],
)

#v(0.6em)

= Por que isso é conteúdo, e não revisão

Disciplinas de Algoritmos trabalham com *valores*: somar, comparar, atribuir. Aqui o programa conversa com *registradores*, onde cada bit comanda um pino físico diferente.

Escrever `TRISC = 0x00` configura os oito pinos de uma vez — inclusive os sete que você não queria tocar. Em um sistema com atuador ligado a um deles, isso é um acidente, não um detalhe de estilo.

#conceito[
  `TRISC &= ~0b00000110` é a forma correta de mexer em dois pinos preservando os outros seis.

  Entender essa linha *é* programação de microcontrolador — não é pré-requisito dela. Máscara de bits é o vocabulário nativo da disciplina.
]

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [Chaves SWITCHS (PORTB)], [Todas em OFF],
    [CH2-1 (LCD)], [OFF],
    [CH3-3 e CH3-5], [OFF],
    [Demais chaves], [OFF],
  )

  Nesta sessão os únicos periféricos usados são os 8 LEDs do PORTD.
]

= Fundamento: o LED que acende com zero

Os 8 LEDs do kit são *ativos em nível baixo*: o pino em 0 acende o LED, o pino em 1 apaga. O anodo está ligado ao $+5$ V e o catodo ao pino do PIC, que funciona como caminho para o terra.

#importante[
  Consequência prática: para *acender* o LED 0 você escreve *0* no bit 0. Para acender todos, `LATD = 0x00`.

  Isso é comum em hardware real e é a origem de metade dos enganos de quem começa. Anote no caderno agora.
]

= Parte 1 — Escrita direta

#tarefa[
  Compile e grave um programa que faça apenas:

  ```c
  LATD  = 0b11110000;
  TRISD = 0x00;
  ```
]

/ 1.1: Quais LEDs acendem? Desenhe os oito círculos e marque os acesos. #resposta(n: 2)

/ 1.2: O resultado bate com sua expectativa? Se não, o que você esperava e por quê? #resposta(n: 2)

= Parte 2 — As quatro operações fundamentais

#previsao[
  Para cada operação desta seção, escreva o resultado esperado *antes* de gravar. Depois verifique.

  Considere sempre o estado inicial `LATD = 0xFF` — todos os LEDs apagados.
]

== Ligar um bit: OU com máscara

```c
LATD |= 0b00000001;
```

Previsão: #box(width: 4cm, stroke: (bottom: 0.4pt)) #h(1em) Observado: #box(width: 4cm, stroke: (bottom: 0.4pt))

== Desligar um bit: E com máscara invertida

```c
LATD &= ~0b00000001;
```

Previsão: #box(width: 4cm, stroke: (bottom: 0.4pt)) #h(1em) Observado: #box(width: 4cm, stroke: (bottom: 0.4pt))

== Inverter um bit: OU-exclusivo

```c
LATD ^= 0b00000001;
```

Aplique duas vezes seguidas.

/ 2.3: O que acontece após a segunda aplicação? Por quê? #resposta()

== Testar um bit

```c
if ((PORTD & 0b00000001) == 0) {
    /* o bit 0 está em nível baixo */
}
```

/ 2.4: Por que a comparação é com `0` e não com `1`? #resposta(n: 2)

= Parte 3 — Construção de máscara por deslocamento

Escrever `0b00001000` funciona, mas não é reaproveitável. A forma usual é *construir* a máscara a partir do número do bit:

```c
#define BIT(n)   (1u << (n))
```

#tarefa[
  *3.1* — Complete a tabela.

  #table(
    columns: (1.2fr, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Expressão],
      text(fill: white, weight: "bold")[Binário],
      text(fill: white, weight: "bold")[Hexadecimal],
    ),
    [`BIT(0)`], [], [],
    [`BIT(3)`], [], [],
    [`BIT(7)`], [], [],
    [`BIT(2) | BIT(5)`], [], [],
    [`~BIT(0)`], [], [],
  )
]

#tarefa[
  *3.2* — Escreva as três macros usando `BIT(n)`. Lembre que os LEDs são ativos em nível baixo: *acender* significa escrever zero.

  ```c
  #define LED_ACENDER(n)   /* completar */
  #define LED_APAGAR(n)    /* completar */
  #define LED_INVERTER(n)  /* completar */
  ```
]

#tarefa[
  *3.3* — Grave um programa que acenda *apenas* os LEDs 1, 3 e 6, usando suas macros.

  Não é permitido escrever o byte inteiro de uma vez.
]

= Parte 4 — Por que a máscara importa

Considere o kit XM118, onde:

- RC1 aciona a *resistência de aquecimento*;
- RC2 aciona a *ventoinha*;
- RC6 e RC7 são a *comunicação serial*.

#previsao[
  *4.1* — Um colega precisa ligar a ventoinha e escreve:

  ```c
  LATC = 0b00000100;
  ```

  O que acontece com a comunicação serial? E com a resistência de aquecimento?

  #resposta(n: 2)
]

/ 4.2: Reescreva a linha de forma segura. #resposta()

/ 4.3: Em uma frase — qual a diferença entre `=` e `|=` quando o registrador comanda dispositivos independentes? #resposta(n: 2)

#conceito[
  Um registrador de porta não é uma variável comum: ele é um *painel de comandos compartilhado*. Escrever nele por atribuição direta equivale a redefinir o estado de todos os dispositivos ligados àquela porta, e não apenas do que interessa.
]

= Teste de aceitação

#quadro LEDs 1, 3 e 6 acesos, usando macros construídas com `BIT(n)`.

#quadro Um membro do grupo, sorteado pelo professor, explica por que `LATD &= ~BIT(2)` *apaga* o LED 2 em vez de acender.

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
    [0,2], [Tabela 3.1 completa e correta],
    [0,2], [Macros 3.2 corretas para a lógica invertida],
    [0,4], [Respostas da Parte 4, com justificativa],
  ),
  caption: [Distribuição do ponto do Roteiro 1.],
)

#observacao[
  Nas previsões da Parte 2, avalia-se o *registro da previsão*, não o acerto.

  Previsão errada com raciocínio explícito vale integral. Previsão preenchida depois de observar o resultado não vale nada — e é facilmente identificável.
]

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
    [LEDs invertidos do esperado], [Esqueceu que são ativos em nível baixo],
    [`LATD &= BIT(2)` apaga tudo], [Faltou o `~`: a máscara precisa ser invertida],
    [Nada acende], [`TRISD` não foi zerado; pinos ainda são entrada],
    [Um LED some ao mexer em outro], [Usou `=` no lugar de `|=` ou `&=`],
  ),
  caption: [Diagnóstico rápido do Roteiro 1.],
)

= Para a próxima sessão

#tarefa[
  Escreva, sem compilar, um trecho que faça o LED 0 piscar.

  Você ainda não viu laços em C nesta disciplina — use o que lembra de Algoritmos e não se preocupe com a sintaxe exata.
]
