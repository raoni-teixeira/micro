// figuras.typ — figuras desenhadas em Typst puro (sem pacotes externos)
// Microcontroladores — DENE/UFMT — Raoni F. S. Teixeira
//
// Todas em preto e branco, para casar com o modo teoria do estilo.

#let _cinza = rgb("#4A4A4A")
#let _claro = rgb("#9A9A9A")

// ===========================================================================
// 1. CAMPOS DE UMA INSTRUÇÃO
// ---------------------------------------------------------------------------
// grupos: array de (rotulo, bits)  — bits é uma string, um caractere por bit.
//   fig_campos(
//     (("código da operação", "0110111"), ("a", "a"), ("endereço de arquivo", "ffffffff")),
//   )
// ===========================================================================

#let _celula(ch, w, h, ultima) = box(
  width: w, height: h,
  stroke: (right: if ultima { none } else { 0.3pt + _claro }),
  align(center + horizon, text(font: "DejaVu Sans Mono", size: 8pt)[#ch]),
)

#let _chave(largura, rotulo, fonte: 7.6pt) = box(width: largura, {
  align(center, text(size: fonte, fill: _cinza)[#rotulo])
  v(-6.5pt)
  align(center, box(
    width: largura - 2pt, height: 3.5pt,
    stroke: (bottom: 0.5pt + _cinza, left: 0.5pt + _cinza, right: 0.5pt + _cinza, top: none),
  ))
  v(-1.5pt)
})

#let fig_campos(grupos, w: 0.52cm, h: 0.55cm, fonte_rotulo: 7.6pt) = {
  let larguras = grupos.map(g => w * g.at(1).clusters().len())
  block(breakable: false, above: 6pt, below: 6pt, {
    // rótulos com chave
    stack(dir: ltr, ..grupos.zip(larguras).map(((g, lg)) => _chave(lg, g.at(0), fonte: fonte_rotulo)))
    // caixas de bits
    stack(
      dir: ltr,
      ..grupos.zip(larguras).map(((g, lg)) => {
        let cs = g.at(1).clusters()
        box(width: lg, stroke: 0.8pt, stack(
          dir: ltr,
          ..cs.enumerate().map(((i, ch)) => _celula(ch, w, h, i == cs.len() - 1)),
        ))
      }),
    )
  })
}

// ===========================================================================
// 2. O RELÓGIO E A DISCRETIZAÇÃO DO TEMPO
// ---------------------------------------------------------------------------
// instrucoes: array de conteúdo, uma por ciclo de instrução.
// ===========================================================================

#let fig_relogio(instrucoes, p: 0.62cm, rotulo_esq: 2.5cm) = {
  let n = instrucoes.len()
  let np = n * 4                    // períodos do oscilador
  let alt = 0.42cm                  // amplitude da onda
  let larg = np * p
  let total = rotulo_esq + larg

  // --- onda quadrada do oscilador
  let pts = ()
  for i in range(np) {
    pts.push((i * p, 0pt))
    pts.push((i * p, alt))
    pts.push((i * p + p / 2, alt))
    pts.push((i * p + p / 2, 0pt))
  }
  pts.push((np * p, 0pt))

  block(breakable: false, above: 10pt, below: 12pt, width: total, {
    set text(size: 7.6pt)

    // ---------------------------------------------------------------- linha 1
    stack(
      dir: ltr,
      box(width: rotulo_esq, height: alt,
        align(right + horizon)[#h(0pt)$F_"osc"$#h(6pt)]),
      box(width: larg, height: alt, {
        place(curve(
          stroke: 0.7pt,
          curve.move(pts.first()),
          ..pts.slice(1).map(pt => curve.line(pt)),
        ))
      }),
    )

    v(2pt)

    // ---------------------------------------------------------------- linha 2
    // fases Q1..Q4 e fronteiras de ciclo
    stack(
      dir: ltr,
      box(width: rotulo_esq, height: 0.34cm, align(right + horizon)[fases#h(6pt)]),
      box(width: larg, height: 0.34cm, {
        for i in range(np) {
          place(dx: i * p, box(width: p, height: 0.34cm,
            stroke: (left: 0.3pt + _claro, right: if i == np - 1 { 0.3pt + _claro }),
            align(center + horizon, text(size: 6.6pt, fill: _cinza)[Q#(calc.rem(i, 4) + 1)])))
        }
      }),
    )

    v(2pt)

    // ---------------------------------------------------------------- linha 3
    // ciclos de instrução: o que executa em cada um
    stack(
      dir: ltr,
      box(width: rotulo_esq, height: 0.52cm,
        align(right + horizon)[executa#h(6pt)]),
      box(width: larg, height: 0.52cm, {
        for (i, ins) in instrucoes.enumerate() {
          place(dx: i * 4 * p, box(width: 4 * p, height: 0.52cm, stroke: 0.6pt,
            align(center + horizon, text(size: 8pt, ins))))
        }
      }),
    )

    // ---------------------------------------------------------------- linha 4
    // eixo do tempo discreto: t, t+1, ...
    stack(
      dir: ltr,
      box(width: rotulo_esq, height: 0.42cm, align(right + horizon)[tempo#h(6pt)]),
      box(width: larg, height: 0.45cm, {
        place(dy: 0.04cm, line(length: larg, stroke: 0.4pt + _claro))
        for i in range(n + 1) {
          place(dx: i * 4 * p, dy: 0.04cm,
            line(start: (0pt, -0.07cm), end: (0pt, 0pt), stroke: 0.5pt + _cinza))
          place(dx: i * 4 * p - 0.5cm, dy: 0.09cm, box(width: 1cm,
            align(center + top, text(size: 7.4pt, fill: _cinza,
              if i == 0 [$t$] else [$t + #i$]))))
        }
      }),
    )

    v(6pt)

    // ---------------------------------------------------------------- cotas
    stack(
      dir: ltr,
      box(width: rotulo_esq, height: 0.5cm),
      box(width: larg, height: 0.5cm, {
        // τ_osc sobre o primeiro período
        place(dx: 0pt, dy: 0.06cm, line(length: p, stroke: 0.4pt + _cinza))
        place(dx: 0pt, dy: 0.02cm, line(start: (0pt, 0pt), end: (0pt, 0.08cm), stroke: 0.4pt + _cinza))
        place(dx: p, dy: 0.02cm, line(start: (0pt, 0pt), end: (0pt, 0.08cm), stroke: 0.4pt + _cinza))
        place(dx: p + 4pt, dy: -0.03cm, text(size: 7.4pt, fill: _cinza)[$tau_"osc"$])
        // τ_cy sobre o primeiro ciclo, deslocado
        place(dx: 0pt, dy: 0.22cm, line(length: 4 * p, stroke: 0.4pt + _cinza))
        place(dx: 0pt, dy: 0.18cm, line(start: (0pt, 0pt), end: (0pt, 0.08cm), stroke: 0.4pt + _cinza))
        place(dx: 4 * p, dy: 0.18cm, line(start: (0pt, 0pt), end: (0pt, 0.08cm), stroke: 0.4pt + _cinza))
        place(dx: 4 * p + 4pt, dy: 0.13cm,
          text(size: 7.4pt, fill: _cinza)[$tau_"cy" = 4 tau_"osc" = 250$ ns])
      }),
    )
  })
}

// ===========================================================================
// 3. PIPELINE DE BUSCA E EXECUÇÃO
// ---------------------------------------------------------------------------
// col: array de (busca, executa, descartada)
//   busca / executa: conteúdo ou none
//   descartada: bool — desenha a busca riscada (jogada fora)
// ===========================================================================

#let _cx(c, riscado: false, largura: 2.6cm) = if c == none {
  box(width: largura, height: 0.5cm)
} else {
  box(
    width: largura, height: 0.5cm,
    stroke: if riscado { 0.5pt + _claro } else { 0.6pt },
    {
      align(center + horizon, text(
        size: 7.4pt, fill: if riscado { _claro } else { black },
        font: "DejaVu Sans Mono", c,
      ))
      if riscado {
        place(dx: 0pt, dy: -0.5cm, curve(
          stroke: 0.6pt + _cinza,
          curve.move((0pt, 0pt)), curve.line((largura, 0.5cm)),
        ))
        place(dx: 0pt, dy: -0.5cm, curve(
          stroke: 0.6pt + _cinza,
          curve.move((0pt, 0.5cm)), curve.line((largura, 0pt)),
        ))
      }
    },
  )
}

#let fig_pipeline(colunas, rotulo_esq: 2.3cm, largura: 2.6cm) = {
  let n = colunas.len()
  block(breakable: false, above: 10pt, below: 12pt, {
    set text(size: 7.6pt)
    grid(
      columns: (rotulo_esq,) + (largura,) * n,
      row-gutter: 3pt,
      column-gutter: 3pt,

      // cabeçalho
      box(height: 0.4cm)[],
      ..colunas.enumerate().map(((i, _)) => align(center,
        box(height: 0.4cm, align(center + horizon, text(fill: _cinza)[Ciclo #(i + 1)])))),

      // busca
      align(right + horizon, box(height: 0.5cm, align(right + horizon)[busca (IR1)#h(4pt)])),
      ..colunas.map(c => _cx(c.at(0), riscado: c.at(2), largura: largura)),

      // seta
      box(height: 0.3cm)[],
      ..colunas.map(c => align(center, box(height: 0.3cm, align(center + horizon,
        text(size: 9pt, fill: if c.at(1) == none { rgb("#FFFFFF") } else { _cinza })[#sym.arrow.b])))),

      // executa
      align(right + horizon, box(height: 0.5cm, align(right + horizon)[executa (IR2)#h(4pt)])),
      ..colunas.map(c => _cx(c.at(1), largura: largura)),
    )
    v(1pt)
    align(right, box(width: 100%, {
      place(left, dx: rotulo_esq, line(length: n * (largura + 3pt) - 3pt, stroke: 0.4pt + _claro))
      v(3pt)
      place(left, dx: rotulo_esq + n * (largura + 3pt) - 3pt - 1.2cm,
        text(size: 7pt, fill: _cinza)[tempo #sym.arrow.r])
      v(9pt)
    }))
  })
}


// ===========================================================================
// 4. LEGENDA
// ===========================================================================
#let fig(corpo, legenda) = figure(
  supplement: [Figura],
  kind: "figura",
  caption: legenda,
  corpo,
)

// ===========================================================================
// 5. UTILITÁRIOS DE DESENHO
// ===========================================================================

#let _seta(p1, p2, cor: _cinza, esp: 0.5pt) = {
  let ang = calc.atan2((p2.at(0) - p1.at(0)) / 1pt, (p2.at(1) - p1.at(1)) / 1pt)
  place(curve(stroke: esp + cor, curve.move(p1), curve.line(p2)))
  place(dx: p2.at(0), dy: p2.at(1), box(width: 0pt, height: 0pt,
    place(rotate(ang, origin: left + horizon, curve(fill: cor, stroke: none,
      curve.move((-5pt, -1.8pt)), curve.line((0pt, 0pt)),
      curve.line((-5pt, 1.8pt)), curve.close())))))
}

#let _rot(x, y, w, h, corpo, preenche: none, traco: 0.6pt, fonte: 7.2pt) = place(
  dx: x, dy: y,
  box(width: w, height: h, stroke: traco, fill: preenche,
    align(center + horizon, text(size: fonte, corpo))),
)

#let _txt(x, y, corpo, w: 2cm, al: left, fonte: 6.8pt, mono: false) = place(
  dx: x, dy: y,
  box(width: w, align(al, if mono {
    text(size: fonte, fill: _cinza, font: "DejaVu Sans Mono", corpo)
  } else {
    text(size: fonte, fill: _cinza, corpo)
  })),
)

// ===========================================================================
// 6. MAPA DA MEMÓRIA DE DADOS
// ===========================================================================

#let fig_mapa_dados() = block(breakable: false, width: 17cm, height: 7.6cm, {
  let o  = 0.45cm   // folga para o cabeçalho da coluna de BSR
  let xb = 0cm
  let xn = 1.75cm
  let xm = 3.4cm
  let wm = 3.3cm
  let xa = 6.85cm
  let xk = 9.9cm
  let wk = 3.5cm
  let tracejado = (thickness: 0.4pt, dash: "dashed", paint: _claro)

  _txt(xb, 0.05cm, [BSR⟨3:0⟩], w: 1.6cm, al: right, fonte: 7pt)
  _txt(xm, 0.05cm, [*Memória de dados*], w: wm, al: center, fonte: 7.6pt)

  // --- coluna de memória
  _rot(xm, o + 0cm, wm, 0.4cm, [Access RAM],
    traco: (top: 0.6pt, left: 0.6pt, right: 0.6pt, bottom: tracejado))
  _rot(xm, o + 0.4cm, wm, 0.6cm, [GPR], traco: (left: 0.6pt, right: 0.6pt, bottom: 0.6pt))
  _rot(xm, o + 1.0cm, wm, 0.6cm, [GPR])
  _rot(xm, o + 1.6cm, wm, 0.6cm, [GPR])
  _rot(xm, o + 2.2cm, wm, 0.6cm, [GPR])
  _rot(xm, o + 2.8cm, wm, 1.2cm, [GPR — também buffer da USB], preenche: rgb("#EFEFEF"))
  _rot(xm, o + 4.0cm, wm, 1.6cm,
    [Não implementado \ #text(font: "DejaVu Sans Mono", size: 7pt)[lê 0x00]])
  _rot(xm, o + 5.6cm, wm, 0.45cm, [Não usado],
    traco: (top: 0.6pt, left: 0.6pt, right: 0.6pt, bottom: tracejado))
  _rot(xm, o + 6.05cm, wm, 0.45cm, [SFR], traco: (left: 0.6pt, right: 0.6pt, bottom: 0.6pt))

  // --- BSR e nomes de banco
  let bancos = (
    (0cm, 1.0cm, "0000", [Banco 0]),
    (1.0cm, 0.6cm, "0001", [Banco 1]),
    (1.6cm, 0.6cm, "0010", [Banco 2]),
    (2.2cm, 0.6cm, "0011", [Banco 3]),
    (2.8cm, 1.2cm, "0100–0111", [Bancos 4 a 7]),
    (4.0cm, 1.6cm, "1000–1110", [Bancos 8 a 14]),
    (5.6cm, 0.9cm, "1111", [Banco 15]),
  )
  for (y, h, bsr, nome) in bancos {
    _txt(xb, o + y + h / 2 - 0.16cm, bsr, w: 1.6cm, al: right, fonte: 6.8pt, mono: true)
    _txt(xn, o + y + h / 2 - 0.16cm, nome, w: 1.5cm, al: center, fonte: 7pt)
    place(dx: xn + 1.55cm, dy: o + y + h / 2,
      line(length: xm - xn - 1.55cm, stroke: 0.35pt + _claro))
  }

  // --- endereços (pares nas fronteiras estreitas)
  for (y, e) in ((0.0, "000h"), (0.29, "05Fh / 060h"), (0.86, "0FFh"),
                 (3.88, "7FFh / 800h"), (5.48, "EFFh / F00h"),
                 (5.93, "F5Fh / F60h"), (6.36, "FFFh")) {
    _txt(xa, o + y * 1cm, e, w: 1.6cm, fonte: 6.4pt, mono: true)
  }

  // --- access bank
  _txt(xk, o + 1.42cm, [*Access Bank*], w: wk, al: center, fonte: 8pt)
  _rot(xk, o + 2.0cm, wk, 0.65cm, [Access RAM Low],
    traco: (top: 0.7pt, left: 0.7pt, right: 0.7pt, bottom: tracejado))
  _rot(xk, o + 2.65cm, wk, 0.65cm, [Access RAM High (SFR)],
    traco: (left: 0.7pt, right: 0.7pt, bottom: 0.7pt))
  for (y, e) in ((2.02, "00h"), (2.42, "5Fh"), (2.67, "60h"), (3.07, "FFh")) {
    _txt(xk + wk + 0.08cm, o + y * 1cm, e, w: 1cm, fonte: 6.4pt, mono: true)
  }

  // --- setas
  _seta((8.6cm, o + 0.18cm), (xk - 0.05cm, o + 2.3cm))
  _seta((8.6cm, o + 6.42cm), (xk - 0.05cm, o + 3.05cm))

  // --- nota lateral
  _txt(13.9cm, o + 4.1cm,
    [Com #text(font: "DejaVu Sans Mono", size: 6.6pt)[a = 0] o BSR é ignorado: valem os
     96 bytes do banco 0 e os 160 SFRs do banco 15.

     Com #text(font: "DejaVu Sans Mono", size: 6.6pt)[a = 1] o BSR escolhe o banco e o
     campo #text(font: "DejaVu Sans Mono", size: 6.6pt)[f] escolhe a posição dentro dele.],
    w: 3.0cm, fonte: 7pt)
})

// ===========================================================================
// 7. OS DOIS ESPAÇOS DE ENDEREÇAMENTO
// ===========================================================================

#let fig_espacos() = block(breakable: false, width: 15cm, height: 6.0cm, {
  let mono(c) = text(font: "DejaVu Sans Mono", size: 6.8pt, c)

  // ---- programa
  _txt(0.4cm, 0cm, [*Memória de programa* (Flash)], w: 5.6cm, al: center, fonte: 8pt)
  _txt(0.4cm, 0.36cm, [endereçada por byte, palavra de 16 bits], w: 5.6cm, al: center, fonte: 6.6pt)
  let prog = (("0000h", "BCF  0x8C,0,0", "908C"), ("0002h", "BCF  0x95,0,0", "9095"),
              ("0004h", "BTG  0x8C,0,0", "708C"), ("0006h", "BRA  0x0004", "D7FE"))
  for (i, (end, ins, hx)) in prog.enumerate() {
    let y = 0.8cm + i * 0.5cm
    _rot(0.4cm, y, 5.6cm, 0.5cm, [], traco: 0.5pt)
    _txt(0.55cm, y + 0.13cm, end, w: 1.1cm, fonte: 6.8pt, mono: true)
    _txt(1.7cm, y + 0.13cm, ins, w: 3cm, fonte: 6.8pt, mono: true)
    _txt(4.7cm, y + 0.13cm, hx, w: 1.2cm, al: right, fonte: 6.8pt, mono: true)
  }

  // ---- dados
  _txt(9.0cm, 0cm, [*Memória de dados* (RAM + SFR)], w: 5.6cm, al: center, fonte: 8pt)
  _txt(9.0cm, 0.36cm, [endereçada por byte, dado de 8 bits], w: 5.6cm, al: center, fonte: 6.6pt)
  let dados = (("F8Bh", "LATC", "· · ·"), ("F8Ch", "LATD", "0000 0001"),
               ("F8Dh", "LATE", "· · ·"), ("F95h", "TRISD", "1111 1110"))
  for (i, (end, nome, val)) in dados.enumerate() {
    let y = 0.8cm + i * 0.5cm
    _rot(9.0cm, y, 5.6cm, 0.5cm, [], traco: 0.5pt)
    _txt(9.15cm, y + 0.13cm, end, w: 1.1cm, fonte: 6.8pt, mono: true)
    _txt(10.3cm, y + 0.13cm, nome, w: 2cm, fonte: 6.8pt, mono: true)
    _txt(12.4cm, y + 0.13cm, val, w: 2.1cm, al: right, fonte: 6.8pt, mono: true)
  }

  // ---- CPU
  _rot(5.9cm, 4.7cm, 3.2cm, 0.85cm, [*CPU*], traco: 0.8pt, fonte: 9pt)

  // ---- barramentos: um por espaço, duas pontas
  _seta((3.4cm, 2.95cm), (6.4cm, 4.65cm))
  _seta((6.4cm, 4.65cm), (3.4cm, 2.95cm))
  _txt(1.2cm, 3.45cm, [endereço de 21 bits \ instrução de 16 bits],
    w: 3.0cm, al: right, fonte: 6.6pt)

  _seta((11.6cm, 2.95cm), (8.6cm, 4.65cm))
  _seta((8.6cm, 4.65cm), (11.6cm, 2.95cm))
  _txt(11.9cm, 3.45cm, [endereço de 12 bits \ dado de 8 bits],
    w: 3.0cm, fonte: 6.6pt)
})

// ===========================================================================
// 8. O ENCAPSULAMENTO E AS PORTAS
// ===========================================================================

#let fig_pinos() = block(breakable: false, width: 13cm, height: 7.0cm, {
  let esq = ("MCLR/RE3", "RA0", "RA1", "RA2", "RA3", "RA4", "RA5", "RE0", "RE1", "RE2",
             "VDD", "VSS", "OSC1", "OSC2/RA6", "RC0", "RC1", "RC2", "VUSB", "RD0", "RD1")
  let dir = ("RB7", "RB6", "RB5", "RB4", "RB3", "RB2", "RB1", "RB0",
             "VDD", "VSS", "RD7", "RD6", "RD5", "RD4", "RC7", "RC6", "RC5", "RC4", "RD3", "RD2")
  let x0 = 3.6cm
  let wc = 3.0cm
  let y0 = 0.55cm
  let passo = 0.30cm

  _rot(x0, y0, wc, 20 * passo, [], traco: 0.8pt)
  _txt(x0, y0 + 2.4cm, [PIC18F4550 \ PDIP-40], w: wc, al: center, fonte: 8pt)
  // entalhe
  place(dx: x0 + wc / 2 - 0.25cm, dy: y0 + 0.005cm,
    box(width: 0.5cm, height: 0.22cm, fill: white,
      stroke: (left: 0.8pt, right: 0.8pt, bottom: 0.8pt, top: none)))

  for (i, nome) in esq.enumerate() {
    let y = y0 + i * passo
    place(dx: x0 - 0.35cm, dy: y + passo / 2, line(length: 0.35cm, stroke: 0.5pt))
    _txt(x0 - 2.7cm, y + 0.03cm, nome, w: 2.3cm, al: right, fonte: 6.2pt, mono: true)
    _txt(x0 + 0.05cm, y + 0.04cm, str(i + 1), w: 0.5cm, fonte: 5.6pt)
  }
  for (i, nome) in dir.enumerate() {
    let y = y0 + i * passo
    place(dx: x0 + wc, dy: y + passo / 2, line(length: 0.35cm, stroke: 0.5pt))
    _txt(x0 + wc + 0.45cm, y + 0.03cm, nome, w: 2.3cm, fonte: 6.2pt, mono: true)
    _txt(x0 + wc - 0.55cm, y + 0.04cm, str(40 - i), w: 0.5cm, al: right, fonte: 5.6pt)
  }

  // legenda das portas
  _txt(9.6cm, 0.9cm,
    [*As cinco portas* \
     PORTA — 7 pinos (RA0–RA6) \
     PORTB — 8 pinos (RB0–RB7) \
     PORTC — 7 pinos (RC0–RC7, sem RC3) \
     PORTD — 8 pinos (RD0–RD7) \
     PORTE — 4 pinos (RE0–RE3) \
     \
     34 pinos de E/S em 40. O resto é \
     alimentação, cristal e USB.],
    w: 3.4cm, fonte: 7pt)
})


// ===========================================================================
// 9. O ARQUIVO HEX
// ===========================================================================

#let fig_hex(w: 0.5cm) = {
  let grupos = (
    ("", ":"),
    ("bytes", "08"),
    ("endereço", "0000"),
    ("tipo", "00"),
    ("dados", "8C9095908C70FED7"),
    ("soma", "E6"),
  )
  let nd = 9  // caracteres antes do campo de dados
  block(breakable: false, width: 27 * w, {
    fig_campos(grupos, w: w, h: 0.5cm, fonte_rotulo: 6.8pt)
    place(dx: nd * w, dy: 2pt, box(width: 4 * w, height: 4pt,
      stroke: (top: none, left: 0.5pt + _cinza, right: 0.5pt + _cinza,
               bottom: 0.5pt + _cinza)))
    place(dx: nd * w - 1.5cm, dy: 8pt, box(width: 4 * w + 3cm,
      align(center, text(size: 7pt, fill: _cinza,
        font: "DejaVu Sans Mono")[8C 90 #sym.arrow.r 0x908C])))
    v(20pt)
  })
}

// ===========================================================================
// 10. A ELETRÔNICA DE UM PINO
// ===========================================================================

#let _diodo(x, y, rot: 0deg) = place(dx: x, dy: y, rotate(rot, origin: center + horizon,
  box(width: 0.34cm, height: 0.34cm, {
    place(curve(fill: black, stroke: none,
      curve.move((0.05cm, 0.28cm)), curve.line((0.29cm, 0.28cm)),
      curve.line((0.17cm, 0.06cm)), curve.close()))
    place(dy: 0.04cm, line(start: (0.03cm, 0pt), end: (0.31cm, 0pt), stroke: 0.6pt))
  })))

#let fig_pino() = block(breakable: false, width: 14cm, height: 5.6cm, {
  let xp = 1.9cm      // nó do pino
  let yp = 2.55cm

  // trilhos de alimentação
  _txt(1.35cm, 0.02cm, "VDD", w: 1.2cm, al: center, fonte: 7pt, mono: true)
  _txt(1.35cm, 4.95cm, "VSS", w: 1.2cm, al: center, fonte: 7pt, mono: true)
  place(dx: 1.55cm, dy: 0.32cm, line(length: 0.8cm, stroke: 0.7pt))
  place(dx: 1.55cm, dy: 4.9cm, line(length: 0.8cm, stroke: 0.7pt))

  // diodos de proteção
  place(dx: xp, dy: 0.32cm, line(start: (0pt, 0pt), end: (0pt, 0.55cm), stroke: 0.6pt))
  _diodo(xp - 0.17cm, 0.87cm)
  place(dx: xp, dy: 1.21cm, line(start: (0pt, 0pt), end: (0pt, yp - 1.21cm), stroke: 0.6pt))
  _diodo(xp - 0.17cm, 3.75cm)
  place(dx: xp, dy: yp, line(start: (0pt, 0pt), end: (0pt, 3.75cm - yp), stroke: 0.6pt))
  place(dx: xp, dy: 4.09cm, line(start: (0pt, 0pt), end: (0pt, 0.81cm), stroke: 0.6pt))
  _txt(2.15cm, 0.85cm, [proteção], w: 1.6cm, fonte: 6.4pt)
  _txt(2.15cm, 3.75cm, [proteção], w: 1.6cm, fonte: 6.4pt)

  // o pino
  place(dx: 0.35cm, dy: yp, line(length: xp - 0.35cm, stroke: 0.8pt))
  place(dx: 0.2cm, dy: yp - 0.09cm, box(width: 0.18cm, height: 0.18cm, radius: 50%, stroke: 0.7pt))
  _txt(0cm, yp - 0.55cm, [pino], w: 1.4cm, al: center, fonte: 7pt)

  // ramo 1 — buffer digital
  place(dx: xp, dy: 1.45cm, line(length: 1.1cm, stroke: 0.6pt))
  place(dx: xp, dy: 1.45cm, line(start: (0pt, 0pt), end: (0pt, yp - 1.45cm), stroke: 0.6pt))
  _rot(3.0cm, 1.15cm, 3.4cm, 0.6cm, [buffer Schmitt], fonte: 7pt)
  _seta((6.4cm, 1.45cm), (7.6cm, 1.45cm))
  _rot(7.7cm, 1.15cm, 2.6cm, 0.6cm, [`PORTx`], fonte: 7pt)

  // ramo 2 — canal analógico
  place(dx: xp, dy: yp, line(length: 1.1cm, stroke: 0.6pt))
  _rot(3.0cm, yp - 0.3cm, 3.4cm, 0.6cm, [chave analógica], fonte: 7pt)
  _seta((6.4cm, yp), (7.6cm, yp))
  _rot(7.7cm, yp - 0.3cm, 2.6cm, 0.6cm, [$C_"HOLD"$ 25 pF], fonte: 7pt)
  _seta((10.3cm, yp), (11.4cm, yp))
  _rot(11.5cm, yp - 0.3cm, 2.2cm, 0.6cm, [ADC, 10 bits], fonte: 7pt)

  // ramo 3 — driver de saída
  place(dx: xp, dy: 3.6cm, line(length: 1.1cm, stroke: 0.6pt))
  place(dx: xp, dy: yp, line(start: (0pt, 0pt), end: (0pt, 3.6cm - yp), stroke: 0.6pt))
  _rot(3.0cm, 3.3cm, 3.4cm, 0.6cm, [driver de saída], fonte: 7pt)
  _seta((7.6cm, 3.6cm), (6.5cm, 3.6cm))
  _rot(7.7cm, 3.3cm, 2.6cm, 0.6cm, [`LATx`], fonte: 7pt)
  _txt(3.0cm, 4.0cm, [habilitado por `TRISx`], w: 3.4cm, al: center, fonte: 6.4pt)
})

// ===========================================================================
// 11. APROXIMAÇÕES SUCESSIVAS
// ===========================================================================

#let fig_sar(vin: 0.250, npassos: 10) = block(breakable: false, width: 13cm, height: 4.6cm, {
  let x0 = 1.5cm
  let dx = 1.0cm
  let y0 = 0.3cm      // topo = 5 V
  let alt = 3.4cm     // 5 V de altura
  let ey(v) = y0 + alt * (1 - v / 5.0)

  // eixos
  place(dx: x0, dy: y0, line(start: (0pt, 0pt), end: (0pt, alt), stroke: 0.5pt + _cinza))
  place(dx: x0, dy: y0 + alt, line(length: npassos * dx + 0.3cm, stroke: 0.5pt + _cinza))
  for (v, r) in ((5.0, "5 V"), (2.5, "2,5 V"), (0.0, "0 V")) {
    _txt(0cm, ey(v) - 0.13cm, r, w: 1.4cm, al: right, fonte: 6.6pt)
    place(dx: x0 - 0.06cm, dy: ey(v), line(length: 0.12cm, stroke: 0.5pt + _cinza))
  }

  // tensão de entrada
  place(dx: x0, dy: ey(vin), line(length: npassos * dx, stroke: (thickness: 0.6pt,
    dash: "dashed", paint: black)))
  _txt(x0 + npassos * dx + 0.15cm, ey(vin) - 0.16cm,
    [$V_"in"$ = 250 mV \ (25 °C)], w: 2.6cm, fonte: 6.6pt)

  // busca binária
  let lo = 0.0
  let hi = 5.0
  let pts = ()
  let bits = ()
  for i in range(npassos) {
    let m = (lo + hi) / 2
    pts.push((x0 + i * dx, ey(m)))
    pts.push((x0 + (i + 1) * dx, ey(m)))
    if vin >= m { bits.push("1"); lo = m } else { bits.push("0"); hi = m }
  }
  place(curve(stroke: 0.9pt, curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p))))

  // bits resultantes
  for (i, b) in bits.enumerate() {
    _txt(x0 + i * dx, y0 + alt + 0.08cm, b, w: dx, al: center, fonte: 7.4pt, mono: true)
    _txt(x0 + i * dx, y0 + alt + 0.36cm, str(i + 1), w: dx, al: center, fonte: 6pt)
  }
  _txt(x0, y0 + alt + 0.66cm,
    [uma decisão por $T_"AD"$ — o resultado é #text(font: "DejaVu Sans Mono", size: 6.8pt)[0000110011] = 51],
    w: npassos * dx, al: center, fonte: 6.8pt)
})

#let _m(c, t: 6.8pt) = text(font: "DejaVu Sans Mono", size: t, c)

// ===========================================================================
// 12. FORMAS DE ONDA (para contratos de temporização)
// ===========================================================================

// niveis: array de (t, nivel) — pontos de mudança; nivel 0 ou 1.
#let _onda(x0, y0, h, u, niveis, fim) = {
  let pts = ()
  let ant = niveis.first().at(1)
  pts.push((x0 + niveis.first().at(0) * u, y0 + h * (1 - ant)))
  for (t, n) in niveis.slice(1) {
    pts.push((x0 + t * u, y0 + h * (1 - ant)))
    pts.push((x0 + t * u, y0 + h * (1 - n)))
    ant = n
  }
  pts.push((x0 + fim * u, y0 + h * (1 - ant)))
  place(curve(stroke: 0.8pt, curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p))))
}

// segmentos: array de (t_ini, t_fim, rótulo ou none)
#let _barramento(x0, y0, h, u, segmentos, fim) = {
  place(dy: y0, line(start: (x0, 0pt), end: (x0 + fim * u, 0pt), stroke: 0.4pt + _claro))
  place(dy: y0 + h, line(start: (x0, 0pt), end: (x0 + fim * u, 0pt), stroke: 0.4pt + _claro))
  for (a, b, r) in segmentos {
    if r == none {
      place(dx: x0 + a * u, dy: y0, box(width: (b - a) * u, height: h,
        fill: rgb("#E4E4E4"), stroke: 0.4pt + _claro))
    } else {
      place(dx: x0 + a * u, dy: y0, box(width: (b - a) * u, height: h,
        stroke: 0.8pt, align(center + horizon, text(size: 7pt, r))))
    }
  }
}

// cota horizontal com rótulo
#let _cota(x0, y0, u, a, b, rotulo, acima: true, w: 1.5cm) = {
  place(dy: y0, line(start: (x0 + a * u, 0pt), end: (x0 + b * u, 0pt), stroke: 0.4pt + _cinza))
  for t in (a, b) {
    place(dx: x0 + t * u, dy: y0 - 0.09cm,
      line(start: (0pt, 0pt), end: (0pt, 0.18cm), stroke: 0.4pt + _cinza))
  }
  _txt(x0 + (a + b) / 2 * u - w / 2, y0 + (if acima { -0.32cm } else { 0.08cm }),
    rotulo, w: w, al: center, fonte: 6.4pt)
}

#let fig_escrita_lcd() = block(breakable: false, width: 15cm, height: 6.7cm, {
  let xl = 2.0cm
  let u = 0.88cm
  let fim = 12
  let h = 0.42cm

  _txt(0cm, 0.55cm, _m("RS", t: 7.4pt), w: 1.8cm, al: right)
  _txt(0cm, 1.65cm, _m("D7-D4", t: 7.4pt), w: 1.8cm, al: right)
  _txt(0cm, 2.75cm, _m("E", t: 7.4pt), w: 1.8cm, al: right)

  _onda(xl, 0.5cm, h, u, ((0, 0), (1, 1)), fim)
  _barramento(xl, 1.6cm, h, u, (
    (0, 1.5, none), (1.5, 5, [nibble alto]), (5, 6.5, none),
    (6.5, 10, [nibble baixo]), (10, fim, none),
  ), fim)
  _onda(xl, 2.7cm, h, u, ((0, 0), (2, 1), (4, 0), (7, 1), (9, 0)), fim)

  // cotas
  _cota(xl, 3.42cm, u, 1, 2, [$t_"AS" >= 40$ ns])
  _cota(xl, 3.98cm, u, 2, 4, [$"PW"_"EH" >= 230$ ns], w: 2.1cm)
  _cota(xl, 4.54cm, u, 1.5, 4, [$t_"DSW" >= 80$ ns])
  _cota(xl, 4.54cm, u, 4, 5.6, [$t_H >= 10$ ns])
  _cota(xl, 5.10cm, u, 2, 7, [$t_"cicE" >= 500$ ns], w: 2.1cm)

  _txt(xl, 5.55cm,
    [Um byte, dois pulsos de habilitação. Cada #_m("__delay_us(1)") a 16 MHz vale
     1000 ns — folga confortável sobre todos os mínimos acima.],
    w: fim * u, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 13. DDRAM DE UM DISPLAY 16x2
// ===========================================================================

#let fig_ddram() = block(breakable: false, width: 15cm, height: 3.5cm, {
  let x0 = 2.3cm
  let w = 0.62cm
  let h = 0.5cm
  let d = "0123456789ABCDEF"
  let hx(v) = d.at(int(v / 16)) + d.at(calc.rem(v, 16))

  _txt(x0, 0.05cm, [visível na tela], w: 16 * w, al: center, fonte: 7pt)
  for (linha, base, y) in ((0, 0, 0.45cm), (1, 64, 1.5cm)) {
    _txt(0cm, y + 0.14cm, [linha #(linha + 1)], w: 2.1cm, al: right, fonte: 7pt)
    for c in range(16) {
      place(dx: x0 + c * w, dy: y, box(width: w, height: h, stroke: 0.5pt,
        align(center + horizon, _m(hx(base + c), t: 6.4pt))))
    }
    place(dx: x0 + 16 * w + 0.1cm, dy: y, box(width: 2.4cm, height: h,
      stroke: (thickness: 0.5pt, dash: "dashed", paint: _claro),
      align(center + horizon, text(size: 6.4pt, fill: _cinza,
        [até #_m(if linha == 0 { "27" } else { "67" }, t: 6.4pt)]))))
  }
  _txt(x0 + 16 * w + 0.1cm, 2.12cm, [fora da tela — \ existe, e rola],
    w: 2.4cm, al: center, fonte: 6.4pt)

  _txt(0cm, 2.75cm,
    [A segunda linha não começa em #_m("10"): começa em #_m("40"). O endereço é da
     memória do controlador, não da posição na tela.],
    w: 15cm, al: center, fonte: 7pt)
})

// ===========================================================================
// 14. A INICIALIZAÇÃO COMO RESSINCRONIZAÇÃO
// ===========================================================================

#let fig_init() = block(breakable: false, width: 15cm, height: 5.2cm, {
  let cx = (0.5cm, 4.1cm, 7.7cm, 11.3cm)
  let w = 3.1cm
  let ys = (0.55cm, 1.75cm, 2.95cm)
  let m = 0.42cm     // meia altura da caixa
  let oito = [8 bits]
  let ea = [4 bits, esperando \ o nibble alto]
  let eb = [4 bits, esperando \ o nibble baixo]

  let cab = ([estado desconhecido], [após o 1.º], [após o 2.º], [após o 3.º])
  for (k, r) in cab.enumerate() { _txt(cx.at(k), 0.02cm, r, w: w, al: center, fonte: 7pt) }

  // colunas
  _rot(cx.at(0), ys.at(0), w, 0.85cm, oito, fonte: 6.8pt)
  _rot(cx.at(0), ys.at(1), w, 0.85cm, ea, fonte: 6.8pt)
  _rot(cx.at(0), ys.at(2), w, 0.85cm, eb, fonte: 6.8pt)

  _rot(cx.at(1), ys.at(0), w, 0.85cm, oito, fonte: 6.8pt)
  _rot(cx.at(1), ys.at(1), w, 0.85cm, ea, fonte: 6.8pt)
  _rot(cx.at(1), ys.at(2), w, 0.85cm, eb, fonte: 6.8pt)

  _rot(cx.at(2), ys.at(0), w, 0.85cm, oito, fonte: 6.8pt)
  _rot(cx.at(2), ys.at(2), w, 0.85cm, eb, fonte: 6.8pt)

  _rot(cx.at(3), ys.at(0), w, 0.85cm, oito, traco: 1.2pt, fonte: 6.8pt)

  let liga(a, i, b, j) = _seta((cx.at(a) + w, ys.at(i) + m), (cx.at(b) - 0.05cm, ys.at(j) + m))

  // 1.º 0x30:  8b->8b ; EA->EB ; EB->EA
  liga(0, 0, 1, 0)
  liga(0, 1, 1, 2)
  liga(0, 2, 1, 1)
  // 2.º:       8b->8b ; EA->EB ; EB->8b
  liga(1, 0, 2, 0)
  liga(1, 1, 2, 2)
  liga(1, 2, 2, 0)
  // 3.º:       8b->8b ; EB->8b
  liga(2, 0, 3, 0)
  liga(2, 2, 3, 0)

  _txt(0cm, 4.15cm,
    [Cada seta é um pulso de #_m("0x3", t: 7pt) em D7–D4. O estado que espera o
     nibble baixo completa o byte #_m("0x33", t: 7pt) — que é justamente
     \"interface de 8 bits\". Três repetições porque três é o número de estados
     possíveis, e o programa não sabe em qual deles começou.],
    w: 15cm, al: center, fonte: 7pt)
})

// ===========================================================================
// 15. PWM E RAZÃO CÍCLICA
// ===========================================================================

#let fig_pwm(razao: 0.30, nper: 3) = block(breakable: false, width: 14cm, height: 3.9cm, {
  let xl = 1.9cm
  let u = 3.0cm          // um período
  let h = 1.1cm
  let y0 = 0.35cm
  let larg = nper * u

  _txt(0cm, y0 + 0.35cm, [saída], w: 1.7cm, al: right, fonte: 7.4pt)

  let niveis = ()
  for i in range(nper) {
    niveis.push((i, 1))
    niveis.push((i + razao, 0))
  }
  _onda(xl, y0, h, u, niveis, nper)

  // média
  place(dy: y0 + h * (1 - razao), line(start: (xl, 0pt), end: (xl + larg, 0pt),
    stroke: (thickness: 0.7pt, dash: "dashed", paint: _cinza)))
  _txt(xl + larg + 0.15cm, y0 + h * (1 - razao) - 0.16cm,
    [média = #calc.round(razao * 100) % de VDD], w: 3.4cm, fonte: 6.8pt)

  _cota(xl, y0 + h + 0.42cm, u, 0, razao, [$t_"on"$], w: 1.2cm)
  _cota(xl, y0 + h + 0.95cm, u, 0, 1, [$T$ — fixo], w: 1.6cm)

  _txt(xl, y0 + h + 1.35cm,
    [A razão cíclica é $t_"on" slash T$. O período não muda; o que muda é onde a
     borda de descida cai dentro dele.],
    w: larg, al: center, fonte: 6.8pt)
})

// PWM por dentro: TMR2 sobe até PR2 e recomeça; o comparador derruba a saída
// quando a contagem alcança a razão cíclica.
#let fig_pwm_ccp(razao: 0.35, nper: 3) = block(breakable: false, width: 14cm, height: 5.0cm, {
  let xl = 2.4cm
  let u = 3.0cm
  let y0 = 0.3cm
  let alt = 2.0cm
  let y1 = y0 + alt + 0.55cm
  let h = 0.75cm
  let larg = nper * u

  // topo (PR2) e nível da razão cíclica
  place(dy: y0, line(start: (xl, 0pt), end: (xl + larg, 0pt),
    stroke: (thickness: 0.4pt, dash: "dashed", paint: _claro)))
  place(dy: y0 + alt * (1 - razao), line(start: (xl, 0pt), end: (xl + larg, 0pt),
    stroke: (thickness: 0.6pt, dash: "dashed", paint: _cinza)))
  place(dy: y0 + alt, line(start: (xl, 0pt), end: (xl + larg, 0pt), stroke: 0.4pt + _claro))
  _txt(0cm, y0 - 0.12cm, _m("PR2", t: 6.6pt), w: 2.2cm, al: right)
  _txt(0cm, y0 + alt * (1 - razao) - 0.14cm, _m("CCPR1L:DC1B", t: 6.2pt), w: 2.2cm, al: right)
  _txt(0cm, y0 + alt - 0.12cm, _m("0", t: 6.6pt), w: 2.2cm, al: right)
  _txt(0cm, y0 + alt * 0.28, [TMR2], w: 2.2cm, al: right, fonte: 7pt)

  // rampas do Timer2
  let pts = ()
  for i in range(nper) {
    pts.push((xl + i * u, y0 + alt))
    pts.push((xl + (i + 1) * u, y0))
    if i < nper - 1 { pts.push((xl + (i + 1) * u, y0 + alt)) }
  }
  place(curve(stroke: 0.9pt, curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p))))

  // saída
  _txt(0cm, y1 + 0.25cm, [saída (RC2)], w: 2.2cm, al: right, fonte: 7pt)
  let niveis = ()
  for i in range(nper) {
    niveis.push((i, 1))
    niveis.push((i + razao, 0))
  }
  _onda(xl, y1, h, u, niveis, nper)

  // ligações: início do período e instante da comparação
  for i in range(nper) {
    let xc = xl + (i + razao) * u
    place(dx: xc, dy: y0 + alt * (1 - razao),
      line(start: (0pt, 0pt), end: (0pt, y1 - y0 - alt * (1 - razao)),
        stroke: (thickness: 0.4pt, dash: "dotted", paint: _cinza)))
  }

  _txt(xl, y1 + h + 0.25cm,
    [No recomeço, a saída sobe e a razão escrita é copiada para o comparador. Quando
     a contagem alcança essa cópia, a saída desce. `PR2` fixa o período; a razão
     fixa onde cai a descida.],
    w: larg, al: center, fonte: 6.8pt)
})

// PWM filtrado por RC: a média passa, a ondulação fica pequena.
#let fig_pwm_rc(razao: 0.5, nper: 4) = block(breakable: false, width: 14cm, height: 3.6cm, {
  let xl = 2.0cm
  let u = 2.4cm
  let y0 = 0.3cm
  let h = 1.6cm
  let a = 0.22cm          // ondulação, exagerada para ser visível
  let larg = nper * u
  let ym = y0 + h * (1 - razao)

  _txt(0cm, y0 - 0.1cm, [PWM], w: 1.8cm, al: right, fonte: 7pt)
  let niveis = ()
  for i in range(nper) {
    niveis.push((i, 1))
    niveis.push((i + razao, 0))
  }
  place(dx: 0pt, dy: 0pt, block({
    let pts = ()
    let ant = 1
    pts.push((xl, y0))
    for (t, n) in niveis.slice(1) {
      pts.push((xl + t * u, y0 + h * (1 - ant)))
      pts.push((xl + t * u, y0 + h * (1 - n)))
      ant = n
    }
    pts.push((xl + nper * u, y0 + h * (1 - ant)))
    place(curve(stroke: 0.5pt + _claro, curve.move(pts.first()),
      ..pts.slice(1).map(p => curve.line(p))))
  }))

  // saída do filtro: sobe durante t_on, desce durante t_off
  let pts = ()
  for i in range(nper) {
    pts.push((xl + i * u, ym + a / 2))
    pts.push((xl + (i + razao) * u, ym - a / 2))
  }
  pts.push((xl + nper * u, ym + a / 2))
  place(curve(stroke: 1.1pt, curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p))))
  _txt(xl + larg + 0.15cm, ym - 0.2cm, [saída do RC], w: 2.2cm, fonte: 6.8pt)
  _txt(xl + larg + 0.15cm, ym + 0.1cm, [$Delta V$ exagerado], w: 2.2cm, fonte: 6.2pt)

  _txt(xl, y0 + h + 0.35cm,
    [O capacitor carrega durante $t_"on"$ e descarrega durante $t_"off"$. Com
     $T << R C$, a saída fica perto da média, e o que sobra do chaveamento é a
     ondulação $Delta V$.],
    w: larg, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 16. O CONTADOR QUE ANDA SOZINHO
// ===========================================================================

#let fig_contador(nramp: 3) = block(breakable: false, width: 14cm, height: 4.4cm, {
  let xl = 2.4cm
  let u = 2.9cm
  let y0 = 0.3cm
  let alt = 2.5cm
  let carga = 0.39      // fração do fundo de escala onde está o pré-carregamento
  let larg = nramp * u

  // eixos
  place(dx: xl, dy: y0, line(start: (0pt, 0pt), end: (0pt, alt), stroke: 0.5pt + _cinza))
  place(dx: xl, dy: y0 + alt, line(length: larg + 0.3cm, stroke: 0.5pt + _cinza))
  _txt(0cm, y0 - 0.12cm, [65535], w: 2.2cm, al: right, fonte: 6.6pt, mono: true)
  _txt(0cm, y0 + alt * (1 - carga) - 0.12cm, [25536], w: 2.2cm, al: right, fonte: 6.6pt, mono: true)
  _txt(0cm, y0 + alt - 0.12cm, [0], w: 2.2cm, al: right, fonte: 6.6pt, mono: true)
  place(dy: y0 + alt * (1 - carga), line(start: (xl, 0pt), end: (xl + larg, 0pt),
    stroke: (thickness: 0.4pt, dash: "dashed", paint: _claro)))

  // rampas
  let pts = ()
  for i in range(nramp) {
    pts.push((xl + i * u, y0 + alt * (1 - carga)))
    pts.push((xl + (i + 1) * u, y0))
    if i < nramp - 1 { pts.push((xl + (i + 1) * u, y0 + alt * (1 - carga))) }
  }
  place(curve(stroke: 0.9pt, curve.move(pts.first()),
    ..pts.slice(1).map(p => curve.line(p))))

  // marcas de estouro
  for i in range(1, nramp + 1) {
    place(dx: xl + i * u, dy: y0 - 0.1cm,
      line(start: (0pt, 0pt), end: (0pt, 0.2cm), stroke: 0.5pt + _cinza))
    _txt(xl + i * u - 0.9cm, y0 - 0.42cm, _m("TMR0IF = 1", t: 6.2pt),
      w: 1.8cm, al: center)
  }

  _cota(xl, y0 + alt + 0.35cm, u, 0, 1, [10 ms], w: 1.4cm)

  _txt(xl, y0 + alt + 0.75cm,
    [O processador não participa da subida. Ele só precisa aparecer nos
     instantes marcados — para zerar o indicador e recarregar 25536.],
    w: larg, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 17. CICLO ÚTIL DE UM SENSOR ALIMENTADO A PILHA
// ===========================================================================

#let fig_ciclo_util(nper: 3) = block(breakable: false, width: 14cm, height: 3.8cm, {
  let xl = 2.2cm
  let u = 3.2cm
  let h = 1.5cm
  let y0 = 0.68cm
  let larg = nper * u
  let ativo = 0.035    // fração do período em que o processador está acordado

  _txt(0cm, y0 - 0.16cm, [10 mA], w: 2.0cm, al: right, fonte: 6.8pt)
  _txt(0cm, y0 + h - 0.16cm, [2 µA], w: 2.0cm, al: right, fonte: 6.8pt)
  _txt(0cm, y0 + h * 0.42, [corrente], w: 2.0cm, al: right, fonte: 7.4pt)

  let niveis = ()
  for i in range(nper) {
    niveis.push((i, 1))
    niveis.push((i + ativo, 0))
  }
  _onda(xl, y0, h, u, niveis, nper)

  for i in range(nper) {
    _txt(xl + i * u - 0.75cm, y0 - 0.62cm, [acordado \ 20 ms],
      w: 1.8cm, al: center, fonte: 6.2pt)
  }
  _txt(xl + 0.6 * u, y0 + h * 0.55, [dormindo — 60 s], w: 2.4cm, fonte: 6.6pt)

  _cota(xl, y0 + h + 0.4cm, u, 0, 1, [um ciclo], w: 1.5cm)
  _txt(xl, y0 + h + 0.8cm,
    [A escala vertical não é linear: são quatro ordens de grandeza entre os dois
     níveis. A média fica muito mais perto do vale do que do pico.],
    w: larg, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 18. O DESVIO ASSÍNCRONO
// ===========================================================================

#let fig_interrupcao() = block(breakable: false, width: 14cm, height: 4.4cm, {
  let xl = 2.3cm
  let u = 1.05cm
  let h = 0.5cm
  let ym = 1.05cm     // faixa do programa principal
  let yi = 2.35cm     // faixa da rotina de tratamento

  _txt(0cm, ym + 0.13cm, [programa principal], w: 2.1cm, al: right, fonte: 7pt)
  _txt(0cm, yi + 0.13cm, [tratamento], w: 2.1cm, al: right, fonte: 7pt)

  // principal: roda, para, volta
  _rot(xl, ym, 4 * u, h, [executando], fonte: 7pt)
  place(dx: xl + 4 * u, dy: ym, box(width: 3.6 * u, height: h,
    fill: rgb("#EFEFEF"), stroke: (thickness: 0.4pt, dash: "dashed", paint: _claro),
    align(center + horizon, text(size: 6.8pt, fill: _cinza)[parado])))
  _rot(xl + 7.6 * u, ym, 3.4 * u, h, [continua de onde parou], fonte: 7pt)

  // tratamento
  _rot(xl + 4.6 * u, yi, 3 * u, h, [inverte o pino], fonte: 7pt)

  // evento
  _seta((xl + 4 * u, 0.28cm), (xl + 4 * u, ym - 0.05cm), cor: black, esp: 0.7pt)
  _txt(xl + 4 * u - 1.5cm, 0.02cm, [o temporizador estoura],
    w: 3.0cm, al: center, fonte: 6.8pt)

  // descida e retorno
  _seta((xl + 4.05 * u, ym + h), (xl + 4.55 * u, yi))
  _txt(xl + 4.0 * u - 1.9cm, ym + h + 0.08cm, [empilha o PC],
    w: 2.0cm, al: right, fonte: 6.4pt)
  _seta((xl + 7.6 * u, yi), (xl + 7.6 * u + 0.05 * u, ym + h))
  _txt(xl + 7.7 * u, ym + h + 0.08cm, [#_m("RETFIE", t: 6.4pt) desempilha],
    w: 2.6cm, fonte: 6.4pt)

  place(dx: xl + 4 * u, dy: ym - 0.30cm,
    line(length: 0.6 * u, stroke: 0.4pt + _cinza))
  for t in (4, 4.6) {
    place(dx: xl + t * u, dy: ym - 0.38cm,
      line(start: (0pt, 0pt), end: (0pt, 0.16cm), stroke: 0.4pt + _cinza))
  }
  _txt(xl + 4.75 * u, ym - 0.46cm, [latência: 3 a 4 ciclos], w: 3.2cm, fonte: 6.4pt)

  _txt(xl, yi + h + 0.35cm,
    [O programa principal não é consultado, não coopera e não fica sabendo. Do
     ponto de vista dele, nenhuma instrução foi pulada — só levou mais tempo.],
    w: 11 * u, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 19. REPIQUE DE CONTATO E CONFIRMAÇÃO POR TEMPO
// ===========================================================================

#let fig_repique() = block(breakable: false, width: 14cm, height: 4.2cm, {
  let xl = 2.3cm
  let u = 0.52cm
  let h = 0.62cm
  let y0 = 0.75cm
  let n = 20
  let larg = n * u

  _txt(0cm, y0 + 0.18cm, [pino], w: 2.1cm, al: right, fonte: 7.4pt)
  _txt(0cm, y0 + 1.35cm, [amostras], w: 2.1cm, al: right, fonte: 7.4pt)

  // solto (1) -> repique -> preso (0)
  let niveis = ((0, 1), (4, 0), (4.6, 1), (5.1, 0), (5.9, 1), (6.3, 0),
                (7.2, 1), (7.5, 0))
  _onda(xl, y0, h, u, niveis, n)

  _txt(xl + 4.1 * u, y0 - 0.48cm, [repique — 1 a 20 ms], w: 3.4cm, fonte: 6.6pt)
  place(dx: xl + 4 * u, dy: y0 - 0.05cm,
    line(start: (0pt, 0pt), end: (0pt, h + 0.1cm),
      stroke: (thickness: 0.4pt, dash: "dashed", paint: _claro)))
  place(dx: xl + 7.5 * u, dy: y0 - 0.05cm,
    line(start: (0pt, 0pt), end: (0pt, h + 0.1cm),
      stroke: (thickness: 0.4pt, dash: "dashed", paint: _claro)))

  // amostragem periódica
  let leituras = ("1", "1", "0", "1", "0", "0", "0", "0", "0", "0")
  for (i, v) in leituras.enumerate() {
    let x = xl + (i * 2 + 0.5) * u
    place(dx: x, dy: y0 + h + 0.06cm,
      line(start: (0pt, 0pt), end: (0pt, 0.5cm), stroke: 0.4pt + _claro))
    _txt(x - 0.3cm, y0 + 1.22cm, _m(v, t: 6.6pt), w: 0.6cm, al: center)
  }

  // confirmação: três leituras iguais
  place(dx: xl + 10.5 * u, dy: y0 + 1.68cm, box(width: 4.2 * u, height: 0.34cm,
    stroke: (top: none, left: 0.5pt + _cinza, right: 0.5pt + _cinza,
             bottom: 0.5pt + _cinza)))
  _txt(xl + 9.4 * u, y0 + 2.05cm, [três iguais #sym.arrow.r confirmado],
    w: 6.4 * u, al: center, fonte: 6.8pt)

  _txt(xl, y0 + 2.45cm,
    [Amostrar a intervalo fixo e exigir confirmação não bloqueia nada: as
     leituras acontecem dentro do tratamento do temporizador.],
    w: larg, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 20. ESTÁGIO DE POTÊNCIA — MOSFET DE CANAL N EM LADO BAIXO
// ===========================================================================

#let fig_estagio() = block(breakable: false, width: 13cm, height: 6.2cm, {
  let xa = 4.6cm      // ramo da carga
  let xd = 6.9cm      // ramo do diodo
  let ytop = 0.75cm   // trilho de 12 V
  let ynode = 3.0cm   // nó do dreno
  let ygnd = 5.3cm    // trilho de terra
  let xm = 4.2cm      // porta do MOSFET
  let l = 0.7pt

  // trilhos
  place(dy: ytop, line(start: (2.6cm, 0pt), end: (8.0cm, 0pt), stroke: l))
  _txt(0.9cm, ytop - 0.16cm, [+12 V], w: 1.5cm, al: right, fonte: 7.4pt)
  place(dx: 2.6cm, dy: ytop, line(start: (0pt, -0.12cm), end: (0pt, 0.12cm), stroke: l))
  place(dy: ygnd, line(start: (1.4cm, 0pt), end: (8.0cm, 0pt), stroke: l))
  _txt(0.0cm, ygnd - 0.16cm, [GND], w: 1.3cm, al: right, fonte: 7.4pt)

  // carga
  place(dx: xa, dy: ytop, line(start: (0pt, 0pt), end: (0pt, 0.55cm), stroke: l))
  _rot(xa - 0.55cm, ytop + 0.55cm, 1.1cm, 0.85cm, [carga \ 12 V], fonte: 6.8pt)
  place(dx: xa, dy: ytop + 1.4cm, line(start: (0pt, 0pt), end: (0pt, ynode - ytop - 1.4cm), stroke: l))

  // diodo de retorno, em paralelo com a carga
  place(dy: ytop, line(start: (xa, 0pt), end: (xd, 0pt), stroke: l))
  place(dx: xd, dy: ytop, line(start: (0pt, 0pt), end: (0pt, 1.0cm), stroke: l))
  _diodo(xd - 0.17cm, ytop + 1.0cm)          // catodo para cima, para +12 V
  place(dx: xd, dy: ytop + 1.34cm, line(start: (0pt, 0pt), end: (0pt, ynode - ytop - 1.34cm), stroke: l))
  _txt(xd + 0.2cm, ytop + 1.0cm, [diodo de \ retorno], w: 2.2cm, fonte: 6.6pt)

  // nó do dreno
  place(dy: ynode, line(start: (xa, 0pt), end: (xd, 0pt), stroke: l))
  place(dx: xa - 0.05cm, dy: ynode - 0.05cm,
    box(width: 0.1cm, height: 0.1cm, radius: 50%, fill: black))

  // MOSFET
  place(dx: xa, dy: ynode, line(start: (0pt, 0pt), end: (0pt, 0.5cm), stroke: l))   // dreno
  place(dx: xm + 0.18cm, dy: ynode + 0.5cm,
    line(start: (0pt, 0pt), end: (xa - xm - 0.18cm, 0pt), stroke: l))
  place(dx: xm + 0.18cm, dy: ynode + 0.5cm,
    line(start: (0pt, 0pt), end: (0pt, 1.1cm), stroke: 1.1pt))                       // canal
  place(dx: xm, dy: ynode + 0.55cm, line(start: (0pt, 0pt), end: (0pt, 1.0cm), stroke: 1.1pt)) // porta
  place(dx: xm + 0.18cm, dy: ynode + 1.6cm,
    line(start: (0pt, 0pt), end: (xa - xm - 0.18cm, 0pt), stroke: l))
  place(dx: xa, dy: ynode + 1.6cm, line(start: (0pt, 0pt), end: (0pt, ygnd - ynode - 1.6cm), stroke: l))
  _txt(xa + 0.25cm, ynode + 0.85cm, [MOSFET \ canal N], w: 2.2cm, fonte: 6.8pt)
  _txt(xa + 0.12cm, ynode + 0.32cm, [D], w: 0.5cm, fonte: 6.4pt)
  _txt(xa + 0.12cm, ynode + 1.62cm, [S], w: 0.5cm, fonte: 6.4pt)
  _txt(xm - 0.72cm, ynode + 0.70cm, [G], w: 0.5cm, al: right, fonte: 6.4pt)

  // porta: sinal e resistor de descida
  place(dy: ynode + 1.05cm, line(start: (1.9cm, 0pt), end: (xm, 0pt), stroke: l))
  _txt(0.2cm, ynode + 0.89cm, [PWM], w: 1.6cm, al: right, fonte: 7.4pt)
  place(dx: 2.9cm, dy: ynode + 1.05cm,
    line(start: (0pt, 0pt), end: (0pt, 0.45cm), stroke: l))
  _rot(2.62cm, ynode + 1.5cm, 0.56cm, 0.75cm, [10k], fonte: 6.2pt)
  place(dx: 2.9cm, dy: ynode + 2.25cm,
    line(start: (0pt, 0pt), end: (0pt, ygnd - ynode - 2.25cm), stroke: l))
  place(dx: 2.85cm, dy: ynode + 1.0cm,
    box(width: 0.1cm, height: 0.1cm, radius: 50%, fill: black))

  _txt(0cm, 5.65cm,
    [A carga fica *entre a alimentação e o dreno*; a fonte vai ao terra, e é por
     isso que o sinal de 5 V no gate consegue comandar 12 V na carga.],
    w: 13cm, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 21. CICLO LIMITE DO CONTROLE LIGA-DESLIGA
// ===========================================================================

#let fig_ciclo_limite() = block(breakable: false, width: 14cm, height: 6.3cm, {
  let xl = 2.4cm
  let u = 0.78cm          // unidade de tempo
  let y0 = 0.45cm
  let alt = 3.0cm
  let fim = 14
  let ey(f) = y0 + alt * (1 - f)

  // faixas
  for (f, r, tr) in ((0.65, [liga-desliga: desliga], true),
                     (0.50, [alvo], false),
                     (0.35, [liga-desliga: liga], true)) {
    place(dy: ey(f), line(start: (xl, 0pt), end: (xl + fim * u, 0pt),
      stroke: if tr { (thickness: 0.5pt, dash: "dashed", paint: _cinza) }
              else { (thickness: 0.5pt, dash: "dotted", paint: _claro) }))
    _txt(xl + fim * u + 0.12cm, ey(f) - 0.16cm, r, w: 2.6cm, fonte: 6.4pt)
  }
  _txt(0cm, ey(0.5) - 0.16cm, [temperatura], w: 2.2cm, al: right, fonte: 7.4pt)

  // curva de temperatura
  let pts = ((0, 0.35), (2, 0.65), (2.6, 0.78), (5.6, 0.35), (6.4, 0.22),
             (8.4, 0.65), (9.0, 0.78), (12, 0.35), (12.8, 0.22), (14, 0.40))
  place(curve(stroke: 0.9pt,
    curve.move((xl + pts.first().at(0) * u, ey(pts.first().at(1)))),
    ..pts.slice(1).map(p => curve.line((xl + p.at(0) * u, ey(p.at(1)))))))

  // sobressinal
  place(dx: xl + 2.6 * u, dy: ey(0.78) - 0.05cm,
    box(width: 0.1cm, height: 0.1cm, radius: 50%, fill: black))
  _txt(xl + 2.75 * u, ey(0.78) - 0.36cm, [sobressinal], w: 2.0cm, fonte: 6.4pt)
  place(dx: xl + 6.4 * u, dy: ey(0.22) - 0.05cm,
    box(width: 0.1cm, height: 0.1cm, radius: 50%, fill: black))
  _txt(xl + 6.6 * u, ey(0.22) + 0.14cm, [e o oposto], w: 2.0cm, fonte: 6.4pt)

  // estado do aquecedor
  let ya = y0 + alt + 0.55cm
  _txt(0cm, ya + 0.14cm, [aquecedor], w: 2.2cm, al: right, fonte: 7.4pt)
  _onda(xl, ya, 0.45cm, u, ((0, 1), (2, 0), (5.6, 1), (8.4, 0), (12, 1)), fim)

  _cota(xl, ya + 1.0cm, u, 0, 8.4, [um ciclo], w: 1.6cm)

  _txt(xl, ya + 1.4cm,
    [O aquecedor comuta nos cruzamentos; a temperatura só vira depois, por causa
     da inércia térmica. A amplitude medida é sempre maior que a faixa de
     histerese.],
    w: fim * u, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 22. A RELAÇÃO ENTRADA-SAÍDA COM HISTERESE
// ===========================================================================

#let fig_histerese() = block(breakable: false, width: 9cm, height: 4.2cm, {
  let xl = 2.2cm
  let larg = 5.2cm
  let y0 = 0.5cm
  let h = 2.2cm
  let xi = xl + 1.4cm      // limiar inferior
  let xs = xl + 3.8cm      // limiar superior

  // eixos
  place(dx: xl, dy: y0, line(start: (0pt, 0pt), end: (0pt, h), stroke: 0.5pt + _cinza))
  place(dy: y0 + h, line(start: (xl, 0pt), end: (xl + larg, 0pt), stroke: 0.5pt + _cinza))
  _txt(0cm, y0 - 0.14cm, [liga], w: 2.0cm, al: right, fonte: 7pt)
  _txt(0cm, y0 + h - 0.14cm, [desliga], w: 2.0cm, al: right, fonte: 7pt)
  _txt(xl, y0 + h + 0.42cm, [temperatura medida], w: larg, al: center, fonte: 7pt)

  // laço
  place(curve(stroke: 0.9pt, curve.move((xl + 0.15cm, y0)),
    curve.line((xs, y0)), curve.line((xs, y0 + h)), curve.line((xl + larg - 0.15cm, y0 + h))))
  place(curve(stroke: 0.9pt, curve.move((xl + larg - 0.15cm, y0 + h)),
    curve.line((xi, y0 + h)), curve.line((xi, y0)), curve.line((xl + 0.15cm, y0))))

  // setas de sentido
  _seta((xl + 1.0cm, y0 + 0.22cm), (xl + 2.2cm, y0 + 0.22cm))
  _seta((xl + 4.4cm, y0 + h - 0.22cm), (xl + 3.2cm, y0 + h - 0.22cm))

  for (x, r) in ((xi, [alvo #sym.minus h]), (xs, [alvo #sym.plus h])) {
    place(dx: x, dy: y0 + h, line(start: (0pt, 0pt), end: (0pt, 0.1cm), stroke: 0.5pt + _cinza))
    _txt(x - 0.9cm, y0 + h + 0.12cm, r, w: 1.8cm, al: center, fonte: 6.4pt)
  }

  _txt(xl + larg + 0.3cm, y0 + 0.6cm,
    [Para a mesma temperatura há *duas* saídas possíveis. Qual delas vale depende
     de por onde se chegou — ou seja, o sistema tem memória.],
    w: 3.2cm, fonte: 6.8pt)
})

// ===========================================================================
// 23. QUADRO ASSÍNCRONO DA UART
// ===========================================================================

#let fig_quadro_uart() = block(breakable: false, width: 14cm, height: 5.0cm, {
  let xl = 1.9cm
  let u = 0.92cm
  let h = 0.5cm
  let y0 = 0.75cm
  // 'A' = 0x41 = 0100 0001; no fio vai do bit menos significativo para o mais
  let dados = (1, 0, 0, 0, 0, 0, 1, 0)
  let n = 1 + 1 + 8 + 1        // repouso + inicio + dados + parada
  let larg = n * u

  _txt(0cm, y0 + 0.14cm, [linha], w: 1.7cm, al: right, fonte: 7.4pt)

  // níveis
  let niveis = ((0, 1), (1, 0), (2, dados.at(0)))
  for i in range(1, 8) { niveis.push((2 + i, dados.at(i))) }
  niveis.push((10, 1))
  _onda(xl, y0, h, u, niveis, n)

  // separadores e rótulos de bit
  let rot = ([repouso], [*início*], [D0], [D1], [D2], [D3], [D4], [D5], [D6],
             [D7], [*parada*])
  for i in range(n) {
    if i > 0 {
      place(dx: xl + i * u, dy: y0 - 0.08cm,
        line(start: (0pt, 0pt), end: (0pt, h + 0.16cm),
          stroke: (thickness: 0.35pt, dash: "dotted", paint: _claro)))
    }
    _txt(xl + i * u, y0 + h + 0.14cm, rot.at(i), w: u, al: center, fonte: 6.4pt)
    // instante de amostragem, no meio do bit
    if i >= 1 {
      place(dx: xl + (i + 0.5) * u, dy: y0 - 0.30cm,
        line(start: (0pt, 0pt), end: (0pt, 0.22cm), stroke: 0.5pt + _cinza))
    }
  }
  _txt(xl + 1.5 * u - 1.6cm, y0 - 0.62cm, [o receptor amostra no meio de cada bit],
    w: 5.0cm, al: center, fonte: 6.4pt)

  // valores
  for i in range(8) {
    _txt(xl + (2 + i) * u, y0 + h + 0.42cm, _m(str(dados.at(i)), t: 6.6pt),
      w: u, al: center)
  }
  _txt(xl + 2 * u, y0 + h + 0.72cm,
    [`'A'` = 0x41 — o bit menos significativo sai primeiro],
    w: 8 * u, al: center, fonte: 6.6pt)

  _cota(xl, y0 + h + 1.42cm, u, 1, 2, [1 bit], w: 1.2cm)
  _cota(xl, y0 + h + 1.92cm, u, 1, 11, [10 bits por byte], w: 2.4cm)

  _txt(xl, y0 + h + 2.15cm,
    [A 9600 bit/s cada bit dura 104 µs, e um byte ocupa a linha por 1,04 ms. Não
     há relógio no fio: a única referência comum é a borda de início.],
    w: larg, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 24. DRENO ABERTO E O BARRAMENTO EM "E" CABLADO
// ===========================================================================

#let fig_dreno_aberto() = block(breakable: false, width: 12cm, height: 4.4cm, {
  let l = 0.7pt
  let ylinha = 1.85cm
  let ygnd = 3.7cm

  _txt(0.2cm, 0.05cm, [+VDD], w: 1.6cm, al: right, fonte: 7.4pt)
  place(dy: 0.35cm, line(start: (1.9cm, 0pt), end: (2.5cm, 0pt), stroke: l))
  place(dx: 2.2cm, dy: 0.35cm, line(start: (0pt, 0pt), end: (0pt, 0.35cm), stroke: l))
  _rot(1.94cm, 0.7cm, 0.52cm, 0.72cm, [4k7], fonte: 6.2pt)
  place(dx: 2.2cm, dy: 1.42cm, line(start: (0pt, 0pt), end: (0pt, ylinha - 1.42cm), stroke: l))

  // a linha
  place(dy: ylinha, line(start: (2.2cm, 0pt), end: (11.2cm, 0pt), stroke: 0.9pt))
  _txt(11.3cm, ylinha - 0.16cm, [`SDA`], w: 1.2cm, fonte: 7.4pt)

  // dois dispositivos, cada um só sabe puxar para baixo
  for (x, r) in ((4.4cm, [mestre]), (7.6cm, [memória])) {
    place(dx: x, dy: ylinha, line(start: (0pt, 0pt), end: (0pt, 0.5cm), stroke: l))
    place(dx: x - 0.05cm, dy: ylinha - 0.05cm,
      box(width: 0.1cm, height: 0.1cm, radius: 50%, fill: black))
    _rot(x - 0.75cm, ylinha + 0.5cm, 1.5cm, 0.8cm, [só puxa \ para baixo], fonte: 6.4pt)
    place(dx: x, dy: ylinha + 1.3cm, line(start: (0pt, 0pt), end: (0pt, ygnd - ylinha - 1.3cm), stroke: l))
    _txt(x - 1.9cm, ylinha + 0.66cm, r, w: 1.1cm, al: right, fonte: 7pt)
  }

  place(dy: ygnd, line(start: (3.6cm, 0pt), end: (8.4cm, 0pt), stroke: l))
  _txt(2.2cm, ygnd - 0.16cm, [GND], w: 1.3cm, al: right, fonte: 7.4pt)

  _txt(0cm, 3.95cm,
    [Ninguém empurra a linha para cima — quem faz isso é o resistor. Basta um
     dispositivo puxar para que a linha fique em zero, e é por isso que dois
     transmissores simultâneos não queimam nada.],
    w: 12cm, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 25. LEITURA ALEATÓRIA EM I2C, COM START REPETIDO
// ===========================================================================

#let fig_i2c() = block(breakable: false, width: 15cm, height: 4.9cm, {
  let xl = 1.5cm
  let u = 0.80cm
  let h = 0.5cm
  let ysda = 1.25cm
  let yscl = 2.45cm

  let seg = (
    (0.0, 0.6, [S], true),
    (0.6, 3.2, [`1010` A#sub[2]A#sub[1]A#sub[0] `0`], false),
    (3.2, 3.6, [A], true),
    (3.6, 6.2, [endereço interno], false),
    (6.2, 6.6, [A], true),
    (6.6, 7.2, [Sr], true),
    (7.2, 9.8, [`1010` A#sub[2]A#sub[1]A#sub[0] `1`], false),
    (9.8, 10.2, [A], true),
    (10.2, 12.8, [dado lido], false),
    (12.8, 13.2, [N], true),
    (13.2, 13.8, [P], true),
  )
  let fim = 13.8

  _txt(0cm, ysda + 0.14cm, [`SDA`], w: 1.3cm, al: right, fonte: 7.4pt)
  _txt(0cm, yscl + 0.14cm, [`SCL`], w: 1.3cm, al: right, fonte: 7.4pt)

  for (a, b, r, estreito) in seg {
    place(dx: xl + a * u, dy: ysda, box(width: (b - a) * u, height: h,
      fill: if estreito { rgb("#EFEFEF") } else { none }, stroke: 0.6pt,
      align(center + horizon, text(size: if estreito { 6.6pt } else { 7pt }, r))))
  }

  // SCL: pulsos durante os bytes, alto durante S, Sr e P
  let niveis = ((0.0, 1),)
  for (ini, f) in ((0.6, 6.6), (7.2, 13.2)) {
    let p = (f - ini) / 18
    niveis.push((ini, 0))
    for k in range(18) {
      niveis.push((ini + k * p, 1))
      niveis.push((ini + k * p + p / 2, 0))
    }
    niveis.push((f, 1))
  }
  _onda(xl, yscl, h, u, niveis, fim)

  _txt(xl + 6.9 * u - 2.4cm, ysda - 0.48cm,
    [*start repetido* — o barramento não é solto], w: 4.8cm, al: center, fonte: 6.6pt)
  place(dx: xl + 6.9 * u, dy: ysda - 0.12cm,
    line(start: (0pt, 0pt), end: (0pt, 0.1cm), stroke: 0.5pt + _cinza))

  _txt(xl, yscl + h + 0.32cm,
    [Uma única transação, com dois sentidos. O endereço interno é *escrito*, e só
     então o sentido se inverte — sem que ninguém mais possa entrar no meio.],
    w: fim * u, al: center, fonte: 6.8pt)
})


// ===========================================================================
// 26. TRÊS ESTRATÉGIAS NA MESMA PLANTA
// ===========================================================================

#let _curvas(series, ymin, ymax, alvo, xl, u, y0, alt, larg) = {
  let ey(v) = y0 + alt * (1 - (v - ymin) / (ymax - ymin))
  place(dy: ey(alvo), line(start: (xl, 0pt), end: (xl + larg, 0pt),
    stroke: (thickness: 0.5pt, dash: "dashed", paint: _cinza)))
  for (dados, esp) in series {
    let n = dados.len()
    place(curve(stroke: esp,
      curve.move((xl, ey(dados.at(0)))),
      ..range(1, n).map(i => curve.line((xl + i * larg / (n - 1), ey(dados.at(i)))))))
  }
}

#let fig_estrategias() = block(breakable: false, width: 14cm, height: 5.4cm, {
  let xl = 1.9cm
  let larg = 9.4cm
  let y0 = 0.4cm
  let alt = 3.4cm
  let ymin = 24.0
  let ymax = 45.0
  let ey(v) = y0 + alt * (1 - (v - ymin) / (ymax - ymin))

  let onoff = (25.02, 26.49, 27.91, 29.27, 30.59, 31.86, 33.08, 34.25, 35.38, 36.47, 37.52, 38.54, 39.51, 40.45, 40.02, 39.70, 40.47, 39.90, 39.89, 40.36, 39.79, 40.06, 40.25, 39.68, 40.25, 40.13, 39.58, 40.43, 40.02, 39.69, 40.48, 39.91, 39.88, 40.36, 39.80, 40.07, 40.25, 39.69, 40.25, 40.14, 39.58, 40.44, 40.02, 39.67, 40.48, 39.91, 39.86, 40.37, 39.80, 40.05, 40.26, 39.69, 40.24, 40.14, 39.58, 40.42, 40.03, 39.68, 40.49, 39.92, 39.87, 40.37, 39.81, 40.05, 40.26, 39.70, 40.22, 40.15, 39.59, 40.41, 40.03, 39.66)
  let prop  = (25.02, 26.10, 27.06, 27.92, 28.69, 29.38, 30.00, 30.55, 31.04, 31.48, 31.87, 32.23, 32.53, 32.81, 33.06, 33.29, 33.48, 33.67, 33.82, 33.96, 34.09, 34.21, 34.30, 34.39, 34.47, 34.55, 34.63, 34.68, 34.72, 34.76, 34.79, 34.82, 34.85, 34.88, 34.91, 34.94, 34.97, 34.99, 35.02, 35.04, 35.06, 35.08, 35.11, 35.13, 35.15, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16, 35.16)
  let pi    = (25.02, 26.30, 27.72, 29.08, 30.40, 31.67, 32.89, 34.06, 35.19, 36.28, 37.32, 38.32, 39.26, 40.13, 40.91, 41.59, 42.16, 42.62, 42.97, 43.20, 43.34, 43.39, 43.36, 43.25, 43.06, 42.82, 42.53, 42.22, 41.88, 41.54, 41.20, 40.87, 40.56, 40.28, 40.01, 39.80, 39.61, 39.46, 39.35, 39.28, 39.23, 39.21, 39.22, 39.25, 39.31, 39.39, 39.50, 39.60, 39.70, 39.81, 39.92, 40.04, 40.13, 40.22, 40.30, 40.37, 40.44, 40.51, 40.55, 40.56, 40.55, 40.53, 40.53, 40.53, 40.53, 40.53, 40.53, 40.52, 40.52, 40.52, 40.51, 40.51)

  place(dx: xl, dy: y0, line(start: (0pt, 0pt), end: (0pt, alt), stroke: 0.5pt + _cinza))
  place(dy: y0 + alt, line(start: (xl, 0pt), end: (xl + larg + 0.2cm, 0pt), stroke: 0.5pt + _cinza))
  for lv in (25.0, 30.0, 35.0, 40.0, 45.0) {
    _txt(0cm, ey(lv) - 0.14cm, [#calc.round(lv) °C], w: 1.7cm, al: right, fonte: 6.6pt)
  }
  _txt(xl, y0 + alt + 0.12cm, [90 minutos], w: larg, al: center, fonte: 6.6pt)

  _curvas(((onoff, 0.7pt + _claro), (prop, 0.8pt), (pi, 1.1pt)),
          ymin, ymax, 40.0, xl, 0pt, y0, alt, larg)

  _txt(xl + larg + 0.25cm, ey(41.4) - 0.16cm, [liga-desliga], w: 2.6cm, fonte: 6.6pt)
  _txt(xl + larg + 0.25cm, ey(35.2) - 0.16cm, [*proporcional*], w: 2.6cm, fonte: 6.6pt)
  _txt(xl + larg + 0.25cm, ey(38.6) - 0.16cm, [*PI*], w: 2.6cm, fonte: 6.6pt)

  _txt(xl, y0 + alt + 0.5cm,
    [O proporcional estabiliza e erra por quase cinco graus; o PI chega ao alvo. O
     liga-desliga chega perto e nunca para de oscilar.],
    w: larg, al: center, fonte: 6.8pt)
})

// ===========================================================================
// 27. SATURAÇÃO DO INTEGRADOR
// ===========================================================================

#let fig_windup() = block(breakable: false, width: 14cm, height: 5.2cm, {
  let xl = 1.9cm
  let larg = 9.4cm
  let y0 = 0.4cm
  let alt = 3.2cm
  let ymin = 24.0
  let ymax = 48.0
  let ey(v) = y0 + alt * (1 - (v - ymin) / (ymax - ymin))

  let com = (25.02, 26.49, 27.91, 29.27, 30.59, 31.86, 33.08, 34.24, 35.31, 36.33, 37.27, 38.12, 38.84, 39.46, 39.97, 40.36, 40.66, 40.88, 41.03, 41.07, 41.05, 41.01, 41.01, 41.01, 40.98, 40.93, 40.86, 40.76, 40.65, 40.52, 40.49, 40.46, 40.43, 40.40, 40.36, 40.33, 40.30, 40.26, 40.23, 40.19, 40.15, 40.12, 40.08, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04)
  let sem = (25.02, 26.49, 27.91, 29.27, 30.59, 31.86, 33.08, 34.25, 35.38, 36.47, 37.52, 38.54, 39.51, 40.45, 41.35, 42.22, 43.06, 43.87, 44.65, 45.40, 46.12, 46.76, 47.04, 46.98, 46.68, 46.20, 45.59, 44.91, 44.21, 43.52, 42.86, 42.24, 41.69, 41.20, 40.79, 40.45, 40.19, 39.98, 39.87, 39.77, 39.70, 39.65, 39.62, 39.62, 39.63, 39.66, 39.71, 39.78, 39.87, 39.97, 40.04, 40.05, 40.06, 40.06, 40.07, 40.07, 40.07, 40.06, 40.06, 40.05, 40.05, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04, 40.04)

  place(dx: xl, dy: y0, line(start: (0pt, 0pt), end: (0pt, alt), stroke: 0.5pt + _cinza))
  place(dy: y0 + alt, line(start: (xl, 0pt), end: (xl + larg + 0.2cm, 0pt), stroke: 0.5pt + _cinza))
  for lv in (25.0, 30.0, 35.0, 40.0, 45.0) {
    _txt(0cm, ey(lv) - 0.14cm, [#calc.round(lv) °C], w: 1.7cm, al: right, fonte: 6.6pt)
  }

  _curvas(((sem, 0.8pt + _claro), (com, 1.1pt)), ymin, ymax, 40.0, xl, 0pt, y0, alt, larg)

  _txt(xl + larg + 0.25cm, ey(46.0) - 0.16cm, [sem proteção], w: 2.6cm, fonte: 6.6pt)
  _txt(xl + larg + 0.25cm, ey(40.2) - 0.16cm, [*com proteção*], w: 2.6cm, fonte: 6.6pt)

  _txt(xl, y0 + alt + 0.32cm,
    [Durante o aquecimento a saída fica saturada em 100% por quarenta minutos. Sem
     proteção, o acumulador cresce esse tempo todo e cobra sete graus de
     sobressinal para se desfazer.],
    w: larg, al: center, fonte: 6.8pt)
})
