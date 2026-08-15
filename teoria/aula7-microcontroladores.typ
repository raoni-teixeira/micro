#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 7])
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
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 7 --- Temporizadores e Base de Tempo] \
  #v(0.2em)
  #text(size: 12pt)[Como um sistema passa a saber que horas são] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Explicar o funcionamento de um contador com divisor de entrada e distinguir
    os modos temporizador e contador.
  - Calcular pré-carga e período para um intervalo desejado, e reconhecer as
    fontes de erro do resultado.
  - Escolher entre os temporizadores disponíveis conforme a aplicação.
  - Construir uma base de tempo de 1 ms e, sobre ela, um escalonador
    cooperativo capaz de executar tarefas em ritmos distintos.
  - Distinguir deriva de flutuação e adotar a estratégia de recarga que evita a
    primeira.
]

= O problema da espera ativa

Todo o firmware até aqui mediu tempo esperando. A função de atraso do compilador
executa um laço vazio dimensionado para consumir a quantidade certa de ciclos ---
e, enquanto o consome, o processador não faz nada.

#atencao[
  Além do desperdício, há um problema de correção: o atraso por software supõe
  que nada interrompe o laço. Quando as interrupções entram em cena, cada
  interrupção atendida durante um atraso o *estende*, e o tempo real deixa de
  corresponder ao pedido. Atrasos por software e interrupções coexistem mal ---
  outra razão para migrar para o temporizador.
]

#definicao("temporizador")[
  Contador em hardware que incrementa automaticamente a cada ciclo de uma fonte
  de clock, independentemente da execução do programa, e sinaliza quando
  transborda. No modo *contador*, a fonte é um sinal externo, e o mesmo
  periférico passa a contar eventos em vez de tempo.
]

A independência é a propriedade essencial: o contador avança enquanto o
processador faz outra coisa, dorme ou atende interrupções. O tempo deixa de ser
consumido e passa a ser *observado*.

= Os temporizadores do PIC18F4550

#figure(
  table(
    columns: (auto, auto, 1.6fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Módulo], cab[Bits], cab[Característica], cab[Uso típico]),
    [Temporizador 0], [8 ou 16], [Divisor de entrada amplo, largura
      selecionável], [Base de tempo geral],
    [Temporizador 1], [16], [Aceita cristal externo de baixa frequência],
      [Relógio de tempo real; despertar do modo de baixo consumo],
    [Temporizador 2], [8], [Possui registrador de período e divisor de saída],
      [Base de tempo exata; obrigatório para a modulação por largura de pulso],
    [Temporizador 3], [16], [Semelhante ao 1], [Captura e comparação],
  ),
  caption: [Os quatro temporizadores e suas vocações.],
) <tab-timers>

#observacao[
  A terceira linha merece destaque porque decide o encontro seguinte: o
  temporizador 2 é o único com *registrador de período*, isto é, com um valor de
  comparação que reinicia a contagem automaticamente. Isso o torna exato --- e é
  a razão de o módulo de modulação por largura de pulso depender obrigatoriamente
  dele.
]

= Cálculo do intervalo

#derivacao[
  O contador avança a cada ciclo de instrução dividido pelo fator do divisor de
  entrada. O intervalo até o transbordo, partindo de um valor de pré-carga $P$
  num contador de $n$ bits, é
  $ t = T_"cy" dot D dot (2^n - P) $
  em que $D$ é o fator do divisor. Isolando a pré-carga:
  $ P = 2^n - t/(T_"cy" dot D) $
]

#exemplo[
  Objetivo: 1 ms com oscilador de 48 MHz, contador de 16 bits e divisor 1:16.
  Com $T_"cy" approx 83,33 "ns"$, cada incremento vale
  $ 83,33 "ns" dot 16 approx 1,333 "µs" $
  O número de incrementos necessários é
  $ 1 "ms" / 1,333 "µs" = 750 $
  e a pré-carga vale
  $ P = 65536 - 750 = 64786 $
]

#atencao[
  A conta acima só fecha quando o número de incrementos resulta inteiro. Se
  resultar fracionário, o intervalo obtido difere do pedido e o erro se acumula
  a cada ciclo --- em um relógio, essa fração vira minutos ao fim de um dia.
  Nesses casos, ou se ajusta o divisor, ou se escolhe um intervalo vizinho que
  feche exato, ou se compensa periodicamente em software.
]

= Deriva e flutuação

Dois erros distintos afetam uma base de tempo, e confundi-los leva a correções
inúteis.

#definicao("deriva e flutuação")[
  *Deriva* é o erro sistemático acumulado: cada ciclo é ligeiramente mais longo
  que o pretendido, e o desvio cresce indefinidamente. *Flutuação* é a variação
  aleatória em torno do valor correto, sem acúmulo.
]

#derivacao[
  Considere o tratador que recarrega o contador escrevendo o valor absoluto de
  pré-carga. Entre o transbordo e a escrita decorrem a latência de interrupção e
  as instruções iniciais do tratador --- digamos $t_e$. Como a contagem recomeça
  do valor escrito, e não da posição em que estava, esses $t_e$ são *perdidos* a
  cada ciclo:
  $ t_"real" = t_"desejado" + t_e $
  Com $t_e$ de 2 µs e período de 1 ms, o erro é de 0,2%: dezessete segundos por
  dia.
]

#codigo[
```c
/* Recarga por soma: preserva o excedente da contagem
   e elimina a deriva sistematica.                     */
void __interrupt(high_priority) isr_alta(void)
{
    if (INTCONbits.TMR0IF) {
        INTCONbits.TMR0IF = 0;

        /* soma a precarga ao valor atual, em vez de sobrescrever */
        uint16_t atual = (uint16_t)(((uint16_t)TMR0H << 8) | TMR0L);
        atual += PRECARGA;
        TMR0H = (uint8_t)(atual >> 8);
        TMR0L = (uint8_t)(atual & 0xFF);

        g_tique = 1;
    }
}
```
]

#atencao[
  A ordem de escrita dos dois bytes do contador não é indiferente: a parte alta
  é armazenada num registrador intermediário e só é efetivada quando a parte
  baixa é escrita. *Escrever na ordem errada corrompe a contagem*, e o mesmo vale
  para a leitura, que deve começar pela parte baixa. É um mecanismo de
  atomicidade em hardware, análogo à discussão de acesso não atômico do encontro
  9 --- e vale conferir a ordem exigida na folha de dados.
]

#observacao[
  A solução definitiva contra a deriva é o registrador de período do
  temporizador 2, que recarrega em hardware, sem participação do software e
  portanto sem latência alguma. Quando a exatidão importa, esse é o módulo a
  usar --- e é essa a razão de ele ser a base do encontro seguinte.
]

= O escalonador cooperativo

Com uma base de 1 ms, o sistema ganha uma noção de tempo, e as tarefas passam a
ser expressas em múltiplos dela.

#codigo[
```c
volatile uint8_t g_tique = 0;

int main(void)
{
    uint16_t ms_display = 0, ms_sensor = 0, ms_botao = 0;

    sistema_iniciar();

    for (;;) {
        if (!g_tique) {
            continue;
        }
        g_tique = 0;                     /* consome o tique */

        if (++ms_botao >= 5u) {          /* a cada 5 ms */
            ms_botao = 0;
            botao_amostrar();
        }

        if (++ms_sensor >= 100u) {       /* a cada 100 ms */
            ms_sensor = 0;
            temperatura = adc_ler(CANAL_LM35);
            controlar(temperatura, alvo);
        }

        if (++ms_display >= 300u) {      /* a cada 300 ms */
            ms_display = 0;
            atualizar_display(temperatura);
        }
    }
}
```
]

#observacao[
  Três ritmos distintos convivem sem que nenhum bloqueie os demais, e a estrutura
  não muda quando se acrescenta a quarta tarefa. Compare com a versão em
  varredura do encontro 2: lá, cada funcionalidade nova degradava o tempo de
  resposta de todas as anteriores. *Este é o ponto de virada arquitetural do
  curso* --- daqui em diante o firmware só cresce em largura, nunca em
  profundidade.
]

#atencao[
  A palavra *cooperativo* é literal: nenhuma tarefa é interrompida por outra, de
  modo que cada uma precisa devolver o controle rapidamente. Uma tarefa que
  demore mais que o período do tique faz os tiques seguintes serem perdidos ---
  e o sistema passa a marcar o tempo mais devagar que o relógio. A escrita no
  display, com 1,3 ms, está justamente nessa fronteira e merece medição.
]

= Transposição

Todo microcontrolador de 32 bits traz um temporizador dedicado à base de tempo
do sistema, com finalidade idêntica à construída aqui. As diferenças são
convenientes: contadores de 32 bits eliminam boa parte dos problemas de faixa,
e o registrador de recarga automática elimina a deriva por construção --- não há
software na malha de recarga.

#observacao[
  O escalonador cooperativo desta aula é, também, o degrau anterior ao sistema
  operacional de tempo real. Um sistema desses substitui o encadeamento de
  contadores por tarefas independentes com suas próprias pilhas, capazes de
  suspender e retomar. A troca é clara: ganha-se organização e preempção,
  paga-se em memória e em previsibilidade. Para o projeto deste semestre, o
  escalonador cooperativo é a escolha correta --- e reconhecer *quando* deixaria
  de ser é parte do que se avalia no seminário.
]

= Exercícios

#exercicio("7.1")[
  Calcule a pré-carga para obter 10 ms com oscilador de 20 MHz, contador de 16
  bits e divisor 1:32. Verifique se o número de incrementos é inteiro e, se não
  for, proponha um ajuste.
]

#exercicio("7.2")[
  Um sistema usa recarga por sobrescrita com $t_e = 3 "µs"$ e período nominal de
  2 ms. Calcule o erro percentual, o atraso acumulado em 24 h e o número de
  tiques perdidos nesse intervalo.
]

#exercicio("7.3")[
  Acrescente ao escalonador da seção 5 uma quarta tarefa que envie telemetria a
  cada 2 s, sem alterar a estrutura existente. Justifique o tipo escolhido para
  o contador correspondente.
]

#exercicio("7.4")[
  Explique por que o temporizador 2 é preferível ao 0 quando a exatidão do
  período é crítica, apontando o mecanismo de hardware responsável pela
  diferença.
]

#exercicio("7.5")[
  Um estudante afirma que o escalonador cooperativo "não é tempo real, porque
  uma tarefa longa atrasa as outras". Avalie a afirmação: em que sentido ela
  está correta, em que sentido é imprecisa, e o que exatamente seria necessário
  para caracterizar o sistema como de tempo real.
]
