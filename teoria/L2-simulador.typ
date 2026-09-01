// =====================================================================
// Lista 2 — O simulador (trabalho para casa)
// Microcontroladores — DENE/UFMT
// Compilar: typst compile L2-simulador.typ
// Gabarito: typst compile --input gab=1 L2-simulador.typ L2-gab.pdf
// =====================================================================

#let primaria = rgb("#1c3f6e")
#let secundaria = rgb("#b8621b")

#set page(
  paper: "a4",
  margin: (x: 2.2cm, y: 2.4cm),
  header: context {
    grid(
      columns: (1fr, auto),
      text(8.5pt, fill: primaria, weight: "semibold")[Microcontroladores],
      text(8.5pt, fill: secundaria)[Lista 2 — O simulador],
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
#set heading(numbering: "1.1")

#show heading.where(level: 1): it => block(above: 1.3em, below: 0.7em)[
  #text(fill: primaria, size: 13pt, weight: "bold")[#it]
]
#show heading.where(level: 2): it => block(above: 1.0em, below: 0.5em)[
  #text(fill: primaria.darken(10%), size: 11pt, weight: "bold")[#it]
]

#show raw.where(block: true): it => block(
  width: 100%, fill: rgb("#f5f6f8"), stroke: (left: 3pt + primaria),
  inset: (x: 10pt, y: 8pt), radius: (right: 3pt), breakable: true,
  text(size: 8.8pt, it),
)
#show raw.where(block: false): it => box(
  fill: rgb("#eef0f3"), inset: (x: 3pt, y: 1pt), radius: 2pt, text(size: 9.3pt, it),
)

#let caixa(titulo, cor, corpo) = block(
  width: 100%, fill: cor.lighten(90%), stroke: (left: 3pt + cor),
  inset: (x: 10pt, y: 8pt), radius: (right: 3pt), breakable: true,
  above: 0.9em, below: 0.9em,
)[
  #text(size: 9pt, weight: "bold", fill: cor.darken(15%))[#upper(titulo)]
  #v(-5pt)
  #corpo
]

#let objetivos(corpo) = caixa("Objetivos", primaria, corpo)
#let atencao(corpo) = caixa("Atenção", rgb("#b8860b"), corpo)
#let nota(corpo) = caixa("Nota", rgb("#4a5568"), corpo)
#let tarefa(corpo) = caixa("Tarefa", rgb("#2f6b4f"), corpo)
#let conceito(corpo) = caixa("Conceito", rgb("#5b3a8e"), corpo)
#let divergencia(corpo) = caixa("Divergência", rgb("#a03070"), corpo)
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

// ============================= título ================================
#align(center)[
  #text(size: 17pt, weight: "bold", fill: primaria)[Lista 2 — O simulador]
  #v(-8pt)
  #text(size: 10.5pt, fill: secundaria)[Implementar instruções e observar a memória]
  #v(-4pt)
  #text(size: 9pt)[Microcontroladores — DENE/UFMT · trabalho individual, para casa]
]
#v(0.5em)

#align(center)[
  #box(width: 92%)[
    #tabela(columns: (0.25fr, 1fr, 0.25fr, 0.7fr),
      [*Nome*], [], [*Matrícula*], [])
  ]
]

#objetivos[
  - Implementar, no simulador, instruções que operam diretamente sobre a memória.
  - Usar o despejo de memória para observar o estado da máquina, na ausência de
    qualquer forma de impressão.
  - Demonstrar experimentalmente que o acumulador não participa dessas operações.
  - Comparar o custo de uma tarefa escrita ao estilo registrador-memória e ao
    estilo #emph[load-store].
]

// =====================================================================
= Preparação

Baixe `pic18.py`. Não precisa instalar nada além do Python 3.

```
$ python3 pic18.py programa.s  --trace 10 --dump
```

#tabela(
  columns: (0.28fr, 1fr),
  [*Opção*], [*O que faz*],
  [`--trace N`], [Mostra as $N$ primeiras instruções executadas, com o custo em ciclos],
  [`--dump`], [Ao final, despeja `W`, a pilha e os 64 primeiros bytes da memória],
  [`--passos N`], [Interrompe após $N$ instruções. Útil para laços infinitos],
  [`--pino D,0`], [Mede as comutações de RD0 e calcula a frequência],
)

O arquivo de entrada pode ser um `.hex` gravável no chip ou um `.s` em texto, que
o próprio simulador monta. O montador aceita rótulos, registradores por nome
(`LATD`) ou por número (`0x20`), e os sufixos `,f`, `,w` e número de bit.

```
        clrf   0x20
        movlw  99
laco:   incf   0x20,f
        bra    laco
```

#atencao[
  *Não há `print`.* Este é o ponto da lista, não uma limitação a contornar.

  No chip real não existe terminal: para saber o valor de uma variável você acende
  um LED, envia por serial ou olha a memória pelo depurador. O `--dump` é o
  equivalente da terceira opção, e é assim que se depura um sistema embarcado.
]

// =====================================================================
= Parte 1 — A instrução que não existe

Rode o programa acima. Ele para na terceira instrução:

```
  0004  2A20  ??? 0x2A20 (nao implementada)
```

O montador conhece `incf` e produziu o opcode correto. O *executor* não sabe o
que fazer com ele. Sua tarefa é ensiná-lo.

#tarefa[
  *E2.1 — Implementar `incf`.*

  *(a)* Consulte o formato de `INCF` no conjunto de instruções do datasheet e
  anote os campos.

  *(b)* Implemente-a em `executa()`, seguindo o padrão do `decfsz` que já está
  lá. Respeite o bit $d$.

  *(c)* Rode o programa e mostre o despejo. Quanto vale `0x20`? Quanto vale `W`?

  *(d)* Explique o que o valor de `W` demonstra sobre a arquitetura.
]

#resposta[
  *(a)* `INCF f,d,a` tem formato `0010 10da ffffffff`, portanto máscara `0x2800`
  sobre os seis bits altos. Uma palavra, um ciclo.

  *(b)*
  ```python
  if op & 0xFC00 == 0x2800:                      # incf
      v = (self.mem.ler(f, acesso) + 1) & 0xFF
      if d: self.mem.escrever(f, v, acesso)
      else: self.W = v
      return f"incf 0x{f:02X}", 1
  ```

  *(c)* Com `--passos 8`, o contador em `0x20` avança normalmente e `W` permanece
  em *99* — o valor que `movlw` deixou lá antes do laço.

  *(d)* `W` não foi tocado. O incremento leu a memória, somou e escreveu de volta
  na memória, tudo numa instrução, sem intermediário.

  Numa arquitetura #emph[load-store] isso é impossível: nenhuma instrução
  aritmética pode ter memória como destino. O incremento exigiria `ldr`, `adds` e
  `str`, e o valor teria obrigatoriamente passado por um registrador.

  O `99` intacto é a evidência experimental de que o PIC18 é registrador-memória.
]

#criterio[
  O item (d) vale mais que os outros três somados. Resposta que apenas descreva o
  código sem interpretar o `W = 99` não atingiu o objetivo da lista.
]

// =====================================================================
= Parte 2 — Duas mais, e uma sem acumulador

#tarefa[
  *E2.2 — `addwf` e `movff`.*

  *(a)* Implemente `ADDWF f,d,a`, que soma `W` ao conteúdo de `f`. Consulte o
  formato no datasheet.

  *(b)* Implemente `MOVFF fs,fd`. Atenção: ela ocupa *duas palavras* — a segunda
  contém o endereço de destino. Você precisará ler a palavra seguinte e avançar o
  contador de programa. Custo: dois ciclos.

  *(c)* Escreva um programa que coloque 7 em `0x30`, some 5 a ele, e copie o
  resultado para `0x31`. Mostre o despejo.

  *(d)* Quantas instruções `MOVFF` economiza em relação a fazer a mesma cópia com
  `movf` e `movwf`? E quantos ciclos?
]

#resposta[
  *(a)* `ADDWF` tem formato `0010 01da ffffffff`, máscara `0x2400`.

  *(b)*
  ```python
  if (op & 0xF000) == 0xC000:                    # movff
      dst = self.palavra(pc + 2) & 0xFFF
      self.mem.dados[dst] = self.mem.dados[op & 0xFFF]
      self.PC += 2                               # pula a segunda palavra
      return "movff", 2
  ```

  *(c)*
  ```
          movlw  7
          movwf  0x30
          movlw  5
          addwf  0x30,f      ; 0x30 = 12
          movff  0x30,0x31
  fim:    bra    fim
  ```
  O despejo mostra `0C 0C` nas posições `0x30` e `0x31`.

  *(d)* `MOVFF` é uma instrução contra duas (`movf f,w` seguido de `movwf`).
  Em ciclos, porém, é *empate*: `MOVFF` custa 2, e o par custa 1 + 1 = 2.

  A economia real é de uma palavra de Flash e, sobretudo, de não destruir o
  conteúdo de `W` — que pode estar sendo usado para outra coisa. Em código gerado
  por compilador isso importa; escrito à mão, quase nunca.
]

#criterio[
  O item (d) tem uma armadilha: a maioria vai supor que menos instruções significa
  menos ciclos. Resposta que perceba o empate e identifique a preservação de `W`
  como o ganho verdadeiro merece nota cheia.
]

// =====================================================================
= Parte 3 — Os dois estilos, medidos

#tarefa[
  *E2.3.* Some três variáveis, guardadas em `0x40`, `0x41` e `0x42`, deixando o
  resultado em `0x43`.

  *(a)* Escreva ao *estilo registrador-memória*, usando `addwf` com destino na
  memória sempre que possível. Conte instruções e ciclos.

  *(b)* Escreva ao *estilo load-store*: toda operação passa por `W`, e a memória
  só é tocada por `movf` e `movwf`. Conte de novo.

  *(c)* Compare. Explique por que a diferença é menor do que a discussão sobre
  arquitetura faria supor.

  *(d)* Agora considere a tarefa oposta: incrementar em um uma única variável.
  Compare os dois estilos nesse caso e explique por que aqui a diferença é grande.
]

#resposta[
  *(a)* Estilo registrador-memória, acumulando no destino:
  ```
          movf   0x40,w
          movwf  0x43        ; 0x43 = a
          movf   0x41,w
          addwf  0x43,f      ; 0x43 = a + b
          movf   0x42,w
          addwf  0x43,f      ; 0x43 = a + b + c
  ```
  Seis instruções, seis ciclos.

  *(b)* Estilo #emph[load-store]:
  ```
          movf   0x40,w
          addwf  0x41,w      ; ainda le memoria...
          addwf  0x42,w
          movwf  0x43
  ```
  Quatro instruções, quatro ciclos — *menos* que o item (a).

  *(c)* A comparação surpreende, e a razão é que o item (b) não é realmente
  #emph[load-store]: `addwf 0x41,w` continua lendo a memória diretamente, o que
  uma máquina #emph[load-store] verdadeira não permite. Num Cortex-M o mesmo
  trecho exigiria três `ldr`, dois `add` e um `str` — seis instruções, e nenhuma
  delas com operando em memória.

  Ou seja: quando há vários operandos distintos, acumular em `W` é a melhor
  estratégia *no PIC também*. A vantagem da arquitetura não está em somar vetores.

  *(d)* Para incrementar uma única variável:

  #tabela(
    columns: (0.4fr, 0.3fr, 0.3fr),
    [*Estilo*], [*Instruções*], [*Ciclos*],
    [`incf 0x40,f`], [1], [1],
    [`movf` + `addlw`/`incf w` + `movwf`], [3], [3],
  )

  Três vezes mais. É aqui que a diferença aparece, e é o caso mais comum em código
  de controle: mexer em *uma* posição por vez — ligar um bit de porta, incrementar
  um contador, decrementar um temporizador.

  A conclusão útil: a vantagem do PIC18 é sobre operações de operando único, não
  sobre expressões aritméticas. Um laço de contagem se beneficia; um filtro
  digital não.
]

#criterio[
  Este exercício existe para desmontar a leitura ingênua de que "registrador-memória
  é sempre melhor". Resposta que conclua isso, mesmo tendo feito as contas certas,
  não leu os próprios números.
]

// =====================================================================
= Parte 4 — Olhando o despejo

#tarefa[
  *E2.4.* Rode este programa com `--passos 12 --dump` e responda *antes* de
  interpretar o resultado.

  ```
          movlw  0xAA
          movwf  0x50
          movwf  0x51
          clrf   0x51
          movlw  0x0F
          addwf  0x50,f
  fim:    bra    fim
  ```

  *(a)* Preveja o conteúdo de `0x50` e `0x51` ao final. Escreva a previsão antes
  de executar.

  *(b)* Execute e compare.

  *(c)* Nada no programa escreve em `LATD`. Ainda assim, o que o despejo mostraria
  se o programa tivesse acionado um pino? Em que região da memória?

  *(d)* O despejo mostra apenas os 64 primeiros bytes. Modifique `despeja()` para
  aceitar um endereço inicial e exibir a região dos registradores especiais.
  Rode o `blink.hex` com essa modificação e localize `LATD`.
]

#resposta[
  *(a)* e *(b)* `0x50` recebe `0xAA`, depois soma `0x0F` e fica `0xB9`. `0x51`
  recebe `0xAA` e em seguida é zerado por `clrf`, ficando `0x00`. O despejo mostra
  `B9 00` a partir de `0x50`.

  *(c)* Apareceria na região alta, a partir de `0xF80`, onde moram os registradores
  especiais. `LATD` está em `0xF8C`.

  Repare que é o *mesmo* despejo, o mesmo vetor de memória: não há nada de especial
  no endereço de um pino do ponto de vista da máquina. A diferença está no silício
  ligado atrás dele.

  *(d)* Basta chamar `despeja(cpu, 0xF80, 32)`. Com o `blink.hex` rodando, o byte
  em `0xF8C` alterna entre `00` e `01` conforme o `btg` executa — é o estado do
  pino, visível como um número.
]

#criterio[
  O item (c) é o mais importante: verifica se o aluno entendeu que registradores
  de periférico são endereços comuns, e não uma categoria à parte. É a afirmação
  central da Aula 1, §3, testada de outro ângulo.
]

// =====================================================================
= Parte 5 — O erro que compila

#tarefa[
  *E2.5.* Na sua implementação do `incf`, troque a máscara de `0x2800` para
  `0x2C00`.

  *(a)* Que instrução `0x2C00` designa? Consulte o datasheet.

  *(b)* Rode o programa da Parte 1. Descreva o que acontece.

  *(c)* Este material cometeu exatamente esse tipo de erro ao gerar código à mão:
  um `decfsz` codificado como `0x2200`, que é `ADDWFC`. Descreva o sintoma que
  isso produziu num programa de piscar LED, e explique por que ele é mais caro de
  achar do que um erro que impedisse a compilação.

  *(d)* Que procedimento teria detectado o erro em segundos?
]

#resposta[
  *(a)* `0x2C00` é `DECFSZ`. As duas instruções diferem em dois bits do código da
  operação.

  *(b)* O contador passa a ser decrementado em vez de incrementado, e o `decfsz`
  ganha o comportamento de pular. Partindo de zero, `0x20` vai para `0xFF` e o
  laço se comporta de maneira completamente diferente — sem qualquer erro
  reportado.

  *(c)* No caso do `decfsz` virando `ADDWFC`, o contador era *somado* em vez de
  decrementado, nunca chegava a zero, o salto nunca ocorria, e o laço de atraso
  não terminava. O LED ficava parado.

  O custo está em que nada acusa: o montador aceita, o gravador aceita, o chip
  executa. O programador procura o defeito no algoritmo — na lógica do atraso, nas
  constantes, no pino — porque a hipótese "o opcode está errado" não ocorre a
  ninguém. Um erro que impede a montagem aponta a linha; este aponta para o lugar
  errado.

  *(d)* Montar o mesmo fonte numa ferramenta independente — o MPLAB — e comparar
  os arquivos palavra por palavra. Foi assim que o erro real foi encontrado.

  Note que conferir o *checksum* do arquivo `.hex` não teria ajudado: ele estava
  correto. O checksum garante que os bytes chegaram íntegros, não que são os bytes
  certos.
]

#criterio[
  O item (d) é o objetivo da parte inteira. Verificação exige uma fonte
  independente; repetir o próprio método com mais cuidado não é verificação.
]

// =====================================================================
= Entrega

#entrega[
  Um arquivo compactado contendo:

  + `pic18.py` modificado, com as instruções implementadas.
  + Os arquivos `.s` que você escreveu.
  + Um documento de no máximo *três páginas* com as respostas, incluindo os
    despejos de memória colados como texto.

  Prazo: início da aula seguinte. Trabalho individual — discutir com colegas é
  bem-vindo, entregar código idêntico não.
]

#conceito[
  *Por que esta lista existe.* Vocês contaram ciclos a mão na Aula 2 e vão
  medi-los no osciloscópio no Roteiro 2. Esta lista é o terceiro método, e o único
  em que vocês constroem o instrumento em vez de usá-lo.

  Depois de escrever `executa()`, a frase "o processador busca, decodifica e
  executa" deixa de ser uma definição decorada e passa a ser algo que vocês
  implementaram. É a diferença entre saber o que uma instrução faz e saber por que
  ela faz.
]
