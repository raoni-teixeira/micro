#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 2.8cm, right: 2.2cm),
  header: [
    #set text(size: 8pt, fill: luma(120))
    #grid(columns: (1fr, 1fr),
      align(left)[Microcontroladores], align(right)[Aula 10])
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
  #text(size: 19pt, weight: "bold", fill: azul)[Aula 10 --- Robustez e Persistência] \
  #v(0.2em)
  #text(size: 12pt)[Reinicialização, cão de guarda, baixo consumo e memória não volátil] \
  #v(0.4em)
  #text(size: 10pt, fill: luma(90))[Microcontroladores --- DENE/UFMT]
]

#v(1em)

#objetivos[
  - Enumerar as fontes de reinicialização do dispositivo e diagnosticar, em
    execução, qual delas ocorreu.
  - Explicar a função da proteção contra subtensão e por que ela é
    indispensável em sistemas alimentados pela rede.
  - Empregar corretamente o cão de guarda, reconhecendo o que ele protege e o
    que não protege.
  - Descrever os modos de baixo consumo e as fontes capazes de despertar o
    dispositivo.
  - Gravar e ler a memória não volátil interna, respeitando a sequência de
    desbloqueio, o tempo de escrita e o limite de ciclos.
]

= Por que esta aula existe

Um sistema embarcado opera sem operador, por meses, sujeito a interferência
elétrica, oscilações de alimentação e defeitos de software que não se
manifestaram em bancada. As duas perguntas desta aula são práticas: *como o
sistema se recupera quando algo dá errado* e *como ele preserva informação
quando é desligado*.

= Reinicialização

#definicao("reinicialização")[
  Evento que leva o dispositivo a um estado inicial conhecido --- registradores
  em valores padrão, contador de programa no endereço zero --- a partir do qual a
  execução recomeça.
]

#figure(
  table(
    columns: (1.3fr, 1.5fr, 1.5fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Fonte], cab[Quando ocorre], cab[Significado para o projeto]),
    [Energização], [Ao aplicar alimentação], [Início normal],
    [Subtensão], [Alimentação abaixo de um limiar configurável],
      [Rede instável, fonte subdimensionada ou carga pesada comutando],
    [Pino externo], [Sinal aplicado ao pino de reinicialização],
      [Botão de reset ou circuito supervisor],
    [Cão de guarda], [O programa deixou de alimentá-lo no prazo],
      [*O firmware travou*: é um diagnóstico, não um acidente],
    [Estouro da pilha], [Aninhamento de chamadas além da capacidade],
      [Recursão ou cadeia de chamadas profunda demais],
    [Instrução dedicada], [O próprio programa solicita], [Reinício controlado],
  ),
  caption: [Fontes de reinicialização.],
) <tab-resets>

#observacao[
  O dispositivo mantém indicadores que permitem descobrir, *em execução*, qual
  fonte causou o reinício. Lê-los logo no início do programa e registrá-los ---
  na memória não volátil ou na telemetria --- transforma "o equipamento reiniciou
  sozinho" em informação acionável. Sem esse registro, um sistema em campo que
  reinicia esporadicamente é praticamente indiagnosticável.
]

== Proteção contra subtensão

Abaixo de certa tensão, o dispositivo não deixa de funcionar de forma limpa: ele
funciona *mal*. A memória pode ser lida incorretamente, uma escrita na memória
não volátil pode ser interrompida no meio, e instruções podem ser decodificadas
de forma errada.

#atencao[
  A faixa perigosa não é "sem alimentação", é "alimentação insuficiente" --- e
  ela é atravessada em toda energização e em todo desligamento. A proteção contra
  subtensão mantém o dispositivo em reinicialização enquanto a tensão estiver
  abaixo do limiar, garantindo que ele só execute em condições válidas. Em
  qualquer sistema alimentado pela rede, ela deve estar habilitada.
]

= O cão de guarda

#definicao("cão de guarda")[
  Contador independente do núcleo, com oscilador próprio, que provoca uma
  reinicialização ao transbordar. O programa deve reiniciá-lo periodicamente ---
  "alimentá-lo" --- por meio de uma instrução dedicada. Se deixar de fazê-lo, o
  sistema é reiniciado.
]

A lógica é simples: um programa que executa normalmente passa pelo ponto de
alimentação com regularidade. Um programa travado, preso num laço inesperado ou
aguardando um sinal que nunca chega, não passa --- e o cão de guarda o
reinicia.

#atencao[
  *Onde alimentar é uma decisão de projeto, não de conveniência.* A alimentação
  deve ocorrer em *um único ponto*, no laço principal, depois de as tarefas
  essenciais terem sido executadas. Alimentá-lo dentro de um tratador de
  interrupção anula sua utilidade: as interrupções continuam ocorrendo mesmo com
  o laço principal travado, e o cão de guarda passa a atestar que o temporizador
  funciona --- o que ninguém questionava.
]

#codigo[
```c
for (;;) {
    if (!g_tique) {
        continue;
    }
    g_tique = 0;

    executar_tarefas();

    CLRWDT();      /* unico ponto de alimentacao, ao fim do ciclo */
}
```
]

#observacao[
  Vale ser claro sobre os limites. O cão de guarda *não* protege contra lógica
  errada que continue rodando, contra um controlador que aqueça a planta
  indefinidamente com o laço funcionando, nem contra corrupção de dados. Ele
  detecta uma classe específica de falha --- a parada de progresso --- e a trata
  com o remédio mais bruto disponível. É valioso e é modesto; anunciá-lo como
  garantia de confiabilidade é engano.
]

#atencao[
  Um sistema que reinicia periodicamente sem motivo aparente tem, quase sempre,
  o cão de guarda habilitado na palavra de configuração e nunca alimentado ---
  frequentemente porque o estudante copiou um bloco de configuração de outro
  projeto. É a hipótese a verificar antes de qualquer outra, e liga-se
  diretamente à tabela de bits de configuração do encontro 1.
]

= Modos de baixo consumo

A instrução de suspensão desliga o oscilador principal e para a execução. O
consumo cai de miliampères para microampères, e o dispositivo permanece assim
até que um evento o desperte.

#figure(
  table(
    columns: (1.4fr, 2fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Fonte de despertar], cab[Observação]),
    [Interrupções externas], [Resposta imediata a um evento em pino],
    [Mudança de estado em porta], [Útil para teclado],
    [Cão de guarda], [Despertar periódico, sem oscilador principal],
    [Comparador], [Opera sem clock; vide encontro 5],
    [Temporizador com cristal próprio], [Base de tempo mantida durante o repouso],
  ),
  caption: [Eventos capazes de despertar o dispositivo.],
)

#atencao[
  Ao despertar, a execução prossegue na instrução *seguinte* à de suspensão ---
  e, se a interrupção correspondente estiver habilitada, o tratador é executado
  antes. Programas escritos supondo que o despertar reinicia o dispositivo se
  comportam de maneira inesperada. Convém também lembrar que periféricos
  dependentes do oscilador principal --- conversor, modulação, comunicação serial
  --- param durante o repouso.
]

#observacao[
  O termostato do laboratório é alimentado pela rede e não se beneficia disso.
  A técnica é apresentada porque é o principal argumento comercial dos
  microcontroladores em produtos a bateria: um sensor que dorme 99,9% do tempo,
  desperta por temporizador, mede, transmite e volta a dormir opera anos com uma
  pilha. Todo o projeto de firmware desses produtos gira em torno de minimizar o
  tempo acordado.
]

= Memória não volátil interna

O dispositivo dispõe de 256 bytes de memória não volátil de dados, gravável pelo
próprio programa e preservada com o equipamento desligado --- o lugar natural
para o valor desejado de temperatura configurado pelo operador.

#figure(
  table(
    columns: (1.4fr, 1.8fr),
    fill: (col, row) => if row == 0 { azul } else if calc.odd(row) { cinza } else { white },
    stroke: 0.5pt + luma(200), inset: 6pt, align: left,
    table.header(cab[Característica], cab[Ordem de grandeza]),
    [Capacidade], [256 bytes],
    [Tempo de escrita de um byte], [Alguns milissegundos],
    [Tempo de leitura], [Um ciclo de instrução],
    [Ciclos de escrita suportados], [Centenas de milhares por posição],
    [Retenção de dados], [Décadas],
  ),
  caption: [Características da memória não volátil. Confirmar na folha de dados.],
) <tab-eeprom>

#atencao[
  A assimetria entre leitura e escrita é enorme --- da ordem de mil vezes --- e
  define como o recurso deve ser usado: *ler à vontade, escrever raramente*. Uma
  escrita bloqueante de alguns milissegundos no meio do laço principal tem o
  mesmo custo de uma atualização completa de display.
]

== A sequência de desbloqueio

A escrita não é uma atribuição: exige uma sequência específica de dois valores
gravados num registrador de controle, imediatamente antes do comando de escrita.

#observacao[
  A sequência existe para impedir escritas acidentais. Um programa desgovernado
  --- ou um transiente elétrico --- pode escrever num registrador por acaso; a
  chance de reproduzir exatamente dois valores específicos, na ordem certa e sem
  nada entre eles, é desprezível. É uma proteção contra a própria falha do
  firmware, coerente com o tema desta aula.
]

#atencao[
  A exigência de que *nada* ocorra entre os dois valores tem consequência
  direta: uma interrupção atendida no meio da sequência a invalida, e a escrita
  falha silenciosamente. As interrupções devem ser desabilitadas durante a
  sequência e reabilitadas em seguida --- uma seção crítica, no sentido exato do
  encontro 9.
]

== Desgaste

Cada posição suporta um número finito de escritas. Gravar o valor desejado a
cada ciclo do laço principal esgotaria a vida útil da posição em pouco tempo.

#codigo[
```c
/* Grava apenas quando o valor mudou e depois de estabilizado. */
static int16_t gravado = 0;
static uint16_t ms_desde_mudanca = 0;

void persistir(int16_t alvo)          /* chamada a cada 1 ms */
{
    if (alvo == gravado) {
        ms_desde_mudanca = 0;
        return;
    }

    if (++ms_desde_mudanca < 5000u) { /* espera 5 s de estabilidade */
        return;
    }

    eeprom_escrever_16(ENDERECO_ALVO, alvo);
    gravado = alvo;
    ms_desde_mudanca = 0;
}
```
]

#observacao[
  As duas proteções são cumulativas e vale nomeá-las: escrever apenas quando o
  valor *mudou*, e apenas depois de ele ter *permanecido estável* por algum
  tempo. A segunda evita gravar cada passo intermediário enquanto o operador
  percorre valores no teclado --- que, sem ela, produziria dezenas de escritas
  para uma única alteração real.
]

= Transposição

Duas diferenças relevantes nas plataformas de 32 bits. A primeira: a maioria
*não possui* memória não volátil de dados separada. A persistência é feita
reservando um setor da memória de programa e emulando o comportamento em
software --- o que envolve apagar blocos inteiros e distribuir o desgaste entre
posições, tarefa entregue a bibliotecas específicas. O recurso simples usado
aqui é, nesse aspecto, mais conveniente que o das plataformas modernas.

A segunda: costuma haver *dois* cães de guarda, um independente com oscilador
próprio e outro com janela de tempo, que exige a alimentação nem cedo nem tarde
demais --- capaz, portanto, de detectar também um programa que enlouqueceu e
passou a alimentá-lo rápido demais.

= Exercícios

#exercicio("10.1")[
  Um equipamento em campo reinicia algumas vezes por dia, sem padrão aparente.
  Descreva um procedimento de diagnóstico baseado nos indicadores de fonte de
  reinicialização, indicando o que cada resultado possível sugere como causa.
]

#exercicio("10.2")[
  Explique por que alimentar o cão de guarda dentro do tratador de interrupção
  do temporizador anula sua função. Em seguida, descreva uma falha real de
  firmware que essa configuração deixaria passar despercebida.
]

#exercicio("10.3")[
  Um sistema grava o valor desejado na memória não volátil a cada 100 ms.
  Supondo o limite de ciclos da tabela desta aula, calcule em quanto tempo a
  posição atingiria esse limite, e compare com a vida útil pretendida de um
  equipamento industrial.
]

#exercicio("10.4")[
  Justifique tecnicamente por que as interrupções devem ser desabilitadas
  durante a sequência de desbloqueio da escrita, e estime o impacto dessa seção
  crítica sobre a latência do sistema, considerando os tempos desta aula.
]

#exercicio("10.5")[
  Um colega propõe habilitar o cão de guarda com o menor período disponível,
  argumentando que "quanto mais rápido detectar o travamento, melhor". Analise a
  proposta apontando pelo menos dois riscos concretos, e proponha um critério
  objetivo para escolher o período.
]
