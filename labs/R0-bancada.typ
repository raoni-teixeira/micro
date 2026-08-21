// ============================================================
//  Microcontroladores — Roteiro 0 (Bancada)
//  Raoni F. S. Teixeira — DENE/UFMT
//  Compilar:  typst compile R0-bancada.typ R0-bancada.pdf
//  Sem imports externos: o arquivo é autocontido.
// ============================================================

// ---------- configurações de página ----------
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Microcontroladores — Prática],
      align(right)[Roteiro 0],
    )
    #line(length: 100%, stroke: 0.4pt + luma(180))
  ],
  footer: [
    #line(length: 100%, stroke: 0.4pt + luma(180))
    #set text(size: 8pt, fill: luma(120))
    #grid(
      columns: (1fr, 1fr),
      align(left)[Raoni F. S. Teixeira, Rodolfo Quadros — DENE/UFMT],
      align(right)[#context counter(page).display("1")],
    )
  ],
)

// ---------- tipografia ----------
#set text(font: "Linux Libertine", size: 11pt, lang: "pt")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: none)
#show heading: set block(below: 1.0em, above: 1.6em)
#show heading.where(level: 1): set text(size: 15pt)
#show heading.where(level: 2): set text(size: 12pt)
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
#let importante(corpo) = caixa("Atenção", vermelho, rgb("#fff5f0"), corpo)
#let perigo(corpo)     = caixa("Perigo — leia antes de encostar a ponta de prova", vermelho, rgb("#ffecec"), corpo)
#let tarefa(corpo)     = caixa("Tarefa", verde, rgb("#f0faf0"), corpo)
#let previsao(corpo)   = caixa("Previsão — registre ANTES de medir", roxo, rgb("#f5f0ff"), corpo)
#let observacao(corpo) = caixa("Observação", laranja, rgb("#fff8ee"), corpo)
#let manual(corpo)     = caixa("Divergência do manual", laranja, rgb("#fff8ee"), corpo)

// ---------- utilidades ----------
#let quadro = box(width: 9pt, height: 9pt, stroke: 0.6pt + luma(90), radius: 1pt)
#let resposta(n: 1) = for _ in range(n) [ #v(0.9em) #line(length: 100%, stroke: 0.4pt + luma(170)) ]
#let cab(c) = text(fill: white, weight: "bold")[#c]
#let listra = (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white }

// ============================================================
//  CAPA
// ============================================================
#block(
  width: 100%,
  fill: azul,
  inset: (x: 16pt, y: 20pt),
  radius: 4pt,
)[
  #text(fill: white, size: 18pt, weight: "bold")[Microcontroladores]
  \
  #text(fill: rgb("#aaccee"), size: 12pt)[Roteiro 0 — Bancada]
  \
  #v(4pt)
  #text(fill: luma(200), size: 9pt)[Raoni F. S. Teixeira, Rodolfo Quadros · DENE/UFMT · 1 sessão · 1,0 ponto · grupos de 3]
]

#v(0.8em)

#caixa(
  "Objetivos desta sessão",
  rgb("#555555"),
  cinza,
  [
    Ao final desta sessão o grupo deve ser capaz de:

    + Identificar as seções do kit XM118 e localizar o microcontrolador;
    + Criar e compilar um projeto em C no MPLAB X com o compilador XC8;
    + Gravar o firmware no PIC18F4550 pelo bootloader USB;
    + Explicar por que os atuadores precisam de estado de repouso seguro;
    + Prever e medir no osciloscópio a frequência da onda gerada em RD0.
  ],
)

#v(0.6em)
/*
= O caminho de gravação deste laboratório

O manual da Exsto descreve a gravação pelo *PICkit-2 embutido*. Esse caminho
*não funciona neste laboratório*: o firmware do kit foi regravado e a gravação
passou a ser feita por um *bootloader USB*.

Se você tentar usar o PICkit-2 pelo MPLAB, receberá o erro
`PK2Error0022: PICkit 2 not found`. Isso é o comportamento esperado, não
defeito do equipamento.

#importante[
  Consequência prática: *o MPLAB X apenas compila.* Quem grava é o programa do
  bootloader, executado separadamente. Por isso o projeto será criado no modo
  *No Tool* — ausência de gravador é a configuração correta, não um defeito.
]

== Como o bootloader funciona

O que está gravado no PIC18F4550 não é apenas a aplicação. Existe, no início da
memória de programa, um programa chamado *bootloader*, cuja única função é
receber firmware novo pela USB e gravá-lo no restante da memória.

O ponto que mais causa confusão é este:

#importante[
  O bootloader só aceita conexão durante os *primeiros 4 a 5 segundos* após o
  kit ser ligado ou reiniciado.

  Passada essa janela, ele entrega o controle à aplicação e deixa de responder.
  O programa no PC continua aberto e *sem mensagem de erro*, mas o botão
  Connect simplesmente não encontra nada.
]

Cinco segundos é tempo suficiente para clicar sem pressa, desde que o programa
já esteja aberto e a janela visível na tela. O erro típico não é lentidão no
clique — é reiniciar o kit antes de abrir o programa, ou procurar o botão
Connect depois do reset.

=== Procedimento correto

+ Abra o programa do bootloader *antes*, deixando o botão Connect visível.
+ Pressione o *botão de reset* do kit.
+ Clique em *Connect* dentro dos 4 a 5 segundos seguintes.
+ Se não conectar, repita: reset e Connect logo em seguida.

=== Onde fica o botão de reset

Na seção *PUSH BUTTONS*, na metade inferior da placa, logo à direita do gerador
de frequência. São seis botões dispostos em três linhas de dois:

#figure(
  table(
    columns: (auto, 1fr, 1fr),
    fill: listra,
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(cab[], cab[Coluna esquerda], cab[Coluna direita]),
    [Linha 1], [CH0 (SW11)],    [INT2 (SW14)],
    [Linha 2], [TMR1 (SW10)],   [INT1 (SW13)],
    [Linha 3], [*RESET (SW9)*], [INT0 (SW12)],
  ),
  caption: [Disposição dos botões na seção PUSH BUTTONS.],
) <tab-botoes>

O reset é o *botão inferior esquerdo* do conjunto, com a palavra RESET impressa
logo acima dele.

#manual[
  A tabela 9.6 do manual da Exsto numera esses botões como SW1 a SW6. A
  serigrafia da placa usa SW9 a SW14. *Confie na serigrafia* — é o que está
  impresso à sua frente.

  Esta não é a única inconsistência. A tabela 9.1 traz o cabeçalho PIC18F4520
  numa tabela cuja legenda diz PIC18F4550; a tabela 9.3 lista o pino RA3 duas
  vezes com funções diferentes; e a nota sobre gravação inverte PGC e PGD em
  relação ao datasheet.

  Documentação de fabricante é fonte útil, não verdade absoluta. Quando ela
  discorda do equipamento, o equipamento vence.
]

= Configuração de bancada

#bancada[
  #table(
    columns: (1.6fr, 1fr),
    stroke: 0.5pt + luma(200),
    inset: 6pt,
    [Cabo de força tripolar], [Conectado, com aterramento],
    [Chave traseira], [Ligada],
    [Cabo USB], [*USB frontal (CN9)*, não a traseira],
    [Chaves SWITCHS (PORTB)], [Todas em OFF],
    [CH3-3 (aquecedor)], [OFF],
    [CH3-5 (ventoinha)], [ON],
  )
]

#importante[
  As fontes do kit são _fullrange_ automáticas (90 a 240 V). *Não há chave
  110/220.* O terceiro pino do cabo precisa estar aterrado — é ele que habilita
  as proteções contra surto descritas no manual.
]
*/
= Parte 1 — Reconhecimento do kit

#tarefa[
  Localize e anote a posição de cada item:

  + O microcontrolador (CI de 40 pinos, seção MICROCONTROLLER);
  + Os bancos de chaves DIP CH1 a CH5 e a chave U8;
  + A seção PUSH BUTTONS e, dentro dela, o botão RESET (SW9);
  + Os 8 LEDs da seção LEDS;
  + O display LCD alfanumérico;
  + A ventoinha e a resistência de aquecimento;
  + O conector USB frontal e o DB9 da seção RS232.
]

Ligue o kit *sem nada conectado* e observe:

/ 1.1: Os LEDs indicadores de alimentação acendem? #resposta()
/ 1.2: O LCD acende? #resposta()
/ 1.3: A ventoinha liga sozinha? #resposta()


= Parte 2 — Compilar

== Criar o projeto

+ MPLAB X #sym.arrow.r *File #sym.arrow.r New Project* (`Ctrl+Shift+N`).
+ Categoria *Microchip Embedded*, tipo *Application Project(s)*. Avançar.
+ Em *Device*, digite `PIC18F4550`. Confira que a família selecionada é
  *Advanced 8-bit MCUs (PIC18)*. Avançar.
+ Em *Select Tool*, escolha *No Tool*. Avançar.
+ Em *Select Compiler*, escolha o *XC8* disponível na máquina. Avançar.
+ Em *Project Name*, use `r0_blink`. Confira a pasta de destino e conclua em
  *Finish*.

#observacao[
  Em versões mais antigas do MPLAB X, o tipo de projeto aparece como
  *Standalone Project* em vez de *Application Project(s)*. É o mesmo caminho.

  Se o MPLAB X pedir para baixar o _Device Family Pack_ do PIC18F4550,
  autorize. Sem ele o compilador não encontra o cabeçalho do dispositivo.
]

#importante[
  O caminho da pasta do projeto não pode conter *acentos, espaços ou cedilha*.
  Um caminho como `C:\Users\Joao Carlos\Meus Projetos\` faz o XC8 falhar com
  mensagens que não têm relação aparente com a causa. Use algo como
  `C:\micro\r0_blink`.
]

== Adicionar o código

Botão direito em *Source Files* #sym.arrow.r *Add Existing Item*, e adicione o
arquivo `r0_blink.c` fornecido pelo professor.

O trecho essencial do programa é este:

```c
#include <xc.h>
#define _XTAL_FREQ 16000000UL

void main(void) {
    LATD  = 0xFF;   /* valor primeiro: os 8 LEDs nascem acesos */
    TRISD = 0x00;   /* direção depois: PORTD vira saída        */

    while (1) {
        LATDbits.LATD0 = 1;
        __delay_ms(500);
        LATDbits.LATD0 = 0;
        __delay_ms(500);
    }
}
```

Sete LEDs permanecem acesos; apenas o LED ligado a *RD0* pisca. Esse pino é o
sinal que você vai medir na Parte 5.

#manual[
  Diretivas `#pragma config` escritas na aplicação são *silenciosamente
  ignoradas* neste kit: os bits de configuração pertencem ao bootloader, que já
  os fixou. O bootloader configura 48 MHz para o periférico USB e *16 MHz para
  a CPU*. Por isso `_XTAL_FREQ` vale `16000000UL`, e não `48000000UL`.
]

== Compilar

Use o *martelo* da barra de ferramentas (_Clean and Build_, F11).

#importante[
  *Não use o botão de Debug.* O build de depuração gera `.elf` mas *não gera*
  `.hex`, e sem `.hex` não há o que gravar.

  Este é o erro mais frequente da sessão.
]

O arquivo deve estar em:

```
<projeto>/dist/default/production/<nome>.production.hex
```

Se existir apenas a pasta `debug`, você compilou no modo errado. Volte e use o
martelo.

/ 2.1: Anote o caminho completo do arquivo gerado. #resposta(n: 2)

= Parte 3 — Gravar

+ Conecte o cabo USB na *porta frontal do kit (CN9)*.
+ Abra o programa *Bootloader PIC18 — XM118* (USB HID Bootloader).
+ Pressione o *botão de reset (SW9)* do kit.
+ Clique em *Connect* dentro de 4 a 5 segundos.
+ *Buscar arq HEX* #sym.arrow.r selecione o `.production.hex` da Parte 2.
+ *Begin uploading*.
+ Ao final, pressione *RESET (SW9)* para executar o firmware novo.

A janela de histórico deve mostrar a sequência:

```
Flash Erase...
Flash Write...
Completed successfully.
Disconnected.
Reset device to reenter bootloader mode.
```

#observacao[
  Repare na última mensagem do próprio programa: _reset device to reenter
  bootloader mode_. Ela confirma o que foi explicado na primeira seção — para
  gravar de novo, é preciso reiniciar de novo.
]

== Se não conectar

Na ordem:

+ *Reinicie o kit e clique em Connect dentro de 4 a 5 segundos.* A causa mais
  frequente é a janela do bootloader ter expirado. O programa não avisa: apenas
  não encontra o dispositivo.
+ Confirme que o cabo está na USB *frontal*, não na traseira.
+ Feche o MPLAB X antes de tentar.
+ Desconecte e reconecte o cabo com o programa fechado.

/ 3.1: Quantas tentativas o grupo precisou até conectar na primeira vez? O que estava errado? #resposta(n: 2)

= Parte 4 — Estado de repouso seguro

Com o _blink_ rodando, responda:

/ 4.1: Sete LEDs ficam acesos e um pisca. Qual deles pisca, e com que período aproximado? #resposta()



/ 4.2: Localize no código as duas linhas abaixo e explique, com suas palavras, o que cada uma faz.

```c
LATC  &= ~0b00000110;   /* linha A */
TRISC &= ~0b00000110;   /* linha B */
```

#resposta(n: 2)

#previsao[
  *4.4* — O que aconteceria se as linhas A e B fossem trocadas de ordem?

  Pense no que o pino faz no instante em que deixa de ser entrada e passa a ser
  saída. Formule a resposta *antes* de testar; depois, se quiser, teste.

  #resposta(n: 3)
]

#conceito[
  A pergunta 4.4 é o conceito central deste roteiro. Com uma ventoinha, o
  efeito de um pulso indesejado é inofensivo. Com a resistência de aquecimento
  — ou, em um sistema de potência real, com um disjuntor ou uma chave de
  manobra — não seria.

  Escrever no registrador de dados (`LAT`) *antes* de configurar a direção
  (`TRIS`) é a diferença entre um atuador que acorda desligado e um que acorda
  em estado indefinido.
]

= Parte 5 — Medindo o pisca no osciloscópio

Até aqui você julgou o programa pelo que o olho vê. Agora vai medir o mesmo
sinal com um instrumento, e comparar a medida com um número calculado antes.

== Onde medir

O pino que pisca é o *RD0*, na seção *LEDS* do kit. Meça o sinal lógico nesse
ponto, com a garra de terra em um ponto de *GND* da placa.

#perigo[
  Os pontos de teste *LAMP*, *HEATER* e *COOLER* estão no *trilho de 12 V*. A
  garra de terra do osciloscópio *nunca* pode encostar neles: a garra está
  ligada ao terra da rede pelo cabo de força, e o contato cria um curto através
  do instrumento.

  Nesta parte você mede *apenas RD0*, que é um pino lógico de 5 V. Se a ponta
  de prova precisar ir a qualquer outro lugar, chame o professor antes.
]

#bancada[
  Ponta de prova em *1×* ou *10×* (anote qual). Acoplamento *DC*. Base de tempo
  inicial em torno de *200 ms/div* para enxergar o período de 1 s.
]

== De onde vem o número previsto

O compilador precisa de `_XTAL_FREQ` para converter um atraso em milissegundos
num número de ciclos de máquina. Com $F_(o s c) = 16$ MHz:

$ T_(c y) = 4 / F_(o s c) = 4 / (16 times 10^6) = 250 "ns" $

O laço acende por 500 ms e apaga por 500 ms. O período da onda é a soma das
duas metades, e a frequência é o seu inverso.

#previsao[
  *5.1* — Preencha as colunas de período e frequência previstos para os quatro
  valores da tabela, *antes de ligar a ponta de prova*. Rubrique e mostre ao
  professor.

  A nota é pelo raciocínio registrado, não pelo acerto.
]

#figure(
  table(
    columns: (auto, 1fr, 1fr, 1fr, 1fr),
    fill: listra,
    stroke: 0.5pt + luma(200),
    inset: 11pt,
    align: center + horizon,
    table.header(
      cab[`__delay_ms` (cada metade)],
      cab[Período previsto],
      cab[$f$ prevista],
      cab[$f$ medida],
      cab[Erro (%)],
    ),
    [500], [], [], [], [],
    [250], [], [], [], [],
    [100], [], [], [], [],
    [50],  [], [], [], [],
  ),
  caption: [Previsão e medição da onda quadrada em RD0.],
) <tab-previsao>

#tarefa[
  *5.2* — Meça o período com os cursores e preencha as duas últimas colunas.
  Cada linha exige alterar o valor no código, recompilar (martelo) e regravar
  (reset, Connect, upload, reset).

  *5.3* — O erro percentual é aproximadamente o mesmo nas quatro linhas ou
  cresce com a frequência? O que isso diz sobre a origem do erro: uma fonte
  proporcional ao período (o clock) ou uma fonte de valor fixo (as instruções
  do laço que não são o atraso)?

  #resposta(n: 2)
]

== Descobrindo o clock pela medida

Suponha que um colega tenha declarado `_XTAL_FREQ` como `48000000UL`, por ter
lido no manual que o kit opera a 48 MHz. O compilador acredita na declaração e
calcula os ciclos do atraso a partir dela.

#previsao[
  *5.4* — Se o clock real da CPU é 16 MHz e o compilador supôs 48 MHz, o atraso
  executado será mais *curto* ou mais *longo* que o pedido, e por qual fator?
  Deduza antes de testar.

  #resposta()
]

#tarefa[
  *5.5* — Volte o atraso para 500 ms, troque `_XTAL_FREQ` para `48000000UL`,
  recompile, grave e meça o novo período. A razão entre o período medido e o
  previsto confirma sua dedução?

  *5.6* — Inverta o raciocínio: partindo apenas de um período medido no
  osciloscópio e do valor declarado em `_XTAL_FREQ`, escreva a expressão que
  recupera a frequência real da CPU. Este é o método que você usará sempre que
  suspeitar do clock.

  #resposta(n: 2)
]

#importante[
  Ao terminar, *devolva `_XTAL_FREQ` para `16000000UL`* e regrave. Sair da
  sessão com o valor errado quebra todos os roteiros seguintes.
]

#observacao[
  Toda temporização do semestre — o Timer0 do termostato, o _baud rate_ da
  comunicação serial, a frequência do PWM — depende de `_XTAL_FREQ` estar
  correto. Um clock supostamente errado é a primeira hipótese a testar quando
  um periférico temporizado se comporta de forma estranha.
]

== O limite do olho

#tarefa[
  *5.7* — Reduza o atraso progressivamente e registre a partir de qual valor o
  LED *parece continuamente aceso*, sem piscar perceptível. Converta esse
  atraso em frequência.

  *5.8* — Nessa condição, o LED ainda está piscando? O que o osciloscópio
  mostra? Explique por que, acima dessa frequência, o osciloscópio deixa de ser
  um instrumento conveniente e passa a ser o *único* capaz de revelar o que o
  pino está fazendo.

  #resposta(n: 2)
]

#conceito[
  Você acaba de encontrar experimentalmente o princípio do controle por largura
  de pulso: acima de algumas dezenas de hertz, a carga — o olho, um motor, uma
  resistência de aquecimento — responde à *média* do sinal, não a cada
  transição. Esse mesmo fenômeno reaparece mais adiante no curso, com o
  hardware do módulo CCP gerando a onda no lugar do laço de atraso.
]

= Teste de aceitação

O roteiro está concluído quando, na presença do professor:

#quadro Sete LEDs do PORTD permanecem acesos e o LED de RD0 pisca.


#quadro O grupo mostra o arquivo `.production.hex` que gerou.

#quadro O grupo grava novamente o firmware, do zero, sem consultar o roteiro.

#quadro A tabela de previsão está preenchida e rubricada, com as medidas ao lado.

#quadro `_XTAL_FREQ` foi devolvido a `16000000UL` e o kit regravado.

= Entrega e critério

#figure(
  table(
    columns: (auto, 1fr),
    fill: listra,
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(cab[Peso], cab[Item]),
    [0,20], [Teste de aceitação aprovado em bancada],
    [0,10], [Resposta 3.1 — tentativas até conectar e diagnóstico],
    [0,15], [Respostas 4.1 a 4.3],
    [0,25], [Resposta 4.4, com justificativa do mecanismo],
    [0,30], [Parte 5 — previsão rubricada, medidas e respostas 5.3 a 5.6],
  ),
  caption: [Distribuição do ponto do Roteiro 0.],
)

As respostas 4.4 e 5.6 valem mais que as demais porque são as únicas que exigem
raciocínio sobre causa, e não observação.

= Armadilhas frequentes

#figure(
  table(
    columns: (1.1fr, 1.4fr),
    fill: listra,
    stroke: 0.5pt + luma(200),
    inset: 7pt,
    table.header(cab[Sintoma], cab[Causa provável]),
    [Não existe pasta `production`], [Compilou pelo botão de Debug],
    [`PK2Error0022`], [Tentou gravar pelo PICkit-2; use o bootloader],
    [Bootloader não conecta], [Janela de 4 a 5 s expirou: reinicie e clique em seguida],
    [Bootloader não conecta (persistente)], [MPLAB X aberto, ou cabo na USB traseira],
    [LED não pisca após gravar], [Faltou o RESET (SW9)],
    [Ventoinha continua ligada], [O `.hex` gravado não é o que você compilou],
    [XC8 falha com erro sem sentido], [Caminho do projeto com acento ou espaço],
    [Período medido é 3× menor que o previsto], [`_XTAL_FREQ` declarado como 48 MHz],
    [Osciloscópio mostra linha reta], [Garra de terra fora do GND, ou ponta no pino errado],
  ),
  caption: [Diagnóstico rápido do Roteiro 0.],
)

= Para a próxima sessão

#tarefa[
  Traga escrito: qual a diferença entre `LATD = 0x01` e `LATD |= 0x01`?

  Se não souber, escreva o que você *acha* que acontece em cada caso. A
  hipótese errada é material de aula — e vale nota tanto quanto a certa.
]
