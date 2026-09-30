// Avaliação Integradora I — encontros 0 a 5
// Ocupa o encontro 6: 1h30 de prova. Consulta às folhas de referência.
//
// Um problema base — o perfilômetro de asfalto — e cinco questões amarradas a
// ele. A Q4 é a que a aula 7 cita: o mecanismo de desvio com retorno, descrito
// antes de ter nome.
//
// Compilação:  typst compile I1-integradora.typ
//              typst compile --input gab=1 I1-integradora.typ I1-integradora-gab.pdf

#let gab = sys.inputs.at("gab", default: "0") == "1"

#set page(paper: "a4", margin: (x: 18mm, y: 14mm), numbering: "1")
#set text(font: "New Computer Modern", size: 10pt, lang: "pt")
#set par(justify: false, leading: 0.6em)
#let mono = "DejaVu Sans Mono"
#let c(x) = text(font: mono, size: 9pt)[#x]

#let q(n, pontos, aulas, corpo) = block(above: 12pt, below: 4pt)[
  #text(weight: "bold")[Questão #n] #h(4pt)
  #text(size: 8.5pt, fill: luma(90))[(#pontos · encontros #aulas)]
  #v(3pt)
  #corpo
]

#let resp(corpo) = if gab {
  block(width: 100%, inset: 6pt, radius: 2pt, fill: luma(243),
        stroke: (left: 2pt + luma(120)), above: 6pt, below: 8pt)[
    #text(size: 8.5pt, weight: "bold", fill: luma(70))[RESPOSTA]
    #v(2pt)
    #set text(size: 9pt)
    #corpo
  ]
} else { v(4pt) }

#let criterio(corpo) = if gab {
  block(width: 100%, inset: 6pt, radius: 2pt,
        stroke: (left: 2pt + luma(160)), above: 2pt, below: 8pt)[
    #text(size: 8.5pt, weight: "bold", fill: luma(70))[CRITÉRIO]
    #v(2pt)
    #set text(size: 8.8pt)
    #corpo
  ]
}

#let esp(n) = if gab { v(2pt) } else { v(n) }

// Campo de resposta pautado (linhas dentro de uma moldura).
#let campo_resposta(n_linhas) = block(
  stroke: 0.5pt,
  width: 100%,
  stack(
    dir: ttb,
    ..range(n_linhas).map(i => {
      let b = if i < n_linhas - 1 { (bottom: 0.5pt) } else { none }
      block(
        width: 100%,
        height: 1.6em,
        inset: (left: 5pt, top: 4pt),
        stroke: b
      )
    })
  )
)

// Caixa arredondada para preencher um valor no meio do texto.
#let campo_codigo(w) = box(
  stroke: 0.5pt,
  radius: 5pt,
  width: w,
  height: 1.4em,
  outset: (bottom: 2pt)
)

// Só na versão do aluno: no gabarito o espaço é a própria resposta.
#let pauta(n) = if not gab {
  v(3pt)
  campo_resposta(n)
  v(6pt)
}

// Tela de osciloscópio: 10 × 8 divisões, onda quadrada de 0 a 5 V.
#let osciloscopio(periodo_div: 4, alto_div: 2.5, inicio: 1) = {
  let dx = 0.95cm
  let dy = 0.55cm
  let base = 6 * dy                       // nível de 0 V, duas divisões acima do fundo
  box(width: 10 * dx, height: 8 * dy + 0.5cm, {
    place(rect(width: 10 * dx, height: 8 * dy, stroke: 0.6pt, fill: luma(250)))
    for i in range(1, 10) {
      place(dx: i * dx, line(start: (0pt, 0pt), end: (0pt, 8 * dy),
        stroke: (thickness: 0.3pt, paint: luma(190), dash: "dotted")))
    }
    for j in range(1, 8) {
      place(dy: j * dy, line(start: (0pt, 0pt), end: (10 * dx, 0pt),
        stroke: (thickness: 0.3pt, paint: luma(190), dash: "dotted")))
    }
    // onda: sobe em inicio, meio período alto, meio baixo
    let pts = ((0pt, base),)
    let t = inicio
    while t < 10 {
      pts.push((t * dx, base))
      pts.push((t * dx, base - alto_div * dy))
      let t2 = calc.min(t + periodo_div / 2, 10)
      pts.push((t2 * dx, base - alto_div * dy))
      if t2 < 10 {
        pts.push((t2 * dx, base))
      }
      t = t + periodo_div
    }
    pts.push((10 * dx, if calc.rem(10 - inicio, periodo_div) < periodo_div / 2 { base - alto_div * dy } else { base }))
    place(curve(stroke: 1.1pt, curve.move(pts.first()),
      ..pts.slice(1).map(p => curve.line(p))))
    place(dx: -0.35cm, dy: base - 0.18cm, text(size: 7pt)[0])
    place(dy: 8 * dy + 0.12cm, text(size: 8pt, font: mono)[CH1: 2 V/div #h(1.2cm) base de tempo: 200 µs/div])
  })
}


// Captura das linhas do display (modo de 4 bits): RS, E e D7–D4.
// Cada linha: lista de (instante, nível) nos pontos de mudança, de 0 a 10.
#let captura_lcd() = {
  let u = 0.9cm
  let h = 0.38cm
  let passo = 0.62cm
  let linhas = (
    ("RS", ((0, 0),)),
    ("E",  ((0, 0), (2, 1), (3, 0), (6, 1), (7, 0))),
    ("D7", ((0, 0),)),
    ("D6", ((0, 0),)),
    ("D5", ((0, 0), (1, 1), (5, 0))),
    ("D4", ((0, 0), (1, 1), (9, 0))),
  )
  box(width: 10 * u + 1.2cm, height: linhas.len() * passo + 0.5cm, {
    for (k, (nome, mud)) in linhas.enumerate() {
      let y0 = k * passo + h
      place(dy: y0 - 0.3cm, text(size: 8pt, font: mono)[#nome])
      let x0 = 1.0cm
      place(dy: y0 - h, line(start: (x0, 0pt), end: (x0 + 10 * u, 0pt),
        stroke: (thickness: 0.3pt, paint: luma(185), dash: "dotted")))
      let pts = ()
      let ant = mud.first().at(1)
      pts.push((x0, y0 - ant * h))
      for (t, n) in mud.slice(1) {
        pts.push((x0 + t * u, y0 - ant * h))
        pts.push((x0 + t * u, y0 - n * h))
        ant = n
      }
      pts.push((x0 + 10 * u, y0 - ant * h))
      place(curve(stroke: 1pt, curve.move(pts.first()),
        ..pts.slice(1).map(p => curve.line(p))))
    }
    for t in (2, 6) {
      place(dx: 1.0cm + t * u, dy: 0pt, line(start: (0pt, 0pt), end: (0pt, linhas.len() * passo),
        stroke: (thickness: 0.3pt, paint: luma(150), dash: "dotted")))
    }
    place(dy: linhas.len() * passo + 0.1cm, dx: 1.0cm,
      text(size: 7.5pt, fill: luma(80))[pontilhado = nível alto (5 V); traço embaixo = 0 V. O controlador lê os dados na borda de descida de E])
  })
}

#align(center)[
  #text(size: 12pt, weight: "bold")[Avaliação Integradora I — encontros 0 a 5]
  #v(-3pt)
  #text(size: 9pt)[Microcontroladores · DENE/UFMT#if gab [ · #text(weight: "bold")[GABARITO]]]
]
#v(4pt)
#line(length: 100%, stroke: 0.6pt)
#v(2pt)

#text(size: 9pt)[
Nome: #box(width: 60%, line(length: 100%, stroke: 0.4pt)) #h(1fr) 1h30
#v(2pt)
Consulta permitida às folhas de referência do curso. Todas as questões falam do
*mesmo sistema*, descrito abaixo; os dados e as fórmulas de que você precisa
estão nas caixas. A resposta vale pelo raciocínio: um número certo sem
justificativa vale metade.
]

#v(3pt)
#block(width: 100%, inset: 8pt, stroke: 0.8pt)[
  #text(size: 8.5pt, weight: "bold", fill: luma(70))[O SISTEMA: UM PERFILÔMETRO DE ASFALTO]
  #v(3pt)
  #set text(size: 9.3pt)
  Um carro de passeio trafega a 100 km/h. Um sistema com o PIC18F4550 precisa medir
  a altura do asfalto *a cada 1 mm de estrada percorrida*, para mapear trincas e
  buracos. Ele tem duas entradas:

  - um *encoder* de 100 pulsos por volta, preso a uma roda de raio 0,30 m, que
    entrega uma onda quadrada de 0 a 5 V em RC0 — o pino T13CKI do Timer1;
  - um *sensor laser* de distância, que entrega em AN0 uma tensão de 0 a 5 V
    proporcional à distância até o asfalto, de 50 mm (0 V) a 150 mm (5 V).

  O display do kit mostra a altura medida, e um LED em RC1 indica "medindo".
]

#v(3pt)
#grid(columns: (1fr, 1fr), gutter: 6pt,
  block(width: 100%, inset: 7pt, stroke: 0.5pt + luma(120))[
    #text(size: 8.5pt, weight: "bold", fill: luma(70))[DADOS]
    #v(2pt)
    #set text(size: 8.8pt)
    Núcleo a 16 MHz: $T_"CY"$ = 250 ns \
    Conversor: 10 bits, 0 a 5 V, 1 LSB = 4,883 mV \
    Uma leitura do conversor: 15 µs (60 ciclos) \
    Atualização do display: 1,3 ms (5#h(1pt)200 ciclos) \
    Timer0 com divisor 1:8: `T0CON` = #c[0x82]
  ],
  block(width: 100%, inset: 7pt, stroke: 0.5pt + luma(120))[
    #text(size: 8.5pt, weight: "bold", fill: luma(70))[FORMULÁRIO]
    #v(2pt)
    #set text(size: 8.8pt)
    Circunferência: $C = 2 pi r$ #h(8pt) ($pi approx 3,1416$) \
    Distância por pulso: $d = C slash "PPR"$ \
    Velocidade: $v ["m/s"] = v ["km/h"] slash 3,6$ \
    Tempo por distância: $Delta t = Delta x slash v$ #h(8pt) $f = 1 slash T$ \
    Ciclos: $n = Delta t slash T_"CY"$ \
    Conversor: $V = "código" dot.c 5000 slash 1024$ mV \
    Laser: $h = 50 + 100 dot.c V slash 5$ mm #h(4pt) ($V$ em volts) \
    Timer0: $N = Delta t slash (T_"CY" dot.c "divisor")$, pré-carga $= 65#h(1pt)536 - N$ \
    Timer1 (16 bits): passo $= T_"CY" dot.c "divisor"$; estoura após 65#h(1pt)536 passos
  ],
)

#v(3pt)
#block(width: 100%, inset: 7pt, stroke: 0.5pt + luma(120))[
  #text(size: 8.5pt, weight: "bold", fill: luma(70))[DISPLAY (HD44780)]
  #v(2pt)
  #set text(size: 8.8pt)
  #grid(columns: (1fr, 1fr), gutter: 8pt,
    [
      *Modo de 4 bits:* cada byte vai em dois pulsos de E, pelas linhas D7–D4 —
      primeiro o nibble alto, depois o baixo. \
      O controlador lê os dados na *borda de descida* de E. \
      RS = 0: o byte é *instrução*. RS = 1: o byte é *dado* (caractere).
    ],
    [
      Caracteres: #c['0'] … #c['9'] = #c[0x30] … #c[0x39]; #c['.'] = #c[0x2E] \
      Instruções: \
      #c[0x01] limpa a tela #h(6pt) #c[0x80 | end] posiciona o cursor \
      #c[0x28] Function Set: 4 bits, 2 linhas \
      #c[0x30]–#c[0x33] Function Set: *8 bits*, 1 linha
    ],
  )
]

#v(2pt)
#line(length: 100%, stroke: 0.4pt)

#q(1, "2,0", "0, 1 e 2")[
Um colega escreveu a primeira versão do firmware. O LED em RC1 "medindo" deveria
seguir o sinal do encoder, e nunca acende com o carro andando.

#v(3pt)
#block(inset: (left: 8pt))[
#set text(font: mono, size: 9pt)
```c
void main(void)
{
    LATC  = 0x00;
    TRISC = 0x00;             /* "configura a porta C" */
    while (1) {
        LATCbits.LATC1 = PORTCbits.RC0;   /* LED segue o encoder */
    }
}
```
]
#v(3pt)

*(a)* O que #c[PORTCbits.RC0] devolve com esse código, e por quê?

#pauta(4)

*(b)* Corrija a configuração com o mínimo de mudança:
#h(6pt) #c[TRISC =] #if gab [#c[0x01;]] else [#campo_codigo(3cm) #c[;]]
#v(5pt)
]
#resp[
*(a)* Sempre 0. #c[TRISC = 0x00] põe *todos* os pinos da porta C como saída,
inclusive RC0. O próprio microcontrolador força o pino ao valor do latch
(#c[LATC0] = 0), e a leitura de #c[PORTC] devolve esse nível, qualquer que seja o
encoder. Pior: a saída do encoder e a do microcontrolador ficam ligadas no mesmo
fio, brigando.

*(b)* RC0 como entrada e o resto como saída: #c[TRISC = 0x01;].
]
#criterio[
(a) 1,2: sempre 0 (0,4); RC0 virou saída e a leitura devolve o próprio latch
(0,8). O conflito entre saídas, se citado, compensa falhas menores.
(b) 0,8: RC0 como entrada, mantendo as saídas.
]

#q(2, "2,0", "2 e o problema base")[
*(a)* Que distância a roda percorre a cada pulso do encoder? A meta de uma
amostra por milímetro é atendida só com esses pulsos?

#pauta(4)

*(b)* Numa caminhonete com rodas de raio 0,45 m, a distância por pulso aumenta ou
diminui, e em que proporção?
#pauta(3)
]
#resp[
*(a)* $C = 2 dot.c 3,1416 dot.c 0,30 = 1,885$ m, e $d = 1,885 slash 100 =
18,85$ mm por pulso. Não atende: entre dois pulsos a roda anda quase 19 mm, e o
sistema não sabe o que houve nos milímetros intermediários. Seria preciso um
encoder de pelo menos 1885 pulsos por volta.

*(b)* Aumenta, na mesma proporção do raio: $d = 2 pi r slash "PPR"$. Com 0,45 m,
$d = 28,27$ mm — 1,5 vez pior.
]
#criterio[
(a) 1,3: $d$ = 18,85 mm, com a conta (0,8); não atende, com o motivo (0,5).
(b) 0,7: aumenta, proporcional ao raio (0,4); 28,27 mm ou "1,5 vez" (0,3).
]

#q(3, "2,0", "2 e 5")[
Alguém mediu RC0 com o osciloscópio, com o carro andando:

#align(center)[#osciloscopio()]

*(a)* Leia na tela o período do sinal. Qual a frequência dos pulsos, e qual a
velocidade do carro, em km/h? (Use o $d$ da Questão 2.)

#pauta(5)

*(b)* Outra forma de medir a velocidade: o Timer1, com fonte interna, mede o
*tempo entre dois pulsos* do encoder. O sistema precisa funcionar de *1 km/h a
150 km/h*. Quais divisores do Timer1 — 1:1, 1:2, 1:4 ou 1:8 — servem? Justifique
com os dois extremos de velocidade.
#pauta(6)
]
#resp[
*(a)* De uma borda de subida à seguinte são 4 divisões: $T = 4 dot.c 200 = 800$
µs, e $f = 1 slash 800 "µs" = 1250$ Hz. Cada pulso vale 18,85 mm:
$v = 1250 dot.c 0,01885 = 23,6$ m/s, ou *≈ 85 km/h*. (A velocidade medida não
precisa ser os 100 km/h do enunciado: é o carro naquele instante.)

*(b)* O período entre pulsos é $d slash v$.

A *1 km/h* (0,278 m/s): $0,01885 slash 0,278 = 67,9$ ms. O Timer1 estoura em
$65#h(1pt)536 dot.c 250 "ns" dot.c "divisor"$: 16,4 ms (1:1), 32,8 ms (1:2),
65,5 ms (1:4) e 131 ms (1:8). Só com *1:8* o contador não estoura antes do
pulso seguinte.

A *150 km/h* (41,7 m/s): $0,01885 slash 41,7 = 452$ µs. Com 1:8, cada passo vale
2 µs, e o período cabe em *226 passos* — resolução de ≈ 0,4%, suficiente.

Resposta: *só 1:8*. O extremo lento decide o divisor mínimo; o extremo rápido
confirma que ainda sobra resolução.
]
#criterio[
(a) 1,0: período lido (0,4); frequência (0,3); velocidade (0,3).
(b) 1,0: período a 1 km/h e os estouros, excluindo 1:1 a 1:4 (0,5); período a
150 km/h e a resolução com 1:8 (0,3); a conclusão, só 1:8 (0,2).
]

#q(4, "2,0", "1, 2 e 5")[
Suponha que o encoder foi trocado por um que dá *um pulso por milímetro*, e que a
cada pulso o firmware lê o laser.

*(a)* A 100 km/h, quanto tempo passa entre dois pulsos, e quantos ciclos de
máquina isso dá?

#pauta(3)

*(b)* O firmware consulta o indicador do Timer1 no laço, e o laço também atualiza
o display. Quantos pulsos chegam durante uma atualização, e o que acontece com
eles?

#pauta(4)

*(c)* Para atender cada pulso no instante em que ele chega, o *hardware*
precisaria desviar para uma rotina e depois voltar. Descreva o que ele precisa
fazer — com o contador de programa e com os registradores que o laço usava —
para que o laço continue exatamente de onde parou.
#pauta(6)
]
#resp[
*(a)* $v = 100 slash 3,6 = 27,78$ m/s; $Delta t = 0,001 slash 27,78 = 36$ µs;
$n = 36 "µs" slash 250 "ns" = 144$ ciclos — dos quais a leitura do conversor já
consome 60.

*(b)* 1,3 ms #sym.div 36 µs $approx 36$ pulsos. O indicador é *um bit*: sobe no
primeiro, e os outros o encontram já em 1 — são perdidos, sem nenhum aviso. O
mapa pula ≈ 35 mm de estrada a cada atualização de tela.

*(c)* Ao fim da instrução em curso, o hardware *guarda o PC* (o endereço da
próxima instrução do laço) numa pilha e *carrega no PC um endereço fixo*, onde
está a rotina. A rotina *preserva W, STATUS e BSR*, faz o trabalho curto e os
restaura; uma instrução de *retorno* devolve ao PC o endereço guardado. Para o
laço, nada foi pulado: só levou mais tempo.
]
#criterio[
(a) 0,6: 36 µs (0,3); 144 ciclos (0,3).
(b) 0,6: ≈ 36 pulsos (0,2); indicador de um bit perde os outros, em silêncio (0,4).
(c) 0,8: PC guardado e restaurado (0,4); endereço fixo (0,2); preservar
registradores (0,2). Não se exige o nome "interrupção".
]

#q(5, "2,0", "3 e 4")[
Numa amostra, o conversor devolveu o código *614* para o laser.

*(a)* Qual a tensão, e qual a distância até o asfalto, em mm?

#pauta(3)

*(b)* No firmware, a altura é calculada em centésimos de milímetro:

#align(center)[#c[uint16_t cmm = 5000u + (codigo \* 625u) / 64u;]]

A fórmula está certa, e o resultado sai errado para esse código. Por quê? Corrija.

#pauta(4)

*(c)* O primeiro caractere da altura vai para o display. A captura mostra as
linhas do controlador durante esse envio, no modo de 4 bits:

#align(center)[#captura_lcd()]

Decodifique o byte enviado. O firmware tem um erro, visível na captura: qual é, e
o que acontece com o display a partir daí? Use a caixa do display.
#pauta(6)
]
#resp[
*(a)* $V = 614 dot.c 5000 slash 1024 = 2998$ mV $approx 3,00$ V, e
$h = 50 + 100 dot.c 3,00 slash 5 = 109,96$ mm.

*(b)* O produto é calculado em 16 bits: $614 dot.c 625 = 383#h(1pt)750$ não cabe
em 65#h(1pt)535, e sobra só o resto da divisão por 65#h(1pt)536. Estoura a partir
do código 105 — quase toda a faixa —, nada avisa, e o número que sai é
plausível. Correção: produto em 32 bits,
#c[5000u + ((uint32_t)codigo \* 625u) / 64u]; o resultado final (até 14 990)
cabe em 16 bits, o intermediário não.

*(c)* Nas duas bordas de descida de E, D7–D4 valem #c[0011] e depois #c[0001]:
o byte é #c[0x31], o caractere #c['1'] — o primeiro dígito de 109,96, correto.

O erro é *RS em 0* o tempo todo. Com RS = 0 o byte vai para o registrador de
*instrução*, e #c[0x31] não é o caractere #c['1']: é o comando *Function Set*
com DL = 1 — interface de *8 bits*, uma linha. O controlador passa a esperar um
byte por pulso de E; o firmware continua mandando nibbles, e tudo o que vier
depois sai lixo, até uma nova inicialização.
]
#criterio[
(a) 0,6: tensão (0,2); altura (0,4).
(b) 0,7: o produto estoura 16 bits (0,4); a correção em 32 bits (0,3).
(c) 0,7: byte #c[0x31] decodificado (0,3); RS em 0, byte vai como instrução
(0,2); Function Set em 8 bits e o lixo que se segue (0,2).
]
