#let gab = sys.inputs.at("gab", default: "0") == "1"

#set page(paper: "a4", margin: (x: 18mm, y: 14mm), numbering: "1")
#set text(font: "New Computer Modern", size: 10pt, lang: "pt")
#set par(justify: false, leading: 0.6em)
#let mono = "DejaVu Sans Mono"
#let c(x) = text(font: mono, size: 9pt)[#x]

#let q(n, pontos, corpo) = block(above: 12pt, below: 4pt)[
  #text(weight: "bold")[Questão #n] #h(4pt)
  #text(size: 8.5pt, fill: luma(90))[(#pontos)]
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

#let esp(n) = if gab { v(2pt) } else { v(n) }

#align(center)[
  #text(size: 12pt, weight: "bold")[Miniteste M4 — Conversão analógico-digital]
  #v(-3pt)
  #text(size: 9pt)[Microcontroladores · DENE/UFMT#if gab [ · #text(weight: "bold")[GABARITO]]]
]
#v(4pt)
#line(length: 100%, stroke: 0.6pt)
#v(2pt)

#text(size: 9pt)[
Nome: #box(width: 60%, line(length: 100%, stroke: 0.4pt)) #h(1fr) 20 minutos
#v(2pt)
*Todos os dados de que você precisa estão na caixa abaixo* — nenhuma questão
se responde procurando. As respostas valem pelo raciocínio; um número certo sem
justificativa vale metade.
]

#v(3pt)
#block(width: 100%, inset: 7pt, stroke: 0.5pt + luma(120))[
  #text(size: 8.5pt, weight: "bold", fill: luma(70))[DADOS]
  #v(2pt)
  #set text(size: 9pt)
  #grid(
    columns: (1fr, 1fr),
    gutter: 8pt,
    [
      Referência de fundo de escala: #c[VDD] = 5 V \
      Resolução do conversor: 10 bits \
      Sensor LM35: 10 mV por #sym.degree#h(0pt)C
    ],
    [
      Aquisição: 4 $T_"AD"$ #h(6pt) Conversão: 11 $T_"AD"$ \
      $T_"AD"$ = 1 µs (#c[ADCS] = #c[101], $F_"osc"$/16) \
      Ciclo de máquina a 16 MHz: 250 ns
    ],
  )
]

#v(2pt)
#line(length: 100%, stroke: 0.4pt)

#q(1, "2,0")[
Um estudante liga um botão em RB0 e escreve, como primeira linha do #c[main]:

#v(3pt)
#c[while (1) { if (PORTBbits.RB0 == 0) LATD = 0xFF; else LATD = 0x00; }]
#v(3pt)

Com a chave pressionada ou solta, #c[PORTBbits.RB0] devolve sempre 0 — e os LEDs
ficam sempre acesos. O botão foi testado no multímetro e está bom.

*(a)* O que está acontecendo com o pino? Nomeie o mecanismo.

*(b)* Um colega sugere acrescentar #c[\#pragma config PBADEN = OFF] no início do
arquivo. Avalie a sugestão e diga o que resolve.
]
#resp[
*(a)* RB0 nasceu analógico. O bit de configuração #c[PBADEN] vale 1 de fábrica, e
com ele RB0 a RB4 saem do reset como entradas analógicas. Num pino em modo
analógico o buffer de entrada digital está desligado, e a leitura de #c[PORT]
devolve 0 qualquer que seja a tensão no pino. O defeito não está no botão nem no
#c[if] — está no caminho de entrada que o reset escolheu.

*(b)* Não resolve. As palavras de configuração pertencem ao bootloader — é o
código que veio antes do seu, do encontro 0 — e o #c[\#pragma config] da
aplicação é ignorado. #c[PBADEN] não é ajustável pelo programa do aluno.

O que resolve é desfazer o efeito em tempo de execução, antes de qualquer
leitura:

#v(2pt)
#c[ADCON1 = 0x0F;] #h(12pt) #text(size: 8.5pt)[/\* PCFG = 1111: todos os canais digitais \*/]
]
#esp(24mm)

#q(2, "2,0")[
Um estudante monta um divisor com dois resistores de 1 M#sym.Omega entre 5 V e o
terra, e liga o ponto do meio em AN0. O multímetro no pino mede 2,50 V, como
esperado. O conversor devolve um código perto de 140, e não de 512.

*(a)* Explique o defeito a partir do que o conversor realmente mede.

*(b)* O estudante passa a ler dezesseis vezes e tirar a média. O código melhora?
Justifique, e diga o que de fato corrige.
]
#resp[
*(a)* O conversor não lê o pino: lê um capacitor de retenção, de cerca de 25 pF,
que precisa se carregar através da resistência da fonte durante o tempo de
aquisição. A resistência equivalente do divisor é 1 M#sym.Omega em paralelo com
1 M#sym.Omega, ou 500 k#sym.Omega, e a constante de tempo fica em
500 k#sym.Omega #sym.times 25 pF = 12,5 µs.

A aquisição dura 4 $T_"AD"$ = 4 µs, menos de um terço de uma constante de tempo.
O capacitor chega a cerca de 27% dos 2,50 V, ou 0,69 V — que em dez bits dá
justamente algo perto de 140. O multímetro não vê o problema porque a entrada
dele tem dezenas de megaohms e praticamente não puxa carga; o ADC puxa.

*(b)* Não melhora nada. O erro é *sistemático*: todas as dezesseis amostras têm o
mesmo déficit de carga, e a média de dezesseis valores igualmente errados é o
mesmo valor errado. Média reduz variância, não viés.

O que corrige é diminuir a impedância da fonte — resistores muito menores no
divisor — ou pôr um seguidor de tensão entre o divisor e o pino. Alternativa
válida: aumentar #c[ACQT], mas para 12,5 µs de constante de tempo o tempo de
aquisição necessário fica caro.
]
#esp(24mm)

#pagebreak()

#q(3, "2,0")[
*(a)* Quanto vale um degrau do conversor, em milivolts e em graus Celsius com o
LM35? Mostre as duas contas.

*(b)* Um colega propõe ligar uma referência estável de 1,00 V no pino RA3 e usá-la
como #c[VREF+], "para ganhar resolução". Quanto ele ganha? Cite duas coisas que
ele perde.
]
#resp[
*(a)* 5 V #sym.div 1024 = 4,8828125 mV. Não é arredondamento: 1024 é potência de
dois e a divisão é exata em binário.

Com o LM35 entregando 10 mV por grau, um degrau vale
4,8828125 #sym.div 10 = 0,48828125 #sym.degree#h(0pt)C — cerca de meio grau.

Nenhuma leitura desta cadeia distingue 24,7 de 25,0 #sym.degree#h(0pt)C, e isso
não melhora com código melhor.

*(b)* Ganha cinco vezes: 1 V #sym.div 1024 = 0,977 mV, ou 0,098
#sym.degree#h(0pt)C por degrau.

Perde, entre outras coisas:

— *um canal*: RA3 deixa de estar disponível como AN3, porque virou a entrada de
referência;

— *a estabilidade vira erro de medida*: a referência passa a ser um componente
do qual toda leitura depende, e a deriva dela com temperatura e tempo entra
diretamente no resultado. Com #c[VDD] o problema existe também, mas a referência
é a mesma que alimenta o sensor;

— *a faixa*: o fundo de escala cai para 1 V, ou 100 #sym.degree#h(0pt)C de LM35.
Suficiente para o termostato, mas satura acima disso.

#text(size: 9pt)[Aceitar dois dos três.]
]
#esp(26mm)

#q(4, "2,0")[
A conversão de código para décimos de grau é exata em inteiros, porque
4,8828125 = 625/128. Um estudante escreve:

#v(3pt)
#c[uint16_t n = ((uint16_t) ADRESH << 8) | ADRESL;] #h(8pt) #text(size: 8.5pt)[/\* 0 a 1023 \*/] \
#c[uint16_t decimos = (n \* 625u) >> 7;]
#v(3pt)

*(a)* Com #c[n] = 1023, que valor aparece em #c[decimos], e que valor deveria
aparecer? Mostre a conta.

*(b)* Por que esse defeito é mais perigoso que um que trava o programa?
]
#resp[
*(a)* A conta correta é 1023 #sym.times 625 = 639#h(1pt)375, e
639#h(1pt)375 #sym.div 128 = 4995 décimos, ou 499,5 #sym.degree#h(0pt)C — o fundo
de escala, como esperado.

O que acontece: os dois operandos são de 16 bits, então o produto é calculado em
16 bits e 639#h(1pt)375 não cabe. Sobra o resto da divisão por 65#h(1pt)536:

#v(2pt)
639#h(1pt)375 − 9 #sym.times 65#h(1pt)536 = 49#h(1pt)551 #h(10pt) e #h(10pt)
49#h(1pt)551 #sym.div 128 = 387
#v(2pt)

Aparece 387, isto é *38,7 #sym.degree#h(0pt)C*. A correção é forçar a conta em 32
bits: #c[((uint32_t) n \* 625u) >> 7].

*(b)* Porque 38,7 #sym.degree#h(0pt)C é um número *plausível*. Nada trava, nada
avisa, nenhum valor absurdo aparece na tela — e o termostato vai agir sobre ele.
Um programa que trava é um programa que denuncia o próprio defeito; este mente
com naturalidade, e só é descoberto por quem conferir a conta ou aquecer o sensor
até o fim da escala.
]
#esp(24mm)

#q(5, "2,0")[
*(a)* Quanto custa uma leitura completa do conversor, em microssegundos e em
ciclos de máquina? Uma atualização das duas linhas do display custa cerca de
5#h(1pt)200 ciclos. Que consequência de projeto sai da comparação?

*(b)* Um estudante lê o LM35 quatro vezes seguidas e divide por quatro, esperando
"ganhar resolução". Com o sensor parado, as quatro leituras devolvem exatamente o
mesmo código. Explique por que a média não ajudou, e diga sob que condição ela
ajudaria.
]
#resp[
*(a)* 4 $T_"AD"$ de aquisição mais 11 $T_"AD"$ de conversão dão 15 $T_"AD"$. A
$T_"AD"$ = 1 µs são 15 µs, e 15 µs #sym.div 250 ns = *60 ciclos de máquina*.

A comparação: 60 contra 5#h(1pt)200. Medir custa cerca de 1,2% do que custa
mostrar.

A consequência é contraintuitiva: *num termostato o gargalo não é medir, é
escrever*. Quem precisar de tempo de processador não deve amostrar menos — deve
atualizar a tela menos.

*(b)* Porque a média só recupera informação entre degraus se houver ruído *maior
que um LSB* somado ao sinal. Com ruído, amostras sucessivas caem em degraus
diferentes e a proporção entre elas carrega a informação intermediária. Sem
ruído, as quatro amostras caem no mesmo degrau, e a média de um valor com ele
mesmo é ele mesmo.

A quantização já descartou a informação; nenhuma soma a traz de volta.

#text(size: 9pt)[A média continua útil para o que ela de fato faz: reduzir a
variância de leitura quando há interferência da rede, do PWM do cooler ou do
relé chaveando.]
]
