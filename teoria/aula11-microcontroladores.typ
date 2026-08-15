#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 11])
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
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 11 --- Comunicação Serial Assíncrona] \
  #v(0.2em)
  #text(size: 12pt)[Quadro, taxa de símbolos, buffers e protocolo] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Descrever o quadro assíncrono e explicar como o receptor se sincroniza sem
    receber clock.
  - Calcular o valor do gerador de taxa e o erro resultante, e avaliar se ele é
    tolerável.
  - Reconhecer e tratar os erros de recepção característicos do módulo.
  - Implementar recepção por interrupção com buffer circular.
  - Projetar um protocolo de telemetria e um interpretador de comandos
    adequados a um sistema embarcado.
]

= O quadro assíncrono

Comunicações síncronas transportam um sinal de clock junto aos dados. A
comunicação assíncrona não o faz: economiza uma linha e exige que os dois lados
tenham sido *previamente configurados* com a mesma taxa.

#definicao("quadro assíncrono")[
  Estrutura mínima de transmissão composta por: um bit de início, que leva a
  linha ao nível oposto ao de repouso; os bits de dado, transmitidos do menos
  para o mais significativo; opcionalmente um bit de paridade; e um ou mais bits
  de parada, que devolvem a linha ao repouso.
]

#observacao[
  O bit de início é o mecanismo de sincronização. Ao detectar a borda que o
  inicia, o receptor dispara um relógio interno e passa a amostrar cada bit
  *no seu centro*, onde o sinal está mais estável. A sincronização é
  restabelecida a cada quadro --- e é por isso que pequenas diferenças de taxa
  entre os dois lados não se acumulam indefinidamente: elas precisam apenas
  sobreviver a dez bits.
]

#derivacao[
  Isso permite quantificar a tolerância. Se o receptor amostra no centro de cada
  bit, ele pode errar até meio bit ao chegar no último. Com dez bits contados
  desde a borda de início, o erro acumulado tolerável é
  $ epsilon.alt < (0,5)/10 = 5% $
  Na prática, exige-se folga: erros do transmissor e do receptor podem somar-se e
  atuar em sentidos opostos, e a borda de início tem incerteza própria. *A regra
  usual é manter o erro de cada lado abaixo de 2%.*
]

= O gerador de taxa

A taxa é obtida dividindo a frequência do oscilador por um valor programável em
dois registradores, que juntos formam um número de 16 bits --- recurso ausente
na família anterior, em que apenas 8 bits estavam disponíveis.

#derivacao[
  Na configuração de alta velocidade com divisor de 16 bits, a taxa vale
  $ "baud" = f_"osc"/(4 dot (n + 1)) $
  Isolando o valor a programar:
  $ n = f_"osc"/(4 dot "baud") - 1 $
  Com $f_"osc" = 48 "MHz"$ e 9600 símbolos por segundo:
  $ n = (48 dot 10^6)/(4 dot 9600) - 1 = 1250 - 1 = 1249 $
  O resultado é inteiro: o erro é *nulo*.
]

#exemplo[
  Para 115 200 símbolos por segundo, nas mesmas condições:
  $ n = (48 dot 10^6)/(4 dot 115200) - 1 approx 104,17 - 1 = 103,17 $
  Arredondando para 103, a taxa efetiva é
  $ (48 dot 10^6)/(4 dot 104) approx 115 385 $
  com erro de aproximadamente 0,16% --- muito abaixo do limite de 2%.
]

#atencao[
  Note que o valor 1249 não caberia em 8 bits. Na família anterior, obter 9600
  com erro nulo a partir de certas frequências era impossível, e a solução era
  escolher o cristal em função da taxa desejada --- daí os valores
  aparentemente estranhos como 11,0592 MHz, que existem exatamente para fechar
  divisões inteiras de taxa. Com o divisor de 16 bits, essa restrição
  praticamente desaparece.
]

#observacao[
  Aqui está a razão pela qual um erro de configuração de clock se manifesta
  primeiro na serial. A taxa deriva da frequência do processador; se `PLLDIV`
  estiver errado, como discutido no encontro 1, a taxa sai proporcionalmente
  errada e a recepção produz caracteres corrompidos. *Caracteres estranhos no
  terminal são, com frequência, um sintoma de clock e não de serial.*
]

= Erros de recepção

Dois indicadores de erro precisam ser tratados, e ignorá-los produz o defeito
mais frustrante deste periférico.

#figure(
  table(
    columns: (1.2fr, 1.5fr, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Erro], cab[Causa], cab[Tratamento]),
    [Sobrescrita], [Chegou um terceiro byte antes de os anteriores serem lidos],
      [*A recepção para até ser tratada*: é preciso desligar e religar o
       habilitador de recepção],
    [Enquadramento], [O bit de parada não foi encontrado no lugar esperado ---
      tipicamente taxa incorreta ou ruído], [Descartar o byte lendo o registrador
      de recepção],
  ),
  caption: [Erros de recepção e seu tratamento.],
) <tab-erros>

#atencao[
  A primeira linha é a origem do relato "a serial funcionou por um tempo e depois
  parou de receber". O módulo tem espaço para dois bytes; se o programa se
  distrai --- numa escrita de display, por exemplo --- e chega um terceiro, o
  indicador de sobrescrita liga e *a recepção é bloqueada permanentemente*. Nada
  mais chega até que o programa a reative explicitamente. Todo tratador de
  recepção deve verificar esse indicador; nenhum código sem essa verificação é
  confiável.
]

= Recepção por interrupção e buffer circular

Uma taxa de 9600 símbolos por segundo entrega um byte por milissegundo. Como a
atualização de display consome mais que isso, a recepção por varredura perde
dados. A solução é receber por interrupção e depositar num buffer.

#codigo[
```c
#define RX_TAM      32u                 /* potencia de dois */
#define RX_MASCARA  (RX_TAM - 1u)

static volatile uint8_t  rx_buf[RX_TAM];
static volatile uint8_t  rx_inicio = 0, rx_fim = 0;

void __interrupt(low_priority) isr_baixa(void)
{
    if (PIR1bits.RCIF) {
        if (RCSTAbits.OERR) {           /* sobrescrita: reativa */
            RCSTAbits.CREN = 0;
            RCSTAbits.CREN = 1;
        }

        uint8_t d = RCREG;              /* a leitura limpa o sinalizador */
        uint8_t prox = (uint8_t)((rx_fim + 1u) & RX_MASCARA);

        if (prox != rx_inicio) {        /* descarta se cheio */
            rx_buf[rx_fim] = d;
            rx_fim = prox;
        }
    }
}

uint8_t rx_disponivel(void)
{
    return (uint8_t)(rx_inicio != rx_fim);
}
```
]

#observacao[
  Três decisões nesse código merecem registro. O tamanho é potência de dois, o
  que troca o resto da divisão por uma máscara. Os índices são `volatile`, porque
  são escritos no tratador e lidos fora dele --- exatamente a regra do encontro
  9. E o buffer é considerado cheio quando *faltaria uma posição*, sacrificando
  um byte de capacidade: sem isso, buffer cheio e buffer vazio teriam a mesma
  representação e seriam indistinguíveis.
]

#atencao[
  Como os índices são de 8 bits, sua leitura é atômica neste dispositivo e não
  exige seção crítica. *Essa conveniência desaparece* se o buffer crescer a ponto
  de exigir índices de 16 bits --- e aí volta integralmente o problema do
  encontro 9. É uma correção que depende de um detalhe que ninguém revisita ao
  aumentar o buffer.
]

= Projeto do protocolo

Ter bytes trafegando não é ter comunicação. É preciso definir o que significam,
onde uma mensagem começa e termina, e o que fazer com o inesperado.

#figure(
  table(
    columns: (1.2fr, 1.4fr, 1.4fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Decisão], cab[Texto legível], cab[Binário compacto]),
    [Volume de dados], [Maior], [Menor],
    [Depuração], [Direta, em qualquer terminal], [Exige ferramenta própria],
    [Delimitação], [Natural, por fim de linha], [Exige marcador e escape],
    [Custo de conversão], [Formatação numérica], [Nenhum],
    [Adequação], [Telemetria didática, taxas baixas], [Enlaces rápidos, dados volumosos],
  ),
  caption: [Duas famílias de protocolo.],
) <tab-protocolo>

#observacao[
  Para o projeto do semestre, texto legível é a escolha correta, e por uma razão
  pedagógica explícita: o estudante abre um terminal e *vê* o sistema
  funcionando, sem intermediários. Um protocolo binário economizaria bytes que
  não faltam e esconderia justamente o que se quer observar.
]

Um formato adequado tem quatro propriedades: *delimitação* inequívoca --- fim de
linha; *identificação* do tipo de mensagem no início; *campos separados* por
caractere fixo; e *tolerância* a mensagens malformadas, que devem ser
descartadas sem travar o interpretador.

#codigo[
```
T:253;A:300;S:1;P:45     <- telemetria: temperatura, alvo, saida, potencia
SET:280                  <- comando: ajustar alvo para 28,0 C
OK:280                   <- confirmacao
ERR:FORA_FAIXA           <- recusa, com motivo
```
]

#atencao[
  Todo comando deve receber resposta --- confirmação ou recusa explícita. Sem
  isso, o lado remoto não distingue "comando aceito" de "comando perdido no
  caminho", e a única saída é reenviar às cegas. A regra vale para qualquer
  protocolo: *silêncio nunca é resposta*.
]

#observacao[
  O interpretador de comandos é uma máquina de estados que consome caracteres
  até o delimitador, e é o segundo exemplo natural desse padrão no curso --- o
  primeiro foi o controlador com histerese do encontro 6. O encontro seguinte
  formaliza a construção.
]

= Níveis elétricos

#atencao[
  Os pinos do microcontrolador operam entre 0 V e 5 V. O padrão RS-232 de
  computadores antigos opera com tensões de polaridade invertida e amplitude
  bem maior, capazes de destruir o pino. *Nunca ligue diretamente*: é preciso um
  circuito conversor de níveis. No laboratório, a ligação é feita por um
  conversor para porta USB, que já opera nos níveis corretos --- mas convém
  confirmar antes de conectar.
]

= Transposição

O periférico equivalente nas plataformas de 32 bits acrescenta transferência por
acesso direto à memória, que move blocos inteiros sem custo de processador e
torna o buffer circular um recurso de hardware; buffers internos maiores, que
reduzem o risco de sobrescrita; e detecção automática de taxa.

#observacao[
  Do lado do computador, a conexão física deixou de ser serial há muito tempo:
  usa-se um conversor USB que apresenta uma porta serial virtual. Toda a
  disciplina de taxa, quadro e erro descrita aqui continua valendo do lado do
  microcontrolador --- o que mudou foi apenas o outro extremo do cabo.
]

= Exercícios

#exercicio("11.1")[
  Com oscilador de 20 MHz, calcule o valor a programar e o erro resultante para
  9600 e para 115 200 símbolos por segundo. Indique se cada um é utilizável
  segundo o critério de 2%.
]

#exercicio("11.2")[
  Um sistema recebe corretamente por alguns segundos e depois deixa de receber
  qualquer dado, embora continue transmitindo normalmente. Identifique a causa
  mais provável, explique o mecanismo e escreva o trecho de código que a corrige.
]

#exercicio("11.3")[
  Dimensione o buffer de recepção para um sistema que recebe a 9600 símbolos por
  segundo e cuja tarefa mais longa bloqueia o laço principal por 15 ms. Indique o
  tamanho mínimo e o valor que você adotaria, justificando a margem.
]

#exercicio("11.4")[
  Projete o formato de mensagem para acrescentar ao protocolo desta aula um
  comando que consulte o histórico das últimas dez leituras. Especifique
  requisição, resposta e comportamento diante de requisição malformada.
]

#exercicio("11.5")[
  Argumente contra a afirmação: "como o erro tolerável é de 5%, uma taxa com 3%
  de erro funciona sem problemas". Aponte pelo menos dois fatores que consomem
  essa margem na prática.
]
