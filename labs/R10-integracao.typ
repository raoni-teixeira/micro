#import "@preview/fletcher:0.5.1" as fletcher: diagram, node, edge

// ---------- configurações de página ----------
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Microcontroladores — Prática],
      align(right)[Roteiro 10],
    )
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira · Rodolfo Quadros — DENE/UFMT],
      align(right)[#context counter(page).display("1")],
    )
  ],
)

#show heading: set block(below: 1.4em, above: 1.8em)

// ---------- tipografia ----------
#set text(font: "Linux Libertine", size: 11pt, lang: "pt")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1")
#show raw.where(block: true): it => block(
  width: 100%,
  fill: luma(247),
  stroke: 0.5pt + luma(210),
  inset: 8pt,
  radius: 3pt,
)[#it]

// ---------- cores ----------
#let azul     = rgb("#003366")
#let destaque = rgb("#1a6bad")
#let cinza    = luma(245)
#let vermelho = rgb("#b04020")
#let verde    = rgb("#1a6b1a")
#let roxo     = rgb("#5a0080")
#let laranja  = rgb("#805000")

// ---------- ambientes ----------
#let caixa(titulo, cor-borda, cor-fundo, corpo) = block(
  width: 100%,
  fill: cor-fundo,
  stroke: (left: 3pt + cor-borda),
  inset: (left: 10pt, right: 10pt, top: 8pt, bottom: 8pt),
  radius: (right: 3pt),
  breakable: true,
)[
  #text(weight: "bold", fill: cor-borda)[#titulo] \
  #corpo
]

#let conceito(corpo)   = caixa("Conceito central", azul, rgb("#eef3fa"), corpo)
#let bancada(corpo)    = caixa("Configuração de bancada", destaque, rgb("#f0f6ff"), corpo)
#let importante(corpo) = caixa("⚠ Atenção", vermelho, rgb("#fff5f0"), corpo)
#let tarefa(corpo)     = caixa("Tarefa", verde, rgb("#f0faf0"), corpo)
#let previsao(corpo)   = caixa("✎ Previsão — registre ANTES de gravar", roxo, rgb("#f5f0ff"), corpo)
#let observacao(corpo) = caixa("Observação", laranja, rgb("#fff8ee"), corpo)
#let manual(corpo)     = caixa("📕 Divergência do manual", laranja, rgb("#fff8ee"), corpo)

// ---------- utilidades ----------
#let quadro = box(width: 9pt, height: 9pt, stroke: 0.6pt + luma(90), radius: 1pt)
#let resposta(n: 1) = for _ in range(n) [ #v(0.9em) #line(length: 100%, stroke: 0.4pt + luma(170)) ]
#block(width: 100%, fill: azul, inset: (x: 16pt, y: 20pt), radius: 4pt)[
  \
  #text(fill: white, size: 18pt, weight: "bold")[Microcontroladores]
  \
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 10 — Integração, hardware real e fechamento]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · Rodolfo Quadros · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa("Objetivos desta sessão", rgb("#555555"), cinza, [
  Ao final desta sessão o grupo deve ser capaz de:

  1. Distinguir o microcontrolador do kit didático que o hospeda;
  2. Identificar o conjunto mínimo de componentes para operar um MCU;
  3. Comparar plataformas e reconhecer o que muda e o que permanece;
  4. Justificar a escolha de microcontrolador em aplicações de potência.
])

#v(0.6em)

= Parte 1 — O que é, afinal, o microcontrolador

/ 1.1: Da sessão anterior — em uma frase, o que exatamente é "o microcontrolador" no kit XM118? #resposta(n: 2)

#conceito[
  Depois de nove sessões manuseando uma caixa de dois quilos com relés, DB9 e fonte chaveada, é natural associar "microcontrolador" ao conjunto inteiro.

  O microcontrolador é o circuito integrado de 40 pinos da seção MICROCONTROLLER. *Todo o restante do kit é conveniência de laboratório*: os LEDs, o LCD, os conectores, e as chaves DIP que tanto atrapalharam ao longo do semestre existem para poupar montagem, não porque sejam necessários.
]

== Demonstração de bancada

O professor apresenta, em sequência:

#figure(
  table(
    columns: (auto, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Item],
      text(fill: white, weight: "bold")[O que observar],
    ),
    [O chip nu], [Um PIC18F4550 em encapsulamento DIP, fora de qualquer placa],
    [Gravador + protoboard], [O conjunto mínimo: chip, cristal, capacitores, alimentação e ICSP],
    [Outra placa de desenvolvimento], [Mesma ideia, outro fabricante, outra geração],
    [ESP32], [A plataforma de prototipagem dominante hoje],
  ),
  caption: [Progressão de hardware apresentada em bancada.],
)

/ 1.2: Liste o conjunto mínimo de componentes necessários para o PIC18F4550 executar um programa. #resposta(n: 3)

/ 1.3: Dos periféricos que vocês usaram no semestre, quais estão *dentro* do chip e quais estão *fora*? #resposta(n: 3)

= Parte 2 — A mesma aplicação em outra plataforma

O professor demonstra o *mesmo termostato* executando em um STM32F407 (núcleo ARM Cortex-M4).

#tarefa[
  *2.1* — Acompanhando a demonstração, preencha:

  #table(
    columns: (1fr, 1fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    table.header(
      text(fill: white, weight: "bold")[Aspecto],
      text(fill: white, weight: "bold")[PIC18F4550],
      text(fill: white, weight: "bold")[STM32F407],
    ),
    [Largura do núcleo], [], [],
    [Clock máximo], [], [],
    [Resolução do ADC], [], [],
    [Base de tempo periódica], [], [],
    [Ferramenta de gravação], [], [],
  )
]

/ 2.2: A lógica do controle com histerese precisou mudar de uma plataforma para outra? E a configuração dos periféricos? #resposta(n: 3)

#conceito[
  O que muda entre plataformas é a *configuração*: nomes de registradores, ferramentas, camadas de abstração. O que permanece é o *raciocínio*: estado seguro no reset, base de tempo periódica, tratamento de ruído, separação entre medir e atuar.

  Nove décimos do que vocês aprenderam transfere. O décimo restante é o que se consulta no manual.
]

= Parte 3 — Escolha de plataforma

O ESP32 é, hoje, a melhor plataforma de prototipagem para uso amador: Wi-Fi e Bluetooth integrados, preço baixo, comunidade ativa e ferramentas acessíveis.

#previsao[
  *3.1* — Considerando isso, responda antes da discussão:

  Por que um relé de proteção de sistema elétrico não usa ESP32?

  #resposta(n: 4)
]

Discussão em plenário. Elementos a considerar:

#figure(
  table(
    columns: (1fr, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Critério],
      text(fill: white, weight: "bold")[Por que pesa em potência],
    ),
    [Determinismo temporal], [A atuação precisa ocorrer em janela previsível, sempre],
    [Certificação], [Normas exigem componentes qualificados e rastreáveis],
    [Imunidade a ruído], [Ambiente de subestação é eletromagneticamente hostil],
    [Faixa de temperatura], [Painéis externos operam muito além do grau comercial],
    [Ciclo de vida], [Equipamento instalado permanece em campo por décadas],
    [Superfície de ataque], [Conectividade é vetor de risco em infraestrutura crítica],
  ),
  caption: [Critérios de escolha de microcontrolador em aplicações de potência.],
) <tab-criterios>

/ 3.2: Após a discussão, revise sua resposta 3.1. O que você não havia considerado? #resposta(n: 3)

/ 3.3: Retomando o semestre: quais conteúdos desta disciplina fazem sentido à luz da @tab-criterios? Cite ao menos dois e explique a conexão. #resposta(n: 4)

#conceito[
  A insistência do semestre em estado seguro de atuador, temporização determinística e tratamento de ruído não foi rigor gratuito. São exatamente os requisitos que separam um protótipo de bancada de um equipamento que pode ser instalado em uma subestação.
]

= Parte 4 — Entrega final

#tarefa[
  *4.1* — Demonstre o termostato completo em funcionamento, com:

  - leitura de temperatura com média de amostras;
  - controle selecionável entre as estratégias estudadas;
  - atuação por PWM em ambos os atuadores;
  - exibição no LCD;
  - telemetria serial;
  - laço principal orientado a interrupção, sem `__delay_ms()`.
]

#tarefa[
  *4.2* — Entregue um relatório de *no máximo três páginas* contendo:

  + O diagrama de blocos do sistema construído;
  + A tabela comparativa das quatro estratégias (do Roteiro 9);
  + A escolha da estratégia que vocês adotariam para uma aplicação real, com justificativa;
  + Uma limitação conhecida do sistema, honestamente descrita.
]

#observacao[
  O item 4 do relatório vale tanto quanto os outros três. Um sistema cujas limitações são conhecidas e documentadas é mais confiável que um cujas limitações são desconhecidas — e reconhecê-las é competência de engenharia, não confissão de fracasso.
]

= Teste de aceitação

#quadro Termostato completo funcionando, com todos os itens do 4.1.

#quadro Relatório entregue.

#quadro Cada membro do grupo responde a uma pergunta sobre parte diferente do sistema.

= Entrega e critério

#figure(
  table(
    columns: (auto, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Peso],
      text(fill: white, weight: "bold")[Item],
    ),
    [0,3], [Demonstração 4.1 completa e funcionando],
    [0,3], [Relatório 4.2, incluindo a limitação documentada],
    [0,2], [Respostas 1.2 e 1.3 sobre o que é o microcontrolador],
    [0,2], [Previsão 3.1 e revisão 3.3, conectando o semestre aos critérios],
  ),
  caption: [Distribuição do ponto do Roteiro 10.],
)

= Encerramento

#conceito[
  O PIC18F4550 é um microcontrolador de 2004. Não é o que vocês usarão profissionalmente, e isso nunca foi segredo.

  Ele foi escolhido porque é *transparente*: não há camada de abstração escondendo os registradores, nem biblioteca decidindo pelo programador. Cada bit configurado neste semestre foi configurado por vocês.

  Quando encontrarem uma plataforma moderna, com HAL, gerador de código e centenas de páginas de manual de referência, vocês saberão o que aquelas camadas estão fazendo por baixo — porque já fizeram à mão.
]
