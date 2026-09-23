// estilo.typ — preâmbulo comum das aulas de Microcontroladores
// DENE/UFMT — Raoni F. S. Teixeira
//
// Uso:  #import "estilo.typ": *
//       #show: conf.with(titulo: "Aula 1 — ...", subtitulo: "...")
//       #show: conf.with(..., modo: "roteiro")   // bancada, com cor
//
// modo: "teoria"  (padrão) — sem cor, rótulos na margem, coluna de texto estreita
// modo: "roteiro"           — comportamento anterior, caixas com cor

#let gab = sys.inputs.at("gab", default: "0") != "0"

#let navy     = rgb("#003366")
#let vermelho = rgb("#9B1C1C")
#let ambar    = rgb("#8A5A00")
#let verde    = rgb("#1F5E3D")
#let teal     = rgb("#0F5F6B")
#let roxo     = rgb("#4B3A80")
#let cinza    = rgb("#4A4A4A")
#let tinta    = rgb("#111111")

// ---------------------------------------------------------------- geometria
// Largura da coluna de notas e deslocamento, usados pelo modo teoria.
#let _mg_larg = 4.2cm
#let _mg_dx   = 4.9cm

// Estado do modo, para as caixas saberem como se desenhar.
#let _modo = state("modo", "teoria")

// ------------------------------------------------------------------ caixas
// Caixa colorida — modo roteiro (comportamento original)
#let _caixa_cor(titulo, cor, corpo) = block(
  width: 100%,
  breakable: true,
  fill: cor.lighten(92%),
  stroke: (left: 3pt + cor),
  inset: (x: 10pt, y: 8pt),
  radius: 1pt,
  above: 10pt,
  below: 10pt,
  {
    text(size: 8pt, weight: "bold", fill: cor, tracking: 0.7pt)[#upper(titulo)]
    v(-5pt)
    corpo
  },
)

// Passagem recuada com rótulo na margem — modo teoria
#let _caixa_margem(titulo, corpo, tamanho: 10.5pt, selo: none, cor: cinza) = block(
  width: 100%,
  breakable: true,
  above: 10pt,
  below: 10pt,
  {
    place(
      right,
      dx: _mg_dx,
      dy: 0.25em,
      box(
        width: _mg_larg,
        align(left, {
          text(size: 7.4pt, fill: cinza, tracking: 0.8pt, weight: "medium")[#upper(titulo)]
          // Selo de pontuação: visível também na versão do aluno, porque é ele
          // quem precisa saber onde vale a pena gastar o tempo da sessão. Fica
          // na mesma linha do rótulo — a linha de baixo da margem é invadida
          // pelos blocos de código e de tabela, que avançam _mg_dx à direita.
          if selo != none {
            text(size: 7.4pt, fill: cinza)[ #sym.dot.c ]
            text(size: 8.2pt, fill: cor, weight: "bold", selo)
          }
        }),
      ),
    )
    pad(left: 1.3em, right: 1.3em, text(size: tamanho, corpo))
  },
)

// Bloco emoldurado sem preenchimento — para o que o aluno preenche à mão
#let _caixa_moldura(titulo, corpo) = block(
  width: 100%,
  breakable: true,
  stroke: 0.5pt + cinza,
  inset: (x: 11pt, y: 9pt),
  above: 11pt,
  below: 11pt,
  {
    text(size: 7.6pt, fill: cinza, tracking: 0.9pt, weight: "medium")[#upper(titulo)]
    v(-4pt)
    corpo
  },
)

// Seletor: usa a forma do modo corrente.
#let _sel(titulo, cor, corpo, tamanho: 10.5pt, moldura: false, selo: none) = context {
  if moldura {
    _caixa_moldura(titulo, corpo)
  } else {
    _caixa_margem(titulo, corpo, tamanho: tamanho, selo: selo, cor: cor)
  }
}

// --------------------------------------------------------- notas de margem
// Grafite de margem: uma ou duas linhas, sem rótulo. Só no modo teoria;
// no roteiro degrada para nota de rodapé para não sumir.
#let margem(corpo) = place(
  right, dx: _mg_dx, dy: 0.2em,
  box(width: _mg_larg, align(left, text(size: 8.2pt, fill: cinza, style: "italic", corpo))),
)

// ---------------------------------------------------------------- rótulos
#let objetivos(c)   = context {
  {
    block(width: 100%, above: 4pt, below: 14pt, {
      line(length: 100%, stroke: 0.6pt + tinta)
      v(3pt)
      text(size: 7.6pt, fill: cinza, tracking: 0.9pt, weight: "medium")[OBJETIVOS]
      v(-3pt)
      text(size: 9.8pt, c)
      v(3pt)
      line(length: 100%, stroke: 0.6pt + tinta)
    })
  }
}

#let conceito(c)    = _sel("Conceito", navy, c)
// `nota` é a pontuação da tarefa, escrita na margem logo abaixo do rótulo:
//   #tarefa(nota: "1,5 pontos")[...]
#let tarefa(c, nota: none) = _sel("Tarefa", navy, c, selo: nota)
// Pergunta da folha de previsões reproduzida no roteiro, com a sua nota:
//   #prevista(nota: "0,4 pt")[*P1.* ...]
#let prevista(c, nota: none) = _sel("Previsão", roxo, c, selo: nota)
#let atencao(c)     = _sel("Atenção", ambar, c, tamanho: 9.6pt)
#let nota(c)        = _sel("Nota", cinza, c, tamanho: 9.6pt)
#let divergencia(c) = _sel("Divergência", roxo, c, tamanho: 9.6pt)
#let semnota(c)     = _sel("Sem nota", verde, c, tamanho: 9.6pt)
#let bancada(c)     = _sel("Bancada", teal, c, tamanho: 9.6pt)
#let experimento(c) = _sel("Experimento", teal, c)
#let previsao(c)    = _sel("Previsão", roxo, c, moldura: true)

// Afirmação contingente: verdadeira nesta placa, não necessariamente em outra.
// Marcar com `kit` mantém visível a fronteira entre conteúdo e contingência —
// que é o que o seminário dos encontros 14 e 15 vai exigir do aluno.
#let kit(c)         = _sel("Neste kit", teal, c, tamanho: 9.6pt)

// Conteúdo que enriquece mas não sustenta nada depois. Pode ser pulado sem
// quebrar a continuidade do curso — útil quando o encontro vira folga.
#let opcional(c)    = _sel("Opcional", verde, c, tamanho: 9.6pt)

// `perigo` é o único elemento colorido do sistema, e existe só no roteiro:
// garra de terra em 12 V, atuador energizado, relé chaveando carga. Em modo
// teoria ele degrada para `atencao`, sem cor.
#let perigo(c) = context {
  if _modo.get() == "roteiro" {
    block(
      width: 100%, breakable: true,
      fill: vermelho.lighten(94%),
      stroke: (left: 3pt + vermelho),
      inset: (x: 10pt, y: 8pt), above: 12pt, below: 12pt,
      {
        text(size: 8pt, weight: "bold", fill: vermelho, tracking: 0.9pt)[PERIGO]
        v(-4pt)
        c
      },
    )
  } else {
    _caixa_margem("Atenção", c, tamanho: 9.6pt)
  }
}

#let resposta(c) = if gab {
  context {
    {
      block(
        width: 100%, breakable: true,
        stroke: (left: 0.8pt + cinza),
        inset: (left: 10pt, top: 4pt, bottom: 4pt),
        above: 9pt, below: 11pt,
        {
          text(size: 7.4pt, fill: cinza, tracking: 0.8pt, weight: "medium")[RESPOSTA]
          v(-4pt)
          text(size: 9.8pt, c)
        },
      )
    }
  }
}

#let criterio(c) = if gab {
  context {
    {
      block(
        width: 100%, breakable: true,
        stroke: (left: 0.8pt + cinza),
        inset: (left: 10pt, top: 4pt, bottom: 4pt),
        above: 9pt, below: 11pt,
        {
          text(size: 7.4pt, fill: cinza, tracking: 0.8pt, weight: "medium")[CRITÉRIO]
          v(-4pt)
          text(size: 9.8pt, c)
        },
      )
    }
  }
}

#let docente(c) = if gab {
  block(inset: (left: 10pt), above: 7pt, below: 7pt,
    text(size: 8.6pt, style: "italic", fill: cinza, c))
}

// ------------------------------------------------------------------ lacuna
#let lacuna(largura: 3cm) = box(width: largura, baseline: 0pt,
  line(length: 100%, stroke: 0.5pt + cinza))

// ------------------------------------------------------------------ tabela
#let tab(..args) = context {
  let c = tinta
  let t = table(
    stroke: (x, y) => (
      top: if y == 0 { 0.8pt + c } else if y == 1 { 0.5pt + c } else { 0.3pt + rgb("#BBBBBB") },
      bottom: 0pt, left: 0pt, right: 0pt,
    ),
    inset: (x: 6pt, y: 5pt),
    align: left + top,
    ..args,
  )
  // No modo teoria a coluna de texto é estreita; a tabela avança sobre a
  // coluna de notas em vez de espremer as células.
  block(width: 100% + _mg_dx, t)
}

// -------------------------------------------------------------------- conf
#let conf(titulo: "", subtitulo: "", modo: "teoria", doc) = {
  let roteiro = modo == "roteiro"
  let c = tinta

  _modo.update(modo)

  set page(
    paper: "a4",
    margin: (left: 2.4cm, right: 5.6cm, top: 2.3cm, bottom: 2.1cm),
    header: context {
      set text(size: 8.5pt, fill: cinza)
      grid(columns: (1fr, 1fr), align(left)[#if roteiro [Laboratório] else [Microcontroladores]], align(right)[#titulo])
      v(-7pt)
      line(length: 100%, stroke: 0.5pt + c)
    },
    footer: context {
      line(length: 100%, stroke: 0.5pt + c)
      v(-4pt)
      set text(size: 8.5pt, fill: cinza)
      grid(
        columns: (1fr, 1fr),
        align(left)[Raoni F. S. Teixeira],
        align(right)[#counter(page).display()],
      )
    },
  )

  set text(font: "Libertinus Serif", lang: "pt", size: 10.5pt, fill: tinta)
  set par(justify: true, leading: 0.68em)
  set heading(numbering: "1.1")
  show heading: set text(fill: c)
  show heading.where(level: 1): it => block(above: 18pt, below: 8pt,
    text(size: 12.5pt, weight: "bold", it))
  show heading.where(level: 2): it => block(above: 13pt, below: 6pt,
    text(size: 10.8pt, weight: "regular", style: "italic", it))

  show raw: set text(font: "DejaVu Sans Mono", size: 8.4pt)
  show raw.where(block: true): it => block(
    width: 100% + _mg_dx,
    fill: rgb("#F2F2F2"),
    stroke: none,
    inset: (x: 10pt, y: 8pt),
    radius: 1pt,
    above: 9pt, below: 9pt,
    it,
  )

  show figure: set block(breakable: true)
  show figure.caption: set text(size: 8.6pt, fill: cinza)
  set figure(numbering: "1")

  show table.cell.where(y: 0): set text(weight: "bold", size: 9.3pt)


  block[
    #text(size: 16pt, weight: "bold", fill: c)[#titulo]
    #v(-6pt)
    #text(size: 11.5pt, style: "italic")[#subtitulo]
    #v(-4pt)
    #text(size: 9.5pt, fill: cinza)[
      Microcontroladores — DENE/UFMT #h(1fr) #if gab [*versão do professor*]
    ]
  ]

  doc
}
