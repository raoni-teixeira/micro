// =====================================================================
// Aula 2 — Contando ciclos
// Microcontroladores — DENE/UFMT
// Compilar: typst compile aula2-contando-ciclos.typ
// Gabarito: typst compile --input gab=1 aula2-contando-ciclos.typ aula2-gab.pdf
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
      text(8.5pt, fill: secundaria)[Aula 2 — Contando ciclos],
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
  width: 100%,
  fill: rgb("#f5f6f8"),
  stroke: (left: 3pt + primaria),
  inset: (x: 10pt, y: 8pt),
  radius: (right: 3pt),
  breakable: true,
  text(size: 8.8pt, it),
)
#show raw.where(block: false): it => box(
  fill: rgb("#eef0f3"), inset: (x: 3pt, y: 1pt), radius: 2pt, text(size: 9.3pt, it),
)

// --------------------------- caixas ---------------------------------
#let caixa(titulo, cor, corpo) = block(
  width: 100%,
  fill: cor.lighten(90%),
  stroke: (left: 3pt + cor),
  inset: (x: 10pt, y: 8pt),
  radius: (right: 3pt),
  breakable: true,
  above: 0.9em,
  below: 0.9em,
)[
  #text(size: 9pt, weight: "bold", fill: cor.darken(15%))[#upper(titulo)]
  #v(-5pt)
  #corpo
]

#let objetivos(corpo) = caixa("Objetivos", primaria, corpo)
#let atencao(corpo) = caixa("Atenção", rgb("#b8860b"), corpo)
#let perigo(corpo) = caixa("Perigo", rgb("#b02020"), corpo)
#let nota(corpo) = caixa("Nota", rgb("#4a5568"), corpo)
#let tarefa(corpo) = caixa("Tarefa", rgb("#2f6b4f"), corpo)
#let experimento(corpo) = caixa("Experimento", rgb("#1a6f7a"), corpo)
#let conceito(corpo) = caixa("Conceito", rgb("#5b3a8e"), corpo)
#let bancada(corpo) = caixa("Bancada", rgb("#6b5334"), corpo)
#let divergencia(corpo) = caixa("Divergência", rgb("#a03070"), corpo)
#let contexto(corpo) = caixa("Contexto", rgb("#5a6570"), corpo)

// Gabarito: compilar com  --input gab=1  para a versão do professor
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
  #text(size: 17pt, weight: "bold", fill: primaria)[Aula 2 — Contando ciclos]
  #v(-8pt)
  #text(size: 10.5pt, fill: secundaria)[A listagem como lupa: pipeline, banco de acesso e pilha]
  #v(-4pt)
  #text(size: 9pt)[Microcontroladores — DENE/UFMT]
]
#v(0.6em)

#objetivos[
  - Localizar e ler a listagem gerada pelo compilador, associando cada instrução
    de máquina à linha de C que a originou.
  - Calcular o tempo de execução de um trecho por contagem de ciclos,
    distinguindo instruções de um ciclo das de dois e do desvio condicional.
  - Explicar o sufixo `,c` presente em quase toda instrução gerada, e dizer o que
    muda no custo quando ele desaparece.
  - Construir uma rotina de atraso cuja duração é decidida em tempo de execução, e
    prever seu período #emph[antes] de medir.
  - Identificar as fontes de incerteza dessa previsão e justificar por que
    contagem de ciclos não substitui temporizador por #emph[hardware].
]

// =====================================================================
= A duração não se escreve em C

A Aula 1 fechou com uma afirmação que ficou sem prova: a listagem e o mapa de
memória são instrumentos de trabalho, não subprodutos descartáveis. Hoje ela é
cobrada.

E é cobrada por um problema concreto. Na Oficina 1, vocês produziram notas
musicais no #emph[buzzer] comutando um pino dentro de um laço de espera. Para
mudar a nota, muda-se a duração da espera — e aí `__delay_ms` não serve, porque
ela é uma macro e exige argumento constante em tempo de compilação (Aula 1,
§7.6). A duração precisa ser um parâmetro, e não há função de biblioteca que
faça isso.

#conceito[
  Quando a duração vira parâmetro, ela deixa de ser propriedade do programa que
  vocês escreveram e passa a ser propriedade do *código que o compilador gerou*.

  São coisas diferentes, e a segunda não está no arquivo `.c`. Uma linha de C não
  tem duração; um bloco de instruções de máquina tem. Entre uma e outro há uma
  tradução que ninguém mostrou a vocês ainda.
]

Esta aula abre essa tradução. Não para escrever em #emph[assembly] — vocês não
vão precisar disso no semestre — mas para *ler*, que é uma habilidade muito mais
barata e imediatamente útil. Doze mnemônicos bastam.

== O que a lupa vai mostrar

A Aula 1 encerrou com uma seção de contexto — pilha, contador de programa,
paralelismo, banco de acesso — apresentada como explicação de fundo, sem uso
prático. Hoje cada um desses itens vira um número mensurável, e a listagem é o
que os torna visíveis.

#tabela(
  columns: (0.05fr, 0.5fr, 0.9fr),
  [], [*O que a seção estabelece*], [*Onde isso aparece na listagem*],
  [2], [Como se lê uma listagem], [As quatro colunas e a origem em C de cada instrução],
  [3], [Uma instrução por ciclo, exceto no desvio], [`goto`, `call` e `return` ocupando dois ciclos],
  [4], [O banco de acesso é o que torna o C viável aqui], [O sufixo `,c` em quase toda linha gerada],
  [5], [Chamar uma função custa, e a pilha não é RAM], [Os ciclos de `call` mais `return`],
  [6], [A construção: atraso ajustável em execução], [A contagem de ciclos do laço],
  [7], [Por que a previsão erra, e quanto], [O caminho que só executa às vezes],
)

// =====================================================================
= Anatomia de uma listagem

A listagem é um arquivo de texto com extensão `.lst`, produzido pelo montador a
partir do que o compilador gerou. No MPLAB X, ela aparece no diretório de
construção do projeto; pela linha de comando, o caminho mais direto para
inspecionar um trecho é pedir só a tradução:

```
xc8-cc -mcpu=18F4550 -S programa.c -o programa.s
```

Todos os trechos desta aula vêm de uma listagem real, gerada nesta bancada a
partir do programa abaixo. Ele não faz nada de útil — foi escrito para produzir
poucas instruções e ser lido por inteiro.

```c
#include <xc.h>
#include <stdint.h>

volatile uint8_t heater_on   = 0;
volatile int16_t temperatura = 250;   /* decimos de grau */
volatile int16_t setpoint    = 300;

void controla(void)
{
    if (temperatura < setpoint)
        LATCbits.LATC1 = 1, heater_on = 1;
    else
        LATCbits.LATC1 = 0, heater_on = 0;
}
```

== As quatro colunas

```
   438                           ;macro_do_while.c: 87: if (temperatura < setpoint)
   439   000802  5001               movf   _setpoint^0,w,c
   440   000804  5C03               subwf  _temperatura^0,w,c
```

#tabela(
  columns: (0.22fr, 1fr),
  [*Coluna*], [*Conteúdo*],
  [`439`], [Número da linha da listagem. Sem relação com o arquivo `.c`],
  [`000802`], [Endereço na memória de programa, em bytes. É o valor que o contador de programa terá quando esta instrução for buscada],
  [`5001`], [A instrução propriamente dita: dois bytes gravados na Flash. É isto que vai para o `.hex`],
  [`movf _setpoint^0,w,c`], [A mesma instrução em forma legível],
)

As linhas iniciadas por ponto e vírgula são comentários que o compilador insere
para dizer *de qual linha de C* saiu o bloco seguinte. São elas que transformam a
listagem em instrumento de diagnóstico: permitem perguntar "o que esta linha
minha virou?" e obter resposta.

#nota[
  Repare no endereço: `0x0802` e depois `0x0804`. Instruções ocupam dois bytes e
  os endereços avançam de dois em dois. É a memória de programa de 16 bits da
  Aula 1, §4, vista de perto.
]

== Uma instrução decodificada à mão

Vale fazer isto uma vez na vida, porque desfaz o mistério de forma definitiva.
Mais adiante na mesma listagem aparece:

```
   453   000820  828B               bsf    139,1,c
```

O manual do dispositivo dá o formato de `BSF` — ligar um bit — como
`1000 bbba ffffffff`. Escrevendo `0x828B` em binário:

$ underbrace(1000, "código") space underbrace(001, b) space underbrace(0, a) space underbrace(10001011, f) $

#tabela(
  columns: (0.14fr, 0.28fr, 1fr),
  [*Campo*], [*Valor*], [*Significado*],
  [$b$], [`001` = 1], [O bit a ligar é o bit 1],
  [$a$], [`0`], [Endereço interpretado no banco de acesso],
  [$f$], [`10001011` = `0x8B`], [Endereço 139 — que é `LATC`],
)

Ou seja: `LATCbits.LATC1 = 1;` compilou para *uma única instrução de dois bytes*,
que executa em 250 ns e liga o bit 1 do endereço `0x8B`.

#conceito[
  Isto é a afirmação central da Aula 1, §3 — "os pinos são posições de memória" —
  já não como analogia, mas como campo de bits dentro de um opcode. O endereço
  139 não é tratado de maneira especial em lugar nenhum: é o mesmo campo $f$ que
  apontaria para uma variável comum.

  O que faz `0x8B` acionar um aquecedor é o silício ligado atrás dele, não a
  instrução.
]

== O menor programa que aciona um pino

Se `LATCbits.LATC1 = 1` cabe em uma instrução, quanto ocupa um programa completo
que acende um LED e para? Este:

```c
#include <xc.h>

void main(void)
{
    LATDbits.LATD0   = 1;   /* valor no latch  */
    TRISDbits.TRISD0 = 0;   /* so' entao saida */
    while (1) { }
}
```

Traduzido, é a listagem inteira — três instruções, oito bytes de Flash:

```
000800  808C          bsf   140,0,c      ; LATD  bit 0 <- 1
000802  9095          bcf   149,0,c      ; TRISD bit 0 <- 0
000804  EF02 F004     goto  $            ; while (1)
```

#tabela(
  columns: (0.26fr, 1fr),
  [*Instrução*], [*O que faz, e quando o LED acende*],
  [`bsf 140,0,c`],
    [#emph[Bit set file]. Liga o bit 0 do endereço 140, que é `LATD`. Escreve 1 no
     latch de RD0 — e *nada acontece eletricamente*. No #emph[reset] o pino ainda
     é entrada, em alta impedância. O valor fica guardado, esperando],
  [`bcf 149,0,c`],
    [#emph[Bit clear file]. Zera o bit 0 de `TRISD`; zero é saída. RD0 passa a ser
     saída e assume o que já estava no latch. *O LED acende aqui*],
  [`goto $`],
    [O `$` é notação do montador para "o endereço desta própria instrução". Um
     desvio para si mesma, dois ciclos, indefinidamente. É o `while (1)` do C],
)

#conceito[
  Estas duas primeiras instruções *são* a regra `LAT` antes de `TRIS` da Aula 1,
  §3, reduzida à sua forma mínima. A regra não é convenção de estilo nem
  recomendação do fabricante: é a ordem de dois opcodes.

  Trocá-las faz o pino virar saída enquanto o latch ainda contém o valor
  indefinido do #emph[reset], e só depois receber o valor pretendido. Com um LED,
  o pulso é invisível. Com o #emph[cooler], é o tranco que vocês ouviram na
  Oficina 1.
]

#nota[
  Compare com o exemplo anterior, que gerou 51 instruções. A diferença não está no
  acionamento do pino — que continua custando uma instrução — e sim em ter duas
  variáveis globais `int16_t` inicializadas e uma comparação com sinal. O
  acionamento nunca foi a parte cara.
]

== Onde está o mapeamento dos pinos

O programa diz `LATDbits.LATD0`; a listagem diz `140`. Entre um e outro há quatro
camadas, e apenas a primeira é software.

#tabela(
  columns: (0.05fr, 0.36fr, 1fr),
  [], [*Camada*], [*Onde vive, e o que pode mudá-la*],
  [1], [Nome $arrow.r$ endereço],
    [No cabeçalho do dispositivo, incluído por `xc.h`. É uma declaração da forma
     `extern volatile unsigned char LATD __at(0xF8C);` mais a união de campos de
     bits que dá `LATDbits.LATD0`. Pura tabela de nomes — as 216 linhas `equ` do
     início da listagem são essa mesma tabela vista pelo montador],
  [2], [Endereço $arrow.r$ bloco interno],
    [Fixo em silício. Documentado no mapa de registradores da folha de dados.
     Nenhum ajuste de software altera],
  [3], [Bloco interno $arrow.r$ pino físico],
    [Fixo em silício. RD0 é o pino 19 do encapsulamento de 40 pinos. Está no
     diagrama de pinagem],
  [4], [Pino físico $arrow.r$ o que há na placa],
    [*Não existe em arquivo nenhum.* Está no esquemático da XM118 e na serigrafia
     — e a serigrafia tem precedência sobre o manual do fabricante],
)

Para inspecionar a camada 1 na sua instalação:

```
grep -n "LATD\b" /opt/microchip/xc8/v2.*/pic/include/proc/pic18f4550.h
```

#atencao[
  A camada 4 é a que interessa na bancada, e é a única que nenhuma ferramenta
  conhece. *Nada no programa diz que RD0 é um LED* — nem que RC2 vai ao
  #emph[cooler] ou ao #emph[buzzer] conforme a posição de CH3-5 e CH3-6.

  É exatamente a lacuna descrita na resposta do Exercício 1.6: o compilador não
  avisa que `LATD = 0x01` desliga o aquecedor porque a informação "o bit 1 deste
  endereço comanda 12 V" não existe em lugar algum que ele possa ler. Ela mora no
  esquema elétrico e na cabeça de quem escreveu.
]

== O código que você não escreveu

Ainda assim, a listagem completa do exemplo maior tem 660 linhas. Vale saber de
onde vêm, porque a resposta é útil.

#tabela(
  columns: (0.4fr, 0.2fr, 1fr),
  [*Bloco*], [*Linhas*], [*O que é*],
  [Definições `equ`], [216], [Um nome para cada registrador do dispositivo, inclusive os do módulo USB que o programa nunca toca. Custa zero de Flash],
  [Diretivas, símbolos, mapa], [cerca de 390], [Organização do montador e do ligador],
  [*Instruções de máquina*], [*51*], [O programa propriamente dito],
)

E das 51, apenas 33 são suas: 16 pertencem a um bloco de partida que o compilador
insere antes de `main`.

```
movlw low __pidataCOMRAM      ; aponta para os valores iniciais, na Flash
movwf tblptrl,c
lfsr  0,__pdataCOMRAM         ; aponta para o destino, na RAM
tblrd *+                      ; le um byte da Flash
movff tablat,postinc0         ; escreve na RAM
bnz   copy_data0              ; repete ate' terminar
clrf  __pbssCOMRAM            ; zera as nao inicializadas
goto  _main
```

#conceito[
  *Por que esse bloco existe.* A declaração `int16_t temperatura = 250;` promete
  que a variável vale 250 quando `main` começa. Mas a RAM não guarda nada ao ser
  energizada: o 250 precisa estar na Flash e ser copiado.

  E copiar da Flash não é acesso comum à memória — é a leitura de tabela `TBLRD`
  anunciada na Aula 1, §4, aqui executando. A separação Harvard, que naquela aula
  era uma consequência a acreditar, é este laço.
]

#atencao[
  Uma global inicializada custa *três vezes*: bytes de RAM, bytes de Flash com a
  cópia do valor inicial, e ciclos na partida. Uma global sem inicializador cai
  apenas no `clrf` que zera a região não inicializada.

  Escrever `= 0` numa global não é neutro — é pedir uma cópia da Flash para gravar
  um zero que já estaria lá.
]

== Os doze mnemônicos que bastam

O conjunto completo do PIC18 tem *75 instruções* — mais oito se `XINST` for
habilitado, o bit de configuração que a Aula 1, §6, manda manter desligado por
não ser suportado pelo XC8. Para comparação: o PIC16 tem 35, um Cortex-M0+ tem
cerca de 56, e um processador de mesa tem milhares.

#conceito[
  *O número engana.* O que caracteriza este núcleo não é a quantidade de
  instruções, e sim três decisões:

  / Um acumulador só: `WREG`. Não há banco de registradores — coerente com a
    afirmação da Aula 1, §3, de que toda posição de memória é um registrador.
  / Operação direta sobre a memória: `bsf 140,0` altera a memória sem carregar
    nada antes.
  / Largura fixa: toda instrução ocupa uma palavra, exceto `goto`, `call`, `lfsr`
    e `movff`, que ocupam duas.

  A segunda é o oposto de uma arquitetura #emph[load-store], em que a memória só
  é tocada por instruções de carga e armazenamento. Ligar um bit de porta custa
  uma instrução aqui e três num Cortex-M — que ainda assim termina antes, por
  operar a uma frequência muito maior. Contagem de instruções não é medida de
  desempenho.
]

Praticamente tudo que o XC8 gera em código de controle cabe nesta lista.

#tabela(
  columns: (0.2fr, 0.42fr, 1fr),
  [*Instrução*], [*Efeito*], [*Observação*],
  [`movlw k`], [$W arrow.l k$], [Carrega uma constante no acumulador],
  [`movwf f`], [$f arrow.l W$], [Escreve o acumulador na memória],
  [`movf f,w`], [$W arrow.l f$], [Lê da memória; afeta o indicador de zero],
  [`clrf f`], [$f arrow.l 0$], [Zera uma posição],
  [`bsf f,b`], [Liga o bit $b$ de $f$], [Uma instrução, sem ler-modificar-escrever visível no código],
  [`bcf f,b`], [Desliga o bit $b$ de $f$], [—],
  [`btfsc f,b`], [Pula a próxima instrução se o bit for 0], [Custo variável; vide §3],
  [`btfss f,b`], [Pula a próxima instrução se o bit for 1], [—],
  [`subwf f,w`], [$W arrow.l f - W$], [Comparações saem daqui],
  [`subwfb f,w`], [Subtração com empréstimo], [Byte alto de operações de 16 bits],
  [`goto k`], [Desvio incondicional], [Duas palavras, dois ciclos],
  [`call k`], [Chamada de função], [Empilha o retorno],
  [`return`], [Retorno], [Desempilha],
  [`xorlw k`], [$W arrow.l W xor k$], [Aparece na comparação com sinal; vide §3],
)

O sufixo `,w` significa que o resultado vai para o acumulador em vez de voltar à
memória. O sufixo `,c` é assunto da seção 4. O `^0` que acompanha os nomes é
notação do montador para o deslocamento dentro do banco — pode ser ignorado na
leitura.

// =====================================================================
= Um ciclo por instrução, exceto quando não

A Aula 1, §8.3, afirmou que programa e dados em barramentos separados permitem
buscar a próxima instrução enquanto a atual executa, e que por isso o
processador completa uma instrução por ciclo. Também afirmou que desvios são
exceção. Agora dá para usar isso.

#conceito[
  *Por que o desvio custa o dobro.* Enquanto a instrução no endereço $n$ executa,
  a do endereço $n+2$ já está sendo buscada. Se a instrução em $n$ for um desvio,
  a próxima a executar não é a de $n+2$: a busca adiantada foi trabalho perdido, e
  o processador gasta um ciclo adicional buscando o destino verdadeiro.

  Não é penalidade nem defeito. É o preço de um mecanismo que, no resto do tempo,
  entrega uma instrução por ciclo de graça.
]

#tabela(
  columns: (0.46fr, 0.2fr, 1fr),
  [*Instrução*], [*Ciclos*], [*Observação*],
  [Aritmética, lógica, movimentação, bit], [1], [A maioria esmagadora do código],
  [`goto`, `call`, `return`, `bra`], [2], [Sempre; o desvio é sempre tomado],
  [`btfsc` / `btfss` que *não* pula], [1], [Segue em frente; nada foi descartado],
  [`btfsc` / `btfss` que pula uma instrução de uma palavra], [2], [Descarta a busca adiantada],
  [`btfsc` / `btfss` que pula uma instrução de *duas* palavras], [3], [Precisa descartar as duas palavras],
)

#atencao[
  A última linha é a mais esquecida, e `goto` é justamente uma instrução de duas
  palavras. Um desvio condicional que pula um `goto` custa três ciclos. Como o
  XC8 sem otimização gera exatamente esse padrão o tempo todo, o erro se acumula
  rápido em qualquer contagem manual.
]

== Contando uma função inteira

A listagem completa de `controla()`, com os ciclos anotados. `C` é o indicador de
transporte, que a comparação deixou preparado.

```
        _controla:
000802  movf   _setpoint^0,w,c            1
000804  subwf  _temperatura^0,w,c         1
000806  movf   (_temperatura+1)^0,w,c     1
000808  xorlw  128                        1
00080A  movwf  ??_controla^0,c            1
00080C  movf   (_setpoint+1)^0,w,c        1
00080E  xorlw  128                        1
000810  subwfb ??_controla^0,w,c          1
000812  btfsc  status,0,c                 1 ou 3
000814  goto   u11                        2   (so' se C = 1)
000818  goto   u10                        2   (so' se C = 0)
00081C  u11: goto l17                     2
000820  u10: bsf 139,1,c                  1
000822  movlw  1                          1
000824  movwf  _heater_on^0,c             1
000826  goto   l19                        2
00082A  l17: bcf 139,1,c                  1
00082C  clrf   _heater_on^0,c             1
00082E  l19: return                       2
```

#tabela(
  columns: (0.44fr, 0.24fr, 0.24fr),
  [*Trecho*], [*Aquecedor liga*], [*Aquecedor desliga*],
  [Comparação de 16 bits (8 instruções)], [8], [8],
  [`btfsc`], [3 (pula)], [1 (não pula)],
  [Desvios até o ramo], [2], [4],
  [Corpo do ramo], [3], [2],
  [Saída do ramo], [2], [—],
  [`return`], [2], [2],
  [`call`, no chamador], [2], [2],
  [*Total*], [*22 ciclos*], [*19 ciclos*],
)

A 250 ns por ciclo: 5,5 µs num caso, 4,75 µs no outro.

#conceito[
  *A mesma função, dois tempos.* Nenhuma linha do programa mudou entre uma coluna
  e outra — mudou o valor da temperatura. O tempo de execução deste código
  depende do dado, e a diferença é de 750 ns.

  Isso tem nome: *jitter*, a variação do instante em que algo acontece. Num LED é
  irrelevante. Numa nota musical é desafinação. Num controle amostrado, é ruído
  introduzido pelo próprio programa. A seção 7 volta a isso com número.
]

#nota[
  Os dois `xorlw 128` são a comparação com sinal: inverter o bit mais
  significativo transforma a comparação de números com sinal numa comparação sem
  sinal, que é o que o indicador de transporte sabe fazer. Oito instruções para
  comparar dois `int16_t` — o preço concreto da afirmação da Aula 1, §7.4, de que
  cada operação de 16 bits vira duas ou três instruções.
]

// =====================================================================
= O sufixo `,c`: o banco de acesso

Quase toda instrução da listagem termina em `,c`. Não é decoração.

A Aula 1, §8.4, explicou que os 2 048 bytes de RAM são divididos em bancos de 256
porque o campo de endereço da instrução tem apenas 8 bits — e que, para não
pagar troca de banco a cada acesso, o PIC18 mantém uma janela de 256 bytes
reunindo os 96 primeiros bytes de RAM aos registradores de periférico do topo do
mapa. O bit $a$ do opcode é quem escolhe entre a janela e o banco corrente.

#tabela(
  columns: (0.16fr, 0.3fr, 1fr),
  [*Bit $a$*], [*Na listagem*], [*O que acontece*],
  [0], [`,c`], [Endereço resolvido na janela de acesso. Uma instrução, um ciclo],
  [1], [(ausente)], [Endereço resolvido no banco apontado por `BSR`. Se o banco não for o corrente, o compilador precisa emitir antes uma instrução `movlb` — mais uma palavra de Flash e mais um ciclo],
)

No programa de exemplo, todas as variáveis globais couberam na janela:

```
_setpoint    0x0001      _heater_on   0x0005
_temperatura 0x0003      ??_controla  0x0006
```

#atencao[
  A janela tem 96 bytes de RAM. Um projeto que ultrapasse isso em variáveis
  frequentemente acessadas começa a ter parte delas fora do banco de acesso — e o
  código que as usa fica mais lento *sem que nenhuma linha desse código tenha
  mudado*.

  É o primeiro caso do semestre em que acrescentar uma variável em um módulo
  altera a temporização de outro. Quando uma rotina calibrada começar a errar
  depois de o projeto crescer, esta é a hipótese.
]

#contexto[
  Somando ao endereçamento indireto e ao multiplicador por #emph[hardware], é o
  banco de acesso que sustenta a afirmação de que o PIC18 foi projetado para
  receber código de compilador C. Sem ele, cada acesso a variável exigiria
  gerenciar `BSR` explicitamente, e o código gerado seria perto do dobro.
]

// =====================================================================
= Chamar uma função custa, e a pilha não é RAM

Na contagem da seção 3, quatro dos 22 ciclos foram gastos em `call` e `return` —
cerca de 18% do total, sem que nenhum trabalho útil fosse feito.

#conceito[
  *Onde vai o endereço de retorno.* Numa arquitetura convencional, o `call`
  empilha o endereço de retorno na mesma RAM onde vivem as variáveis. Aqui não:
  a pilha de retorno é um bloco de silício dedicado, com 31 níveis, fora do espaço
  de dados (Aula 1, §8.2).

  A consequência prática é agradável: *chamadas aninhadas não consomem os 2 KB de
  RAM*. A desagradável é que a profundidade é fixa em 31 e não há como
  aumentá-la — o que só é problema com recursão.
]

== Macro em vez de função

Se a chamada custa quatro ciclos e a função é curta, a alternativa é a macro: o
corpo é expandido no lugar da chamada, e os quatro ciclos desaparecem.

#atencao[
  A troca não é gratuita. Cada uso da macro duplica o código na Flash. Com 32 KB
  de Flash contra 2 KB de RAM, a troca costuma valer a pena — mas é uma escolha
  de orçamento, não uma otimização automática.

  E não conte com `inline`: a licença gratuita do XC8 compila sem otimizar, e a
  listagem mostra as chamadas intactas.
]

Uma macro de várias instruções precisa de uma casca sintática, e a casca usual é
`do { ... } while(0)`:

```c
#define LIGA_HEATER()  do { LATCbits.LATC1 = 1; heater_on = 1; } while(0)
```

#conceito[
  *Por que essa forma, e não outra.* O objetivo é que a macro se comporte como
  uma instrução simples, sobrevivendo a um `if` sem chaves. Há três candidatas, e
  o que as separa é o comportamento quando o usuário escreve — ou esquece — o
  ponto e vírgula final.

  #tabela(
    columns: (0.4fr, 0.3fr, 0.4fr),
    [*Definição*], [*Uso com `;`*], [*Uso sem `;`*],
    [`do { ... } while(0)`], [correto], [erro de sintaxe],
    [`if(1) { ... }`], [erro de sintaxe], [*compila e faz o errado*],
    [`{ ... }`], [erro de sintaxe], [correto],
  )

  A casa perigosa é a do meio: sem o ponto e vírgula, um `else` escrito pelo
  usuário se liga ao `if(1)` interno da macro, e o ramo `else` vira código morto.
  Compila limpo e o defeito só aparece em execução.

  A forma `do/while(0)` é a única que funciona com o ponto e vírgula natural *e*
  cuja omissão produz erro de compilação. Não se ganha nada em tamanho de código:
  a condição é constante e o laço desaparece na tradução — as duas formas geram
  exatamente as mesmas instruções. Ganha-se a impossibilidade de falhar em
  silêncio.
]

#nota[
  Dentro de `do/while(0)` é lícito usar `break` como saída antecipada, o que
  permite escrever macros de guarda:

  ```c
  #define ATUALIZA(v)  do {                    \
          if ((v) > LIMITE_SEG) break;         \
          LATD = (v);                          \
      } while(0)
  ```

  Para macros de uma expressão só — `#define LIGA(r,b) ((r) |= (1U << (b)))` —
  nada disso se aplica: use parênteses e mantenha a forma de expressão.
]

// =====================================================================
= Construção: um atraso em unidades de iteração

Agora há material suficiente para construir a rotina que motivou a aula.

```c
void atraso_unidades(uint16_t unidades)
{
    while (unidades > 0u) {
        unidades--;
    }
}
```

Nada nesse código expressa duração. A duração é uma propriedade do que ele virou,
e a listagem informa quanto custa uma volta do laço.

#experimento[
  *Procedimento — e é ele que vocês repetem no Roteiro 2.*

  + Compilar e abrir a listagem. Localizar o comentário com o número da linha do
    `while` e ler o bloco até o `goto` que volta ao início.
  + Anotar cada instrução com seu custo, pela tabela da seção 3. Atenção aos
    desvios condicionais que pulam `goto`.
  + Somar. O resultado é $b$, o custo de uma iteração, em ciclos.
  + Somar separadamente o que executa uma única vez: `call`, preparação do
    parâmetro, teste final, `return`. O resultado é $a$, a sobrecarga.
]

#conceito[
  *O modelo.* Chamando a rotina com $N$ unidades, o tempo total é

  $ t(N) = (a + b dot N) dot T_"cy" $

  com $T_"cy" = 250$ ns. É uma reta: $b$ é a inclinação, $a$ o intercepto.

  Duas grandezas, duas incógnitas — e por isso *duas* medições de frequência com
  valores diferentes de $N$ determinam ambas experimentalmente, sem abrir a
  listagem. É assim que a previsão da contagem pode ser confrontada com a
  bancada.
]

Usada para gerar um sinal quadrado, a rotina ocupa cada meio período:

```c
while (1) {
    LATDbits.LATD0 ^= 1;
    atraso_unidades(N);
}
```

$ T = 2 dot (a + b dot N + c) dot T_"cy" $

onde $c$ é o custo da inversão do pino e do laço externo — que, na prática, se
soma a $a$ e não é separável por medida de frequência. Os dois viram um
intercepto só.

#nota[
  Uma constante de compilação vale mais que um número solto no código. A
  ligação entre unidades e microssegundos é a razão $b dot T_"cy"$, e ela merece
  nome:

  ```c
  #define DECIMOS_US_POR_ITER  23   /* medido nesta bancada */
  ```

  Guardar em décimos de microssegundo evita ponto flutuante, pela mesma razão que
  as temperaturas são guardadas em décimos de grau (Aula 1, §7.4).
]

// =====================================================================
= Onde a previsão erra, e quanto

Uma contagem de ciclos honesta erra. Vale saber por onde, antes de a bancada
mostrar.

== O caminho que só executa às vezes

O contador é `uint16_t` e o núcleo é de 8 bits. Decrementar exige tratar o byte
alto — mas o byte alto só muda quando o byte baixo passa por zero, uma vez a cada
256 iterações. O compilador gera esse tratamento como um desvio condicional, e o
custo da iteração depende de qual caminho foi tomado.

#atencao[
  A consequência é que $b$ não é um inteiro. É uma média, e o valor instantâneo
  oscila. Para um atraso longo isso se dilui; para gerar uma nota musical, é
  desafinação de fração de semitom.

  Um contador `uint8_t` elimina essa variação — ao custo de limitar $N$ a 255.
  A escolha do tipo, aqui, é uma escolha de forma de onda.
]

== As outras fontes

#tabela(
  columns: (0.34fr, 0.24fr, 1fr),
  [*Fonte*], [*Ordem*], [*Comentário*],
  [Byte alto do contador], [fração de ciclo], [Diluída em $N$ grande; visível em $N$ pequeno],
  [Quantização da constante], [até 2%], [`23` décimos representa 2,3 µs onde o real pode ser 2,26],
  [Tolerância do cristal], [0,001% a 0,01%], [Desprezível aqui; decisiva na comunicação serial],
  [*Interrupções*], [*sem limite*], [Um tratador executando durante o atraso o estende pelo tempo que levar. Aula 9],
)

#conceito[
  *O limite do método.* Contagem de ciclos entrega precisão da ordem de 1% e
  *nenhuma garantia*: qualquer coisa que interrompa o laço estraga a conta, e o
  processador fica integralmente ocupado durante a espera.

  É a mesma objeção que a Aula 1, §7.6, levantou contra `__delay_ms`, agora com
  número. A saída não é contar melhor — é deixar de contar: um temporizador por
  #emph[hardware] conta em paralelo, sem consumir instruções e sem ser afetado
  pelo que o programa faz. É o assunto do encontro 7, e a razão de ele existir.
]

#divergencia[
  A rotina construída hoje não é descartada quando o temporizador chegar. Ela
  permanece útil exatamente onde o temporizador é caro demais: esperas de poucos
  microssegundos em protocolos de sensor, em que o custo de armar e desarmar um
  temporizador excede a espera. Saber contar ciclos continua valendo; o que muda
  é a escala em que se aplica.
]

// =====================================================================
= Transposição

O instrumento existe em qualquer plataforma, com outro nome.

#tabela(
  columns: (0.3fr, 1fr),
  [*Ambiente*], [*Como obter a tradução*],
  [XC8 / PIC18], [`xc8-cc -S`, ou o arquivo `.lst` do diretório de construção],
  [GCC, qualquer alvo], [`gcc -S`, ou `objdump -d` sobre o binário já ligado],
  [ARM Cortex-M], [`arm-none-eabi-objdump -d`; no STM32CubeIDE, a janela de desmontagem],
)

#contexto[
  O que *não* se transpõe é a contagem. No PIC18, uma instrução simples custa um
  ciclo, sempre, e a tabela da seção 3 cabe em cinco linhas. Num Cortex-M típico,
  o mesmo trecho pode custar diferente conforme o alinhamento na Flash, o número
  de estados de espera da memória naquela frequência, e a presença de um
  acelerador de leitura com comportamento próximo ao de uma memória associativa.

  Contar ciclos deixa de ser confiável, e é por isso que aquelas plataformas
  oferecem um contador de ciclos em #emph[hardware] para medir o que já não se
  consegue prever. Previsibilidade é uma propriedade que se perde ao subir de
  porte — a mesma discussão de determinismo do Exercício 1.9, agora do lado do
  código gerado. Ela reaparece no seminário comparativo.
]

// =====================================================================
= Antes de descer para o laboratório

O Roteiro 2 mede o que esta aula previu. Preencham a tabela agora, com a teoria
fresca, e levem rubricada.

#nota[
  Vale o mesmo da Aula 1: previsão errada não é problema; previsão feita depois do
  experimento é.
]

#tabela(
  columns: (0.42fr, 1fr, 0.16fr),
  [*Pergunta*], [*Previsão e justificativa*], [*Rubrica*],
  [P1. Quantos ciclos custa uma iteração do laço de `atraso_unidades`? Conte pela
   listagem antes de medir], [], [],
  [P2. Com $N = 400$, que frequência você espera no pino?], [], [],
  [P3. Dobrando $N$ para 800, a frequência cai exatamente pela metade? Justifique
   em termos de $a$ e $b$], [], [],
  [P4. Trocando o contador para `uint8_t` e mantendo $N = 200$, o que acontece com
   a forma de onda?], [], [],
  [P5. O que aconteceria com a medida se houvesse uma interrupção periódica
   ativa?], [], [],
)

#bancada[
  *Leve para a bancada:* esta folha preenchida, a listagem impressa ou aberta, e
  a contagem de ciclos já feita. Medir sem previsão transforma o roteiro em
  digitação.
]

// =====================================================================
= Exercícios

#tarefa[
  *Exercício 2.1.* Na contagem da seção 3, o caminho "aquecedor liga" custou 22
  ciclos e o caminho "aquecedor desliga", 19.

  *(a)* Explique a origem exata dos três ciclos de diferença.

  *(b)* Essa função é chamada a cada 10 ms num laço de controle. Qual é o erro
  relativo introduzido no período de amostragem?

  *(c)* Suponha agora que ela seja chamada dentro do laço que gera a nota musical
  do #emph[buzzer], a 550 Hz. Qual o efeito audível?
]

#resposta[
  *(a)* Duas origens. Primeiro, o `btfsc`: quando o transporte está limpo, ele
  pula um `goto`, que é instrução de duas palavras, e custa 3 ciclos em vez de 1 —
  diferença de 2. Segundo, os ramos têm comprimentos distintos: o ramo que liga
  executa `bsf`, `movlw`, `movwf` e um `goto` de saída (5 ciclos), enquanto o que
  desliga executa `bcf` e `clrf` (2 ciclos) e cai direto no `return`; em
  compensação, o caminho até ele passa por dois `goto` em vez de um. O saldo é 1
  ciclo. Total: 3.

  *(b)* 3 ciclos são 750 ns. Sobre 10 ms, isso é $7,5 dot 10^(-5)$, ou 0,0075% —
  irrelevante para qualquer malha de controle térmico, cuja constante de tempo é
  de segundos.

  *(c)* O período de 550 Hz é 1,82 ms; o meio período, 909 µs. Uma variação de
  750 ns é 0,08% do período, o que corresponde a cerca de 0,014 semitom. Também
  inaudível — o ouvido humano distingue algo em torno de 0,1 semitom em
  comparação direta.

  O ponto do item, porém, é o método: a mesma variação absoluta é desprezível nos
  dois casos porque ambos são lentos. Ela deixaria de ser desprezível num sinal de
  dezenas de quilohertz, e é essa comparação — variação absoluta contra período —
  que decide, não a intuição.
]

#criterio[
  O item (a) avalia domínio da tabela de custos, em especial da regra das três
  palavras. Resposta que atribua toda a diferença ao tamanho dos ramos não
  identificou o `btfsc`.
]

#tarefa[
  *Exercício 2.2.* Duas medições feitas nesta bancada, com o programa da seção 6
  gerando onda quadrada em RD0:

  #tabela(
    columns: (0.3fr, 0.4fr),
    [*$N$*], [*Frequência medida*],
    [400], [551,0 Hz],
    [800], [276,2 Hz],
  )

  *(a)* Determine $b$ (ciclos por iteração) e $a$ (sobrecarga, em ciclos).

  *(b)* Compare $b$ com o que você contou na listagem. Se divergirem, aponte
  candidatos.

  *(c)* Que frequência o modelo prevê para $N = 1200$?

  *(d)* Por que duas medições bastam, e o que uma terceira acrescentaria?
]

#resposta[
  *(a)* Meio período: $1 \/ (2 dot 551,0) = 907,4$ µs e $1 \/ (2 dot 276,2) =
  1810,3$ µs.

  $ b = (1810,3 - 907,4) / (800 - 400) = 2,257 " µs" = 9,03 " ciclos" $
  $ a = 907,4 - 2,257 dot 400 = 4,60 " µs" = 18,4 " ciclos" $

  *(b)* Espera-se contar 9 ciclos por iteração. A fração de 0,03 é o tratamento do
  byte alto do contador, que executa uma vez a cada 256 voltas: $8 \/ 256 approx
  0,03$ — coerente com um caminho adicional de cerca de 8 ciclos.

  Os 18,4 ciclos de $a$ reúnem `call`, `return`, a passagem do parâmetro, o teste
  final que encerra o laço, a inversão do pino e o `goto` do laço externo — ordem
  de grandeza compatível com a função medida na seção 3.

  *(c)* $t \/ 2 = (18,4 + 9,03 dot 1200) dot 250$ ns $= 2713$ µs, logo
  $f approx 184,3$ Hz.

  *(d)* O modelo tem dois parâmetros; duas equações os determinam. Uma terceira
  medição não melhora o ajuste de forma significativa — ela *testa* o modelo. Se
  o ponto previsto cair fora da tolerância do instrumento, a hipótese de
  linearidade está errada, e aí a resposta interessante não é refinar $a$ e $b$: é
  descobrir o que é não linear.
]

#criterio[
  O item (d) é o objetivo real do exercício. Resposta que trate a terceira medição
  como "melhorar a precisão" confundiu ajuste com validação.
]

#tarefa[
  *Exercício 2.3.* Um estudante troca `uint16_t` por `uint32_t` no parâmetro de
  `atraso_unidades`, "para poder esperar mais".

  *(a)* O que acontece com $b$?

  *(b)* O atraso máximo obtenível aumenta na proporção esperada?

  *(c)* Proponha uma solução melhor para atrasos longos, sem alterar o tipo.
]

#resposta[
  *(a)* $b$ cresce. O decremento e o teste passam a operar sobre quatro bytes em
  vez de dois, num núcleo de 8 bits; cada operação vira o dobro de instruções.
  Espera-se algo próximo de 16 a 20 ciclos por iteração, contra 9.

  *(b)* Não. O alcance de $N$ multiplica-se por 65 536, mas o tempo por iteração
  também cresceu — de forma que o atraso máximo aumenta por um fator maior ainda.
  O problema é outro: a *resolução* piorou. O menor incremento de atraso passou de
  2,26 µs para cerca de 4,5 µs, e a rotina ficou pior justamente para o uso que a
  originou, que é gerar notas agudas.

  *(c)* Aninhar: um laço externo `uint8_t` chamando o laço interno `uint16_t`. O
  custo por iteração interna permanece 9 ciclos, a resolução fina é preservada, e
  o alcance se multiplica sem tocar no tipo do contador crítico.

  A lição é a mesma da Aula 1, §7.4: o tamanho do tipo tem custo em ciclos, e o
  reflexo de "aumentar o tipo para caber mais" costuma resolver o alcance
  degradando a resolução.
]

#tarefa[
  *Exercício 2.4.* Um projeto cresce e passa a declarar 140 bytes de variáveis
  globais. Uma rotina de temporização que estava calibrada começa a produzir
  períodos cerca de 10% maiores, sem que uma única linha dela tenha sido alterada.

  Explique o mecanismo e proponha duas providências.
]

#resposta[
  A janela de acesso comporta 96 bytes de RAM. Com 140 bytes de globais, parte
  delas ficou fora, e o acesso a essas exige selecionar o banco: o compilador
  emite `movlb` antes, e a instrução perde o `,c`. Cada acesso a uma variável
  deslocada passa a custar um ciclo a mais, além de uma palavra a mais de Flash.

  Se a variável deslocada for o contador do laço de temporização, o custo extra é
  pago a cada iteração — e 1 ciclo sobre 9 é justamente da ordem de 10%.

  *Providências.* A primeira é diagnóstica: abrir a listagem e verificar quais
  acessos perderam o `,c` — o sintoma é visível em segundos, e adivinhar é pior.
  A segunda é estrutural: tornar locais as variáveis que só um módulo usa,
  liberando espaço na janela; e, se a rotina crítica precisar de garantia,
  parametrizá-la de modo que o contador seja um argumento, que o compilador tende
  a alocar na janela.

  O que este exercício ensina não é a solução, é a classe do defeito: *acoplamento
  por meio do mapa de memória*. Dois módulos sem nenhuma relação no código-fonte
  passam a interferir um no outro por disputarem uma região de endereçamento
  barato. Nenhuma releitura do módulo afetado revela a causa.
]

#criterio[
  Este é o exercício que justifica a seção 4 existir. Resposta que proponha apenas
  "recalibrar a constante" resolve o sintoma e não identificou o mecanismo — vale
  metade.
]

#tarefa[
  *Exercício 2.5.* Considere as duas definições:

  ```c
  #define LIGA_A()  do { LATCbits.LATC1 = 1; heater_on = 1; } while(0)
  #define LIGA_B()  if(1){ LATCbits.LATC1 = 1; heater_on = 1; }
  ```

  *(a)* Compare o código de máquina gerado pelas duas.

  *(b)* Exiba um trecho de programa em que uma funciona e a outra não, e diga
  qual erro o compilador emite em cada caso.

  *(c)* Um colega argumenta que `LIGA_B` é preferível por ser mais legível.
  Responda.
]

#resposta[
  *(a)* Idêntico. Nos dois casos a condição é constante e a construção desaparece
  na tradução: não há teste, não há desvio. A escolha entre as duas é
  exclusivamente sintática.

  *(b)*
  ```c
  if (temperatura < setpoint)
      LIGA_X()
  else
      DESL_X();
  ```
  Sem o ponto e vírgula após a macro, `LIGA_A()` não compila — a gramática de
  `do...while` exige o terminador, e o erro aponta para o `else`. `LIGA_B()`
  compila silenciosamente, e o `else` do programa se associa ao `if(1)` interno da
  macro: o ramo `else` do usuário nunca executa.

  Com o ponto e vírgula, a situação se inverte: `LIGA_A()` funciona e `LIGA_B()`
  produz erro de sintaxe, porque o `else` fica órfão.

  *(c)* A legibilidade da definição é irrelevante comparada ao comportamento no
  uso. `LIGA_B` tem um modo de falha silencioso; `LIGA_A` não tem nenhum. Um
  defeito que o compilador aponta custa minutos; um que compila limpo e desativa
  um ramo de controle custa uma tarde — e, no caso do aquecedor, custa a tarde
  *depois* de alguém notar que a temperatura não para de subir.

  O critério de escolha entre construções equivalentes não é qual parece mais
  clara, é qual falha mais alto.
]
