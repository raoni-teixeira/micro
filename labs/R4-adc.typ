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
      align(right)[Roteiro 4],
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
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 4 — Conversor A/D e sensor de temperatura]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira · Rodolfo Quadros · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa("Objetivos desta sessão", rgb("#555555"), cinza, [
  Ao final desta sessão o grupo deve ser capaz de:

  1. Configurar o conversor A/D do PIC18F4550 e ler um canal analógico;
  2. Converter leitura bruta em temperatura usando aritmética inteira;
  3. Explicar o que é quantização e estimar o erro associado;
  4. Justificar o uso de média de amostras a partir de ruído observado.
])

#v(0.6em)

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [*CH1-7 (TEMP)*], [*ON* — liga o LM35 a RA0],
    [CH1-1 (ANALOG1)], [OFF — disputa RA0],
    [CH1-5 (POT)], [OFF — disputa RA0],
    [CH2-1 (LCD)], [ON],
    [CH3-3 e CH3-5], [OFF],
    [SWITCHS], [Todas em OFF],
  )
]

#importante[
  Três circuitos diferentes podem ser ligados a RA0: a entrada analógica externa, o potenciômetro e o sensor de temperatura. *Apenas um por vez.* Se mais de uma chave estiver em ON, os sinais se somam e a leitura não significa nada.
]

= Fundamento

== O que o conversor entrega

O ADC do PIC18F4550 tem *10 bits*: ele mapeia a faixa de tensão entre as referências em um número inteiro de 0 a 1023.

Com referências em $V_"SS" = 0$ V e $V_"DD" = 5$ V:

$ V = "leitura" times frac(5000, 1024) quad ["mV"] $

/ 4.0: Da sessão anterior — se a leitura for 512, qual a tensão? E a temperatura, sabendo que o LM35 entrega 10 mV por grau? #resposta(n: 2)

== A coincidência que elimina o ponto flutuante

O LM35 entrega 10 mV por grau Celsius. Um milivolt equivale, portanto, a 0,1 #sym.degree\C.

Isso significa que *o valor em milivolts já é o valor em décimos de grau*. Não é preciso converter duas vezes:

$ "decimos de grau" = "leitura" times frac(625, 128) $

#conceito[
  Representar a temperatura como inteiro em décimos de grau — 253 significa 25,3 #sym.degree\C — evita ponto flutuante por completo.

  Isso importa: no XC8 em modo gratuito, operações em `float` custam muito código e muitos ciclos. A escolha de representação é decisão de projeto, não detalhe de implementação.
]

== Quantização

Como a saída é inteira, existe um degrau mínimo — o *LSB*:

$ 1 "LSB" = frac(5000, 1024) approx 4,88 "mV" approx 0,49 degree C $

#importante[
  Nenhuma média, filtro ou artifício de software recupera informação abaixo do LSB. Meio grau é o limite *físico* desta montagem.
]

= Parte 1 — Leitura bruta

#tarefa[
  *1.1* — Usando o driver `adc.c` fornecido, mostre no LCD o valor bruto do conversor (0 a 1023), atualizado a cada 500 ms.
]

/ 1.2: Qual valor aparece à temperatura ambiente? #resposta()

/ 1.3: Encoste o dedo no sensor por dez segundos. O valor sobe ou desce? Em quanto? #resposta(n: 2)

= Parte 2 — Conversão para temperatura

#tarefa[
  *2.1* — Implemente a conversão e mostre a temperatura no formato `NN.N C`.

  ```c
  int16_t adc_para_decimos(uint16_t leitura)
  {
      uint32_t acumulador = (uint32_t)leitura * 625UL;
      return (int16_t)(acumulador >> 7);   /* divide por 128 */
  }
  ```
]

/ 2.2: Por que o acumulador precisa ser de 32 bits? Calcule o maior produto possível. #resposta(n: 2)

/ 2.3: Por que `>> 7` equivale a dividir por 128? #resposta()

/ 2.4: A temperatura mostrada é plausível? Compare com um termômetro da sala, se houver. Se houver diferença, proponha uma explicação. #resposta(n: 2)

#observacao[
  O manual informa que o LM35 fica montado *junto à resistência de aquecimento*. Isso significa que ele mede a temperatura do conjunto sensor-resistência, não a do ar da sala. Uma diferença de alguns graus para mais é esperada.
]

= Parte 3 — O ruído

#previsao[
  *3.1* — Observe o dígito decimal da temperatura por trinta segundos, com o kit imóvel e sem tocar no sensor.

  Antes de olhar: você espera que ele fique parado? Justifique.

  #resposta(n: 2)
]

/ 3.2: O que de fato aconteceu? Entre quais valores o dígito oscilou? #resposta(n: 2)

/ 3.3: A oscilação observada é compatível com o valor de 1 LSB calculado no fundamento? Mostre a comparação. #resposta(n: 2)

#tarefa[
  *3.4* — Implemente a média de 8 amostras e observe novamente.

  ```c
  uint16_t adc_media(uint8_t n_pot2)
  {
      uint32_t soma = 0;
      uint16_t total = (uint16_t)(1u << n_pot2);
      uint16_t i;

      for (i = 0; i < total; i++) {
          soma += adc_amostra();
      }
      return (uint16_t)(soma >> n_pot2);
  }
  ```
]

/ 3.5: A oscilação diminuiu? Desapareceu? #resposta()

/ 3.6: Por que o número de amostras é potência de dois? O que aconteceria com o custo computacional se fossem 10 amostras? #resposta(n: 2)

#conceito[
  A média reduz o ruído *aleatório*, que é o que faz o dígito oscilar. Não reduz o erro de quantização, que é sistemático: se a tensão real cai entre dois códigos, nenhuma quantidade de médias inventa o valor intermediário.

  Distinguir essas duas fontes de erro é o que separa quem filtra por hábito de quem filtra por motivo.
]

= Parte 4 — Custo da representação

#tarefa[
  *4.1* — Compile duas versões do mesmo programa: uma com a conversão inteira e outra usando `float`:

  ```c
  float temp = leitura * 5000.0f / 1024.0f / 10.0f;
  ```

  Anote o tamanho do código informado pelo compilador (janela de saída do build) em cada caso.

  #table(
    columns: (1.4fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    [Versão inteira], [],
    [Versão com `float`], [],
    [Diferença], [],
  )
]

/ 4.2: A diferença justifica o esforço de trabalhar em décimos de grau? Em que situação você aceitaria o custo do `float`? #resposta(n: 2)

= Teste de aceitação

#quadro Temperatura exibida no LCD no formato `NN.N C`, valor plausível.

#quadro Média de 8 amostras implementada, com oscilação visivelmente reduzida.

#quadro Um membro do grupo, sorteado, explica por que 1 LSB vale cerca de meio grau.

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
    [0,2], [Previsão 3.1 registrada antes da observação],
    [0,2], [Respostas 3.2 e 3.3, com a comparação numérica],
    [0,2], [Respostas 2.2 e 2.3],
    [0,2], [Medição 4.1 e resposta 4.2],
  ),
  caption: [Distribuição do ponto do Roteiro 4.],
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
    [Leitura sempre 0 ou 1023], [Chave errada em ON, ou `ADCON1` não configurado],
    [Valor pula aleatoriamente], [Mais de uma chave ligada em RA0],
    [Temperatura absurda], [Overflow: acumulador de 16 bits no lugar de 32],
    [Sempre o mesmo valor], [`GO` não foi setado, ou espera de conversão ausente],
    [LCD parou de funcionar], [`ADCON1` deixou PORTD ou PORTE em modo analógico],
  ),
  caption: [Diagnóstico rápido do Roteiro 4.],
)

= Para a próxima sessão

#tarefa[
  Você agora tem uma temperatura medida e dois atuadores disponíveis: uma resistência que aquece e uma ventoinha que resfria.

  Traga escrito: descreva, em português, a regra mais simples possível para manter a temperatura em 30 #sym.degree\C. Depois, aponte um problema que você já antevê nessa regra.
]
