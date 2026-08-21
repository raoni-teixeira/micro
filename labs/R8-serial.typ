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
      align(right)[Roteiro 8],
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
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 8 — Comunicação serial e telemetria]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · Rodolfo Quadros · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa("Objetivos desta sessão", rgb("#555555"), cinza, [
  Ao final desta sessão o grupo deve ser capaz de:

  1. Configurar a EUSART e calcular o divisor de _baud rate_;
  2. Transmitir dados formatados para um terminal no computador;
  3. Registrar uma série temporal em arquivo e analisá-la;
  4. Receber comandos e alterar o comportamento do sistema em execução.
])

#v(0.6em)

= Por que instrumentar

O LCD mostra o instante presente. Para responder "a temperatura oscila?" ou "quanto tempo levou para estabilizar?", é preciso registrar o *histórico*.

#conceito[
  Sem instrumentação, todo diagnóstico de sistema embarcado vira adivinhação. Com telemetria, o sistema relata seu próprio estado e as perguntas passam a ter resposta baseada em evidência.

  Este roteiro existe em boa parte para viabilizar o Roteiro 9: sem registro temporal não há como comparar estratégias de controle com rigor.
]

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [*CH4-6 (RS232\_TX)*], [*ON* — RC6],
    [*CH4-8 (RS232\_RX)*], [*ON* — RC7],
    [CH4-5 e CH4-7], [OFF — RS485 disputa os mesmos pinos],
    [*CH5 (relés)*], [*TODAS EM OFF*],
    [CH1-7, CH2-1, CH3-3, CH3-5], [ON, como no Roteiro 6],
  )

  *Cabo:* DB9 do kit (CN4) ao computador, direto ou por adaptador USB-RS232. O cabo é de extensão, não _null-modem_.
]

#importante[
  Os relés 1 e 2 estão ligados a RC6 e RC7 — exatamente os pinos da serial. Se qualquer chave do banco CH5 estiver em ON, a comunicação não funciona.

  É o conflito mais fácil de esquecer em todo o semestre.
]

= Parte 1 — Configuração da EUSART

== Cálculo do divisor

Com `BRGH = 1` e `BRG16 = 1`:

$ "SPBRG" = frac(F_"osc", 4 times "baud") - 1 $

/ 1.1: Calcule o divisor para 9600 baud com $F_"osc" = 16$ MHz. Mostre a conta e o valor em hexadecimal. #resposta(n: 2)

/ 1.2: O resultado é um inteiro exato? Arredonde e calcule o _baud rate_ efetivo e o erro percentual. #resposta(n: 3)

#manual[
  *O clock da CPU é 16 MHz*, imposto pelos config bits do bootloader. Diferente dos 48 MHz que o periférico USB recebe.

  Aqui a diferença importa mais que em qualquer outro roteiro: um divisor calculado para o clock errado produz comunicação que parece funcionar e entrega caracteres corrompidos.
]

#observacao[
  Nem toda combinação de clock e _baud rate_ produz divisor exato. Neste caso o divisor dá 415,67 e é arredondado para 416, resultando em 9592 bps — erro de 0,08%.

  O erro aceitável fica em torno de 2 a 3%: acima disso, o receptor perde a sincronia no meio do quadro.

  Este é um dos motivos pelos quais placas com cristal de 11,0592 MHz eram comuns — o valor é escolhido para dar divisores exatos nas taxas usuais.
]

#tarefa[
  *1.3* — Configure a EUSART e transmita a mensagem `Teste XM118` uma vez por segundo. Abra o terminal em 9600, 8N1, sem controle de fluxo.
]

/ 1.4: Os LEDs TX e RX da seção USART piscam? O que cada um indica? #resposta()

= Parte 2 — Protocolo de telemetria

Dados soltos são difíceis de analisar. Defina um formato de linha fixo:

```
T=305;S=300;E=1;A=2;H=0;V=255
```

onde `T` é a temperatura em décimos, `S` o setpoint, `E` a estratégia, `A` a ação, `H` o duty do aquecedor e `V` o da ventoinha.

#tarefa[
  *2.1* — Implemente a transmissão desse formato, uma linha por segundo, terminada em `\r\n`.
]

/ 2.2: Por que enviar a temperatura como `305` em vez de `30.5`? Considere quem vai processar o dado do outro lado. #resposta(n: 2)

/ 2.3: Por que separar os campos com um caractere fixo, em vez de contar posições? #resposta(n: 2)

= Parte 3 — Registro e análise

#tarefa[
  *3.1* — Configure o terminal para gravar a sessão em arquivo (no PuTTY: Session #sym.arrow.r Logging #sym.arrow.r _All session output_).

  Registre *dez minutos* do sistema em regime, com setpoint em 30 #sym.degree\C e controle com histerese.
]

#tarefa[
  *3.2* — Abra o arquivo em uma planilha e trace o gráfico da temperatura ao longo do tempo.

  Dica: separe os campos usando `;` e `=` como delimitadores.
]

/ 3.3: A curva oscila? Meça a amplitude pico a pico e o período da oscilação. #resposta(n: 2)

/ 3.4: Compare com a banda morta configurada. A amplitude da oscilação é igual à banda? Maior? Menor? Explique. #resposta(n: 3)

#conceito[
  A amplitude de oscilação normalmente *excede* a banda morta. O motivo é o atraso: quando o controlador desliga o aquecedor, o calor já acumulado na resistência continua chegando ao sensor.

  Esse excesso é a assinatura do atraso de transporte que vocês mediram no Roteiro 5.
]

= Parte 4 — Recepção de comandos

#tarefa[
  *4.1* — Implemente a recepção de comandos de um caractere:

  #table(
    columns: (auto, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Comando],
      text(fill: white, weight: "bold")[Ação],
    ),
    [`+`], [Aumenta o setpoint em 0,5 #sym.degree\C],
    [`-`], [Diminui o setpoint em 0,5 #sym.degree\C],
    [`?`], [Envia a telemetria imediatamente],
  )
]

#importante[
  A leitura da serial *não pode bloquear* o laço principal. Verifique se há byte disponível antes de ler:

  ```c
  if (PIR1bits.RCIF) {
      b = RCREG;
  }
  ```

  Ler `RCREG` sem verificar trava o programa até que algo chegue — e desmonta toda a estrutura construída no Roteiro 7.
]

/ 4.2: Se ocorrer erro de _overrun_ (`OERR`), o receptor para de funcionar. Por que isso acontece, e como recuperar? #resposta(n: 2)

= Teste de aceitação

#quadro Telemetria chegando ao terminal no formato definido.

#quadro Arquivo de dez minutos registrado e gráfico traçado.

#quadro Comandos `+`, `-` e `?` funcionando sem travar o laço.

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
    [0,2], [Teste de aceitação aprovado],
    [0,2], [Cálculo 1.1 e resposta 1.2],
    [0,3], [Gráfico 3.2 e medições 3.3],
    [0,2], [Resposta 3.4, relacionando amplitude e banda morta],
    [0,1], [Respostas 2.2, 2.3 e 4.2],
  ),
  caption: [Distribuição do ponto do Roteiro 8.],
)

= Armadilhas frequentes

#figure(
  table(
    columns: (1.1fr, 1.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Sintoma],
      text(fill: white, weight: "bold")[Causa provável],
    ),
    [Nada chega ao terminal], [Alguma chave de CH5 em ON — relés em RC6/RC7],
    [Caracteres embaralhados], [_Baud rate_ divergente entre kit e terminal],
    [Só chega lixo], [Cabo _null-modem_ no lugar de extensão direta],
    [Recepção para após alguns bytes], [Erro de _overrun_ não tratado],
    [Programa trava], [Leitura de `RCREG` sem verificar `RCIF`],
    [Porta COM não existe], [Adaptador USB-RS232 sem driver ou desconectado],
  ),
  caption: [Diagnóstico rápido do Roteiro 8.],
)

= Para a próxima sessão

#tarefa[
  Vocês agora têm um instrumento: podem registrar a curva de temperatura e analisá-la.

  Traga escrito: além da histerese e do proporcional, que outra regra de controle você imagina? Descreva em português e diga que problema ela resolveria.
]
