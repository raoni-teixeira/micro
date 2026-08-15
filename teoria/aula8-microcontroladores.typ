#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 8])
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

#align(center)[
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 8 --- Modulação por Largura de Pulso] \
  #v(0.2em)
  #text(size: 12pt)[Valores intermediários a partir de uma saída binária] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Explicar como uma saída de dois níveis produz efeito equivalente a um valor
    intermediário, e sob que condição isso é válido.
  - Configurar o módulo de modulação do PIC18F4550, calculando período e ciclo
    ativo.
  - Deduzir o compromisso entre frequência e resolução e reconhecer a faixa de
    frequências acessível neste dispositivo.
  - Escolher entre modulação por hardware e modulação lenta por software
    conforme o atuador.
  - Dimensionar o acionamento de uma carga real com transistor, incluindo as
    proteções obrigatórias.
]

= A ideia

O encontro 6 terminou com um impasse: o controle liga-desliga nunca estabiliza,
porque o atuador só assume dois valores. A saída digital continua tendo apenas
dois valores --- isso não muda. O que muda é o *tempo* em que cada um é mantido.

#definicao("modulação por largura de pulso")[
  Técnica em que um sinal periódico de dois níveis tem sua fração de tempo em
  nível ativo --- o *ciclo ativo* --- variada, de modo que o valor médio do
  sinal se torne proporcional a essa fração:
  $ overline(V) = d dot V_"DD", quad d = t_"ligado"/T $
]

#atencao[
  A equivalência com um valor contínuo só existe se a carga *filtrar* o
  chaveamento --- isto é, se sua constante de tempo for muito maior que o período
  do sinal. Um bloco térmico, um motor, uma indutância e o olho humano filtram
  naturalmente. Uma entrada lógica não filtra: aplicar modulação a um pino de
  dado produz uma sequência de bits, não meio nível lógico. *A carga é parte do
  conversor.*
]

= O módulo de modulação

O periférico gera o sinal em hardware, sem intervenção do processador após a
configuração. Sua base de tempo é obrigatoriamente o temporizador 2, cujo
registrador de período define a duração do ciclo.

#derivacao[
  O período do sinal é determinado pelo registrador de período $"PR"$, pelo
  divisor de entrada $D$ e pelo período do oscilador:
  $ T_"pwm" = ("PR" + 1) dot 4 dot T_"osc" dot D $
  Equivalentemente, em frequência:
  $ f_"pwm" = f_"osc" / (4 dot D dot ("PR" + 1)) $
  O ciclo ativo é programado num valor de 10 bits, distribuído entre um
  registrador de 8 bits e dois bits adicionais em outro registrador, e o tempo em
  nível ativo vale
  $ t_"ligado" = "valor" dot T_"osc" dot D $
]

#observacao[
  A assimetria chama atenção: o período é contado em ciclos de instrução, e o
  ciclo ativo em ciclos de oscilador --- quatro vezes mais finos. É exatamente
  isso que permite dez bits de resolução sobre um registrador de período de oito
  bits. Não é inconsistência de projeto; é o mecanismo que dá resolução extra.
]

== O compromisso entre frequência e resolução

#derivacao[
  Como o ciclo ativo é contado em unidades quatro vezes menores que o período,
  o número de valores distintos de ciclo ativo é
  $ N = 4 dot ("PR" + 1) $
  e a resolução em bits vale
  $ n = log_2 (4 dot ("PR" + 1)) $
  Com $"PR" = 255$, obtêm-se 1024 valores, ou 10 bits. Reduzir $"PR"$ para elevar
  a frequência reduz a resolução na mesma proporção: com $"PR" = 63$, restam 256
  valores, ou 8 bits.
]

#exemplo[
  Com oscilador de 48 MHz e divisor 1:16, o maior período disponível corresponde
  a $"PR" = 255$:
  $ f_"pwm" = (48 dot 10^6)/(4 dot 16 dot 256) approx 2,93 "kHz" $
  Essa é, portanto, a *menor frequência* obtenível por hardware nessa
  configuração --- e ela vem com a resolução máxima de 10 bits.
]

#atencao[
  A consequência é decisiva para o projeto. Cerca de 3 kHz é perfeitamente
  adequado para um transistor comandando uma resistência ou uma ventoinha ---
  está acima da faixa audível e a inércia térmica filtra com folga. Mas é
  *inaceitável* para um relé eletromecânico, que não comuta nessa velocidade e
  seria destruído em segundos. O módulo de hardware não atende a esse caso, e não
  há configuração que o faça.
]

= Modulação lenta por software

Para atuadores lentos, a solução é gerar a modulação sobre a base de tempo do
encontro anterior, com período de segundos em vez de milissegundos.

#codigo[
```c
/* Modulacao lenta: periodo de 1 s, resolucao de 1%.
   Chamada a cada 10 ms pelo escalonador cooperativo. */
#define PASSOS   100u

static uint8_t fase = 0;

void pwm_lento(uint8_t percentual)
{
    fase = (uint8_t)((fase + 1u) % PASSOS);
    LATCbits.LATC2 = (fase < percentual) ? 1 : 0;
}
```
]

#observacao[
  É o mesmo conceito com outra escala de tempo, e recebe o nome de *controle
  proporcional ao tempo*. Fornos industriais e controladores de temperatura
  comerciais funcionam assim: períodos de 1 s a 20 s, compatíveis com relés e
  com a inércia térmica da planta. A escolha entre as duas formas não é entre
  moderno e improvisado --- é ditada pelo atuador.
]

#figure(
  table(
    columns: (1.2fr, 1.3fr, 1.3fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Aspecto], cab[Por hardware], cab[Lenta, por software]),
    [Faixa de frequência], [Alguns kHz a centenas de kHz], [Fração de hertz a alguns hertz],
    [Custo de processador], [Nulo após configurar], [Uma chamada por passo],
    [Resolução], [Até 10 bits], [Definida pelo número de passos],
    [Atuador adequado], [Transistor, motor, LED], [Relé, contator, aquecedor de grande massa],
    [Precisão do tempo], [De hardware], [Limitada pelo escalonador],
  ),
  caption: [As duas formas de modulação e seus domínios.],
) <tab-pwm>

= Acionamento da carga

Um pino entrega dezenas de miliampères; um aquecedor consome amperes. Entre os
dois entra um transistor --- e é aqui que erros de montagem destroem componentes.

#figure(
  table(
    columns: (1.1fr, 2.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Elemento], cab[Função e dimensionamento]),
    [Transistor de efeito de campo, canal N, chaveando o lado do terra],
      [A carga fica entre a alimentação e o dreno; a fonte vai ao terra.
       Escolher um modelo que conduza plenamente com a tensão de porta
       disponível --- 5 V, e não 10 V],
    [Resistor de porta], [Dezenas a poucas centenas de ohms, em série com o
      pino. Limita o pico de corrente de carga da capacitância de porta],
    [Resistor de abaixamento na porta], [Da ordem de 10 kΩ, entre porta e terra.
      Garante o transistor desligado enquanto o pino ainda está em alta
      impedância, antes de o firmware configurar as portas],
    [Diodo de recirculação], [Obrigatório em carga indutiva. *Em paralelo com a
      carga*, com o catodo na alimentação e o anodo no dreno],
  ),
  caption: [Elementos do acionamento e seu dimensionamento.],
) <tab-carga>

#atencao[
  O diodo de recirculação é a montagem que mais causa dano. Ele vai *em
  paralelo com a carga*, jamais em série com ela. Em série, o diodo bloqueia ou
  conduz a corrente principal --- e, sobretudo, deixa de existir o caminho para a
  corrente da indutância no instante do desligamento. A tensão induzida então se
  desenvolve sobre o transistor até destruí-lo. Este erro já ocorreu em bancada
  nesta disciplina, com perda de componentes; a montagem deve ser conferida
  *antes* de energizar.
]

#observacao[
  O resistor de abaixamento na porta protege contra uma janela de tempo real: da
  energização até a linha de código que configura a direção da porta, o pino está
  em alta impedância, e a porta do transistor --- que é essencialmente um
  capacitor --- pode assumir qualquer potencial. Sem o resistor, é possível que a
  carga seja acionada por alguns milissegundos a cada reinicialização. Num
  aquecedor, isso é inofensivo; num motor, não é.
]

= Do controle à atuação

Com o atuador aceitando valores intermediários, o controlador do encontro 6 pode
deixar de ser binário. A lei proporcional mais simples faz o acionamento
crescer com a distância até o valor desejado:

$ u = k dot (T_"sp" - T), quad "limitado a" [0, 100] $

#observacao[
  Duas propriedades mudam qualitativamente. A oscilação permanente desaparece:
  existe agora um valor de acionamento em que a potência entregue iguala a
  perdida, e o sistema pode repousar nele. Em compensação, surge um *erro
  permanente* --- o equilíbrio ocorre necessariamente com $T$ um pouco abaixo de
  $T_"sp"$, pois é essa diferença que gera o acionamento. Corrigi-lo exige um
  termo integral, assunto de disciplinas de controle. Aqui basta reconhecer a
  troca: sai a oscilação, entra o desvio permanente.
]

#atencao[
  A saturação em $[0, 100]$ não é detalhe de implementação. Sem ela, um desvio
  grande produz um valor de acionamento fora da faixa que, atribuído a uma
  variável de 8 bits, transborda --- e um pedido de 300% pode virar 44%. Limitar
  explicitamente antes de escrever no registrador é obrigatório.
]

= Transposição

Os temporizadores avançados das famílias de 32 bits ampliam o mesmo mecanismo
com três recursos relevantes: saídas *complementares*, para acionar dois
transistores em meia ponte; *tempo morto* inserido por hardware entre o
desligamento de um e a ligação do outro, impedindo condução simultânea; e uma
*entrada de desligamento de emergência* que corta as saídas em hardware.

#observacao[
  Esse último recurso fecha o arco iniciado no encontro 5. A saída do comparador
  interno pode ser ligada diretamente a essa entrada: ultrapassado o limiar de
  sobretemperatura, a modulação é cortada em nanossegundos, sem executar uma
  instrução, e a proteção permanece válida com o firmware travado. É a versão
  madura da camada de proteção que aqui só se consegue com componentes externos.
]

= Exercícios

#exercicio("8.1")[
  Com oscilador de 20 MHz e divisor 1:4, determine o valor do registrador de
  período que produz a frequência mais próxima de 5 kHz. Calcule a frequência
  efetivamente obtida, o número de valores distintos de ciclo ativo e a
  resolução em bits.
]

#exercicio("8.2")[
  Um projeto exige modulação a 20 kHz --- acima da faixa audível --- com
  resolução mínima de 8 bits, e o oscilador está em 48 MHz. Verifique se ambos os
  requisitos podem ser atendidos simultaneamente e, em caso negativo, indique
  qual deles precisa ceder e em quanto.
]

#exercicio("8.3")[
  Adapte a função `pwm_lento` para período de 5 s mantendo resolução de 1%,
  indicando o intervalo de chamada necessário e verificando se ele é compatível
  com o escalonador do encontro 7.
]

#exercicio("8.4")[
  Um estudante monta o acionamento de uma ventoinha e o transistor é destruído
  no primeiro desligamento. Descreva a montagem provável do diodo, explique o
  mecanismo físico da destruição e desenhe em palavras a montagem correta,
  indicando a orientação do componente.
]

#exercicio("8.5")[
  Compare o controle liga-desliga com histerese e o controle proporcional com
  modulação quanto a: oscilação em regime, erro permanente, desgaste do atuador e
  complexidade de implementação. Em seguida, defenda um cenário em que o
  liga-desliga é a escolha superior.
]
