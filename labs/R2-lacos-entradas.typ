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
      align(right)[Roteiro 2],
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
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 2 — Laços, decisão e leitura de entradas]
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

    1. Escrever laços `for` e `while` em C aplicados a saída física;
    2. Explicar por que o programa embarcado termina em laço infinito;
    3. Ler chaves e botões usando resistores de _pull-up_ internos;
    4. Reconhecer e descrever o repique de contato mecânico.
  ],
)

#v(0.6em)

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [Chaves SWITCHS (PORTB)], [Todas em OFF *no início*],
    [CH2-1 (LCD)], [OFF],
    [CH3-3 e CH3-5], [OFF],
  )

  As chaves SWITCHS serão usadas na Parte 3. Até lá, mantenha-as em OFF — quando ligadas, elas aterram os pinos do PORTB.
]

= Parte 1 — O laço infinito

== O programa que termina

#tarefa[
  Grave este código e observe:

  ```c
  void main(void)
  {
      TRISD = 0x00;
      LATD  = 0x00;      /* acende todos */
  }
  ```
]

/ 1.1: Os LEDs acendem? Permanecem acesos? O que acontece depois que `main` termina? #resposta(n: 2)

O comportamento observado costuma surpreender. Anote exatamente o que viu, inclusive se for intermitente.

== A forma normal

```c
void main(void)
{
    TRISD = 0x00;

    for (;;) {
        LATD = 0x00;
        __delay_ms(300);
        LATD = 0xFF;
        __delay_ms(300);
    }
}
```

/ 1.2: Em um sistema embarcado não existe sistema operacional para o qual retornar. Se `main` terminasse, para onde o processador iria? #resposta(n: 2)

/ 1.3: Compare com um programa de Algoritmos que você escreveu antes. Onde estava o "fim" naquele programa? Por que aqui não há? #resposta(n: 2)

#conceito[
  Em um computador de propósito geral, o programa é hóspede: nasce, executa e devolve o controle ao sistema operacional. Em um microcontrolador, o programa *é* o sistema. Não há para onde voltar, e por isso o laço infinito não é um recurso — é a estrutura obrigatória.
]

= Parte 2 — Laços com contador

== Sequência

#tarefa[
  *2.1* — Escreva um programa que acenda os LEDs *um de cada vez*, do 0 ao 7, e recomece. Use um `for` e a construção de máscara do Roteiro 1.

  ```c
  for (;;) {
      for (uint8_t i = 0; i < 8; i++) {
          LATD = ~(uint8_t)(1u << i);   /* por que o ~ ? */
          __delay_ms(150);
      }
  }
  ```
]

/ 2.2: Explique a linha marcada. Por que `1u << i` precisa ser invertido antes de ir para `LATD`? #resposta(n: 2)

== Contador binário

#tarefa[
  *2.3* — Modifique o programa para que os LEDs mostrem uma *contagem binária de 0 a 255*, incrementando a cada 200 ms.
]

#previsao[
  *2.4* — Quanto tempo leva um ciclo completo da contagem?

  Calcule *antes* de medir. Depois confira com um cronômetro e compare.

  Previsto: #box(width: 3cm, stroke: (bottom: 0.4pt)) #h(1em) Medido: #box(width: 3cm, stroke: (bottom: 0.4pt))

  Se houver divergência maior que 10%, o que pode explicá-la?

  #resposta(n: 2)
]

== Ida e volta

#tarefa[
  *2.5* — Modifique a sequência do item 2.1 para ir do LED 0 ao 7 e *voltar* do 7 ao 0, sem repetir os extremos.

  Dica: dois laços, ou um laço com variável de direção. Escolha uma abordagem e justifique em uma frase.
]

#resposta(n: 2)

= Parte 3 — Entradas

== Fundamento

As 8 chaves DIP da seção SWITCHS estão ligadas ao PORTB e são *ativas em nível baixo*: em ON elas aterram o pino.

Quando abertas, quem garante o nível alto são os *resistores de pull-up internos* do PORTB, que precisam ser habilitados por software:

```c
INTCON2bits.RBPU = 0;   /* 0 = pull-ups habilitados */
```

/ 3.1: O bit se chama `RBPU` — _PORTB Pull-Up disable_. Por que escrever *zero* habilita os resistores? #resposta(n: 2)

== Espelho

#previsao[
  *3.2* — Considere o programa abaixo, que pretende refletir o estado das chaves nos LEDs.

  ```c
  TRISB = 0xFF;            /* PORTB como entrada */
  TRISD = 0x00;
  INTCON2bits.RBPU = 0;

  for (;;) {
      LATD = PORTB;
  }
  ```

  Ele faz o que se pede? Considere: a chave em ON produz nível *baixo*, e o LED aceso exige nível *baixo*.

  Preveja o comportamento antes de gravar.

  #resposta(n: 2)
]

#tarefa[
  *3.3* — Grave, verifique e corrija se necessário. O resultado correto é: chave ligada #sym.arrow.r LED aceso.
]

== Contagem de acionamentos

#tarefa[
  *3.4* — Use o push-button *INT0 (SW12, em RB0)*. Escreva um programa que incremente um contador a cada aperto e mostre o valor em binário nos LEDs.
]

/ 3.5: Aperte o botão dez vezes, devagar. O contador marca dez? Anote o valor obtido em três tentativas. #resposta(n: 2)

#observacao[
  Se marcou mais que dez, você encontrou o *repique de contato*: a lâmina metálica do botão bate várias vezes antes de estabilizar, e o programa lê cada batida como um acionamento novo.

  Isso não é defeito do kit nem do seu código. É o comportamento físico de qualquer contato mecânico, de um botão de campainha a um contator de potência.
]

#tarefa[
  *3.6* — Proponha uma solução para o repique, em português, sem escrever código.

  O tratamento formal virá no Roteiro 7, quando vocês tiverem uma base de tempo periódica disponível — a ferramenta que falta hoje.
]

#resposta(n: 3)

= Teste de aceitação

#quadro Sequência de ida e volta funcionando (item 2.5).

#quadro Espelho das chaves nos LEDs, com a polaridade correta (item 3.3).

#quadro Contador de acionamentos funcionando, mesmo que com repique.

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
    [0,2], [Respostas 1.2 e 1.3 sobre o laço infinito],
    [0,2], [Resposta 2.2 e cálculo 2.4 confirmado por medição],
    [0,2], [Respostas 3.1 e previsão 3.2],
    [0,2], [Proposta 3.6 para o repique],
  ),
  caption: [Distribuição do ponto do Roteiro 2.],
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
    [LEDs invertidos no espelho], [Faltou o `~`: as duas polaridades se somam],
    [Chaves sem efeito], [_Pull-ups_ não habilitados, ou `TRISB` errado],
    [Contador dispara sozinho], [Repique — esperado nesta etapa],
    [Programa "trava" após um instante], [`main` sem laço infinito],
    [Tempos errados por fator fixo], [`_XTAL_FREQ` diferente do clock real: use 16 MHz],
  ),
  caption: [Diagnóstico rápido do Roteiro 2.],
)

= Para a próxima sessão

#tarefa[
  Até agora a saída são oito LEDs, que mostram um byte.

  Pense e traga escrito: como você faria para mostrar o número *decimal* 37? E a palavra `TEMP`? O que seria necessário além do que você já tem?
]
