// PREÂMBULO DE PRÉVIA — substituto temporário.
// Serve apenas para renderizar o corpo em PDF.
// No R0 real, descarte este arquivo e use o preâmbulo canônico.

#let primaria = rgb("#1f4e79")
#let secundaria = rgb("#c55a11")

#set page(
  paper: "a4",
  margin: (top: 2.4cm, bottom: 2.2cm, x: 2.2cm),
  header: [
    #set text(size: 8.5pt, fill: primaria)
    #grid(columns: (1fr, 1fr),
      align(left)[*Microcontroladores* — Laboratório],
      align(right)[Roteiro 0 — Bancada])
    #line(length: 100%, stroke: 1pt + secundaria)
  ],
  footer: [
    #line(length: 100%, stroke: 0.5pt + primaria)
    #set text(size: 8.5pt, fill: primaria)
    #grid(columns: (1fr, 1fr),
      align(left)[DENE / UFMT],
      align(right)[#context counter(page).display("1")])
  ],
)

#set text(font: "Libertinus Serif", size: 10.5pt, lang: "pt")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#show heading: it => block(above: 1.2em, below: 0.7em)[
  #set text(fill: primaria)
  #it
]
#show raw.where(block: true): it => block(
  width: 100%, inset: 8pt, radius: 2pt, fill: luma(246),
  stroke: (left: 2.5pt + secundaria),
)[#set text(size: 9pt, font: "DejaVu Sans Mono"); #it]

#let caixa(titulo, cor, corpo) = block(
  width: 100%, inset: 9pt, above: 0.9em, below: 0.9em, radius: 2pt,
  fill: cor.lighten(90%), stroke: (left: 3pt + cor),
)[
  #text(weight: "bold", fill: cor.darken(15%), size: 9.5pt)[#upper(titulo)]
  #v(-0.4em)
  #corpo
]

#let objetivos(c)   = caixa("Objetivos", primaria, c)
#let conceito(c)    = caixa("Conceito", rgb("#5b2c87"), c)
#let atencao(c)     = caixa("Atenção", secundaria, c)
#let perigo(c)      = caixa("Perigo", rgb("#a61b1b"), c)
#let nota(c)        = caixa("Nota", rgb("#4a4a4a"), c)
#let tarefa(c)      = caixa("Tarefa", rgb("#1e7a46"), c)
#let experimento(c) = caixa("Experimento", rgb("#0d6a6a"), c)
#let bancada(c)     = caixa("Na bancada", rgb("#7a5c00"), c)
#let divergencia(c) = caixa("Divergência de documentação", rgb("#a61b1b"), c)
#let semnota(c)     = caixa("Sem nota", rgb("#4a4a4a"), c)

#set table(
  stroke: 0.5pt + luma(190),
  inset: 7pt,
  fill: (col, row) => if row == 0 { primaria } else if calc.odd(row) { luma(244) } else { white },
)
#show table.cell.where(y: 0): set text(fill: white, weight: "bold")
#set figure(gap: 0.8em)
