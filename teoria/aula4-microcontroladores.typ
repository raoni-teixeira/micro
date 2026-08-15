// ============================================================
//  MICROCONTROLADORES — Aula 4
//  Conversão Analógico-Digital
// ============================================================

#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 4])
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
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 4 --- Conversão Analógico-Digital] \
  #v(0.2em)
  #text(size: 12pt)[Amostragem, quantização, tempo de aquisição e aritmética em ponto fixo] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Relacionar as duas discretizações envolvidas na conversão --- no tempo e em
    amplitude --- e reconhecer as consequências de cada uma.
  - Configurar o conversor do PIC18F4550: canal, referências, alinhamento do
    resultado, clock de conversão e tempo de aquisição em hardware.
  - Dimensionar o clock de conversão a partir da frequência do oscilador,
    respeitando os limites do dispositivo.
  - Converter a leitura bruta em grandeza física usando aritmética inteira, sem
    recorrer a ponto flutuante.
  - Avaliar criticamente a resolução efetiva obtida com um sensor real e propor
    formas de melhorá-la.
]

= Duas discretizações

O mundo físico é contínuo em amplitude e em tempo; a memória do microcontrolador
é discreta em ambos. A conversão analógico-digital faz as duas reduções, e é
útil mantê-las separadas, porque cada uma tem seus próprios erros e suas
próprias soluções.

#definicao("amostragem")[
  Discretização no tempo: o sinal contínuo é observado apenas em instantes
  determinados, espaçados de $T_s$. Toda a informação entre duas amostras é
  descartada.
]

#definicao("quantização")[
  Discretização em amplitude: o valor amostrado é aproximado pelo mais próximo
  entre $2^n$ níveis disponíveis. O erro cometido é limitado a meio nível.
]

O teorema da amostragem estabelece que reconstruir o sinal exige amostrar a mais
que o dobro da maior frequência presente. Abaixo disso ocorre o *rebatimento*:
componentes de alta frequência aparecem, no sinal amostrado, disfarçadas de
baixa frequência --- e nenhum processamento posterior as separa das componentes
verdadeiras.

#observacao[
  Numa planta térmica, a tentação é considerar o assunto irrelevante: a
  temperatura de um bloco metálico muda em segundos, e amostrar a cada 100 ms
  parece folgado. E é --- *para o sinal*. O rebatimento, porém, não atinge apenas
  o sinal: ruído elétrico de alta frequência captado pelo cabo do sensor também
  é amostrado, e também rebate para a faixa baixa, onde se confunde com variação
  real de temperatura. É por isso que um filtro passa-baixas na entrada
  analógica não é luxo, e é por isso que o encontro seguinte trata de filtragem.
]

= O conversor por aproximações sucessivas

O PIC18F4550 possui um conversor de 10 bits com 13 canais multiplexados. Seu
princípio é uma busca binária em hardware:

+ o sinal é amostrado e mantido num capacitor interno;
+ um conversor digital-analógico interno gera uma tensão de tentativa;
+ um *comparador* decide se o valor mantido é maior ou menor que a tentativa;
+ o resultado fixa um bit, e o processo se repete para o bit seguinte.

#observacao[
  Dez bits exigem dez decisões, uma por bit --- daí o conversor levar dez vezes
  mais que uma comparação simples. Note que o elemento decisor é exatamente o
  comparador que será estudado no próximo encontro: *a conversão é comparação
  repetida*. Um conversor de 10 bits e um comparador não são periféricos de
  natureza distinta; são o mesmo elemento usado dez vezes ou uma vez só.
]

== Quantização e resolução

#derivacao[
  Com $n$ bits e faixa de entrada de 0 a $V_"ref"$, o degrau elementar vale
  $ "LSB" = V_"ref"/2^n $
  Para $V_"ref" = 5 "V"$ e $n = 10$:
  $ "LSB" = 5/1024 approx 4,88 "mV" $
  O erro de quantização é limitado a meio degrau, isto é, cerca de 2,44 mV.
]

#atencao[
  Resolução não é exatidão. Os 10 bits descrevem quantos degraus existem; nada
  dizem sobre a fidelidade do valor. Erro de referência, não linearidade, ruído
  e impedância da fonte deterioram o resultado, e é comum um conversor de 10
  bits entregar oito bits de informação confiável. Anunciar quatro casas decimais
  de temperatura a partir dessa leitura é reportar precisão inexistente.
]

= Configuração no PIC18F4550

Três registradores controlam o módulo, com uma divisão clara de papéis.

#figure(
  table(
    columns: (1fr, 2.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Registrador], cab[Conteúdo]),
    [`ADCON0`], [Seleção do canal, bit de disparo e término da conversão, e
      ligamento do módulo],
    [`ADCON1`], [Quais pinos são analógicos e quais são digitais; escolha das
      tensões de referência positiva e negativa],
    [`ADCON2`], [Alinhamento do resultado, tempo de aquisição automático e
      seleção do clock de conversão],
  ),
  caption: [Divisão de papéis entre os registradores do conversor.],
) <tab-adcon>

O resultado de 10 bits ocupa dois registradores, `ADRESH` e `ADRESL`, e o bit de
alinhamento decide como os dez bits se distribuem entre os dezesseis
disponíveis.

#atencao[
  Com alinhamento à direita, os dois bits mais significativos ficam em `ADRESH`
  e os oito restantes em `ADRESL` --- é o formato conveniente para leitura em C.
  Com alinhamento à esquerda, `ADRESH` sozinho contém os oito bits mais
  significativos, o que é conveniente quando se deseja descartar os dois bits
  menos significativos e trabalhar com 8 bits. *Escolher o alinhamento errado
  produz valores multiplicados ou divididos por quatro*, um erro fácil de
  cometer e de diagnosticar.
]

== O clock de conversão

Cada uma das dez decisões consome um período $T_"AD"$, derivado da frequência do
oscilador por um divisor selecionável. Esse período tem limites: abaixo do
mínimo, o comparador interno não estabiliza e o resultado é lixo; acima do
máximo, a carga do capacitor de retenção se dissipa durante a própria conversão.

#derivacao[
  Com o oscilador em 48 MHz, os divisores disponíveis produzem:
  $ f_"osc"/32 = 1,5 "MHz" arrow.r T_"AD" approx 0,67 "µs" $
  $ f_"osc"/64 = 750 "kHz" arrow.r T_"AD" approx 1,33 "µs" $
  Sendo o mínimo do dispositivo da ordem de 0,7 µs, a primeira opção está
  *abaixo do limite* e deve ser descartada; a segunda é a escolha correta. A
  conversão completa consome cerca de onze períodos:
  $ t_"conv" approx 11 dot 1,33 "µs" approx 14,7 "µs" $
]

#atencao[
  Confirme o valor mínimo de $T_"AD"$ na folha de dados antes de fixar o
  divisor. O sintoma de um divisor rápido demais é traiçoeiro: a conversão
  *funciona*, mas os bits menos significativos ficam instáveis, e o efeito é
  confundido com ruído do sensor --- levando o estudante a filtrar em software
  um problema criado na configuração.
]

== O tempo de aquisição

Antes de converter, o capacitor de retenção precisa carregar-se até a tensão do
sinal, através da impedância da fonte. Se a conversão começar antes disso, o
valor convertido é o de um capacitor parcialmente carregado --- sempre puxado na
direção da leitura anterior.

#observacao[
  *Esta é a melhoria mais relevante em relação à família anterior.* No PIC16, a
  espera de aquisição era responsabilidade do programa: inseria-se um atraso por
  software entre a seleção do canal e o disparo. No PIC18F4550, os bits de tempo
  de aquisição em `ADCON2` fazem o hardware esperar automaticamente o número
  programado de períodos $T_"AD"$ antes de iniciar a conversão. O código fica
  mais simples *e* mais correto --- material antigo escrito para o PIC16 traz
  atrasos manuais que aqui são desnecessários.
]

#atencao[
  A impedância da fonte é parte do dimensionamento. O fabricante recomenda que
  ela não ultrapasse alguns quilo-ohms; um divisor resistivo com resistores de
  centenas de quilo-ohms na entrada do conversor impede a carga do capacitor no
  tempo previsto, e produz leituras sistematicamente deslocadas. Quando isso é
  inevitável, a solução é um seguidor de tensão entre a fonte e o pino.
]

#atencao[
  *Trocar de canal exige nova aquisição.* Selecionar outro canal e disparar
  imediatamente a conversão devolve um valor contaminado pelo canal anterior ---
  o capacitor ainda guarda a carga da leitura passada. Com o tempo de aquisição
  automático configurado, o hardware cuida disso; sem ele, a leitura alternada
  entre dois canais produz o clássico "os dois sensores interferem um no outro".
]

= Sequência de uso

#codigo[
```c
void adc_iniciar(void)
{
    ADCON1 = 0x0E;    /* apenas AN0 analogico; referencias na alimentacao */
    ADCON2 = 0xBE;    /* direita; aquisicao de 20 TAD; Fosc/64            */
    ADCON0 = 0x01;    /* canal 0, modulo ligado                           */
}

uint16_t adc_ler(uint8_t canal)
{
    ADCON0 = (uint8_t)((canal << 2) | 0x01);   /* seleciona e mantem ligado */

    ADCON0bits.GO = 1;                  /* dispara; o hardware aguarda
                                           a aquisicao antes de converter */
    while (ADCON0bits.GO) { }           /* espera o termino               */

    return (uint16_t)(((uint16_t)ADRESH << 8) | ADRESL);
}
```
]

#observacao[
  A espera na terceira linha da função de leitura é bloqueante, e dura cerca de
  20 µs --- desprezível diante dos milissegundos de uma escrita no display, e
  por isso aceitável no laboratório. A alternativa correta em sistemas mais
  exigentes é disparar a conversão e tratar o término por interrupção, deixando
  o processador livre nesse intervalo. É a mesma progressão vista com o botão no
  encontro 2: primeiro a versão bloqueante, depois a versão orientada a evento.
]

= Do valor bruto à grandeza física

O conversor devolve um número entre 0 e 1023. Transformá-lo em temperatura é o
ponto em que muitos projetos introduzem ponto flutuante --- e, neste
dispositivo, isso é caro: as rotinas de ponto flutuante são implementadas em
software e consomem centenas de ciclos e vários bytes de RAM por operação.

#derivacao[
  O sensor LM35 entrega 10 mV por grau Celsius. Com referência de 5 V, a tensão
  em milivolts correspondente a uma leitura $N$ é
  $ V["mV"] = N dot 5000/1024 $
  Como 10 mV equivalem a 1 °C, então 1 mV equivale a 0,1 °C. Logo, *o valor da
  tensão em milivolts é numericamente igual à temperatura em décimos de grau*:
  $ T["décimos de "degree"C"] = N dot 5000/1024 = N dot 625/128 $
  A fração $625/128$ tem denominador potência de dois, de modo que a divisão é
  um deslocamento de sete posições:
  $ T = (N dot 625) >> 7 $
]

#codigo[
```c
/* Temperatura em decimos de grau, sem ponto flutuante.
   O produto intermediario excede 16 bits: 1023 * 625 = 639375. */
int16_t adc_para_decimos(uint16_t bruto)
{
    return (int16_t)(((uint32_t)bruto * 625u) >> 7);
}

/* Exibicao: 253 decimos  ->  "25.3 C" */
void mostrar(int16_t decimos)
{
    lcd_numero(decimos / 10);
    lcd_texto(".");
    lcd_numero(decimos % 10);
}
```
]

#atencao[
  O comentário sobre o produto intermediário não é decorativo. Sem a conversão
  para 32 bits, `1023 * 625` transborda uma variável de 16 bits e produz um valor
  absurdo --- e o defeito só aparece em temperaturas altas, quando a leitura
  cresce o suficiente. É o tipo de erro que passa por todos os testes feitos em
  temperatura ambiente.
]

#observacao[
  A representação em décimos de grau num inteiro de 16 bits cobre de $-3276,8$ a
  $+3276,7$ °C: folga absurda para a aplicação, ao custo de dois bytes e de
  nenhuma rotina de ponto flutuante. *Ponto fixo não é uma limitação a ser
  tolerada; é a escolha correta neste contexto* --- e é assim que se faz também
  em sistemas de 32 bits sem unidade de ponto flutuante.
]

= A resolução efetiva do arranjo

Vale confrontar os números com a aplicação, como se fez com a referência
programável no encontro seguinte.

#derivacao[
  Cada degrau de 4,88 mV corresponde, com o LM35, a
  $ Delta T = 4,88 "mV" / (10 "mV"\/degree"C") approx 0,49 degree"C" $
  Além disso, a faixa útil é mal aproveitada: a 25 °C o sensor entrega 250 mV, e
  a leitura correspondente é
  $ N = 250/4,88 approx 51 $
  de um total de 1023. Mesmo a 100 °C, apenas um quinto da escala é utilizado.
]

#figure(
  table(
    columns: (1.3fr, 1.3fr, 1.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Providência], cab[Resolução resultante], cab[Custo]),
    [Nada; referência na alimentação], [cerca de 0,49 °C], [Nenhum],
    [Referência externa de 1,024 V], [0,1 °C, com leitura já em décimos],
      [Componente de referência externo; faixa limitada a 102 °C],
    [Amplificar o sensor por 4], [cerca de 0,12 °C],
      [Amplificador operacional e sua precisão],
    [Média de várias amostras], [Melhora o ruído, não o degrau],
      [Tempo e memória; tratado no encontro 6],
  ),
  caption: [Formas de melhorar a resolução efetiva.],
) <tab-resolucao>

#observacao[
  A segunda linha é elegante o bastante para merecer nota: com referência de
  1,024 V, o degrau vale exatamente 1 mV, e a leitura bruta *já é* a temperatura
  em décimos de grau --- a conversão se reduz a nada. É um bom exemplo de como
  uma escolha de hardware elimina código em vez de exigi-lo.
]

#atencao[
  A quarta linha corrige um mal-entendido comum: promediar não reduz o degrau de
  quantização. Se o sinal for perfeitamente estável, todas as amostras cairão no
  mesmo degrau e a média será esse degrau. A média só acrescenta informação
  quando há ruído --- e é precisamente por isso que, em conversores de precisão,
  se *adiciona* ruído deliberadamente antes de promediar.
]

= Transposição

Conversores em plataformas de 32 bits são reconhecíveis a partir do que se viu
aqui, com quatro acréscimos: resolução maior, tipicamente 12 bits; conversão
disparada por temporizador, sem intervenção do processador; transferência do
resultado para memória por acesso direto, permitindo capturar sequências
inteiras sem custo de processador; e varredura automática de vários canais em
sequência programada.

#observacao[
  Reunidos, esses recursos permitem algo que aqui não é possível: amostrar vários
  canais a taxa fixa, com precisão de temporização, e acordar o processador
  apenas quando um bloco de amostras estiver pronto. O conceito, entretanto,
  é o mesmo desta aula --- aquisição, comparação sucessiva, quantização --- e as
  armadilhas de impedância de fonte, referência e tempo de aquisição são
  idênticas.
]

= Exercícios

#exercicio("4.1")[
  Com oscilador de 20 MHz, determine qual divisor produz o $T_"AD"$ mais rápido
  que ainda respeita o mínimo do dispositivo, calcule esse período e estime a
  duração de uma conversão completa.
]

#exercicio("4.2")[
  Um projeto lê alternadamente dois sensores em canais distintos. As leituras
  parecem "contaminadas": quando um sensor aquece, a leitura do outro sobe
  ligeiramente. Explique o mecanismo e apresente duas correções possíveis.
]

#exercicio("4.3")[
  Deduza a expressão em ponto fixo para converter a leitura bruta em décimos de
  grau supondo referência positiva de 2,048 V e sensor LM35. Verifique se o
  produto intermediário cabe em 16 bits e, se não couber, indique a conversão de
  tipo necessária.
]

#exercicio("4.4")[
  Um estudante mede a temperatura ambiente e observa a leitura oscilando entre
  247, 253 e 251 décimos de grau, sem que a temperatura real esteja mudando.
  Liste três causas possíveis --- uma na configuração do conversor, uma no
  circuito e uma inerente à quantização --- e proponha como distinguir
  experimentalmente qual delas domina.
]

#exercicio("4.5")[
  Argumente contra a afirmação: "usar `float` para a temperatura é mais simples e
  o compilador resolve; preocupação com ponto fixo é otimização prematura".
  Apresente pelo menos três objeções técnicas quantificáveis neste dispositivo.
]
