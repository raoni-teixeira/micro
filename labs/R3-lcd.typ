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
      align(right)[Roteiro 3],
    )
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira — DENE/UFMT],
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
#block(
  width: 100%,
  fill: azul,
  inset: (x: 16pt, y: 20pt),
  radius: 4pt,
)[
  \
  #text(fill: white, size: 18pt, weight: "bold")[Microcontroladores]
  \
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 3 — Display LCD alfanumérico]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa(
  "Objetivos desta sessão",
  rgb("#555555"),
  cinza,
  [
    Ao final desta sessão o grupo deve ser capaz de:

    1. Inicializar um display HD44780 16x2 em barramento de 8 bits;
    2. Distinguir *comando* de *dado* e explicar o papel do pino RS;
    3. Respeitar os tempos de resposta de um periférico externo;
    4. Converter valores inteiros em caracteres para exibição decimal.
  ],
)

#v(0.6em)

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [*CH2-1 (LCD)*], [*ON*],
    [Chaves SWITCHS], [Todas em OFF],
    [CH3-3 e CH3-5], [OFF],
  )

  O contraste é ajustado pelo *trimpot R37*. Se o display acender sem mostrar nada, ou mostrar apenas quadrados escuros, ajuste R37 *antes* de suspeitar do código.
]

= Fundamento

== O barramento é compartilhado

No XM118, os dados do LCD usam o *mesmo PORTD dos 8 LEDs*. Escrever no display faz os LEDs piscarem.

#observacao[
  Isso é comportamento esperado, não defeito. E ilustra um problema real de projeto: pinos são recurso escasso, e o compartilhamento tem consequências visíveis.
]

== Ligação

#figure(
  table(
    columns: (1.4fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Sinal],
      text(fill: white, weight: "bold")[Pino do PIC],
    ),
    [Dados D0 a D7], [PORTD],
    [RS (_Register Select_)], [RE0],
    [E (_Enable_)], [RE1],
  ),
  caption: [Ligação do display alfanumérico no XM118.],
) <tab-lcd-pinos>

== Comando ou dado

O pino *RS* decide como o display interpreta o byte presente no barramento:

- `RS = 0` #sym.arrow.r *comando* (limpar, posicionar cursor, configurar);
- `RS = 1` #sym.arrow.r *dado* (caractere a exibir).

O pino *E* é o sinal de validação: o display só lê o barramento na transição de E. Sem o pulso, nada acontece — o dado fica nos fios e é ignorado.

== O display é lento

Este é o primeiro periférico da disciplina que *não obedece instantaneamente*. Cada operação exige tempo de processamento interno, e alguns comandos são bem mais lentos que outros.

#figure(
  table(
    columns: (1.6fr, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Operação],
      text(fill: white, weight: "bold")[Tempo mínimo],
    ),
    [Comando comum], [$approx 40$ #sym.mu s],
    [Limpar display (`0x01`)], [$approx 1,6$ ms],
    [Retornar cursor (`0x02`)], [$approx 1,6$ ms],
    [Energização inicial], [$approx 40$ ms],
  ),
  caption: [Tempos de resposta do controlador HD44780.],
) <tab-lcd-tempos>

#importante[
  Ignorar esses tempos produz o sintoma mais traiçoeiro do roteiro: o display funciona *às vezes*.
]

= Parte 1 — Estudo do driver

O professor fornece `lcd.c` e `lcd.h`. *Leia antes de usar.*

/ 1.1: Localize a função `lcd_pulso_enable()`. Por que existem dois atrasos, um antes e outro depois de baixar o pino E? #resposta(n: 2)

/ 1.2: Em `lcd_comando()` há um teste condicional:

```c
if (c == 0x01u || c == 0x02u) {
    __delay_ms(2);
}
```

Por que apenas esses dois comandos recebem espera adicional? #resposta(n: 2)

/ 1.3: Compare `lcd_comando()` e `lcd_caractere()`. Qual é a *única* diferença funcional entre as duas? #resposta()

#previsao[
  *1.4* — Em `lcd_iniciar()`, o que aconteceria se o `__delay_ms(50)` inicial fosse removido?

  Formule a hipótese *antes* de testar. O teste ocorre no item 2.4.

  #resposta(n: 2)
]

= Parte 2 — Primeiros textos

#tarefa[
  *2.1* — Escreva um programa que mostre, ao ligar:

  ```
  Grupo NN
  Roteiro 3
  ```

  com o número do seu grupo.
]

#tarefa[
  *2.2* — Localize a sequência de inicialização e identifique o que cada comando configura. Consulte a tabela de comandos do HD44780 em anexo.

  #table(
    columns: (auto, 1fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(
      text(fill: white, weight: "bold")[Comando],
      text(fill: white, weight: "bold")[Função],
    ),
    [`0x38`], [],
    [`0x0C`], [],
    [`0x06`], [],
    [`0x01`], [],
  )
]

/ 2.3: Troque `0x0C` por `0x0F` e observe. O que mudou? #resposta()

#tarefa[
  *2.4* — Remova o `__delay_ms(50)` inicial e grave.

  O display funciona? Funciona *sempre*, ou apenas às vezes? Ligue e desligue o kit três vezes e anote cada resultado.

  #table(
    columns: (auto, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    [Tentativa 1], [],
    [Tentativa 2], [],
    [Tentativa 3], [],
  )
]

#conceito[
  Este teste é o ponto central do roteiro.

  Um sistema que funciona "quase sempre" é mais perigoso que um que nunca funciona: o defeito não aparece na bancada, aparece em campo — e sob condições que ninguém consegue reproduzir.

  Confronte agora o resultado com a sua previsão do item 1.4.
]

= Parte 3 — Números no display

O display recebe *caracteres*, não números. Para mostrar o valor 37 é preciso enviar o caractere `'3'` e depois o `'7'`.

A conversão de dígito para caractere usa a tabela ASCII:

```c
caractere = '0' + digito;
```

/ 3.1: Por que essa soma funciona? O que garante que os dígitos de `'0'` a `'9'` sejam consecutivos na tabela? #resposta(n: 2)

#tarefa[
  *3.2* — Escreva uma função que mostre um valor de 0 a 255 em decimal.

  ```c
  void lcd_numero(uint8_t v)
  {
      /* completar */
  }
  ```

  Dica: os operadores `/` e `%` isolam cada dígito.
]

#tarefa[
  *3.3* — Use a função para exibir um contador de 0 a 255, incrementando a cada 500 ms.
]

/ 3.4: Ao passar de 100 para 99, o que aparece no display? Explique o que acontece e proponha uma correção. #resposta(n: 3)

= Parte 4 — Integração com o roteiro anterior

#tarefa[
  *4.1* — Combine com o Roteiro 2: mostre no LCD o *valor decimal* das chaves DIP, mantendo os LEDs espelhando o estado em binário.

  Resultado esperado: chaves em `00000101` produzem `5` no display e os LEDs correspondentes acesos.
]

/ 4.2: Você notou os LEDs piscando de forma estranha ao atualizar o display? Explique por quê, com base no fundamento desta sessão. #resposta(n: 2)

= Teste de aceitação

#quadro Display mostra as duas linhas de identificação do grupo.

#quadro Contador decimal de 0 a 255 funcionando, sem resíduo de dígito.

#quadro Valor decimal das chaves no LCD e binário nos LEDs (item 4.1).

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
    [0,2], [Respostas 1.1 a 1.4],
    [0,2], [Tabela 2.2 completa],
    [0,2], [Observação 2.4 com as três tentativas registradas],
    [0,2], [Respostas 3.4 e 4.2],
  ),
  caption: [Distribuição do ponto do Roteiro 3.],
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
    [Display aceso, sem texto], [Contraste (R37) ou CH2-1 em OFF],
    [Linha superior com quadrados escuros], [Inicialização incompleta],
    [Funciona às vezes], [Falta de atraso após a energização],
    [Caracteres embaralhados], [Falta de espera após o comando `0x01`],
    [Texto na linha errada], [Endereço de cursor: linha 0 = `0x80`, linha 1 = `0xC0`],
    [Resíduo ao diminuir dígitos], [Não limpou a posição anterior],
  ),
  caption: [Diagnóstico rápido do Roteiro 3.],
)

= Para a próxima sessão

#tarefa[
  O kit tem um sensor de temperatura LM35, que entrega *10 mV por grau Celsius*. O microcontrolador lê tensão como um número inteiro de 0 a 1023, onde 1023 corresponde a 5 V.

  Traga respondido, com a conta desenvolvida: se a leitura for *512*, qual a temperatura?
]
