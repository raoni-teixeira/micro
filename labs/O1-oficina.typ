// ============================================================
//  Microcontroladores --- DENE/UFMT
//  Oficina 1 --- arquivo autocontido (sem imports)
// ============================================================

#let azul     = rgb("#003366")
#let vermelho = rgb("#9b1b1b")
#let laranja  = rgb("#a35200")
#let verde    = rgb("#1d5c2e")
#let roxo     = rgb("#5b2a86")
#let marrom   = rgb("#6b4423")
#let cinza    = rgb("#f2f2f2")

#set document(
  title: "Microcontroladores --- Oficina 1",
  author: "Raoni F. S. Teixeira · Rodolfo Quadros",
)

#set page(
  paper: "a4",
  margin: (x: 2.4cm, top: 2.4cm, bottom: 2.2cm),
  header: context {
    set text(8.5pt, fill: luma(110))
    if counter(page).get().first() > 1 [
      Microcontroladores --- Prática #h(1fr) Oficina 1
      #v(-7pt)
      #line(length: 100%, stroke: 0.4pt + luma(190))
    ]
  },
  footer: context {
    set text(8.5pt, fill: luma(110))
    line(length: 100%, stroke: 0.4pt + luma(190))
    v(-3pt)
    [Raoni F. S. Teixeira · Rodolfo Quadros --- DENE/UFMT #h(1fr) #counter(page).display()]
  },
)

#set text(font: ("Linux Libertine", "Libertinus Serif"), size: 10.5pt, lang: "pt")
#set par(justify: true, leading: 0.62em, first-line-indent: 0pt)
#set heading(numbering: "1.1")

#show heading: it => block(
  above: 1.1em, below: 0.6em,
  text(fill: azul, weight: "bold", size: if it.level == 1 { 13pt } else { 11.5pt }, it),
)

#show raw.where(block: true): it => block(
  width: 100%, fill: luma(246), inset: 8pt, radius: 2pt,
  stroke: (left: 2pt + luma(180)), breakable: true,
  text(font: ("DejaVu Sans Mono", "Liberation Mono"), size: 8.8pt, it),
)
#show raw.where(block: false): it => text(
  font: ("DejaVu Sans Mono", "Liberation Mono"), size: 9.2pt, it,
)

#show figure: set block(breakable: true)
#set table(
  stroke: 0.4pt + luma(200),
  inset: 6pt,
  align: (x, y) => left + horizon,
)

// ---------- caixas ----------
#let caixa(titulo, cor, corpo) = block(
  width: 100%, breakable: true, above: 0.9em, below: 0.9em,
  fill: cor.lighten(93%), stroke: (left: 2.5pt + cor),
  inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt), radius: 2pt,
  [
    #text(weight: "bold", fill: cor.darken(5%), size: 9.5pt)[#upper(titulo)]
    #v(-3pt)
    #corpo
  ],
)

#let objetivos(corpo)   = caixa("Objetivos desta sessão", azul, corpo)
#let atencao(corpo)     = caixa("⚠ Atenção", vermelho, corpo)
#let perigo(corpo)      = caixa("⛔ Segurança — leia antes de ligar", vermelho, corpo)
#let nota(corpo)        = caixa("Observação", luma(90), corpo)
#let tarefa(corpo)      = caixa("Tarefa", laranja, corpo)
#let experimento(corpo) = caixa("✎ Experimente e anote", verde, corpo)
#let conceito(corpo)    = caixa("Conceito central", roxo, corpo)
#let bancada(corpo)     = caixa("Configuração de bancada", verde, corpo)
#let divergencia(corpo) = caixa("📕 Divergência do manual", marrom, corpo)
#let semnota(corpo)     = caixa("Por que esta sessão não tem nota", roxo, corpo)

// ---------- título ----------
#align(center)[
  #text(size: 9.5pt, fill: luma(110), tracking: 1.2pt)[MICROCONTROLADORES --- PRÁTICA]
  #v(2pt)
  #text(size: 19pt, weight: "bold", fill: azul)[Oficina 1 --- Bancada, Segurança e Instrumentação]
  #v(1pt)
  #text(size: 11pt, fill: luma(80), style: "italic")[Reconhecimento do kit XM118, multímetro e osciloscópio]
  #v(4pt)
  #text(size: 9.5pt, fill: luma(100))[
    Raoni F. S. Teixeira · Rodolfo Quadros · DENE/UFMT · 1 sessão (2 h) · sem nota · grupos de 3
  ]
  #v(-2pt)
  #line(length: 100%, stroke: 0.6pt + azul)
]
#v(4pt)

#objetivos[
  Esta sessão não produz firmware. Ela produz um estudante que pode encostar em
  uma bancada energizada sem danificar equipamento nem a si mesmo. Ao final, o
  grupo deve ser capaz de:

  + Localizar, no kit XM118, as seções, os bancos de chaves e os pontos de teste
    que serão usados no semestre inteiro;
  + Ligar e desligar a bancada na ordem correta;
  + Explicar por que a garra de terra do osciloscópio não pode ser presa em
    qualquer ponto do circuito;
  + Medir uma tensão contínua com o multímetro e identificar os trilhos de 5 V e
    de 12 V do kit;
  + Justificar por que a serigrafia da placa tem precedência sobre o manual do
    fabricante.
]

#semnota[
  As três primeiras sessões do semestre são oficinas: sem entrega, sem previsão
  registrada e sem ponto. O motivo é simples --- é aqui que você deve errar. Um
  erro na Oficina 1 custa uma conversa; o mesmo erro no Roteiro 6, com o
  osciloscópio na mão e a nota valendo, custa um equipamento.

  O que se cobra aqui é presença ativa: o caderno de bancada preenchido, as
  perguntas anotadas e a bancada devolvida na configuração em que foi encontrada.
]

= A bancada antes da energia

Antes de qualquer coisa, uma ordem de operações. Ela parece burocrática e é
exatamente o que separa uma sessão de laboratório de um conserto.

#figure(
  table(
    columns: (auto, 1fr, 1.4fr),
    table.header([*\#*], [*Ao ligar*], [*Por quê*]),
    [1], [Kit desligado, chave traseira em OFF], [Nenhuma configuração se faz com o circuito energizado],
    [2], [Cabo de força tripolar no estabilizador, com o pino de terra], [O terceiro pino habilita as proteções contra surto],
    [3], [Todas as chaves DIP em OFF, incluindo os bancos CH1 a CH5], [Estado conhecido; nenhum periférico disputa pino],
    [4], [Cabo USB na porta *frontal* (CN9)], [A traseira não é a porta do bootloader],
    [5], [Chave traseira em ON], [Só agora existe tensão na placa],
    [6], [Conferir os LEDs indicadores de alimentação], [Confirma que a fonte partiu],
  ),
  caption: [Ordem de energização da bancada.],
)

Para desligar, a ordem inversa: chave traseira em OFF, depois USB, depois cabo
de força. Nunca se retira o USB de um kit energizado com firmware gravando.

#perigo[
  *O pino de terra do cabo de força não se remove, não se dobra e não se
  substitui por adaptador de dois pinos.* Ele não é uma inconveniência mecânica:
  é o caminho de escoamento que protege o instrumento e o operador. Um cabo com
  o pino de terra removido transforma a carcaça metálica do equipamento em algo
  cujo potencial ninguém pode garantir.

  Se você encontrar na bancada um cabo nessas condições, não use o equipamento e
  avise o professor. Não é zelo excessivo --- é a diferença entre um
  laboratório e um improviso.
]

= Anatomia do XM118

O kit tem mais periféricos do que o PIC18F4550 tem pinos. Essa frase é a chave
de tudo o que vem a seguir: os periféricos *disputam* pinos, e quem arbitra a
disputa são as chaves DIP.

#tarefa[
  Com o kit desligado, localize e anote no caderno a posição física de cada item.
  Desenhe um esboço da placa --- o desenho feito à mão é o que você vai consultar
  no resto do semestre, não a foto do manual.

  + O microcontrolador: circuito integrado de 40 pinos, seção `MICROCONTROLLER`;
  + Os bancos de chaves DIP `CH1` a `CH5` e a chave `U8`;
  + A seção `PUSH BUTTONS` e, dentro dela, o botão `RESET`;
  + Os oito LEDs da seção `LEDS`;
  + O display LCD alfanumérico;
  + Os displays de sete segmentos;
  + A ventoinha (`COOLER`) e a resistência de aquecimento (`HEATER`);
  + O conector USB frontal (`CN9`) e o DB9 da seção `RS232`;
  + Os pontos de teste, em especial `COOLER`, `HEATER`, `LAMP`, `SPEED` e os
    pontos de `GND`.
]

== Os botões e o que a serigrafia diz

A seção `PUSH BUTTONS` fica na metade inferior da placa, à direita do gerador de
frequência. São seis botões em três linhas de dois:

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    table.header([], [*Coluna esquerda*], [*Coluna direita*]),
    [Linha 1], [`CH0` (SW11)], [`INT2` (SW14)],
    [Linha 2], [`TMR1` (SW10)], [`INT1` (SW13)],
    [Linha 3], [`RESET` (SW9)], [`INT0` (SW12)],
  ),
  caption: [Disposição dos botões na seção `PUSH BUTTONS`.],
)

O reset é o botão inferior esquerdo, com a palavra `RESET` impressa acima dele.
Você vai apertá-lo algumas centenas de vezes neste semestre --- vale localizá-lo
sem olhar.

#divergencia[
  O manual da Exsto numera esses botões como SW1 a SW6. A serigrafia da placa usa
  SW9 a SW14. E há mais: uma tabela traz o cabeçalho PIC18F4520 sob legenda que
  diz PIC18F4550; outra lista o pino RA3 duas vezes com funções diferentes; e a
  nota sobre gravação inverte PGC e PGD em relação ao datasheet da Microchip.

  A regra de convivência é esta: *documentação de fabricante é fonte útil, não
  verdade revelada. Quando ela discorda do equipamento, o equipamento vence.*
  Essa postura não vale só para a Exsto --- vale para todo datasheet, errata e
  nota de aplicação que você vai ler na vida profissional.
]

== As chaves DIP são um mapa de conflitos

Cada banco de chaves conecta ou desconecta um periférico de um grupo de pinos.
Ligar duas coisas que compartilham o mesmo pino não gera mensagem de erro:
gera comportamento inexplicável, e às vezes corrente onde não deveria haver.

#figure(
  table(
    columns: (1.1fr, 1.5fr),
    table.header([*Conflito*], [*Sintoma quando acontece*]),
    [Relé e comunicação serial disputando RC6/RC7], [A serial para de funcionar quando o relé é habilitado, ou o relé chaveia sozinho durante a transmissão],
    [Comuns dos displays de sete segmentos sobre RE0/RE2], [O LCD passa a escrever lixo ou não responde a comandos],
    [Chaves de PORTB ligadas junto com os botões de interrupção], [Entradas lidas com valor fixo; interrupção que nunca dispara ou dispara sempre],
    [Chaves que curto-circuitam saídas de PWM], [Sinal de controle sem amplitude, atuador que não responde ao duty],
  ),
  caption: [Conflitos de recurso documentados no XM118.],
)

#conceito[
  Nenhum desses conflitos é defeito do kit. Eles são a materialização didática
  de um problema real de projeto: *um microcontrolador tem menos pinos do que
  funções, e escolher a alocação de pinos é uma decisão de engenharia com
  consequências.* Em um projeto seu, o banco de chaves DIP não existirá --- a
  decisão terá sido tomada na placa, e errá-la custa uma revisão de layout.

  Por isso todo roteiro deste semestre começa com uma caixa de configuração de
  bancada. Ela é o contrato de pinos daquela sessão.
]

#experimento[
  Ligue o kit sem nada conectado, com todas as chaves em OFF, e anote:

  + Os LEDs indicadores de alimentação acendem?
  + O LCD acende? Aparece alguma coisa escrita?
  + A ventoinha liga sozinha?

  A terceira pergunta é a mais interessante das três, e ela volta na Oficina 2.
  Não tente explicá-la agora --- apenas registre o que viu.
]

= Multímetro: os dois trilhos de tensão

O kit trabalha com *dois* níveis de tensão, e confundi-los é a origem de quase
todo acidente de bancada nesta disciplina.

#figure(
  table(
    columns: (auto, 1fr, 1.3fr),
    table.header([*Trilho*], [*Onde aparece*], [*Quem alimenta*]),
    [+5 V], [Pinos do PIC18F4550, LEDs, LCD, chaves], [Toda a lógica digital],
    [+12 V], [Pontos `COOLER`, `HEATER`, `LAMP`], [Cargas de potência: ventoinha, resistência, lâmpada],
    [GND], [Pontos de terra da placa], [Referência comum das duas],
  ),
  caption: [Trilhos de tensão do XM118.],
)

#tarefa[
  Com o multímetro na escala de tensão contínua, ponta preta em um ponto de
  `GND` da placa:

  + Meça a tensão de alimentação da lógica. Anote o valor lido com duas casas.
  + Meça um dos pontos de carga com o atuador desligado. Anote.
  + Compare os dois valores e escreva, em uma frase, por que eles são diferentes.

  Depois, inverta o raciocínio: se você prendesse a ponta preta no ponto de 12 V
  em vez de no terra, o que o multímetro leria ao medir o trilho de 5 V?
  Responda antes de testar --- e pode testar, porque o multímetro é um
  instrumento de alta impedância e essa inversão não danifica nada.

  Guarde essa última observação. Ela deixa de ser verdadeira na próxima seção.
]

= Osciloscópio: a seção mais importante desta oficina

O osciloscópio é o instrumento que transforma esta disciplina de adivinhação em
medição. É também o único equipamento da bancada que um erro de conexão destrói
em menos de um segundo.

== A ponta de prova tem dois condutores

Uma ponta de osciloscópio tem a ponteira, que toca o sinal, e uma *garra de
terra*, que é a malha do cabo coaxial. Essa garra não é um acessório opcional
para "melhorar a leitura": ela é eletricamente a carcaça do osciloscópio, e a
carcaça está ligada ao terra da rede pelo terceiro pino do cabo de força.

#perigo[
  *A garra de terra do osciloscópio só pode ser presa em um ponto de GND.*

  Se você prendê-la em `COOLER`, `HEATER` ou `LAMP` --- que carregam 12 V ---
  você acabou de ligar 12 V ao terra da rede elétrica através da malha do cabo
  da ponta. Isso é um curto-circuito franco. O resultado não é uma leitura
  errada: é a fonte do kit, a ponta de prova ou a entrada do osciloscópio
  danificados, com faísca e cheiro de queimado.

  Não existe configuração no menu do osciloscópio que evite isso. Não adianta
  mudar de canal, de escala ou de acoplamento.
]

#nota[
  Esse acidente já aconteceu nesta bancada. A "solução" adotada na ocasião ---
  remover o pino de terra do cabo de força do osciloscópio para que a garra
  pudesse ser presa em qualquer lugar --- é *pior que o problema original*: ela
  não elimina o curto, apenas transfere o risco do equipamento para a pessoa,
  deixando a carcaça do instrumento em potencial indefinido.

  Isso está registrado aqui porque erro documentado é conteúdo, e porque a
  tentação de repetir a mesma "solução" é grande em quem só conhece o sintoma.
]

== Como medir o que está acima do terra

Se você precisa observar a tensão sobre uma carga alimentada em 12 V, a garra
continua no `GND` e a ponteira vai ao ponto do sinal. Você lê o potencial do
ponto *em relação ao terra*, que é o que interessa em quase todos os casos deste
curso --- inclusive na observação do PWM.

Quando o que interessa é a diferença entre dois pontos e nenhum deles é o terra,
a resposta correta é usar dois canais e a função de subtração do aparelho, ou uma
ponta diferencial. A resposta incorreta, e frequente, é mover a garra.

#tarefa[
  Ainda sem gravar nada no kit, monte a seguinte medição:

  + Ajuste a ponta e o canal para atenuação de 10×. Confira que o valor
    configurado no menu do osciloscópio é o mesmo que está na chave da ponta ---
    discordância entre os dois é a causa de toda leitura com fator dez de erro.
  + Faça a compensação da ponta no terminal de onda quadrada do próprio
    osciloscópio, ajustando o trimmer até o topo do sinal ficar reto.
  + Prenda a garra em um `GND` da placa e observe o trilho de 5 V. Ajuste base de
    tempo e escala vertical até obter uma linha estável.
  + Use a medição automática do aparelho para ler o valor médio.

  Anote a sequência de botões que você usou. Na Oficina 2 você vai repeti-la sem
  o roteiro.
]

#conceito[
  Há um ponto de teste no kit chamado `SPEED` que parece ser o sinal de controle
  da ventoinha e não é: ele carrega os pulsos do tacômetro, isto é, a resposta
  --- quantas voltas o rotor deu. O sinal de controle está em outro ponto.

  Medir a variável errada e concluir sobre o sistema a partir dela é um erro que
  não aparece na tela: a forma de onda existe, é bonita e é irrelevante. A
  pergunta que precede qualquer medição é sempre a mesma: *este ponto é a causa
  ou o efeito?*
]

= Fechamento

#tarefa[
  Antes de sair, devolva a bancada ao estado inicial:

  + Todas as chaves DIP em OFF;
  + Kit desligado pela chave traseira, depois USB, depois força;
  + Pontas de prova enroladas, garras livres, sem nada preso à placa;
  + Multímetro desligado --- e não deixado na escala de corrente.
]

#tarefa[
  *Para a Oficina 2.* Traga escrito, em duas ou três linhas: o que você acha que
  acontece com um pino do microcontrolador entre o instante em que a alimentação
  chega e o instante em que o seu programa começa a rodar? Ele está em nível
  alto, baixo, ou nenhum dos dois?

  Não pesquise. A hipótese errada com raciocínio explícito é material de aula ---
  e vale exatamente tanto quanto a certa.
]
