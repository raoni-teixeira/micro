#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 3])
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
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 3 --- Interfaceamento Paralelo e Display] \
  #v(0.2em)
  #text(size: 12pt)[O controlador HD44780 e o custo da espera] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Distinguir comunicação paralela e serial e reconhecer o compromisso entre
    número de pinos e velocidade.
  - Descrever a organização do controlador HD44780: memória de exibição,
    memória de caracteres e a separação entre comando e dado.
  - Implementar a comunicação em quatro bits, incluindo a sequência de
    inicialização e as temporizações exigidas.
  - Estimar o tempo consumido por uma atualização de tela e reconhecê-lo como o
    principal consumidor de tempo do sistema.
  - Aplicar estratégias de atualização que evitam tremulação e reduzem o tempo
    gasto com o display.
]

= Paralelo e serial

Ligar um periférico externo ao microcontrolador exige transportar bits. Há duas
formas, e a escolha entre elas é um compromisso permanente em projeto embarcado.

#definicao("comunicação paralela")[
  Transmissão simultânea de vários bits, cada um em uma linha física própria,
  acompanhada de linhas de controle que indicam quando o dado é válido.
]

A alternativa serial envia os bits em sequência por uma única linha. O paralelo
é mais rápido para a mesma frequência de sinal e mais simples de gerar; em
compensação, consome pinos --- e pinos são, neste dispositivo, o recurso mais
escasso de todos. Um display em oito bits ocupa onze pinos com sinais de
controle; o mesmo display em quatro bits ocupa sete; um display serial ocupa
dois ou três.

#observacao[
  A conta de pinos decide o projeto do semestre. Com 35 pinos e a necessidade de
  acomodar sensor, aquecedor, ventoinha, teclado matricial e comunicação, os
  quatro pinos economizados pelo modo de quatro bits não são detalhe: são o que
  torna o projeto viável no kit. É por isso que o modo reduzido é o padrão
  neste tipo de aplicação, apesar de exigir mais código.
]

= O controlador HD44780

O display alfanumérico do laboratório não é uma matriz de pontos comandada
diretamente: é um módulo com controlador próprio, que recebe comandos e
caracteres e cuida da varredura, da geração de caracteres e da atualização.

#figure(
  table(
    columns: (1fr, 2.6fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Elemento], cab[Função]),
    [Memória de exibição], [Guarda os códigos dos caracteres mostrados. Cada
      posição da tela corresponde a um endereço fixo],
    [Gerador de caracteres em ROM], [Contém os desenhos dos caracteres padrão,
      indexados pelo código recebido],
    [Gerador de caracteres em RAM], [Permite definir caracteres próprios ---
      tipicamente o símbolo de grau, ausente do conjunto padrão],
    [Registrador de instrução], [Recebe comandos: limpar, posicionar cursor,
      configurar modo],
    [Registrador de dados], [Recebe os códigos dos caracteres a exibir],
  ),
  caption: [Elementos internos do controlador.],
) <tab-hd44780>

Três linhas de controle governam a comunicação:

#figure(
  table(
    columns: (auto, 1fr, 2.2fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Linha], cab[Nome usual], cab[Significado]),
    [RS], [Seleção de registrador], [Nível baixo indica comando; nível alto
      indica dado a ser exibido],
    [R/W], [Leitura ou escrita], [Nível baixo escreve. Em geral ligado
      permanentemente ao terra, economizando um pino],
    [E], [Habilitação], [O dado é capturado na *borda de descida* deste sinal.
      É o pulso que efetiva a transferência],
  ),
  caption: [Linhas de controle.],
)

#atencao[
  Ligar a linha de leitura ao terra economiza um pino e tem uma consequência:
  torna-se impossível *ler* o indicador de ocupado do controlador. Sem ele, não
  há como perguntar se a operação anterior terminou --- resta esperar o tempo
  máximo especificado. Toda a temporização por atraso fixo descrita adiante é
  consequência dessa escolha de hardware.
]

== Endereçamento da tela

Os endereços da memória de exibição não são contíguos entre as linhas. Numa tela
de duas linhas por dezesseis colunas, a primeira linha começa no endereço zero e
a segunda começa em 64, independentemente do número de colunas.

#atencao[
  A descontinuidade é a origem de um defeito clássico: escrever dezessete
  caracteres seguidos não faz o texto passar para a segunda linha --- ele
  continua em posições invisíveis da primeira. Mudar de linha exige um comando
  explícito de posicionamento.
]

= O modo de quatro bits

No modo reduzido, cada byte é enviado em duas etapas: primeiro os quatro bits
mais significativos, depois os quatro menos significativos, cada metade
acompanhada de seu próprio pulso de habilitação.

#codigo[
```c
static void lcd_pulso(void)
{
    LATCbits.LATC0 = 1;        /* E em nivel alto  */
    __delay_us(1);
    LATCbits.LATC0 = 0;        /* borda de descida: captura */
    __delay_us(50);            /* tempo de execucao do comando */
}

static void lcd_nibble(uint8_t valor)
{
    LATD = (uint8_t)((LATD & 0x0F) | (valor & 0xF0));
    lcd_pulso();
}

void lcd_escrever(uint8_t valor, uint8_t eh_dado)
{
    LATCbits.LATC1 = eh_dado;      /* RS */
    lcd_nibble(valor);             /* parte alta   */
    lcd_nibble((uint8_t)(valor << 4));  /* parte baixa */
}
```
]

#observacao[
  Note o uso de `LATD` na leitura *e* na escrita da primeira função: preserva-se
  a parte baixa do latch enquanto se altera a parte alta. Ler `PORTD` ali
  reintroduziria exatamente o defeito de leitura-modificação-escrita do encontro
  2. A regra da aula anterior não é abstrata --- ela aparece na terceira linha de
  código do primeiro periférico externo do curso.
]

== A sequência de inicialização

O controlador inicia em modo de oito bits. Configurá-lo para quatro exige uma
sequência específica, executada às cegas: enviam-se meias palavras de comando
antes de o controlador estar no modo em que essas palavras fazem sentido.

#atencao[
  Essa sequência tem aparência de superstição --- valores repetidos, esperas
  arbitrárias --- e é frequentemente copiada sem compreensão. A lógica é a
  seguinte: o comando de configuração é reconhecido tanto em oito quanto em
  quatro bits; repeti-lo em modo de oito bits garante um estado conhecido,
  qualquer que fosse o estado inicial, e só então se comuta para quatro bits.
  Os atrasos iniciais existem porque o controlador tem sua própria
  inicialização interna, mais lenta que a do microcontrolador.
]

#codigo[
```c
void lcd_iniciar(void)
{
    __delay_ms(50);          /* espera a inicializacao interna do modulo */

    lcd_nibble(0x30); __delay_ms(5);
    lcd_nibble(0x30); __delay_us(150);
    lcd_nibble(0x30); __delay_us(150);
    lcd_nibble(0x20);        /* a partir daqui, modo de 4 bits */

    lcd_comando(0x28);       /* 4 bits, 2 linhas, matriz 5x8 */
    lcd_comando(0x0C);       /* display ligado, sem cursor   */
    lcd_comando(0x06);       /* avanco automatico do cursor  */
    lcd_comando(0x01);       /* limpar */
    __delay_ms(2);           /* limpar demora mais que os demais */
}
```
]

= O custo em tempo

#derivacao[
  A maioria dos comandos exige cerca de 37 µs. Escrever dezesseis caracteres
  numa linha custa
  $ 16 dot 37 "µs" approx 0,6 "ms" $
  Acrescentando o posicionamento de cursor de cada linha e considerando duas
  linhas, uma atualização completa de tela custa da ordem de 1,3 ms. O comando de
  limpeza, sozinho, exige aproximadamente 1,5 ms --- quarenta vezes mais que um
  comando comum.
]

#atencao[
  Compare com os números do curso: uma conversão do conversor analógico-digital
  custa 15 µs, e o tratador de interrupção do encontro 9 custa poucos
  microssegundos. *O display é, com folga, o periférico mais lento do sistema* ---
  duas ordens de grandeza acima de tudo o mais. Qualquer discussão sobre
  desempenho neste projeto passa por ele.
]

== Duas consequências de projeto

*Não limpar a tela a cada atualização.* Limpar e reescrever custa os 1,5 ms do
comando somados ao tempo de escrita, e produz tremulação visível: por um
instante a tela está em branco. A prática correta é reposicionar o cursor e
sobrescrever, mantendo o comprimento do texto constante e completando com
espaços quando o número encolhe --- caso contrário, restam dígitos antigos à
direita.

*Não atualizar mais rápido do que se consegue ler.* Atualizar a tela a cada ciclo
de 1 ms é desperdício puro: o olho não acompanha, e o custo é o mais alto do
sistema. Uma atualização a cada 200 ms a 500 ms é confortável e reduz o consumo
de tempo em duas ordens de grandeza.

#codigo[
```c
/* Escrever apenas quando o valor mudou. */
static int16_t exibido = INT16_MIN;

void atualizar_display(int16_t decimos)
{
    if (decimos == exibido) {
        return;                    /* nada a fazer: sai imediatamente */
    }
    exibido = decimos;

    lcd_posicao(0, 0);
    lcd_texto("T=");
    lcd_numero_fixo(decimos);      /* largura constante */
    lcd_texto(" C ");
}
```
]

#observacao[
  Essa técnica --- guardar o que já foi mostrado e escrever apenas a diferença
  --- é a versão elementar de uma ideia que reaparece em toda interface gráfica,
  de displays de duas linhas a navegadores. O princípio é o mesmo: *comparar com
  o estado exibido é sempre mais barato que redesenhar*.
]

= Transposição

Displays modernos são majoritariamente seriais, e a economia de pinos é
decisiva. Mudam a camada física e a velocidade; permanece intacta a separação
entre comando e dado, e permanece o fato de o display ser o periférico lento do
sistema.

#observacao[
  Em plataformas com mais memória, aparece uma diferença estrutural: o
  *quadro de memória*. Em vez de escrever caracteres diretamente no display, o
  programa desenha numa imagem em RAM e a transfere de uma vez, por acesso
  direto à memória, sem custo de processador. Isso exige memória que este
  dispositivo não tem --- um display gráfico modesto consome mais RAM do que os
  2 KB disponíveis --- e é uma das fronteiras concretas entre 8 e 32 bits.
]

= Exercícios

#exercicio("3.1")[
  Calcule quantos pinos são necessários para o display em oito bits e em quatro
  bits, incluindo as linhas de controle e considerando a linha de leitura ligada
  ao terra. Em seguida, verifique no contrato de pinos do laboratório se a versão
  de oito bits seria viável junto aos demais periféricos do projeto.
]

#exercicio("3.2")[
  Um estudante escreve `lcd_texto("Temp: 25.3 C")` e, em seguida,
  `lcd_texto("Temp: 9.1 C")`, sem limpar a tela. Descreva exatamente o que
  aparece no display e proponha duas correções, uma na função de escrita e outra
  na formatação do número.
]

#exercicio("3.3")[
  Estime o tempo total gasto com o display em um sistema que atualiza duas
  linhas completas a cada 100 ms, e expresse esse valor como percentual do tempo
  de processador. Repita para atualização a cada 500 ms e comente a diferença.
]

#exercicio("3.4")[
  Explique por que a função `lcd_nibble` apresentada lê `LATD` em vez de `PORTD`,
  e descreva concretamente o defeito que ocorreria com a leitura da porta caso
  os quatro pinos baixos estivessem ligados a uma carga capacitiva.
]

#exercicio("3.5")[
  A sequência de inicialização envia três vezes o mesmo valor antes de comutar o
  modo. Justifique tecnicamente essa repetição, considerando que o
  microcontrolador pode ser reiniciado sem que o display seja desenergizado ---
  e que, nesse caso, o controlador pode estar em qualquer um dos dois modos.
]
