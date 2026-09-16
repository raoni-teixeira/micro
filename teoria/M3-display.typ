#let gab = sys.inputs.at("gab", default: "0") == "1"

#set page(paper: "a4", margin: (x: 18mm, y: 14mm), numbering: "1")
#set text(font: "Latin Modern Roman", size: 10pt, lang: "pt")
#set par(justify: false, leading: 0.6em)
#let mono = "Latin Modern Mono"
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
  #text(size: 12pt, weight: "bold")[Miniteste M3 — Interfaceamento paralelo e display]
  #v(-3pt)
  #text(size: 9pt)[Microcontroladores · DENE/UFMT#if gab [ · #text(weight: "bold")[GABARITO]]]
]
#v(4pt)
#line(length: 100%, stroke: 0.6pt)
#v(2pt)

#text(size: 9pt)[
Nome: #box(width: 60%, line(length: 100%, stroke: 0.4pt)) #h(1fr) 20 minutos
#v(2pt)
Consulta permitida à folha de referência do HD44780. #strong[Nenhuma questão se
responde procurando] — todas pedem uma consequência do que está lá.
As respostas valem pelo raciocínio; um número certo sem justificativa vale
metade.
]

#v(2pt)
#line(length: 100%, stroke: 0.4pt)

#q(1, "2,0")[
Um estudante escreve o código abaixo esperando ver a letra #c[A] na tela. O
display foi inicializado corretamente antes.

#v(3pt)
#c[LATE0 = 1;] #h(20pt) #text(size: 8.5pt)[/\* RS \*/] \
#c[LATE2 = 0;] #h(20pt) #text(size: 8.5pt)[/\* R/W \*/] \
#c[LATD  = 0x41;] \
#c[\_\_delay_us(40);]
#v(3pt)

*(a)* O que aparece na tela? Justifique em uma frase.

*(b)* Um colega sugere: "aumenta o atraso para 1 ms que resolve". Avalie a
sugestão.
]
#resp[
*(a)* Nada. O valor fica parado nos fios e o controlador o ignora: a linha #c[E]
nunca subiu, e portanto nunca desceu. O nível prepara; é a borda que transfere.

*(b)* Não resolve, e nenhum valor de atraso resolveria. O problema não é
quantidade de tempo — é a ausência de um evento. O controlador não amostra o
barramento continuamente; ele amostra na borda de descida de #c[E]. Sem essa
borda, esperar mil vezes mais é esperar por nada.
]
#esp(28mm)

#q(2, "2,0")[
Duas versões da mesma linha:

#v(3pt)
#c[LATD = (LATD  & 0x0F) | (valor & 0xF0);] \
#c[LATD = (PORTD & 0x0F) | (valor & 0xF0);]
#v(3pt)

*(a)* Descreva concretamente o defeito da segunda versão, supondo que os quatro
bits baixos do #c[PORTD] estejam ligados a LEDs.

*(b)* O estudante desconecta os LEDs para investigar e o defeito desaparece.
Explique por quê — e diga o que isso significa para quem procura o erro.
]
#resp[
*(a)* A operação é na verdade três: ler os oito bits, alterar quatro, escrever
os oito de volta. Lendo de #c[PORTD], o que se lê é o nível elétrico do pino, e
não o que foi escrito nele. Um pino carregando um LED pode ainda não ter subido
ao nível escrito no instante da leitura; lê-se 0 onde havia 1, e esse 0 é
reescrito. O LED apaga sozinho, sem que nenhuma linha do programa tenha mandado
apagá-lo.

*(b)* Sem carga, o pino atinge o nível quase instantaneamente e a leitura passa
a coincidir com o latch. O defeito não some: some o sintoma. E é a pior
categoria de defeito justamente por isso — a ação de investigar é a ação que o
esconde. Só o raciocínio sobre o mecanismo encontra este erro; tentativa e erro
na bancada, não.
]
#esp(30mm)

#q(3, "2,0")[
Um programa posiciona o cursor no endereço #c[0x00] e escreve 20 caracteres
seguidos, sem nenhum outro comando.

*(a)* Quantos caracteres aparecem, e onde estão os demais?

*(b)* Sem reescrever nenhum caractere, é possível fazer o 17.º aparecer na
tela? Se sim, como.
]
#resp[
*(a)* Aparecem 16, todos na primeira linha. Os quatro restantes foram gravados
em #c[0x10] a #c[0x13] — posições que existem na memória do controlador, guardam
o que foi escrito nelas, e não correspondem a nenhum ponto da tela. Não passam
para a segunda linha: a segunda linha começa em #c[0x40], e o contador de
endereços não salta.

*(b)* Sim, com um comando de deslocamento (#c[0001 1x\*\*]). A tela é uma janela
de 16 posições sobre 40; deslocar move a janela, não o conteúdo. Os caracteres
continuam onde estão e passam a cair dentro da parte visível.

#text(size: 8.5pt)[Aceitar também: reposicionar o cursor em #c[0x40] e reescrever
— mas isso reescreve, e o enunciado proíbe.]
]
#esp(30mm)

#q(4, "2,0")[
O kit está ligado. Você aperta SW9, o microcontrolador reinicia e o display
permanece energizado o tempo todo.

*(a)* Por que o controlador pode estar em #strong[três] estados, e não em dois?

*(b)* Um estudante remove uma das três repetições de #c[0x30]. Descreva uma
situação em que o programa continua funcionando e uma em que falha.
]
#resp[
*(a)* Os dois estados óbvios são interface de 8 bits e interface de 4 bits. O
terceiro existe porque, em 4 bits, um byte são dois pulsos — e o reset pode cair
#strong[entre] os dois. O controlador fica esperando a segunda metade de um byte
cuja primeira metade veio do programa anterior.

*(b)* *Funciona* quando o display acabou de ser energizado junto com o
microcontrolador: aí ele está seguramente em 8 bits, e o primeiro #c[0x30] já é
o comando que se queria. *Falha* quando só o microcontrolador foi reiniciado e o
controlador estava esperando a segunda metade de um byte: são necessários três
passos para levar os três estados ao mesmo lugar, e com dois um deles ainda não
chegou.

#text(size: 8.5pt)[O detalhe que vale ponto: é justamente o reset por SW9 — o
gesto mais comum do laboratório — que produz o estado que a sequência encurtada
não resolve.]
]
#esp(30mm)

#q(5, "2,0")[
*(a)* No driver, a linha #c[LATE2 = 0] é escrita explicitamente antes de cada
byte, embora #c[0] pareça ser o valor natural do pino. Por que essa linha não é
redundante? Que tipo de sintoma sua ausência produz?

*(b)* Uma atualização completa de tela custa cerca de 1,3 ms. O gerador de
melodia da bancada inverte um pino a cada 1,14 ms para produzir um lá.
Escrever no display e tocar a nota no mesmo laço funciona? Justifique com os
dois números.
]
#resp[
*(a)* O pino sai do reset como #strong[entrada], não como saída em nível baixo.
Sem escrever no latch e configurar o #c[TRIS], #c[R/W] fica flutuando, e o
módulo pode entender leitura onde o programa quis escrita. O sintoma é
intermitente: funciona, funciona, funciona, e um dia não — sem que nada no
código tenha mudado. Vale mencionar que é um defeito sem sintoma reprodutível, e
por isso capaz de sobreviver meses num projeto.

*(b)* Não funciona. Uma atualização de tela é #strong[mais longa] que meio
período da nota, e durante ela o processador está bloqueado esperando o
controlador. O pino não é invertido a tempo, e a nota sai errada toda vez que o
display é escrito — um estalo, ou queda de tom. Nenhuma reorganização do laço
resolve enquanto a escrita for bloqueante; a saída é o processador ser
interrompido durante a espera.
]
#esp(30mm)

#v(6pt)
#line(length: 100%, stroke: 0.4pt)
#v(3pt)

#block[
  #text(weight: "bold")[Questão-ponte] #h(4pt)
  #text(size: 8.5pt, fill: luma(90))[(sem nota — leve a resposta para o R4)]
  #v(3pt)
  A folha de referência traz cinco tempos mínimos e diz que #c[limpar a tela]
  custa quarenta vezes mais que um comando comum. Nenhuma das duas coisas foi
  explicada em aula.

  *(a)* Dos cinco mínimos, quais o seu código paga com um #c[\_\_delay_us]
  explícito, e quais ele paga sem que ninguém tenha escrito atraso nenhum?

  *(b)* Por que justamente #c[limpar] e #c[voltar ao início] custam 1,52 ms, e
  todos os outros comandos custam 37 µs?
  #v(3pt)
  #text(size: 8.5pt)[Escreva o que você acha antes da bancada. Você vai medir os
  dois no R4.]
]

#if gab [
  #resp[
  *(a)* Só #c[PW#sub[EH]] tem atraso dedicado. Os outros quatro são pagos pelo
  tempo das próprias instruções: escrever #c[RS], escrever #c[R/W] e compor o
  dado consomem ciclos de 250 ns cada, e isso já é dezenas de vezes os 40, 80 e
  10 ns exigidos. O #c[t#sub[cicE]] de 500 ns é coberto pelo segundo
  #c[\_\_delay_us] somado às instruções do próximo nibble.

  #text(size: 9pt)[O ponto a extrair: num processador lento, a maioria dos
  contratos de temporização é cumprida por acidente. O perigo é que ninguém está
  olhando para eles — e eles deixam de ser cumpridos quando alguém "otimiza" a
  função ou leva o código para um chip mais rápido.]

  *(b)* Porque são os dois únicos comandos que percorrem toda a memória de
  exibição: 80 posições a serem preenchidas com espaço, ou o contador e a janela
  a serem devolvidos à origem. Os demais alteram um registrador ou uma posição
  só. O custo acompanha a quantidade de trabalho interno, e não a complexidade
  aparente do comando.
  ]
]
