// ============================================================
//  MICROCONTROLADORES — Componente Teórico
//  Plano de Ensino e Programa (32 h)
//  DENE / UFMT
// ============================================================

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores — Teoria], align(right)[Plano de Ensino])
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira — DENE/UFMT],
      align(right)[#context counter(page).display("1")])
  ],
)

#set text(font: ("Linux Libertine", "New Computer Modern", "Georgia"), size: 11pt, lang: "pt")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#show heading: set block(below: 1.4em, above: 1.8em)

#let azul     = rgb("#003366")
#let destaque = rgb("#1a6bad")
#let cinza    = luma(245)
#let vermelho = rgb("#b04020")
#let verde    = rgb("#1a6b1a")
#let laranja  = rgb("#805000")

#show heading.where(level: 1): it => {
  set text(fill: azul, size: 15pt)
  it
}
#show heading.where(level: 2): it => {
  set text(fill: destaque, size: 12pt)
  it
}

#let caixa(titulo, cor-borda, cor-fundo, corpo) = block(
  width: 100%, fill: cor-fundo,
  stroke: (left: 3pt + cor-borda),
  inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt),
  radius: (right: 3pt),
)[#text(weight: "bold", fill: cor-borda)[#titulo] \ #corpo]

#let atencao(corpo)   = caixa("Atenção", vermelho, rgb("#fdf2f0"), corpo)
#let nota(corpo)      = caixa("Nota", destaque, rgb("#f0f6fb"), corpo)
#let principio(corpo) = caixa("Princípio", verde, rgb("#f1f8f1"), corpo)
#let decisao(corpo)   = caixa("Decisão pendente", laranja, rgb("#fdf8ef"), corpo)

#show figure: set block(breakable: true)
#set table(inset: 6pt)

#let cab(txt) = text(fill: white, weight: "bold", size: 9.5pt)[#txt]

// ============================================================

#align(center)[
  #text(size: 20pt, weight: "bold", fill: azul)[Microcontroladores] \
  #v(0.2em)
  #text(size: 13pt)[Componente Teórico --- Plano de Ensino e Programa] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[
    Departamento de Engenharia Elétrica --- Universidade Federal de Mato Grosso
  ]
]

#v(1em)

= Identificação

#figure(
  table(
    columns: (auto, 1fr),
    fill: (col, row) => if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 7pt, align: left,
    [*Disciplina*], [Microcontroladores --- componente teórico],
    [*Carga horária*], [32 h --- 16 encontros de 2 h],
    [*Componente associado*], [Microcontroladores --- laboratório (32 h), ministrado pelo mesmo docente],
    [*Plataforma*], [PIC18F4550 (kit Exsto XM118); MPLAB X + XC8],
    [*Docente*], [Prof. Raoni F. S. Teixeira],
    [*Semestre*], [#h(4em)],
  ),
  caption: [Identificação da disciplina.],
)

= Ementa

Arquitetura de sistemas embarcados e classificação de dispositivos programáveis:
microprocessador, microcontrolador, processador digital de sinais e sistema em
chip. Organização interna do microcontrolador: núcleo, memórias, periféricos e
oscilador. Entrada e saída digital. Interfaceamento com dispositivos externos.
Conversão analógico-digital e comparação analógica. Temporizadores, geração de
sinais modulados em largura de pulso e acionamento de cargas. Sistema de
interrupções, prioridade e latência. Mecanismos de reinicialização, cão de
guarda e modos de baixo consumo. Memória não volátil interna. Comunicação serial
assíncrona e protocolos de aplicação. Interface homem-máquina e máquinas de
estado finito. Programação em C para sistemas embarcados. Estudo de caso
integrado e comparação com arquiteturas contemporâneas.

= Objetivos

== Objetivo geral

Capacitar o estudante a projetar, implementar e avaliar sistemas embarcados
baseados em microcontroladores, compreendendo os periféricos não como recursos
de um fabricante específico, mas como abstrações recorrentes que reaparecem em
qualquer arquitetura.

== Objetivos específicos

Ao final da disciplina, espera-se que o estudante seja capaz de:

+ Distinguir microcontrolador, microprocessador, processador digital de sinais,
  sistema em chip e placa de desenvolvimento, justificando a escolha de
  plataforma a partir de requisitos de projeto.
+ Interpretar o mapa de memória e a folha de dados de um microcontrolador,
  localizando registradores e traduzindo descrições de hardware em código.
+ Configurar e empregar os periféricos fundamentais --- portas digitais,
  conversor analógico-digital, comparadores, temporizadores, modulação por
  largura de pulso, interrupções e comunicação serial assíncrona.
+ Avaliar criticamente soluções em hardware e em software para um mesmo
  problema, considerando custo computacional, determinismo e complexidade.
+ Estruturar firmware não bloqueante em C, com separação em módulos, uso
  correto de `volatile` e proteção de seções críticas.
+ Transpor os conceitos estudados para arquiteturas modernas, identificando o
  que é conceito transferível e o que é particularidade da família estudada.

= Plataforma e posicionamento pedagógico

A disciplina utiliza o PIC18F4550, presente nos kits Exsto XM118 do laboratório.
Trata-se de uma arquitetura de 8 bits consolidada, cuja documentação e
simplicidade de configuração favorecem a leitura direta de registradores ---
prática que se perde quando se parte de bibliotecas de abstração.

#principio[
  A escolha da plataforma é instrumental, não doutrinária. Cada periférico é
  apresentado primeiro como conceito --- o que é um conversor de aproximações
  sucessivas, o que é um temporizador, o que é um vetor de interrupção --- e só
  então como conjunto de registradores. O encontro final e os seminários
  fecham explicitamente essa transposição para ARM Cortex-M, RISC-V e ESP32.
]

= Programa e agenda dos encontros

A agenda abaixo pressupõe 16 encontros semanais de 2 h. A coluna à direita
indica o roteiro de laboratório executado na mesma semana, uma vez que os dois
componentes são conduzidos de forma coordenada.

#figure(
  table(
    columns: (auto, 2.6fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Enc.], cab[Tema e conteúdo], cab[Laboratório na semana]),

    [0], [*Apresentação e panorama.* Plano de ensino, avaliação e bibliografia.
      Taxonomia dos dispositivos programáveis: microprocessador com unidade de
      gerenciamento de memória, microcontrolador, processador digital de sinais,
      sistema em chip, arranjo lógico programável. Chip, módulo e placa: por que
      Arduino, Raspberry Pi e ESP32 não são a mesma categoria de objeto.
      Critérios de seleção em projeto.], [---],

    [1], [*Arquitetura do PIC18 e ambiente de desenvolvimento.* Harvard,
      ciclo de máquina, oscilador e árvore de clock. Organização de memória:
      Flash, RAM com banco de acesso e registrador de seleção, memória não
      volátil. Vetores de reinicialização e de interrupção. Fluxo de compilação
      e gravação. Palavras de configuração: divisores do oscilador, cão de
      guarda e programação em baixa tensão.], [R0 --- Bancada],

    [2], [*Entrada e saída digital.* Modelo elétrico do pino. Registrador de
      direção, leitura da porta e escrita no latch --- o problema
      leitura-modificação-escrita e como o PIC18 o resolve. Seleção entre função
      analógica e digital. Ruído de contato e estratégias de filtragem.
      Limites de corrente e dimensionamento.], [R1 --- GPIO],

    [3], [*Interfaceamento paralelo e display alfanumérico.* Barramento de dados
      e sinais de controle. Controlador HD44780: inicialização, modo de quatro
      bits, temporização de escrita. Custo de espera bloqueante e a motivação
      para uma base de tempo.], [R2 --- LCD],

    [4], [*Conversão analógico-digital.* Amostragem, quantização e resolução
      efetiva. Conversor de aproximações sucessivas. Registradores de controle,
      seleção de canal, tempo de aquisição e referência de tensão. Sensor LM35 e
      representação em ponto fixo: temperatura em décimos de grau.],
      [R3 --- ADC],

    [5], [*Comparação analógica.* Comparadores internos e referência de tensão
      programável. Histerese implementada em hardware. Decisão analógica sem
      custo de processador: quando ela é preferível à conversão completa e
      quando não é.], [R3 (continuação)],

    [6], [*Ruído, filtragem e controle liga-desliga.* Média móvel e o
      compromisso entre suavização e atraso. Controle por histerese: banda
      morta, oscilação em torno do limiar, frequência de comutação do atuador.
      Comparação direta com a solução em hardware do encontro anterior.],
      [R4 --- Histerese],

    [7], [*Avaliação Integradora I* (primeira metade do encontro), sobre os
      encontros 1--6. \ *Temporizadores.* Contadores, divisor de frequência,
      pré-carga e cálculo de período. Base de tempo de 1 ms. Escalonador
      cooperativo: interrupção sinaliza, laço principal executa.],
      [R5 --- PWM],

    [8], [*Modulação por largura de pulso.* Período e ciclo ativo. Resolução
      efetiva e o compromisso com a frequência. Módulo de captura, comparação e
      modulação. Acionamento de cargas: transistor de potência, diodo de
      recirculação, filtragem para conversão em nível médio.],
      [R5 (continuação)],

    [9], [*Sistema de interrupções.* Modelo de eventos e comparação com
      varredura. Vetores de alta e baixa prioridade, habilitação de níveis,
      latência e salvamento de contexto. Sinalizadores e seu tratamento.
      Variáveis compartilhadas, palavra-chave `volatile` e seções críticas.],
      [R6 --- Interrupções],

    [10], [*Robustez e persistência.* Fontes de reinicialização e seu
      diagnóstico. Cão de guarda: função, dimensionamento e uso incorreto.
      Modos de baixo consumo e despertar por evento. Memória não volátil
      interna: ciclo de escrita, endurance e retenção.], [R6 (continuação)],

    [11], [*Comunicação serial assíncrona.* Quadro de transmissão, taxa de
      símbolos e tolerância a erro. Gerador de taxa e o modo estendido de 16
      bits. Recepção por interrupção e buffer circular. Níveis elétricos e
      conversores para o computador. Projeto de um protocolo de telemetria e de
      um interpretador de comandos.], [R7 --- Serial],

    [12], [*Interface homem-máquina e máquinas de estado.* Varredura de teclado
      matricial. Filtragem de contato por amostragem periódica. Máquinas de
      estado finito aplicadas a menu e edição de parâmetros. Organização
      modular do firmware e boas práticas de C embarcado.], [R8 --- Teclado],

    [13], [*Avaliação Integradora II* (primeira parte do encontro), sobre os
      encontros 7--12. \ *Estudo de caso integrado e transposição.* O
      termostato completo revisto como sistema. Orçamento de tempo e de memória.
      O que é conceito transferível e o que é particularidade da família:
      Cortex-M, controlador de interrupções aninhadas, camadas de abstração,
      RISC-V e ESP32.], [R8 (continuação)],

    [14], [*Seminários.* Apresentação das duplas.], [R9 --- Integração],

    [15], [*Seminários* (conclusão) e encerramento da disciplina.],
      [R9 --- Comparativo ARM],
  ),
  caption: [Agenda dos 16 encontros e coordenação com o laboratório.],
) <tab-agenda>

#atencao[
  A coordenação da @tab-agenda só se sustenta se, na grade horária semanal, *o
  encontro teórico ocorrer antes da sessão de laboratório*. Como o laboratório
  inicia uma semana depois da teoria e ocupa 15 sessões --- quatro roteiros em
  sessão dupla ---, não há folga para atrasá-lo mais. Se o horário alocado puser
  a prática antes da teoria, a alternativa é iniciar o laboratório duas semanas
  depois e reduzir o R9 a uma única sessão.
]

= Metodologia

Os encontros são expositivos e dialogados, apoiados em notas de aula próprias
distribuídas antecipadamente. Cada tópico segue a mesma progressão: o problema
de projeto que motiva o periférico, o conceito independente de fabricante, a
realização concreta no PIC18F4550 e, quando pertinente, a comparação com a
solução equivalente em arquiteturas de 32 bits.

O componente prático não repete a teoria: ele constrói, ao longo do semestre, um
único sistema --- um termostato digital com atuação modulada, display, teclado e
telemetria serial --- em que cada roteiro acrescenta uma camada. A teoria
antecede cada camada.

#nota[
  As notas de aula, as listas de exercícios e o código de referência de cada
  roteiro são publicados progressivamente. O estudante que não concluir uma
  etapa do laboratório recebe a versão de referência e consegue prosseguir na
  seguinte.
]

= Avaliação

== Instrumentos

#figure(
  table(
    columns: (2.2fr, auto, 2.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 7pt, align: left,
    table.header(cab[Instrumento], cab[Peso], cab[Quando]),
    [Minitestes], [3,0], [Ao final dos encontros 2--6 e 8--12 (dez aplicações)],
    [Avaliação Integradora I], [2,0], [Encontro 7 --- conteúdo dos encontros 1--6],
    [Avaliação Integradora II], [2,0], [Encontro 13 --- conteúdo dos encontros 7--12],
    [Seminário], [3,0], [Encontros 14 e 15],
    [*Total*], [*10,0*], [],
  ),
  caption: [Instrumentos de avaliação e respectivos pesos.],
)

A nota final é obtida por

$ "NF" = 0","3 dot overline("MT") + 0","2 dot "AI"_1 + 0","2 dot "AI"_2 + 0","3 dot "SEM" $

em que $overline("MT")$ é a média dos minitestes considerados, $"AI"_1$ e
$"AI"_2$ são as avaliações integradoras e $"SEM"$ é a nota do seminário.

== Minitestes

Aplicados nos últimos quinze minutos do encontro, os minitestes cobrem *o
conteúdo do encontro anterior*, não o do dia. A intenção é explícita: deslocar
o estudo para o intervalo entre as aulas, transformando o instrumento em
mecanismo de revisão e não apenas de medição.

São dez aplicações ao longo do semestre. #text(weight: "bold")[As duas piores
notas são descartadas], e a média é calculada sobre as oito restantes. O
descarte dispensa justificativa e absorve ausências, atrasos e imprevistos, de
modo que não há reposição de miniteste.

== Avaliações integradoras

Diferentemente dos minitestes, as duas avaliações integradoras *não admitem
descarte*: cada uma cobre metade do semestre --- a cadeia analógica nos
encontros 1--6, a cadeia temporal e de comunicação nos encontros 7--12 --- e
dispensar uma delas eliminaria a verificação de metade do conteúdo.

Cada avaliação ocupa cerca de quarenta minutos e é composta por três questões:

+ um cálculo de projeto, com folha de fórmulas fornecida --- pré-carga de
  temporizador, ciclo ativo, erro de taxa de símbolos, resolução do conversor;
+ a leitura de um trecho de firmware contendo um defeito plantado, a ser
  identificado e corrigido;
+ uma questão discursiva curta de escolha de projeto, do tipo "comparador ou
  conversor para esta especificação, e por quê".

No encontro em que há avaliação integradora não se aplica miniteste.

== Seminário

Realizado em duplas, o seminário retoma a pergunta aberta no encontro 0. Cada
dupla recebe uma plataforma --- ARM Cortex-M, RISC-V, ESP32, processador digital
de sinais da família C2000, núcleo sintetizado em arranjo lógico programável, ou
processador de aplicação executando Linux --- e responde a três perguntas:

+ o que dessa plataforma já existe, em alguma forma, no PIC18F4550;
+ o que não existe e por quê;
+ o que mudaria no projeto do termostato se ele fosse reimplementado ali.

A apresentação tem 15 minutos, seguidos de 5 minutos de arguição. Ambos os
integrantes devem responder sobre qualquer parte do trabalho. A avaliação
considera correção técnica (4,0), qualidade da comparação com a plataforma da
disciplina (3,0), clareza da apresentação e do material (2,0) e adequação ao
tempo (1,0).

#decisao[
  A distribuição dos temas do seminário deve ocorrer até o encontro 8, para que
  as duplas trabalhem em paralelo à segunda metade da disciplina. O número de
  duplas precisa ser conferido contra o tempo disponível: dez duplas a 20
  minutos consomem integralmente os encontros 14 e 15.
]

= Bibliografia

== Básica

+ PEREIRA, F. *Microcontroladores PIC18: detalhado --- hardware e software.*
  São Paulo: Érica.
+ ZANCO, W. S. *Microcontroladores PIC18 com linguagem C.* São Paulo: Érica.
+ MICROCHIP TECHNOLOGY. *PIC18F2455/2550/4455/4550 Data Sheet.* Documento
  DS39632.

== Complementar

+ SOUZA, D. J. *Desbravando o PIC.* São Paulo: Érica.
+ MICROCHIP TECHNOLOGY. *MPLAB XC8 C Compiler User's Guide.*
+ YIU, J. *The Definitive Guide to Arm Cortex-M3 and Cortex-M4 Processors.*
  Oxford: Newnes.
+ OPPENHEIM, A. V.; SCHAFER, R. W. *Discrete-Time Signal Processing.*
  Upper Saddle River: Pearson. (capítulos sobre amostragem e quantização)
+ EXSTO TECNOLOGIA. *Manual do kit XM118.*

#nota[
  Os dados bibliográficos completos --- edição, ano e local --- devem ser
  conferidos contra o acervo da biblioteca e o projeto pedagógico do curso
  antes da submissão do plano.
]

= Disposições gerais

*Frequência.* Registrada a cada encontro, conforme a norma da instituição. Como
os minitestes ocorrem em sala e admitem apenas dois descartes, a ausência
reiterada compromete diretamente a nota.

*Reposição.* Não há reposição de miniteste; o descarte cumpre essa função. A
ausência a uma avaliação integradora só é reposta mediante justificativa
formalmente aceita, em data e formato definidos pelo docente.

*Atendimento.* Horário a definir e divulgado no primeiro encontro.

*Integridade acadêmica.* O uso de ferramentas de geração automática de texto e
de código é permitido no preparo do seminário, desde que declarado. A
responsabilidade pelo conteúdo apresentado é integralmente da dupla, e a
arguição verifica o domínio efetivo do material.
