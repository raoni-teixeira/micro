// =====================================================================
// Miniteste 2 — O simulador (trabalho para casa)
// Microcontroladores — DENE/UFMT
// Compilar: typst compile M2-simulador.typ
// Gabarito: typst compile --input gab=1 M2-simulador.typ M2-gab.pdf
// =====================================================================

#let primaria = rgb("#1c3f6e")
#let secundaria = rgb("#b8621b")

#set page(
  paper: "a4",
  margin: (x: 2.1cm, y: 2.2cm),
  header: context {
    grid(
      columns: (1fr, auto),
      text(8.5pt, fill: primaria, weight: "semibold")[Microcontroladores],
      text(8.5pt, fill: secundaria)[Miniteste 2],
    )
    v(-7pt)
    line(length: 100%, stroke: 0.6pt + primaria)
  },
  footer: context {
    line(length: 100%, stroke: 0.6pt + secundaria)
    v(-3pt)
    grid(
      columns: (1fr, auto),
      text(8.5pt, fill: primaria)[Raoni F. S. Teixeira],
      text(8.5pt, fill: secundaria)[#counter(page).display("1")],
    )
  },
)

#set text(font: "Libertinus Serif", size: 10.5pt, lang: "pt")
#set par(justify: true, leading: 0.62em)

#show raw.where(block: true): it => block(
  width: 100%, fill: rgb("#f5f6f8"), stroke: (left: 3pt + primaria),
  inset: (x: 10pt, y: 8pt), radius: (right: 3pt), breakable: true,
  text(size: 8.6pt, it),
)
#show raw.where(block: false): it => box(
  fill: rgb("#eef0f3"), inset: (x: 3pt, y: 1pt), radius: 2pt, text(size: 9.3pt, it),
)

#let caixa(titulo, cor, corpo) = block(
  width: 100%, fill: cor.lighten(90%), stroke: (left: 3pt + cor),
  inset: (x: 10pt, y: 8pt), radius: (right: 3pt), breakable: true,
  above: 0.85em, below: 0.85em,
)[
  #text(size: 9pt, weight: "bold", fill: cor.darken(15%))[#upper(titulo)]
  #v(-5pt)
  #corpo
]

#let atencao(corpo) = caixa("Atenção", rgb("#b8860b"), corpo)
#let nota(corpo) = caixa("Nota", rgb("#4a5568"), corpo)
#let entrega(corpo) = caixa("Entrega", rgb("#6b5334"), corpo)

#let gab = sys.inputs.at("gab", default: "0") == "1"
#let resposta(corpo) = if gab { caixa("Resposta", rgb("#2b6cb0"), corpo) }
#let criterio(corpo) = if gab {
  block(inset: (left: 10pt), text(size: 9pt, style: "italic", fill: rgb("#4a5568"), corpo))
}

#let tabela(..args) = table(
  stroke: (x, y) => if y == 0 { (bottom: 0.8pt + primaria) } else { (bottom: 0.3pt + rgb("#c9ced6")) },
  fill: (_, y) => if y == 0 { primaria.lighten(88%) } else if calc.odd(y) { rgb("#f5f6f8") },
  inset: (x: 7pt, y: 5pt),
  ..args
)

#let questao(n, pontos, titulo) = block(above: 1.1em, below: 0.5em)[
  #text(fill: primaria, size: 11.5pt, weight: "bold")[Questão #n]
  #h(6pt) #text(size: 9pt, fill: secundaria)[(#pontos)]
  #h(6pt) #text(size: 11.5pt, weight: "bold")[#titulo]
]

// ============================= título ================================
#align(center)[
  #text(size: 16pt, weight: "bold", fill: primaria)[Miniteste 2 — O simulador]
  #v(-8pt)
  #text(size: 10pt, fill: secundaria)[Trabalho individual, para casa]
]
#v(0.3em)

#align(center)[
  #box(width: 96%)[
    #tabela(columns: (0.22fr, 1fr, 0.28fr, 0.6fr),
      [*Nome*], [], [*Matrícula*], [])
  ]
]

#nota[
  *Três das cinco questões são respondidas em português, sem escrever código.*
  Elas valem 65% da nota. Só a Questão 2 pede programação, e são quatro linhas.

  O objetivo é verificar se você entendeu como a máquina funciona — não se você
  digita Python depressa.
]

*Preparação.* Baixe `pic18.py`. Precisa apenas de Python 3, sem instalar nada.

```
python3 pic18.py programa.s --trace 10 --dump --passos 20
```

// =====================================================================
#questao(1, "2,5 pontos", [Descreva o que a máquina faz])

O processador vai executar a instrução `incf 0x20,f`, cujo código de máquina é
`0x2A20`. Ela incrementa em um o conteúdo da posição `0x20` da memória.

*Descreva, em português, passo a passo, tudo o que o processador precisa fazer
para executar essa instrução* — desde o momento em que o contador de programa
aponta para ela até o momento em que ela termina.

Numere os passos. Espera-se entre quatro e seis. Não escreva código.

#v(3.2cm)

#resposta[
  Espera-se, em qualquer redação equivalente:

  + *Buscar.* Ler duas palavras de memória de programa no endereço apontado pelo
    contador de programa, obtendo `0x2A20`.
  + *Avançar o contador* em dois bytes, para a próxima instrução.
  + *Decodificar.* Separar os campos do opcode: os bits altos identificam `incf`;
    o bit $d$ indica que o resultado vai para a memória (e não para `W`); o bit
    $a$ indica banco de acesso; os oito bits baixos dão o endereço, `0x20`.
  + *Ler* o conteúdo atual da posição `0x20`.
  + *Somar um* a esse valor, descartando o que passar de 8 bits.
  + *Escrever o resultado de volta* na posição `0x20`.

  Resposta que mencione buscar, decodificar, ler, somar e escrever de volta está
  completa, mesmo com outras palavras.
]

#criterio[
  2,5 pontos: os cinco passos essenciais, com a leitura e a escrita *na memória*
  explícitas. 1,5 ponto: descrição correta mas que faça o valor passar por um
  registrador intermediário. 0,5 ponto: apenas "soma um na posição 0x20".

  O item decisivo é o aluno perceber que ler e escrever de volta fazem parte da
  *mesma* instrução.
]

// =====================================================================
#questao(2, "2,0 pontos", [Implemente])

O simulador não conhece `incf`: ele para com a mensagem
`??? 0x2A20 (nao implementada)`.

Abra `pic18.py`, localize o comentário `# ---- EXERCICIO` dentro de `executa()`, e
implemente a instrução. Use o `decfsz`, logo acima, como modelo — a estrutura é a
mesma.

O formato de `INCF` está no conjunto de instruções do datasheet. A máscara a
testar é `0x2800`.

*Cole abaixo apenas as linhas que você escreveu.*

#v(2.6cm)

#resposta[
  ```python
  if op & 0xFC00 == 0x2800:                      # incf
      v = (self.mem.ler(f, acesso) + 1) & 0xFF
      if d: self.mem.escrever(f, v, acesso)
      else: self.W = v
      return f"incf 0x{f:02X}", 1
  ```

  O `& 0xFF` é obrigatório: a memória tem 8 bits por posição, e 255 + 1 deve dar
  0, não 256.
]

#criterio[
  2,0 pontos: funciona e respeita o bit $d$. 1,5: funciona só para $d = 1$.
  1,0: incrementa sem truncar em 8 bits. Não descontar por estilo.
]

// =====================================================================
#questao(3, "2,5 pontos", [Leia os dois despejos])

Os dois programas abaixo diferem em *uma letra*. Foram executados com
`--passos 7 --dump`, e os despejos são reais.

#grid(columns: (1fr, 1fr), gutter: 10pt,
  [
    *Programa A*
    ```
        clrf   0x20
        movlw  99
        incf   0x20,f
        incf   0x20,f
        incf   0x20,f
    fim: bra   fim
    ```
    ```
    W = 99   ciclos = 9
      020:  03 00 00 00 ...
    ```
  ],
  [
    *Programa B*
    ```
        clrf   0x20
        movlw  99
        incf   0x20,w
        incf   0x20,w
        incf   0x20,w
    fim: bra   fim
    ```
    ```
    W = 1    ciclos = 9
      020:  00 00 00 00 ...
    ```
  ],
)

Responda em português:

*(a)* No programa B, por que a posição `0x20` continua valendo zero, mesmo tendo
sido "incrementada" três vezes?

*(b)* No programa B, por que `W` vale 1 e não 3?

*(c)* Os dois gastaram exatamente 9 ciclos. O que isso diz sobre a relação entre
custo e efeito de uma instrução?

#v(3.4cm)

#resposta[
  *(a)* O sufixo `,w` põe o bit $d$ em zero, e o resultado do incremento vai para
  `W` em vez de voltar à memória. A posição `0x20` é *lida* três vezes e nunca
  escrita, então permanece com o valor que o `clrf` deixou.

  *(b)* Cada incremento parte do valor lido da memória, que é sempre zero, e
  produz 1. As três instruções fazem a mesma coisa: `W` recebe $0 + 1$. Não há
  acumulação porque o resultado nunca é guardado em lugar nenhum que a próxima
  instrução leia.

  *(c)* O custo em ciclos não depende do destino. As duas versões executam o mesmo
  número de instruções, com o mesmo tempo — e produzem resultados completamente
  diferentes.

  Ou seja: contar ciclos prevê o *tempo*, e nada mais. Um programa errado pode
  levar exatamente o mesmo tempo que o certo. Tempo e correção são propriedades
  independentes, e cada uma exige seu próprio método de verificação.
]

#criterio[
  Item (a): 1,0. Item (b): 1,0 — o difícil é perceber que não há acumulação.
  Item (c): 0,5, e é o item que separa nota máxima.

  Resposta em (b) do tipo "porque só executou uma vez" está errada: as três
  executaram.
]

// =====================================================================
#questao(4, "1,5 ponto", [Meça])

Rode o programa de piscar fornecido e preencha:

```
python3 pic18.py blink.hex --pino D,0
```

#tabela(
  columns: (0.52fr, 0.48fr),
  [*Grandeza*], [*Valor medido*],
  [Ciclos entre duas comutações do pino], [],
  [Tempo correspondente, em ms (a 250 ns por ciclo)], [],
  [Frequência do piscar, em Hz], [],
  [Ciclos de uma volta do laço mais interno], [],
)

Para a última linha, use `--trace 20` e observe as duas instruções que se repetem.

#v(0.4cm)

#resposta[
  #tabela(
    columns: (0.52fr, 0.48fr),
    [*Grandeza*], [*Valor*],
    [Ciclos entre comutações], [942 528],
    [Tempo], [235,6 ms],
    [Frequência], [2,12 Hz],
    [Volta do laço interno], [3 ciclos — `decfsz` (1) mais `bra` (2)],
  )

  Aceitar 235,632 ms e 2,1 Hz. A última linha admite a observação de que a
  *última* volta custa 2, porque o `decfsz` pula o `bra`.
]

// =====================================================================
#questao(5, "1,5 ponto", [Conclua])

No Programa A da Questão 3, a posição `0x20` foi incrementada três vezes e
terminou valendo 3. E `W` terminou valendo *99* — o mesmo valor que o `movlw`
havia colocado antes do laço.

*Explique em português por que esse `99` intacto é importante*, e diga o que
teria acontecido com o valor de `W` num processador ARM executando a mesma tarefa.

#v(3.2cm)

#resposta[
  O `99` intacto mostra que o incremento aconteceu *inteiramente dentro da
  memória*: a instrução leu `0x20`, somou e escreveu de volta, sem usar o
  acumulador em momento algum.

  Num ARM isso é impossível. A arquitetura é #emph[load-store]: instruções
  aritméticas só operam sobre registradores, e a memória só é alcançada por
  instruções de carga e armazenamento. O mesmo incremento exigiria três
  instruções — carregar em um registrador, somar, armazenar de volta — e o
  registrador usado teria perdido o conteúdo anterior.

  A consequência prática é que operações sobre *uma* posição de memória — ligar um
  bit de porta, incrementar um contador, decrementar um temporizador — custam uma
  instrução aqui e três lá. Como é isso que código de controle faz o tempo todo, a
  diferença aparece.
]

#criterio[
  1,5: identifica que a memória foi alterada sem passar pelo acumulador *e* diz
  que o ARM precisaria de três instruções com um registrador intermediário.
  1,0: só a primeira parte. 0,5: descreve o `99` sem interpretar.

  Não é necessário usar o termo "load-store".
]

// =====================================================================
#entrega[
  Um único arquivo PDF ou compactado com:

  + Este documento respondido, ou as respostas numeradas em folha separada.
  + O arquivo `pic18.py` modificado.

  Prazo: início da aula seguinte ao Roteiro 2. Individual — discutir com colegas é
  bem-vindo; entregar código idêntico, não.
]

#atencao[
  *Não existe `print` no chip.* Este trabalho inteiro é feito olhando o despejo de
  memória, porque é assim que se depura um sistema embarcado: não há terminal, não
  há tela, não há mensagem de erro. Só o conteúdo da memória e o estado dos pinos.
]
