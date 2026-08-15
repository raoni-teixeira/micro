#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 13])
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
#let ciano    = rgb("#006b6b")

#show heading.where(level: 1): it => { set text(fill: azul, size: 15pt); it }
#show heading.where(level: 2): it => { set text(fill: destaque, size: 12pt); it }
#show figure: set block(breakable: true)
#show raw: set text(size: 9.5pt)

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
#let derivacao(corpo)  = caixa("Derivação", ciano, rgb("#eff7f7"), corpo)
#let codigo(corpo)     = caixa("Código", laranja, rgb("#fdf8ef"), corpo)
#let exercicio(n, c)   = caixa("Exercício " + n, laranja, rgb("#fdf8ef"), c)

#let cab(txt) = text(fill: white, weight: "bold", size: 9.5pt)[#txt]

#align(center)[
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 13 --- Estudo de Caso e Transposição] \
  #v(0.2em)
  #text(size: 12pt)[O termostato como sistema, e a ponte para arquiteturas de 32 bits] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Reler o projeto do semestre como sistema, identificando camadas e
    responsabilidades.
  - Construir orçamentos de tempo e de memória e interpretá-los como
    instrumentos de projeto.
  - Separar, no que foi aprendido, o conceito transferível da particularidade da
    família.
  - Descrever o que mudaria e o que permaneceria na reimplementação do projeto
    em ARM Cortex-M.
  - Retomar, com fundamento, a pergunta de escolha de plataforma aberta no
    encontro 0.
]

= O sistema completo

Treze encontros produziram um sistema com cerca de dez módulos. Vale olhá-lo
inteiro uma vez, porque a competência que se avalia daqui em diante não é sobre
periféricos isolados.

#figure(
  table(
    columns: (1fr, 1.5fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Camada], cab[Módulos], cab[Conhece]),
    [Escalonador], [Base de tempo e despacho de tarefas],
      [Apenas ritmos; nada do problema nem do hardware],
    [Aplicação], [Controle, interface, telemetria, persistência],
      [O problema: temperatura, limiares, comandos],
    [Acesso ao hardware], [Display, conversor, teclado, serial, modulação,
      memória não volátil], [Registradores; nada de termostatos],
  ),
  caption: [As três camadas do firmware.],
) <tab-camadas>

#observacao[
  A propriedade que interessa é a *direção das dependências*: a camada de baixo
  não sabe que existe um termostato, e a de cima não sabe qual microcontrolador
  está em uso. Trocar de dispositivo reescreveria apenas a camada inferior. Essa
  afirmação será testada de forma concreta pelos seminários.
]

= Orçamento de tempo

#derivacao[
  Com base de 1 ms, cada tique dispõe de aproximadamente 12 000 ciclos de
  instrução a 48 MHz. Estimando o custo de cada tarefa e sua frequência:
  #v(0.5em)
  #table(
    columns: (1.3fr, 1fr, 1fr, 1fr),
    stroke: 0.5pt + luma(200), inset: 5pt, align: left,
    [*Tarefa*], [*Duração*], [*Período*], [*Ocupação*],
    [Teclado], [≈ 50 µs], [5 ms], [1,0%],
    [Conversor e controle], [≈ 30 µs], [100 ms], [0,03%],
    [Display, quando muda], [≈ 1,3 ms], [300 ms], [0,43%],
    [Telemetria], [≈ 200 µs], [1 s], [0,02%],
    [Tratador de interrupção], [≈ 5 µs], [1 ms], [0,5%],
  )
  #v(0.5em)
  A ocupação total fica em torno de 2%. O processador está *ocioso 98% do tempo*.
]

#atencao[
  Esse número desmente a intuição de que um dispositivo de 8 bits a 48 MHz seja
  apertado para a aplicação --- e explica por que a plataforma segue viável para
  esta classe de problema. Note, porém, o que o número esconde: a tarefa de
  display dura 1,3 ms, *mais que o período do tique*. Sua ocupação média é
  baixa, mas no ciclo em que executa ela atrasa tudo o mais. Ocupação média e
  pior caso são grandezas diferentes, e é o segundo que determina se o sistema é
  aceitável.
]

= Orçamento de memória

#figure(
  table(
    columns: (1.4fr, 1fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Item], cab[Ordem], cab[Observação]),
    [Buffers de comunicação], [64 B], [Recepção e transmissão],
    [Janela da média móvel], [16 B], [Oito amostras de 16 bits],
    [Estado da aplicação], [≈ 40 B], [Alvo, temperatura, estados, contadores],
    [Variáveis do escalonador], [≈ 20 B], [Contadores por tarefa],
    [Cadeias de texto], [Flash], [Declaradas `const`; não ocupam RAM],
    [Pilha de retorno], [Separada], [Não consome memória de dados],
  ),
  caption: [Onde a RAM é consumida.],
) <tab-memoria>

#observacao[
  O total ronda 150 bytes de 2 048 --- também folgado. As duas linhas finais
  concentram a lição: cadeias de texto declaradas `const` residem na Flash, e a
  pilha é separada. Removidas essas duas providências, o mesmo projeto se
  aproximaria do limite. O orçamento é confortável *porque* decisões corretas
  foram tomadas ao longo do caminho, não por generosidade do dispositivo.
]

= O que é conceito e o que é família

Esta é a separação central do curso, e o critério é operacional: *o que
reapareceria numa plataforma completamente diferente?*

#figure(
  table(
    columns: (1.5fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Conceito transferível], cab[Particularidade da família]),
    [Amostragem, quantização e resolução efetiva], [Nomes e bits dos
      registradores do conversor],
    [Tempo de aquisição e impedância da fonte], [Codificação do tempo de
      aquisição em hardware],
    [Base de tempo e escalonamento cooperativo], [Cálculo de pré-carga e a
      deriva por recarga em software],
    [Ciclo ativo, resolução e frequência], [Vínculo obrigatório com o
      temporizador 2],
    [Latência, prioridade e contexto], [Dois vetores fixos e o modo de
      compatibilidade],
    [`volatile`, seções críticas, atomicidade], [Largura de 8 bits que torna
      certos acessos atômicos],
    [Histerese, filtragem, atraso na malha], [Resolução grosseira da referência
      programável],
    [Quadro serial, erro de taxa, buffers], [Gerador de taxa de 16 bits e o
      bloqueio por sobrescrita],
    [Máquinas de estado e arquitetura em camadas], [Banqueamento, banco de
      acesso, não reentrância],
  ),
  caption: [A separação que o curso vinha construindo.],
) <tab-separacao>

#atencao[
  A coluna da esquerda é o que se leva desta disciplina. A da direita é
  conhecimento com prazo de validade --- útil, necessário para fazer o sistema
  funcionar neste semestre, e descartável na próxima plataforma. Confundir as
  duas colunas leva ao engenheiro que "sabe PIC" e se descobre incapaz de
  transferir a competência.
]

= Reimplementando em Cortex-M

Um exercício mental útil: o mesmo termostato, no STM32F407 da demonstração
comparativa.

#figure(
  table(
    columns: (1.2fr, 1.4fr, 1.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Aspecto], cab[O que muda], cab[O que permanece]),
    [Configuração inicial], [Ferramenta gráfica gera o código de inicialização],
      [Erros de clock continuam invalidando toda a temporização],
    [Entrada e saída], [Escrita atômica elimina o problema do encontro 2],
      [Limites de corrente e necessidade de transistor],
    [Conversor], [12 bits, disparo por temporizador, transferência automática],
      [Aquisição, impedância, referência, quantização],
    [Base de tempo], [Temporizador dedicado com recarga automática],
      [Escalonamento e orçamento de tempo],
    [Interrupções], [Um vetor por fonte, dezenas de prioridades],
      [`volatile`, seções críticas, tratador curto],
    [Persistência], [*Piora*: não há memória não volátil dedicada],
      [Desgaste e escrita apenas quando muda],
    [Memória], [192 KB de RAM contra 2 KB], [O orçamento continua sendo lido no
      mapa do ligador],
  ),
  caption: [O mesmo projeto em outra arquitetura.],
) <tab-arm>

#observacao[
  A linha da persistência é a mais instrutiva porque contraria a expectativa: em
  um aspecto concreto, a plataforma moderna é *menos* conveniente. Progresso
  tecnológico não é uniforme, e o hábito de verificar recurso por recurso, em vez
  de supor superioridade global, é exatamente o que a coluna da direita da tabela
  anterior treina.
]

#atencao[
  A camada de abstração fornecida pelo fabricante acelera o início e cobra
  depois: quando algo não funciona, o estudante que nunca escreveu num
  registrador não tem como investigar. *Esta disciplina existe, em boa parte,
  para que essa investigação seja possível.* A abstração é útil justamente para
  quem sabe o que há embaixo dela.
]

= A pergunta do encontro 0

O curso abriu perguntando como se escolhe uma plataforma. Com o semestre inteiro
como evidência, a resposta pode ser formulada:

+ *A categoria decorre dos requisitos.* Determinismo, consumo e tempo de partida
  puxam para microcontrolador; interface rica, rede e sistema de arquivos puxam
  para processador de aplicação; paralelismo verdadeiro e latência de
  nanossegundos puxam para lógica programável.
+ *Dentro da categoria, decidem os periféricos e o orçamento.* Os dois
  orçamentos desta aula --- tempo e memória --- são o instrumento. Um projeto que
  ocupa 2% do processador e 7% da RAM tem folga para crescer; um que ocupa 80%
  não tem.
+ *O ecossistema pesa tanto quanto o silício.* Ferramentas, documentação,
  disponibilidade do componente por anos e domínio da equipe frequentemente
  decidem mais que uma diferença de desempenho.
+ *Não existe plataforma superior.* Existe adequação a requisitos, e a resposta
  muda quando os requisitos mudam.

#observacao[
  O PIC18F4550 não seria a escolha para um produto novo hoje --- isso foi dito no
  encontro 0 e continua verdadeiro. Ele foi, porém, um veículo adequado para o
  que se pretendia: uma arquitetura pequena o bastante para caber inteira na
  cabeça, com relação direta e observável entre código e hardware. *O que se
  leva não é o dispositivo; é a coluna da esquerda da tabela desta aula.*
]

= Preparação para o seminário

Os dois encontros finais são das duplas. Cada uma recebeu uma plataforma e
responde a três perguntas, que agora podem ser lidas à luz de tudo o que foi
construído: o que dela já existe, de alguma forma, no PIC18F4550; o que não
existe e por quê; e o que mudaria no projeto do termostato se ele fosse
reimplementado ali.

#observacao[
  A tabela de reimplementação da seção 5 é o modelo esperado de resposta à
  terceira pergunta --- inclusive na disposição de registrar aquilo em que a
  plataforma nova é *pior*. Comparações que só encontram vantagens costumam
  indicar que a plataforma não foi realmente estudada.
]

= Exercícios

#exercicio("13.1")[
  Refaça o orçamento de tempo da seção 2 supondo atualização de display a cada
  100 ms e telemetria a cada 200 ms. Calcule a nova ocupação e verifique se
  algum ciclo passaria a exceder o período do tique.
]

#exercicio("13.2")[
  Escolha três itens da coluna direita da tabela da seção 4 e descreva, para cada
  um, qual mecanismo o substitui numa plataforma Cortex-M e por que o problema
  original deixa de existir.
]

#exercicio("13.3")[
  Um requisito novo pede registro das últimas 24 h de temperatura, com uma
  amostra por minuto. Calcule a memória necessária, verifique se cabe no
  dispositivo e proponha uma solução caso não caiba.
]

#exercicio("13.4")[
  Especifique um sistema para o qual o PIC18F4550 seria escolha *inadequada*,
  justificando com pelo menos três requisitos concretos, e indique a categoria de
  dispositivo apropriada segundo os critérios do encontro 0.
]

#exercicio("13.5")[
  Argumente contra a afirmação: "aprender arquitetura de 8 bits é perda de tempo,
  já que todo projeto novo usa 32 bits". Apresente pelo menos três argumentos
  técnicos e um de formação, e reconheça o que há de correto na crítica.
]
