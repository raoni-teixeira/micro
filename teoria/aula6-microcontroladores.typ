// ============================================================
//  MICROCONTROLADORES — Aula 6
//  Ruído, Filtragem e Controle Liga-Desliga
// ============================================================

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 6])
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
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 6 --- Ruído, Filtragem e Controle Liga-Desliga] \
  #v(0.2em)
  #text(size: 12pt)[Da amostra bruta à decisão de acionamento] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Identificar as origens do ruído numa cadeia de medida e reconhecer quais
    delas se combatem em hardware e quais em software.
  - Implementar e comparar os dois filtros digitais viáveis neste dispositivo:
    média móvel e filtro exponencial de primeira ordem.
  - Quantificar o compromisso entre suavização e atraso, e reconhecer o atraso
    como fator que degrada o controle.
  - Projetar um controle liga-desliga com histerese em ponto fixo, deduzindo o
    período de comutação a partir das taxas da planta.
  - Comparar a histerese em software com a histerese em hardware do encontro
    anterior, e justificar a escolha em cada caso.
]

= De onde vem o ruído

O encontro anterior produziu um número em décimos de grau. Colocado no display,
esse número raramente fica parado: oscila entre valores vizinhos mesmo com a
planta em repouso. Antes de filtrar, convém saber o que está sendo filtrado,
porque cada origem tem sua contramedida --- e algumas não se resolvem em
software.

#figure(
  table(
    columns: (1.2fr, 1.5fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Origem], cab[Característica], cab[Onde se combate]),
    [Quantização], [Oscilação de um degrau entre valores adjacentes],
      [Não se remove; só se reduz mudando a referência ou o ganho],
    [Ruído térmico e do sensor], [Aleatório, sem correlação entre amostras],
      [Média: é o caso em que a filtragem digital funciona bem],
    [Captação pelo cabo], [Correlacionada com a rede, em 60 Hz e harmônicas],
      [Blindagem, cabo curto, par trançado; e escolha da taxa de amostragem],
    [Comutação do atuador], [Picos coincidentes com o chaveamento da carga],
      [Separação de terras, filtro na alimentação, não amostrar durante a comutação],
    [Oscilação da alimentação], [Desloca a referência e, com ela, toda a escala],
      [Desacoplamento; referência independente da alimentação],
  ),
  caption: [Origens do ruído e respectivas contramedidas.],
) <tab-ruido>

#atencao[
  As três últimas linhas se resolvem principalmente em *hardware*. Filtrar em
  software um ruído de comutação de relé é tratar o sintoma: o pico continua
  entrando na cadeia, e a média apenas o dilui pelas amostras vizinhas. A ordem
  correta de trabalho é reduzir o ruído na origem e só então filtrar o que
  restou.
]

#observacao[
  Um caso merece destaque porque é contraintuitivo e reaparece no laboratório: a
  captação em 60 Hz. Se a taxa de amostragem for um múltiplo inteiro de 60 Hz,
  todas as amostras cairão sempre na mesma fase da interferência, que passa a
  parecer um *deslocamento constante* em vez de ruído --- indetectável por
  filtragem. Uma taxa que seja submúltiplo do período da rede, ao contrário, faz
  a média sobre um ciclo completo cancelar a interferência. A escolha da taxa de
  amostragem é, portanto, também uma decisão de filtragem.
]

= Média móvel

#definicao("média móvel")[
  Filtro que substitui cada amostra pela média das $N$ amostras mais recentes:
  $ y[n] = 1/N sum_(k=0)^(N-1) x[n-k] $
]

#derivacao[
  Para ruído aleatório e não correlacionado, promediar $N$ amostras reduz o
  desvio padrão por um fator $sqrt(N)$:
  $ sigma_y = sigma_x / sqrt(N) $
  A consequência prática é dura: para melhorar a suavidade por um fator 10 é
  preciso *cem* amostras. O retorno é decrescente, e passar de 16 para 32
  amostras dobra o custo em memória e atraso para ganhar apenas 41%.
]

O preço aparece no tempo. Uma média de $N$ amostras atrasa o sinal em cerca de
$(N-1)/2$ amostras: diante de um degrau real de temperatura, o valor filtrado
demora esse tanto para acompanhar.

#atencao[
  Numa malha de controle, esse atraso não é apenas incômodo estético: ele *entra
  na malha*. O controlador passa a decidir com base em uma temperatura que já
  não é a atual, o que aumenta a sobrelevação e pode induzir oscilação. Filtrar
  demais é um erro de projeto tão real quanto filtrar de menos.
]

#codigo[
```c
/* Media movel de 8 amostras. Tamanho potencia de dois:
   a divisao vira deslocamento e o indice vira mascara.  */
#define N_AMOSTRAS   8u
#define MASCARA      (N_AMOSTRAS - 1u)

static int16_t  janela[N_AMOSTRAS] = {0};
static uint8_t  indice = 0;
static int32_t  soma   = 0;

int16_t media_movel(int16_t amostra)
{
    soma -= janela[indice];        /* remove a mais antiga */
    soma += amostra;               /* acrescenta a nova    */
    janela[indice] = amostra;
    indice = (indice + 1u) & MASCARA;

    return (int16_t)(soma / (int32_t)N_AMOSTRAS);
}
```
]

#observacao[
  Duas escolhas nesse código merecem atenção. Manter a *soma corrente*, em vez
  de somar o vetor a cada chamada, torna o custo independente de $N$ --- duas
  operações, e não $N$. E escolher $N$ como potência de dois transforma a divisão
  numa operação barata e o avanço do índice numa máscara, dispensando o teste de
  retorno ao início. É um exemplo do princípio geral: *num sistema de 8 bits,
  potências de dois são quase sempre a escolha certa*.
]

= Filtro exponencial

Quando os 16 bytes do vetor pesam --- e num dispositivo com 2 KB de RAM, com
frequência pesam ---, há uma alternativa que não guarda histórico nenhum.

#definicao("filtro exponencial de primeira ordem")[
  Filtro que aproxima a saída da entrada por uma fração fixa da diferença a cada
  amostra:
  $ y[n] = y[n-1] + alpha dot (x[n] - y[n-1]), quad 0 < alpha <= 1 $
  É o equivalente discreto de um circuito RC passa-baixas.
]

#derivacao[
  Escolhendo $alpha = 1\/2^k$, a multiplicação vira um deslocamento de $k$
  posições à direita:
  $ y[n] = y[n-1] + (x[n] - y[n-1]) >> k $
  O filtro custa uma subtração, um deslocamento e uma soma, e ocupa uma única
  variável. Sua constante de tempo equivale a aproximadamente $2^k$ amostras, de
  modo que $k = 3$ tem suavização comparável a uma média de oito amostras --- com
  um dezesseis avos da memória.
]

#atencao[
  A implementação em inteiros tem uma armadilha. Se a diferença entre entrada e
  saída for menor que $2^k$, o deslocamento à direita resulta em zero e *o filtro
  para de convergir*, estacionando a alguns décimos de distância do valor
  verdadeiro. O sintoma é um erro residual permanente e pequeno. A solução usual
  é manter a variável interna com resolução ampliada --- guardar $y$ multiplicado
  por $2^k$ e dividir apenas na saída.
]

#figure(
  table(
    columns: (1.2fr, 1.3fr, 1.3fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Aspecto], cab[Média móvel], cab[Exponencial]),
    [Memória], [$N$ amostras], [Uma variável],
    [Custo por amostra], [Constante, com soma corrente], [Menor ainda],
    [Resposta a degrau], [Rampa, conclui em $N$ amostras], [Exponencial, nunca conclui formalmente],
    [Rejeição de pico isolado], [Divide o pico por $N$], [Divide por $2^k$ e decai],
    [Previsibilidade do atraso], [Exata: $(N-1)/2$], [Aproximada],
    [Quando preferir], [Quando o atraso precisa ser conhecido], [Quando a memória é o limite],
  ),
  caption: [Comparação entre os dois filtros.],
) <tab-filtros>

#observacao[
  Nenhum dos dois remove um pico isolado de grande amplitude --- ambos apenas o
  espalham. Para picos, o instrumento adequado é o *filtro de mediana*, que
  ordena um pequeno conjunto de amostras e toma a central, descartando extremos
  por construção. Com três amostras, ele custa duas comparações e é a defesa
  mais barata contra o pico de comutação do relé.
]

= Controle liga-desliga

Com a temperatura medida e filtrada, resta decidir o acionamento. A lei mais
simples compara com o valor desejado:

$ u = cases(
  1 & "se" T < T_"sp",
  0 & "se" T >= T_"sp"
) $

#atencao[
  Essa lei é inutilizável na prática, e a razão está no encontro anterior: em
  torno do ponto de comutação, o ruído residual --- inclusive o de quantização,
  que nenhum filtro elimina --- faz a saída alternar a cada amostra. Com
  amostragem a 10 Hz, isso significa dez acionamentos por segundo de um relé
  especificado para algumas centenas de milhares de operações em toda a vida
  útil.
]

== Histerese

A solução é a mesma do encontro anterior, agora em software: dois limiares em
vez de um.

#definicao("controle liga-desliga com histerese")[
  Lei de controle com banda morta de largura $Delta$ em torno do valor desejado:
  $ u[n] = cases(
    1 & "se" T < T_"sp" - Delta\/2,
    0 & "se" T > T_"sp" + Delta\/2,
    u[n-1] & "caso contrário"
  ) $
  Dentro da banda, a saída *não muda* --- ela conserva o estado anterior.
]

#codigo[
```c
/* Tudo em decimos de grau. Banda de 1,0 C -> DELTA = 10. */
#define DELTA   10

static uint8_t aquecedor = 0;

uint8_t controlar(int16_t temp, int16_t alvo)
{
    if (temp < (int16_t)(alvo - DELTA / 2)) {
        aquecedor = 1;
    } else if (temp > (int16_t)(alvo + DELTA / 2)) {
        aquecedor = 0;
    }
    /* entre os limiares: mantem o estado — esta é a histerese */

    return aquecedor;
}
```
]

#observacao[
  A ausência de `else` final não é esquecimento: *é o mecanismo*. A memória do
  estado anterior é o que distingue este controlador do anterior, e ela está na
  variável estática. Um controlador com histerese é, formalmente, uma máquina de
  dois estados --- observação que retorna no encontro 12.
]

== O período de comutação

A largura da banda não é escolha estética: ela determina com que frequência o
atuador liga e desliga.

#derivacao[
  Seja $a$ a taxa de aquecimento com o aquecedor ligado, em graus por segundo, e
  $b$ a taxa de resfriamento com ele desligado. Para atravessar a banda $Delta$
  em cada sentido:
  $ t_"liga" = Delta/a, quad t_"desliga" = Delta/b $
  O período de um ciclo completo é a soma:
  $ T_"ciclo" = Delta dot (1/a + 1/b) $
  *O período é diretamente proporcional à largura da banda.* Estreitar a banda
  para melhorar a precisão multiplica na mesma proporção o número de
  acionamentos.
]

#exemplo[
  Numa planta com $a = 0,5 degree"C/s"$ e $b = 0,2 degree"C/s"$, uma banda de
  1,0 °C resulta em
  $ T_"ciclo" = 1,0 dot (1/0,5 + 1/0,2) = 2 + 5 = 7 "s" $
  ou aproximadamente 514 comutações por hora. Reduzir a banda para 0,2 °C leva o
  período a 1,4 s e a cerca de 2 570 comutações por hora --- cinco vezes mais
  desgaste em troca de 0,8 °C de precisão.
]

#atencao[
  Daí decorre a regra de projeto desta aula: *a banda de histerese é um
  compromisso entre precisão de temperatura e vida do atuador*, e o número
  correto sai da conta acima com as taxas medidas na planta real, não de um
  valor copiado de outro projeto. Medir $a$ e $b$ no kit é, por isso, parte do
  roteiro de laboratório correspondente.
]

= Histerese em software ou em hardware

O encontro anterior obteve histerese sem software algum. Vale confrontar as duas
soluções sobre o mesmo problema.

#figure(
  table(
    columns: (1.2fr, 1.3fr, 1.3fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Aspecto], cab[Comparador com realimentação], cab[Conversor e software]),
    [Limiar ajustável em operação], [Não, sem componentes adicionais], [Sim, em qualquer valor],
    [Largura da banda], [Fixada pelos resistores], [Alterável por software],
    [Custo de processador], [Nenhum], [Uma amostragem por ciclo],
    [Latência], [Centenas de nanossegundos], [Um período de amostragem],
    [Depende do firmware], [Não], [Sim, integralmente],
    [Permite mostrar e transmitir o valor], [Não], [Sim],
    [Permite filtrar antes de decidir], [Não], [Sim],
  ),
  caption: [As duas realizações da mesma lei de controle.],
) <tab-hw-sw>

#observacao[
  As duas últimas linhas decidem o projeto do semestre. O termostato precisa
  mostrar a temperatura, transmiti-la por telemetria e permitir que o operador
  altere o valor desejado pelo teclado --- e nada disso é possível com a solução
  puramente analógica. A quinta linha, porém, é o argumento para *não abandonar*
  o comparador: a proteção de sobretemperatura permanece válida com o firmware
  travado. Cada solução no seu papel: *o software controla, o hardware protege*.
]

= O limite do liga-desliga

Este controlador tem uma propriedade que nenhum ajuste corrige: *ele nunca
estabiliza*. Como a saída assume apenas dois valores, a temperatura
necessariamente oscila entre os limiares --- não existe condição de equilíbrio
em que o aquecedor entregue exatamente a potência perdida pela planta.

#observacao[
  Estabilizar exige que o atuador possa entregar valores *intermediários*, e não
  apenas ligado ou desligado. É exatamente o que a modulação por largura de pulso
  fornece: variando a fração de tempo ligado, uma carga com inércia térmica
  responde à *média*, e não ao chaveamento. Essa é a ponte para os encontros 7 e
  8 --- e o motivo de o projeto trocar o relé por um transistor comandado por
  modulação.
]

= Exercícios

#exercicio("6.1")[
  Um sistema amostra a 100 Hz e usa média móvel de 32 amostras. Calcule a
  redução esperada do desvio padrão do ruído aleatório e o atraso introduzido,
  em milissegundos. Comente se esse atraso é aceitável para uma planta térmica
  com constante de tempo de 30 s e para um controle de corrente com constante de
  tempo de 5 ms.
]

#exercicio("6.2")[
  Implemente o filtro exponencial com $k = 4$ preservando resolução interna
  ampliada, de modo a evitar o erro residual descrito na seção 3. Mostre a
  expressão do valor retornado ao chamador.
]

#exercicio("6.3")[
  Uma planta aquece a $0,8 degree"C/s"$ e resfria a $0,3 degree"C/s"$. Determine
  a largura de banda que limita o acionamento a no máximo 200 comutações por
  hora, e informe a precisão de temperatura resultante.
]

#exercicio("6.4")[
  Um estudante relata que, ao acrescentar média móvel de 64 amostras, a
  temperatura ficou "bonita no display", mas o sistema passou a ultrapassar o
  valor desejado em vários graus antes de desligar o aquecedor. Explique o
  mecanismo, indique qual grandeza da malha foi alterada e proponha duas
  correções distintas.
]

#exercicio("6.5")[
  Um colega propõe eliminar a histerese e, no lugar dela, exigir cinco leituras
  consecutivas do mesmo lado do limiar antes de comutar. Analise a proposta:
  ela resolve o problema do chaveamento excessivo? Que diferença existe entre
  esse mecanismo e a histerese propriamente dita? Em que situação as duas
  soluções divergem?
]
