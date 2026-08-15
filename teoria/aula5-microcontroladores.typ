// ============================================================
//  MICROCONTROLADORES — Aula 5
//  Comparação Analógica: Comparadores, CVREF e Histerese
// ============================================================

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 5])
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

// ============================================================

#align(center)[
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 5 --- Comparação Analógica] \
  #v(0.2em)
  #text(size: 12pt)[Comparadores internos, referência programável e histerese em hardware] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Reconhecer o comparador analógico como um conversor de um bit, contínuo no
    tempo, e situá-lo em relação ao conversor por aproximações sucessivas
    estudado no encontro anterior.
  - Configurar o módulo de comparadores do PIC18F4550: modos de operação,
    pinos envolvidos, inversão de saída e interrupção por mudança de estado.
  - Calcular a tensão da referência interna programável nas duas faixas e
    avaliar criticamente sua resolução para um sensor real.
  - Implementar histerese em hardware por realimentação positiva e deduzir os
    dois limiares resultantes.
  - Decidir, diante de uma especificação, entre a solução por conversão e a
    solução por comparação --- e reconhecer quando as duas convivem.
]

= O problema que motiva a aula

No encontro anterior, o conversor analógico-digital produziu uma temperatura em
décimos de grau: um número de 16 bits, obtido a cada amostragem, ao custo de
configurar o canal, aguardar o tempo de aquisição, disparar a conversão, esperar
o término e converter o resultado. É a base de todo o projeto do semestre.

Vale, no entanto, olhar para o que se faz com esse número no caso mais simples.
A decisão do termostato é:

$ "aquecedor" = cases(
  "ligado" & "se" T < T_"sp",
  "desligado" & "se" T >= T_"sp"
) $

O resultado dessa cadeia inteira é *um bit*. Dez bits de conversão, dezenas de
ciclos de processador e várias linhas de código produzem uma única informação
binária: a temperatura está abaixo ou acima do limiar.

Existe um periférico que produz exatamente esse bit, sem processador, sem
conversão e sem latência de software. É o comparador analógico --- e ele está
dentro do mesmo chip, desligado, desde a primeira aula.

#atencao[
  Esta aula não propõe substituir o conversor pelo comparador. Propõe entender
  por que os dois coexistem em praticamente todo microcontrolador moderno, e
  qual pergunta de projeto decide entre eles. O encontro seguinte volta ao
  controle liga-desliga e compara as duas soluções sobre o mesmo problema.
]

= O que é um comparador

#definicao("comparador analógico")[
  Amplificador diferencial operando em malha aberta, cuja saída digital indica
  qual das duas entradas analógicas é maior:
  $ V_"out" = cases(
    1 & "se" V_+ > V_-,
    0 & "se" V_+ < V_-
  ) $
  A transição ocorre continuamente no tempo, sem comando de disparo e sem
  intervenção do processador.
]

Do ponto de vista de circuito, é o amplificador operacional visto em Eletrônica,
sem realimentação negativa: com ganho de malha aberta muito alto, qualquer
diferença de entrada acima de alguns milivolts leva a saída à saturação. A
diferença é que o comparador integrado é projetado para saturar --- tem estágio
de saída digital, tempo de resposta especificado e não sofre com as limitações
de excursão de um amplificador usado fora de sua região linear.

#observacao[
  *O comparador é um conversor de um bit.* Essa não é uma analogia forçada: é
  literalmente a definição. E a recíproca também vale --- um conversor
  #emph[flash] de $n$ bits é construído com $2^n - 1$ comparadores em paralelo,
  cada um com seu limiar, todos decidindo simultaneamente. O conversor por
  aproximações sucessivas do encontro anterior usa *um* comparador e um
  conversor digital-analógico, aplicando o limiar sucessivas vezes. O comparador
  é o tijolo elementar de toda conversão.
]

Três propriedades diferenciam a comparação da conversão e explicam por que ela
sobrevive em qualquer arquitetura:

- *Custo de processador nulo.* O comparador opera continuamente, em hardware
  analógico. O processador pode estar executando outra coisa --- ou dormindo.
- *Latência determinística e muito baixa.* O tempo de resposta é de algumas
  centenas de nanossegundos, contra dezenas de microssegundos de uma conversão
  completa somada ao tempo de software que a rodeia.
- *Funciona sem clock.* Como não depende de sequenciamento digital, o comparador
  continua operando com o processador em modo de baixo consumo, e sua mudança de
  estado pode ser o próprio evento que desperta o sistema.

= O módulo de comparadores do PIC18F4550

O dispositivo contém *dois* comparadores, C1 e C2, cuja interligação com os
pinos é selecionável. Toda a configuração está no registrador `CMCON`.

#figure(
  table(
    columns: (auto, 1fr, 2.2fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Bit], cab[Nome], cab[Função]),
    [7], [`C2OUT`], [Saída do comparador 2, somente leitura],
    [6], [`C1OUT`], [Saída do comparador 1, somente leitura],
    [5], [`C2INV`], [Inverte a polaridade da saída de C2],
    [4], [`C1INV`], [Inverte a polaridade da saída de C1],
    [3], [`CIS`], [Chave de seleção de entrada, nos modos multiplexados],
    [2--0], [`CM2:CM0`], [Modo de operação do módulo],
  ),
  caption: [Registrador `CMCON`.],
) <tab-cmcon>

Os oito modos codificados em `CM2:CM0` vão do módulo completamente desligado até
dois comparadores independentes com saída levada a pinos. Os de uso mais comum
são três:

#figure(
  table(
    columns: (auto, 1.6fr, 2.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[`CM2:CM0`], cab[Modo], cab[Uso típico]),
    [`111`], [Comparadores desligados], [Estado de menor consumo; os pinos ficam
      disponíveis como entrada e saída digital ou como canais do conversor],
    [`100`], [Dois comparadores independentes], [Dois limiares distintos, cada um
      com sua própria referência externa],
    [`011`], [Dois comparadores com referência comum], [Duas grandezas
      comparadas contra o mesmo limiar --- tipicamente a referência interna],
    [`110`], [Referência comum, com saídas nos pinos], [Como o anterior, mas com
      o resultado disponível eletricamente para outro circuito],
  ),
  caption: [Modos de operação mais usados.],
)

#atencao[
  O valor `CMCON = 0x07` --- que aparece na inicialização do firmware de
  referência do laboratório --- é justamente o modo "comparadores desligados".
  Ele está lá por segurança: com o módulo ativo, os pinos de RA0 a RA3 deixam de
  responder como entrada e saída digital, e um projeto que não espera isso
  apresenta um defeito difícil de localizar. *Ativar os comparadores exige
  remover essa linha*, e isso precisa ser feito conscientemente.
]

== Pinos envolvidos

As entradas dos comparadores compartilham pinos com o conversor
analógico-digital, e as saídas compartilham pinos com a porta A:

#figure(
  table(
    columns: (auto, 1fr, 2fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Pino], cab[Função no módulo], cab[Compartilhado com]),
    [RA0], [Entrada inversora de C1], [Canal AN0 do conversor],
    [RA1], [Entrada inversora de C2], [Canal AN1 do conversor],
    [RA2], [Entrada não inversora de C2; saída de `CVREF`], [Canal AN2, referência negativa],
    [RA3], [Entrada não inversora de C1], [Canal AN3, referência positiva],
    [RA4], [Saída `C1OUT`, nos modos com saída], [Entrada de clock do temporizador 0],
    [RA5], [Saída `C2OUT`, nos modos com saída], [Canal AN4],
  ),
  caption: [Pinos do módulo de comparação e suas funções concorrentes.],
) <tab-pinos>

#atencao[
  Nada disso é gratuito: cada pino usado pelos comparadores é um pino subtraído
  do conversor ou da porta digital. No kit do laboratório, essa disputa é ainda
  mais restrita porque o roteamento passa por chaves. *Antes de qualquer
  experimento em bancada, confira o contrato de pinos congelado no Roteiro 0* ---
  e, em particular, verifique se as saídas em RA4 e RA5 estão livres.
]

== Interrupção por mudança de estado

O comparador possui interrupção própria, sinalizada por `CMIF` e habilitada por
`CMIE`. Ela é disparada *a cada mudança* na saída de qualquer dos comparadores
--- tanto na subida quanto na descida.

#atencao[
  A interrupção é por mudança, e não por nível. Portanto o tratador não sabe,
  pelo simples fato de ter sido chamado, em qual estado o comparador está: ele
  precisa *ler* `C1OUT` ou `C2OUT`. Mais do que isso, a leitura de `CMCON` faz
  parte da condição para que o sinalizador possa ser baixado --- limpar `CMIF`
  sem ter lido o registrador leva à ressinalização imediata e a um tratador que
  aparentemente é chamado sem parar. É um dos defeitos clássicos deste módulo.
]

= A referência de tensão programável

Comparar contra uma tensão externa exige um divisor resistivo, um potenciômetro
ou uma referência de precisão. O PIC18F4550 evita isso oferecendo uma referência
interna programável, `CVREF`, gerada por uma escada resistiva de 16 degraus e
controlada pelo registrador `CVRCON`.

#figure(
  table(
    columns: (auto, 1fr, 2.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Bit], cab[Nome], cab[Função]),
    [7], [`CVREN`], [Habilita a referência],
    [6], [`CVROE`], [Leva `CVREF` ao pino RA2],
    [5], [`CVRR`], [Seleciona a faixa: 1 para faixa baixa, 0 para faixa alta],
    [4], [`CVRSS`], [Fonte da escada: 0 para a alimentação, 1 para as referências externas],
    [3--0], [`CVR3:CVR0`], [Seleciona o degrau, de 0 a 15],
  ),
  caption: [Registrador `CVRCON`.],
)

As duas faixas obedecem a leis diferentes. Sendo $V_"src"$ a tensão da fonte
selecionada por `CVRSS` e $k$ o valor de `CVR3:CVR0`:

$ "faixa baixa " ("CVRR" = 1): quad V_"CVREF" = k/24 dot V_"src" $

$ "faixa alta " ("CVRR" = 0): quad V_"CVREF" = V_"src"/4 + k/32 dot V_"src" $

#exemplo[
  Com alimentação de 5 V como fonte, a faixa baixa cobre de 0 V a 3,125 V em
  degraus de $5/24 approx 208 "mV"$; a faixa alta cobre de 1,25 V a
  aproximadamente 3,59 V em degraus de $5/32 approx 156 "mV"$.
]

== Uma resolução que precisa ser confrontada com o sensor

O sensor do laboratório é o LM35, com saída de 10 mV por grau. Um degrau de 208
mV da faixa baixa corresponde, portanto, a *mais de 20 °C*. A referência interna
alimentada a partir de 5 V simplesmente não consegue expressar um limiar de
40 °C com precisão útil: os degraus vizinhos valem cerca de 31 °C e 52 °C.

#atencao[
  Este é o ponto central da aula, e é uma limitação real do dispositivo, não um
  detalhe de configuração. *A referência interna programável não tem resolução
  suficiente para o limiar de controle deste projeto.* Qualquer material que
  apresente o comparador como substituto direto do conversor num termostato com
  LM35 está omitindo esta conta.
]

Há três saídas, e cada uma ensina algo diferente:

+ *Reduzir a fonte da escada.* Com `CVRSS = 1`, a escada passa a operar entre as
  referências externas. Alimentada com 1 V, a faixa baixa passa a ter degraus de
  aproximadamente 42 mV, ou pouco mais de 4 °C. Melhora uma ordem de grandeza e
  ainda assim não serve para controle fino.
+ *Amplificar o sensor.* Um ganho de 5 antes do comparador divide por cinco o
  valor de cada degrau em graus. Resolve, ao custo de um amplificador externo ---
  e de deslocar o problema para a precisão desse amplificador.
+ *Usar o comparador para aquilo em que ele é insubstituível.* Um limiar de
  segurança de sobretemperatura não precisa de precisão de um grau: precisa de
  atuação rápida, independente de software e operante com o processador parado.
  Aqui os 208 mV de degrau deixam de ser um problema.

#observacao[
  A terceira saída é a que orienta o projeto do semestre. O conversor permanece
  responsável pela *medição* --- o valor que vai ao display, à telemetria e à
  malha de controle. O comparador assume a *proteção*: um limiar superior que
  desliga o aquecedor por caminho independente, mesmo que o firmware esteja
  travado. Não são alternativas concorrentes; são camadas com funções distintas.
]

= Histerese

O comparador ideal comuta exatamente no cruzamento do limiar. Perto desse ponto,
qualquer ruído --- e um sensor analógico ligado a um cabo sempre tem ruído ---
produz múltiplas comutações. Numa carga como o aquecedor, isso significa
acionamentos repetidos em rápida sucessão, com desgaste do atuador e
interferência elétrica.

#definicao("histerese")[
  Propriedade pela qual o limiar de comutação depende do estado atual da saída:
  o limiar de subida $V_"TH"$ é maior que o limiar de descida $V_"TL"$. A
  diferença entre eles define a faixa em que a saída não muda, tornando o
  circuito imune a ruído de amplitude inferior a essa faixa.
]

#atencao[
  Os comparadores do PIC18F4550 *não possuem histerese programável*. Famílias
  mais recentes trazem um bit dedicado para isso; esta não traz. A histerese
  precisa ser construída --- e há duas maneiras.
]

== Histerese por realimentação positiva

A maneira clássica realimenta a saída para a entrada não inversora através de um
resistor, formando com o resistor da referência um divisor cujo resultado
depende do estado da saída.

#derivacao[
  Seja a referência $V_"ref"$ ligada à entrada não inversora através de $R_1$, e
  a saída do comparador realimentada à mesma entrada através de $R_2$. Sendo
  $V_o$ o valor atual da saída, a tensão no nó de entrada é a superposição das
  duas fontes:
  $ V_+ = (V_"ref" dot R_2 + V_o dot R_1)/(R_1 + R_2) $
  Com a saída em nível baixo, $V_o = 0$, e o limiar efetivo é
  $ V_"TL" = (V_"ref" dot R_2)/(R_1 + R_2) $
  Com a saída em nível alto, $V_o = V_"DD"$, e o limiar passa a
  $ V_"TH" = (V_"ref" dot R_2 + V_"DD" dot R_1)/(R_1 + R_2) $
  A largura da histerese é a diferença entre os dois:
  $ Delta V = V_"TH" - V_"TL" = V_"DD" dot R_1/(R_1 + R_2) $
  Ela depende apenas da razão entre os resistores e da excursão da saída --- não
  da referência.
]

#exemplo[
  Para uma histerese de aproximadamente 2 °C com o LM35, é preciso
  $Delta V = 20 "mV"$. Com $V_"DD" = 5 "V"$:
  $ R_1/(R_1 + R_2) = 20 "mV" / 5 "V" = 0,004 $
  o que dá $R_2 approx 249 dot R_1$. Escolhendo $R_1 = 1 "k" Omega$ e o valor
  comercial $R_2 = 240 "k" Omega$, resulta $Delta V approx 20,7 "mV"$, ou cerca
  de 2,1 °C. \
  #v(0.4em)
  Note a ordem de grandeza da razão: histereses estreitas exigem realimentação
  fraca, e resistores muito desiguais. É a fonte de erro mais comum neste
  circuito.
]

== Histerese por reprogramação da referência

Existe uma alternativa puramente digital, que dispensa componentes externos:
quando a saída comuta, o tratador de interrupção *reprograma* `CVR3:CVR0` para o
degrau vizinho, deslocando o limiar na direção que se opõe a novas comutações.

#codigo[
```c
/* Histerese por deslocamento da referencia programavel.
   Requer leitura de CMCON antes de baixar o sinalizador. */
void tratar_comparador(void)
{
    uint8_t estado = CMCON;          /* leitura obrigatoria */

    if (estado & 0x40) {             /* C1OUT em nivel alto */
        CVRCON = (CVRCON & 0xF0) | DEGRAU_BAIXO;
    } else {
        CVRCON = (CVRCON & 0xF0) | DEGRAU_ALTO;
    }

    PIR2bits.CMIF = 0;
}
```
]

O custo é reintroduzir o software na malha: a largura da histerese passa a ser
um degrau inteiro da escada --- os mesmos 208 mV inconvenientes --- e a resposta
volta a depender da latência de interrupção. É uma solução elegante e limitada,
e vale conhecê-la sobretudo pelo que ela revela: *histerese é um conceito de
sistema, não um recurso de periférico*. Ela pode ser realizada em componentes
externos, na configuração do periférico ou em algumas linhas de código --- e o
encontro seguinte a implementa pela terceira via, sobre o valor lido do
conversor.

= Comparador ou conversor: a decisão de projeto

#figure(
  table(
    columns: (1.2fr, 1.4fr, 1.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Aspecto], cab[Comparador], cab[Conversor]),
    [Informação produzida], [Um bit], [Palavra de 10 bits],
    [Custo de processador], [Nenhum], [Configuração, espera e leitura],
    [Latência], [Centenas de nanossegundos], [Dezenas de microssegundos, mais o software],
    [Precisão do limiar], [Limitada pela referência disponível], [Limitada pela resolução do conversor],
    [Limiar ajustável por software], [Em degraus grosseiros], [Contínuo, em qualquer valor],
    [Opera com o processador parado], [Sim], [Não],
    [Serve para telemetria e display], [Não], [Sim],
    [Permite filtragem e média], [Não], [Sim],
  ),
  caption: [Comparação entre as duas soluções para a mesma decisão binária.],
) <tab-decisao>

A leitura da @tab-decisao sugere a regra prática: *o conversor mede, o
comparador vigia*. Sempre que for preciso saber o valor --- para mostrar,
transmitir, filtrar ou usar num algoritmo de controle ---, a conversão é
necessária. Sempre que bastar saber que um limite foi ultrapassado, e sobretudo
quando isso precisar acontecer rápido, com baixo consumo ou
independentemente do software, a comparação é a resposta.

#exemplo[
  *Detecção de falta de alimentação.* Um sistema alimentado pela rede precisa
  gravar o estado em memória não volátil quando a energia cai, usando a carga
  remanescente do capacitor de filtro --- uma janela de poucos milissegundos.
  Amostrar periodicamente a tensão pelo conversor consome processador o tempo
  todo e pode perder o instante crítico. Um comparador contra um divisor
  resistivo dispara a interrupção no momento exato, e o tratador tem toda a
  janela disponível para o registro. É uma aplicação em que a conversão
  simplesmente não serve.
]

= Transposição para arquiteturas modernas

O comparador é dos periféricos mais transferíveis do curso, e sua evolução em
plataformas de 32 bits mostra por quê. Diversas famílias ARM Cortex-M trazem um
periférico de comparação com dois avanços relevantes sobre o que se viu aqui:
*histerese programável por registrador*, dispensando a rede resistiva externa e
o artifício da reprogramação da referência; e, mais importante,
*interligação direta com outros periféricos*, sem passar pelo processador.

Nesse segundo ponto está a ideia que vale reter. Nas famílias que a suportam, a
saída do comparador pode ser ligada internamente à entrada de desligamento de
emergência do temporizador que gera a modulação por largura de pulso. A
consequência é notável: ao ultrapassar o limiar, o sinal de acionamento é
cortado *em hardware*, em nanossegundos, sem executar uma única instrução ---
e a proteção continua válida ainda que o firmware esteja travado. Essa é a
versão madura da mesma ideia de camada de proteção discutida na seção 4.

#observacao[
  Vale a honestidade sobre a demonstração de bancada: nem toda família traz o
  periférico. O STM32F407 usado na demonstração comparativa da disciplina *não*
  possui comparador integrado, enquanto famílias como F3, L4 e G4 possuem. A
  presença de um periférico é uma decisão de segmentação do fabricante, não uma
  propriedade da arquitetura --- e verificar isso na folha de dados, antes de
  projetar em cima da suposição, é parte do ofício.
]

= Exercícios

#exercicio("5.1")[
  Calcule o valor de `CVR3:CVR0` que produz a referência mais próxima de 1,5 V,
  primeiro na faixa baixa e depois na faixa alta, com a escada alimentada por
  5 V. Compare o erro absoluto das duas escolhas e justifique qual faixa é
  preferível para esse limiar.
]

#exercicio("5.2")[
  Um projeto usa o comparador C1 com realimentação positiva para vigiar uma
  tensão de bateria, com limiar nominal de 3,0 V e histerese de 150 mV. A saída
  do comparador excursiona entre 0 V e 5 V. Determine a razão entre os
  resistores e proponha um par de valores comerciais. Em seguida, calcule os dois
  limiares efetivos $V_"TH"$ e $V_"TL"$ resultantes desses valores.
]

#exercicio("5.3")[
  Um estudante relata que, ao habilitar a interrupção do comparador, o programa
  "para de responder" e o tratador parece ser chamado indefinidamente. O trecho
  do tratador contém apenas a leitura de uma variável global e a linha
  `PIR2bits.CMIF = 0;`. Explique a causa provável e corrija o trecho.
]

#exercicio("5.4")[
  Retome a especificação do termostato do laboratório. Proponha um arranjo em
  que o conversor faça a medição e o comparador implemente uma proteção de
  sobretemperatura em 80 °C, indicando: qual comparador e quais pinos usar, como
  gerar o limiar, e por que a resolução grosseira da referência interna é
  aceitável nesse papel e não seria no controle. Aponte também um conflito de
  pinos que esse arranjo criaria com o contrato congelado do Roteiro 0.
]

#exercicio("5.5")[
  Argumente contra a seguinte afirmação, apresentando pelo menos duas objeções
  técnicas: "como o comparador é um conversor de um bit e o conversor do
  PIC18F4550 tem dez bits, o comparador é sempre uma solução inferior e só se
  justifica em dispositivos que não possuem conversor".
]
