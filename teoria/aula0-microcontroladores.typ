// ============================================================
//  MICROCONTROLADORES — Aula 0
//  Apresentação e Panorama dos Dispositivos Programáveis
// ============================================================

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 0])
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira],
      align(right)[#context counter(page).display("1")])
  ],
)

#set text(font: ("Linux Libertine", "New Computer Modern", "Georgia"), size: 11pt, lang: "pt")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#show heading: set block(below: 1.3em, above: 1.7em)

#let azul     = rgb("#003366")
#let destaque = rgb("#1a6bad")
#let cinza    = luma(245)
#let vermelho = rgb("#b04020")
#let verde    = rgb("#1a6b1a")
#let roxo     = rgb("#5a0080")
#let laranja  = rgb("#805000")

#show heading.where(level: 1): it => { set text(fill: azul, size: 15pt); it }
#show heading.where(level: 2): it => { set text(fill: destaque, size: 12pt); it }
#show figure: set block(breakable: true)

#let caixa(titulo, cor-borda, cor-fundo, corpo) = block(
  width: 100%, fill: cor-fundo,
  stroke: (left: 3pt + cor-borda),
  inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt),
  radius: (right: 3pt),
)[#text(weight: "bold", fill: cor-borda)[#titulo] \ #corpo]

#let objetivos(corpo)  = caixa("Objetivos da aula", azul, rgb("#eef2f7"), corpo)
#let definicao(t, c)   = caixa("Definição --- " + t, roxo, rgb("#f7f0fa"), c)
#let exemplo(corpo)    = caixa("Exemplo", verde, rgb("#f1f8f1"), corpo)
#let atencao(corpo)    = caixa("Atenção", vermelho, rgb("#fdf2f0"), corpo)
#let observacao(corpo) = caixa("Observação", destaque, rgb("#f0f6fb"), corpo)
#let exercicio(n, c)   = caixa("Exercício " + n, laranja, rgb("#fdf8ef"), c)

#let cab(txt) = text(fill: white, weight: "bold", size: 9.5pt)[#txt]

// ============================================================

#align(center)[
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 0 --- Apresentação e Panorama] \
  #v(0.2em)
  #text(size: 12pt)[Onde o microcontrolador se encaixa entre os dispositivos programáveis] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Situar a disciplina: o que será estudado, em que ordem, como será avaliado
    e como o componente teórico se articula com o laboratório.
  - Distinguir microprocessador, microcontrolador, processador digital de
    sinais, sistema em chip e dispositivo lógico programável a partir de
    critérios objetivos, e não de nomes comerciais.
  - Separar três coisas que a linguagem cotidiana confunde: o *chip*, o
    *módulo* e a *placa*.
  - Justificar a escolha de uma plataforma a partir dos requisitos de um
    projeto, reconhecendo que não existe categoria universalmente superior.
]

= Por que esta aula existe

Um estudante que chega a esta disciplina já ouviu falar de Arduino, de Raspberry
Pi, talvez de ESP32. Provavelmente já montou algum circuito com um desses.
Quase sempre, porém, esses nomes chegam misturados: são tratados como se fossem
objetos do mesmo tipo, escolhidos por preferência pessoal ou por qual deles
apareceu primeiro no tutorial que se estava seguindo.

Não são objetos do mesmo tipo. Um deles é uma placa que carrega um
microcontrolador; outro é um computador completo que executa um sistema
operacional de propósito geral; o terceiro é um sistema em chip com rádio
integrado. Confundi-los não é uma imprecisão de vocabulário: leva a decisões de
projeto ruins, do tipo que só se manifestam quando o protótipo precisa virar
produto --- e aí custam caro.

Esta aula estabelece o vocabulário e os critérios. Ela abre uma pergunta que a
disciplina inteira responde e que o último encontro retoma explicitamente:
*dado um problema, como se escolhe a plataforma?*

= Sistemas embarcados

#definicao("sistema embarcado")[
  Sistema computacional dedicado a uma função específica, integrado ao
  equipamento que ele controla, em geral sujeito a restrições de custo, consumo,
  tamanho ou tempo de resposta, e cuja existência não é percebida pelo usuário
  como "um computador".
]

A definição parece vaga, e é --- deliberadamente. O que caracteriza o campo não
é uma fronteira nítida, mas um conjunto de consequências práticas que
distinguem esse tipo de projeto da programação de aplicativos:

- *Os recursos são contados.* Não há memória virtual, não há disco para paginar.
  Se o programa não cabe nos kilobytes disponíveis, ele não é executado --- e o
  compilador informa isso na linha do mapa de memória, não em tempo de execução.
- *O tempo é parte da especificação.* Responder corretamente 50 ms depois do
  necessário pode ser tão inútil quanto responder errado. Determinismo importa
  mais do que desempenho médio.
- *Não há operador.* O sistema precisa iniciar sozinho, tratar falhas sozinho e
  se recuperar sozinho. Não existe alguém para reiniciar o programa.
- *O software toca o mundo físico.* Um defeito não gera uma mensagem de erro:
  aquece uma resistência além do limite, trava um motor, descarrega uma bateria.

#observacao[
  Ao longo do semestre, o laboratório construirá um termostato digital: um
  sistema que mede temperatura, decide, aciona um aquecedor e uma ventoinha,
  mostra o estado num display e reporta por porta serial. É um sistema
  embarcado pequeno, mas completo --- e cada uma das quatro consequências acima
  aparecerá nele de forma concreta.
]

= A taxonomia: cinco categorias e os critérios que as separam

O erro comum é decorar uma lista de categorias. O que funciona é reter o
*critério* que separa cada par, porque é o critério que sobrevive quando surge
uma família nova de dispositivos.

== Microprocessador

#definicao("microprocessador (MPU)")[
  Circuito integrado que contém essencialmente a unidade central de
  processamento. Memória, periféricos e armazenamento são componentes externos,
  conectados por barramentos. Tipicamente inclui unidade de gerenciamento de
  memória, o que permite executar um sistema operacional de propósito geral com
  memória virtual e proteção entre processos.
]

O critério decisivo aqui é a *unidade de gerenciamento de memória*. É ela que
traduz endereços virtuais em físicos e isola processos entre si. Sem ela, um
Linux completo não é executável --- e é por isso que o Raspberry Pi executa
Linux e o Arduino não, uma diferença que não tem nada a ver com velocidade de
clock.

Um microprocessador sozinho não faz nada: precisa de memória externa, de
controlador de armazenamento, de alimentação em múltiplos níveis e de uma
sequência de inicialização de várias etapas. O tempo entre energizar a placa e
ter software de aplicação rodando é medido em segundos.

== Microcontrolador

#definicao("microcontrolador (MCU)")[
  Circuito integrado que reúne, no mesmo encapsulamento, o núcleo de
  processamento, a memória de programa, a memória de dados e um conjunto de
  periféricos --- portas digitais, conversores, temporizadores, interfaces de
  comunicação. Executa a partir da memória interna, sem sistema operacional
  obrigatório.
]

A palavra que define a categoria é *integração*. O microcontrolador é um
computador inteiro num único chip, projetado para ser autossuficiente. A
consequência direta: energizado, ele começa a executar o programa em
microssegundos, com comportamento temporal previsível, porque não há sistema
operacional decidindo quando cada tarefa roda.

#exemplo[
  O PIC18F4550 desta disciplina reúne, num encapsulamento de 40 pinos: núcleo de
  8 bits a até 48 MHz, 32 KB de memória de programa, 2 KB de memória de dados,
  256 B de memória não volátil, conversor analógico-digital de 10 bits com 13
  canais, dois comparadores, quatro temporizadores, dois módulos de captura e
  modulação, comunicação serial assíncrona, interfaces síncronas e um
  controlador USB. Alimentado com 5 V, ele executa o programa. Nada mais é
  necessário.
]

== Processador digital de sinais

#definicao("processador digital de sinais (DSP)")[
  Processador cuja arquitetura é otimizada para operações repetitivas de
  multiplicação e acumulação sobre fluxos de dados, tipicamente com unidade de
  multiplicação-acumulação dedicada, múltiplos barramentos de memória, aritmética
  com saturação e modos de endereçamento circulares para implementação eficiente
  de filtros.
]

O critério aqui é a *operação privilegiada em hardware*. Um filtro digital de
resposta finita ao impulso é uma soma de produtos:

$ y[n] = sum_(k=0)^(N-1) h[k] dot x[n-k] $

Num núcleo de propósito geral, cada termo custa uma multiplicação, uma soma e
duas leituras de memória, executadas em sequência. Num DSP, uma única instrução
busca os dois operandos por barramentos independentes, multiplica, acumula e
avança dois ponteiros de endereçamento circular --- em um ciclo. Para filtragem,
transformadas e controle de alta taxa de amostragem, a diferença é de ordens de
grandeza.

#observacao[
  A fronteira entre DSP e microcontrolador deixou de ser nítida. Famílias como o
  ARM Cortex-M4 e o Cortex-M7 incorporam instruções de processamento de sinais e
  unidade de ponto flutuante, ocupando um espaço intermediário. Existem também
  os chamados controladores digitais de sinais, como a família C2000 da Texas
  Instruments, que combinam periféricos de controle com desempenho de DSP. A
  categoria continua útil como descrição de ênfase arquitetural, não como caixa
  estanque.
]

== Sistema em chip

#definicao("sistema em chip (SoC)")[
  Circuito integrado que reúne, além de núcleo e memória, subsistemas completos
  que tradicionalmente ocupariam chips próprios: rádio, controlador gráfico,
  aceleradores criptográficos, interfaces de alta velocidade.
]

A categoria é definida por *escopo*, não por potência. Um sistema em chip pode
ser construído em torno de um microprocessador de aplicação --- o caso dos
processadores dos telefones celulares e do Raspberry Pi --- ou em torno de um
núcleo de microcontrolador, como o ESP32, que integra rádios Wi-Fi e Bluetooth
junto a um núcleo que, isoladamente, seria classificado como microcontrolador.

== Dispositivo lógico programável

#definicao("arranjo de portas programável em campo (FPGA)")[
  Dispositivo composto de blocos lógicos e interconexões configuráveis. Não
  executa um programa: é *configurado* para se tornar um circuito digital
  descrito em linguagem de descrição de hardware.
]

A distinção fundamental é entre *executar* e *ser*. Um microcontrolador executa
instruções em sequência; um FPGA torna-se o circuito descrito, com todos os
blocos operando simultaneamente em hardware real. Isso lhe dá paralelismo
verdadeiro e latência determinística na casa dos nanossegundos, ao custo de
maior complexidade de projeto, maior consumo e preço mais alto.

É comum, hoje, sintetizar um núcleo de processador dentro do FPGA --- um núcleo
sintetizado, ou #emph[soft-core], frequentemente com conjunto de instruções
RISC-V. Nesse caso o dispositivo executa software *e* implementa lógica
dedicada, e as categorias voltam a se misturar.

#figure(
  table(
    columns: (1.2fr, 1fr, 1fr, 1.2fr, 1.1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Critério], cab[MPU], cab[MCU], cab[DSP], cab[FPGA]),
    [Memória principal], [Externa], [Interna], [Interna ou externa], [Blocos internos],
    [Gerenciamento de memória], [Sim], [Não], [Em geral não], [Não se aplica],
    [Executa Linux completo], [Sim], [Não], [Não], [Só com núcleo sintetizado],
    [Tempo até executar], [Segundos], [Microssegundos], [Microssegundos], [Milissegundos],
    [Determinismo temporal], [Baixo], [Alto], [Alto], [Muito alto],
    [Paralelismo], [Por escalonamento], [Periféricos autônomos], [Unidades dedicadas], [Real],
    [Uso típico], [Interface, rede, dados], [Controle, aquisição], [Filtragem, controle rápido], [Lógica dedicada, alta taxa],
  ),
  caption: [Critérios que separam as categorias. A linha decisiva é a segunda.],
) <tab-taxonomia>

= Chip, módulo e placa

Esta é a confusão mais frequente, e a mais fácil de desfazer.

#definicao("os três níveis")[
  *Chip* --- o circuito integrado propriamente dito. Exemplos: PIC18F4550,
  ATmega328P, STM32F407, RP2040. \
  *Módulo* --- um chip acompanhado dos componentes mínimos para operar
  (oscilador, regulador, antena, memória externa), pronto para ser soldado em
  outra placa. Exemplo: ESP32-WROOM-32. \
  *Placa de desenvolvimento* --- um módulo ou chip montado sobre uma placa com
  conectores, gravador, regulação e proteção, destinada a experimentação.
  Exemplos: Arduino Uno, Raspberry Pi Pico, kit Exsto XM118.
]

#atencao[
  "Arduino" não é um microcontrolador. É uma placa --- e, mais do que isso, um
  ambiente de programação e um ecossistema de bibliotecas. O microcontrolador do
  Arduino Uno é o ATmega328P, da Microchip. Dizer "usei um Arduino" descreve o
  ambiente de trabalho, não o dispositivo: o mesmo ATmega328P pode ser usado sem
  nenhuma camada Arduino, e o ambiente Arduino pode programar dezenas de chips
  diferentes, inclusive ESP32 e placas com ARM Cortex-M.
]

A tabela abaixo desfaz a confusão em casos concretos.

#figure(
  table(
    columns: (1.1fr, 1fr, 1.5fr, 1.3fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Nome usual], cab[O que é], cab[Chip que carrega], cab[Categoria do chip]),
    [Arduino Uno], [Placa], [ATmega328P], [Microcontrolador de 8 bits],
    [Raspberry Pi 4], [Placa (computador)], [Broadcom BCM2711], [SoC com processador de aplicação],
    [Raspberry Pi Pico], [Placa], [RP2040], [Microcontrolador de 32 bits],
    [ESP32 DevKit], [Placa], [Módulo com SoC ESP32], [SoC com núcleo de microcontrolador],
    [STM32 "Blue Pill"], [Placa], [STM32F103], [Microcontrolador ARM Cortex-M3],
    [Kit Exsto XM118], [Placa didática], [PIC18F4550], [Microcontrolador de 8 bits],
  ),
  caption: [O nome popular quase nunca é o nome do chip.],
) <tab-placas>

#observacao[
  O Raspberry Pi Pico ilustra bem por que a distinção importa. Ele leva a marca
  Raspberry Pi, mas não tem parentesco funcional com o Raspberry Pi 4: não
  executa Linux, não tem gerenciamento de memória, e é conceitualmente muito mais
  próximo do PIC18F4550 desta disciplina do que do computador que compartilha seu
  nome comercial.
]

= Ordens de grandeza

Números ajudam a calibrar a intuição. Todos os valores abaixo são aproximados e
servem para comparação relativa, não para especificação de projeto.

#figure(
  table(
    columns: (1.3fr, 1fr, 0.9fr, 0.9fr, 1.2fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Dispositivo], cab[Núcleo], cab[Clock], cab[RAM], cab[Categoria]),
    [PIC18F4550], [8 bits], [48 MHz], [2 KB], [MCU],
    [ATmega328P], [8 bits], [20 MHz], [2 KB], [MCU],
    [STM32F103], [Cortex-M3], [72 MHz], [20 KB], [MCU],
    [STM32F407], [Cortex-M4F], [168 MHz], [192 KB], [MCU],
    [RP2040], [2× Cortex-M0+], [133 MHz], [264 KB], [MCU],
    [ESP32], [2× 32 bits], [240 MHz], [520 KB], [SoC],
    [BCM2711 (Pi 4)], [4× Cortex-A72], [1,5 GHz], [Externa, GB], [SoC/MPU],
  ),
  caption: [Ordens de grandeza. Note o salto de três ordens na última linha.],
) <tab-ordens>

Duas leituras valem mais do que os números isolados. A primeira: entre a
primeira e a penúltima linha há um fator de aproximadamente 250 em memória de
dados, e ainda assim ambos os dispositivos são microcontroladores --- a
categoria é ampla. A segunda: o salto real não está no clock, está na última
coluna. Um Cortex-A72 e um Cortex-M4 pertencem a mundos diferentes não por
serem mais ou menos rápidos, mas porque um tem gerenciamento de memória e o
outro não.

= Como se escolhe uma plataforma

Não existe categoria universalmente superior. A escolha decorre dos requisitos,
e os critérios recorrentes são estes:

+ *Determinismo exigido.* Se a resposta a um evento precisa ocorrer dentro de
  uma janela garantida, um microcontrolador sem sistema operacional é a resposta
  natural. Um Linux de propósito geral não oferece essa garantia sem
  configuração específica.
+ *Consumo.* Um microcontrolador em modo de baixo consumo opera na casa dos
  microampères; um processador de aplicação, na de centenas de miliampères.
  Alimentação por bateria costuma decidir sozinha a questão.
+ *Complexidade da interface e da conectividade.* Interface gráfica rica, pilha
  de rede completa, sistema de arquivos e atualização remota puxam para
  processador de aplicação ou sistema em chip.
+ *Volume de produção e custo unitário.* Em volume alto, alguns reais por
  unidade decidem o projeto. Em volume baixo, o custo de engenharia domina, e
  vale mais escolher a plataforma cujas ferramentas a equipe já domina.
+ *Ecossistema, documentação e longevidade.* Disponibilidade de compilador,
  depurador, bibliotecas e --- item frequentemente esquecido --- garantia de
  fornecimento do componente por anos.

#exemplo[
  *Termostato de um forno industrial.* Requisitos: leitura de temperatura a cada
  200 ms, acionamento de resistência, display simples, registro de eventos,
  operação contínua sem operador. Não há interface gráfica, não há rede, o
  consumo não é crítico, mas o determinismo e a confiabilidade são. \
  #v(0.4em)
  Um microcontrolador de 8 ou 32 bits resolve com folga. Um processador de
  aplicação executando Linux resolveria também, mas acrescentaria inicialização
  de segundos, um sistema de arquivos que pode corromper em queda de energia e
  um custo várias vezes maior --- sem oferecer nada que o requisito peça.
]

= Onde o PIC18F4550 se situa --- e por que ele

O PIC18F4550 é um microcontrolador de 8 bits com arquitetura Harvard, lançado em
meados dos anos 2000. Não é o que se escolheria hoje para um produto novo: um
Cortex-M0+ moderno custa o mesmo ou menos, oferece mais memória, mais desempenho
e ferramentas melhores.

A escolha aqui é *didática*, e o argumento é honesto:

- *Ele cabe na cabeça.* A folha de dados descreve cada registrador bit a bit, e
  todos podem ser configurados manualmente. Numa plataforma moderna, a mesma
  tarefa passa por camadas de abstração que escondem justamente o que se quer
  ensinar.
- *A relação entre código e hardware é direta.* Escrever num registrador muda o
  estado de um pino, e essa cadeia causal é visível e mensurável. É a base para
  entender qualquer plataforma depois.
- *Ele está no laboratório.* Os kits existem, funcionam e têm uma planta térmica
  real --- aquecedor, ventoinha e sensor --- que permite fazer controle de
  verdade em vez de simulação.

#atencao[
  O que se aprende aqui *não* é PIC. São conceitos que reaparecem em qualquer
  arquitetura: amostragem e quantização, base de tempo por temporizador,
  modulação por largura de pulso, latência de interrupção, protocolo serial,
  código não bloqueante. O que muda de plataforma para plataforma são os nomes
  dos registradores --- e essa é a parte descartável do conhecimento. O último
  encontro e os seminários fazem essa separação explicitamente.
]

= O mapa da disciplina

O componente teórico segue uma progressão em duas cadeias. A primeira, dos
encontros 1 a 6, é a *cadeia analógica*: do pino digital ao conversor, do
conversor ao comparador, e do comparador à decisão de controle. A segunda, dos
encontros 7 a 12, é a *cadeia temporal e de comunicação*: temporizadores,
modulação, interrupções, comunicação serial e máquinas de estado. O encontro 13
integra as duas e faz a transposição para arquiteturas de 32 bits.

O laboratório, iniciado uma semana depois, constrói um único sistema ao longo
do semestre. Cada roteiro acrescenta uma camada ao mesmo código: primeiro o
pino, depois o display, depois a leitura de temperatura, o controle, a atuação
modulada, as interrupções, a telemetria e o teclado. Nenhum roteiro descarta o
anterior.

#observacao[
  *Avaliação.* Minitestes ao final dos encontros, sempre sobre o conteúdo do
  encontro *anterior* (peso 3,0; as duas piores notas são descartadas); duas
  avaliações integradoras, nos encontros 7 e 13 (peso 2,0 cada, sem descarte); e
  um seminário em duplas nos encontros 14 e 15 (peso 3,0). O detalhamento está
  no plano de ensino.
]

= Exercícios

#exercicio("0.1")[
  Um colega afirma: "para esse projeto vou usar um Arduino, porque Raspberry Pi
  é caro demais". Aponte o que há de impreciso na frase do ponto de vista de
  vocabulário técnico e reescreva-a de modo a nomear corretamente os objetos
  comparados.
]

#exercicio("0.2")[
  Explique, sem recorrer a velocidade de clock ou quantidade de memória, por que
  o Raspberry Pi 4 executa Linux e o Raspberry Pi Pico não. Identifique o
  recurso de hardware decisivo e diga o que ele faz.
]

#exercicio("0.3")[
  Considere um medidor de vibração portátil, alimentado por bateria, que deve
  amostrar um acelerômetro a 10 kHz, calcular continuamente a transformada de
  Fourier de janelas de 1024 amostras e acionar um alarme quando certa faixa de
  frequência exceder um limiar. Discuta qual categoria de dispositivo é mais
  adequada e quais requisitos sustentam sua escolha. Indique também qual seria a
  segunda melhor opção e o que se perderia com ela.
]

#exercicio("0.4")[
  A @tab-ordens mostra que o STM32F407 tem cerca de cem vezes mais memória de
  dados que o PIC18F4550, e ambos são classificados como microcontroladores.
  Argumente por que a classificação continua correta, apontando qual critério da
  @tab-taxonomia é decisivo e por que a quantidade de memória não é.
]
