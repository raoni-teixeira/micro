// Aula 9 — Controle liga-desliga, histerese e comparação analógica
// Microcontroladores — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#import "figuras.typ": *
#show: conf.with(
  titulo: "Aula 9 — Controle liga-desliga, histerese e comparação analógica",
  subtitulo: "A regra mais simples possível, o que ela cobra, e como o silício a resolve",
)

#objetivos[
- Prever o comportamento de uma regra de comparação direta perto do alvo, e estimar a taxa de comutação resultante.
- Descrever a histerese como a introdução de memória na regra de decisão, e relacioná-la ao disparador Schmitt do encontro 4.
- Derivar o período do ciclo limite a partir das taxas de aquecimento e resfriamento, e converter em acionamentos por hora.
- Justificar um piso para a faixa de histerese a partir da resolução do conversor.
- Distinguir amplitude prevista de amplitude medida, e atribuir a diferença à inércia térmica.
- Descrever o módulo de comparadores do PIC18F4550 e a disputa de pinos que ativá-lo provoca.
- Calcular o degrau da referência programável e confrontá-lo com os 10 mV por grau do LM35.
- Dimensionar histerese por realimentação positiva a partir da largura desejada.
- Decidir entre comparador e conversor a partir de uma especificação, justificando com as grandezas certas.
]

= A regra mais simples do mundo

Existe uma chave capaz de aplicar três watts à planta e um sensor capaz de medir
meio grau. Falta a regra que liga um ao outro, e a primeira versão dela é óbvia:

```c
if (temperatura < alvo) {
    aquecedor = LIGADO;
} else {
    aquecedor = DESLIGADO;
}
```

Está correta. Funciona. E destrói o relé numa tarde.

#conceito[
*Por que.* Longe do alvo, a regra faz o esperado. Perto dele, a leitura fica na
fronteira, e a fronteira não é um lugar estável: o degrau do conversor vale
0,488 #sym.degree#h(0pt)C, e o ruído da medida é da ordem de um degrau.

A leitura passa a alternar entre dois códigos vizinhos, e a saída acompanha —
uma comutação por amostra. Amostrando a 10 Hz:

#align(center)[$10 "comutações/s" dot.c 3600 = 36#h(1pt)000$ acionamentos por hora]

Um relé de sinal suporta da ordem de 100#h(1pt)000 operações sob carga. A conta
fecha em *menos de três horas*.
]

#atencao[
Note o que *não* é o problema. Não é ruído demais, não é sensor ruim, não é
código errado. A regra faz exatamente o que foi pedido; o pedido é que estava
mal formulado.

Este é o modo de falha mais caro da engenharia: a especificação correta de um
comportamento indesejado.
]

= Histerese

A saída não pode depender só da entrada: precisa depender também de onde ela
estava. Dois limiares em vez de um.

#fig(
  fig_histerese(),
  [Com dois limiares, a mesma temperatura admite duas saídas. A regra deixa de
  ser uma função da entrada e passa a ser uma máquina de dois estados.],
)

#nota[
Isto já apareceu neste curso. O buffer de entrada do encontro 4 tem histerese
exatamente pelo mesmo motivo, e resolve exatamente o mesmo problema: um sinal
que atravessa devagar a região de decisão produziria uma rajada de transições.

Lá a solução está em silício e o projetista não escolhe a largura. Aqui ela está
em software e a largura é sua.

E há uma terceira camada, entre as duas, que esta aula vê mais adiante: o
comparador analógico, em que o hardware decide e a largura *também* é sua. Mesma
ideia, três vezes, com três graus de liberdade diferentes — e vale dizer isso à
turma em voz alta.
]

= O que a histerese cobra

#fig(
  fig_ciclo_limite(),
  [O ciclo limite. A temperatura nunca se estabiliza no alvo: ela circula em
  torno dele, e é assim que um controle liga-desliga funciona quando está
  funcionando bem.],
)

#conceito[
*O período do ciclo.* Com faixa total $2h$, taxa de aquecimento $a$ e taxa de
resfriamento $b$:

#align(center)[$T_"ciclo" = (2h) / a + (2h) / b$]

Com $h = 0,5$ #sym.degree#h(0pt)C, $a = 0,8$ #sym.degree#h(0pt)C/min e
$b = 0,4$ #sym.degree#h(0pt)C/min:

#align(center)[$T_"ciclo" = 1 slash 0,8 + 1 slash 0,4 = 1,25 + 2,5 = 3,75$ min]

#align(center)[$60 slash 3,75 = 16$ acionamentos por hora]

Contra 36#h(1pt)000 da regra sem histerese. Um fator de *2250*, obtido com dois
`if` em vez de um.
]

#kit[
As taxas $a$ e $b$ acima são estimativas. Os valores reais desta bancada saem da
resposta ao degrau do R10 — aquecedor a 100% a partir da temperatura ambiente — e
todo número desta seção deve ser refeito com eles.

O aquecedor é um resistor de cimento de 47 #sym.Omega dissipando cerca de 3 W, e
o resfriamento é passivo somado à ventoinha. Nada aqui é rápido.
]

#atencao[
A conta de vida útil muda de escala junto: 100#h(1pt)000 operações a 16 por hora
dão 6#h(1pt)250 horas, ou cerca de *oito meses de operação contínua*.

Nenhuma escolha de firmware compra tanto quanto essa. É por isso que o número de
acionamentos por hora é uma das duas grandezas que o R10 vai medir — ele tem
consequência física direta e mensurável em reais.
]

== Não dá para diminuir $h$ à vontade

#conceito[
A histerese precisa ser maior que a resolução da medida, ou ela não existe.

Com 1 LSB = 0,488 #sym.degree#h(0pt)C, uma faixa de $2h = 0,4$
#sym.degree#h(0pt)C cabe *dentro de um degrau*: os dois limiares caem no mesmo
código, e o comportamento volta a ser o da regra sem histerese.

O piso prático é uma faixa de cerca de 1 #sym.degree#h(0pt)C, que são dois
degraus. Abaixo disso é preciso melhorar a medição antes de melhorar o controle —
e as opções para isso são as do encontro 4: referência menor, amplificação, ou
sobreamostragem.
]

#nota[
Guarde a forma deste argumento, porque ela reaparece: *a qualidade do controle
está limitada pela qualidade da medida, e não pela sofisticação do algoritmo*.
No encontro 13 o mesmo meio grau elimina o termo derivativo.
]

== A amplitude medida é maior que a prevista

A figura já mostrou: o aquecedor comuta no cruzamento do limiar, mas a
temperatura não vira ali. A massa térmica ainda está quente e continua entregando
calor ao sensor por mais alguns instantes.

#conceito[
Amplitude real $= 2h +$ sobressinal $+$ subsinal.

O sobressinal não depende de $h$: depende da energia armazenada e do atraso entre
o aquecedor e o sensor. Diminuir $h$ pela metade *não* reduz a oscilação pela
metade — a partir de certo ponto, só aumenta o número de comutações sem melhorar
nada.

Existe portanto um $h$ abaixo do qual não vale a pena descer, e ele é
determinado pela planta, não pelo código.
]

== A planta é assimétrica

O aquecedor injeta energia; o resfriamento é passivo, somado à ventoinha. As
taxas $a$ e $b$ do exemplo diferem por um fator dois, e a razão cíclica do ciclo
limite reflete isso:

#align(center)[$1,25 slash 3,75 approx 33%$ do tempo com o aquecedor ligado]

#nota[
Essa assimetria não atrapalha o liga-desliga — ele não se importa. Ela vai
importar no encontro 13, quando um controlador proporcional único tiver de servir
aos dois sentidos com um ganho só.

Registrar a assimetria agora, com o número medido no R10, é o que torna aquela
discussão concreta.
]

= Tempo mínimo de estado

Histerese resolve o tremular causado pela medida. Não resolve tudo.

#conceito[
Se alguém encostar a mão no sensor, ou se a ventoinha soprar direto nele, a
temperatura pode atravessar a faixa inteira em segundos, e a comutação será
legítima — porém rápida demais para o atuador.

A proteção usual é um *tempo mínimo em cada estado*: uma vez comutado, o
aquecedor permanece assim por pelo menos $t_"min"$, independentemente do que a
medida disser.

Todo termostato de compressor tem isso, e nele o número é da ordem de três
minutos — ligar um compressor logo após desligá-lo o danifica, porque a pressão
ainda não equalizou.
]

= O código

```c
#define ALVO_D          400        /* 40,0 graus, em decimos           */
#define HISTERESE_D       5        /* 0,5 grau                         */
#define MIN_ESTADO_MS 30000u       /* 30 s no mesmo estado             */

static uint8_t  aquecendo  = 0;
static uint16_t desde      = 0;
volatile uint16_t comutacoes = 0;  /* a segunda medida do R10 */

void controlar(int16_t t_d)
{
    uint16_t agora = ms_ler();     /* encontro 7 */

    if ((uint16_t)(agora - desde) < MIN_ESTADO_MS) {
        return;                    /* ainda no tempo minimo */
    }

    if (aquecendo && t_d > (ALVO_D + HISTERESE_D)) {
        aquecendo = 0;
        desde = agora;
        comutacoes++;
    } else if (!aquecendo && t_d < (ALVO_D - HISTERESE_D)) {
        aquecendo = 1;
        desde = agora;
        comutacoes++;
    }

    AQUECEDOR = aquecendo;
}
```

#atencao[
A conta `(uint16_t)(agora - desde)` está escrita assim de propósito.

O contador de milissegundos é de dezesseis bits e dá a volta a cada 65,5
segundos. Se `agora` já deu a volta e `desde` não, a subtração *com sinal* daria
um número negativo enorme e o tempo mínimo nunca se cumpriria.

Em aritmética sem sinal a volta se cancela: a diferença sai correta desde que o
intervalo medido seja menor que o período de repetição. Trinta segundos contra
65,5 — cabe, com pouca folga.

Comparar `agora > desde + MIN` seria o mesmo erro escrito de outro jeito.
]

= O mesmo problema, resolvido em silício

O código da seção anterior custa uma conversão — 60 ciclos de máquina, medidos no
encontro 4 — mais a aritmética, mais a comparação, mais a máquina de estados. Tudo
isso para produzir *um bit*: ligar ou não ligar.

Existe um periférico que produz exatamente esse bit sem processador nenhum. Está
dentro do mesmo chip, desligado, desde a primeira aula.

#conceito[
*Um comparador é um conversor de um bit.* A frase não é analogia.

Um conversor #emph[flash] de $n$ bits é feito de $2^n - 1$ comparadores em
paralelo, cada um com seu limiar, todos decidindo ao mesmo tempo. E o conversor
por aproximações sucessivas do encontro 4 usa *um* comparador e um conversor
digital-analógico, aplicando o limiar dez vezes seguidas — a figura da busca
binária que vocês viram lá é a figura de um comparador sendo reutilizado.

O comparador é o tijolo elementar de toda conversão. O que muda entre as
arquiteturas é quantos existem e quantas vezes cada um decide.
]

A saída digital diz qual das duas entradas analógicas é maior, e a transição
acontece continuamente no tempo, sem comando de disparo. Três propriedades
separam isso da conversão:

#tab(
  columns: (auto, 1fr),
  [Propriedade], [Consequência],
  [Custo de processador nulo], [Opera em hardware analógico, continuamente. O processador pode estar executando outra coisa — ou dormindo],
  [Latência de centenas de ns], [Contra dezenas de µs da conversão somada ao software que a rodeia],
  [Funciona sem clock], [Continua operando com o processador parado, e a mudança de estado pode ser o evento que o desperta],
)

#margem[Sessenta ciclos contra zero. É a única vez no curso em que a comparação dá esse número.]

== O módulo do PIC18F4550

São *dois* comparadores, C1 e C2, com interligação selecionável aos pinos. Toda a
configuração está em `CMCON`.

#fig(
  fig_campos((
    ("C2OUT", "0"), ("C1OUT", "0"),
    ("C2INV", "0"), ("C1INV", "0"),
    ("CIS", "0"), ("CM<2:0>", "111"),
  ), w: 0.72cm, fonte_rotulo: 6.6pt),
  [`CMCON` no estado em que o firmware do laboratório o deixa: `CM<2:0>` = `111`,
  módulo desligado. `C1OUT` e `C2OUT` são somente leitura — são as saídas dos
  comparadores, não configuração.],
)

#kit[
A linha `CMCON = 0x07` da inicialização do firmware de referência é exatamente o
modo desligado, e está lá por segurança: com o módulo ativo, RA0 a RA3 deixam de
responder como entrada e saída digital.

*Ativar os comparadores exige remover essa linha*, e quem remove precisa saber que
está fazendo isso. É o mesmo feitio do `ADCON1` do encontro 4: o pino tem mais de
um caminho de entrada, e alguém escolheu o outro.
]

Cada pino usado pelo comparador é um pino subtraído do conversor ou da porta
digital:

#tab(
  columns: (auto, 1fr, 1fr),
  [Pino], [Função no módulo], [Disputa com],
  [RA0], [Entrada inversora de C1], [AN0],
  [RA1], [Entrada inversora de C2], [AN1],
  [RA2], [Não inversora de C2; saída de `CVREF`], [AN2, referência negativa],
  [RA3], [Não inversora de C1], [AN3, referência positiva],
  [RA4], [`C1OUT`, nos modos com saída], [Entrada de clock do Timer0],
  [RA5], [`C2OUT`, nos modos com saída], [AN4],
)

#atencao[
Repare em RA3: ele é a entrada não inversora de C1 *e* a entrada de referência
positiva do conversor. Usar referência externa para ganhar resolução no ADC — a
alternativa discutida no encontro 4 — e usar C1 ao mesmo tempo são coisas
mutuamente exclusivas neste chip.

O módulo também tem interrupção própria, por `CMIF`, e ela dispara *a cada
mudança* de saída, na subida e na descida. Vale a regra do encontro 7: o tratador
não sabe em que estado está só por ter sido chamado, e a leitura de `CMCON` faz
parte da condição para baixar o sinalizador. Limpar `CMIF` sem ter lido o
registrador leva à ressinalização imediata, e o sintoma se parece com travamento.
]

== A referência programável, e a conta que não fecha

Comparar contra uma tensão externa exigiria divisor, potenciômetro ou referência
de precisão. O chip evita isso com `CVREF`, gerada por uma escada de dezesseis
degraus e controlada por `CVRCON`.

#fig(
  fig_campos((
    ("CVREN", "1"), ("CVROE", "0"), ("CVRR", "1"), ("CVRSS", "0"),
    ("CVR<3:0>", "0010"),
  ), w: 0.72cm, fonte_rotulo: 6.6pt),
  [`CVRCON` com a referência habilitada, faixa baixa, escada alimentada pela fonte
  interna, degrau 2. `CVROE` leva a referência ao pino RA2, o que permite medir
  com o osciloscópio o valor que se programou.],
)

Sendo $V_"src"$ a tensão selecionada por `CVRSS` e $k$ o valor de `CVR<3:0>`:

$ "faixa baixa" quad ("CVRR" = 1): quad V_"CVREF" = k/24 dot.c V_"src" $

$ "faixa alta" quad ("CVRR" = 0): quad V_"CVREF" = V_"src"/4 + k/32 dot.c V_"src" $

Com os 5 V da alimentação, a faixa baixa vai de 0 a 3,125 V em degraus de 208 mV;
a faixa alta vai de 1,25 V a 3,59 V em degraus de 156 mV.

#conceito[
*Agora a conta que decide a seção.* O LM35 entrega 10 mV por grau, então um degrau
de 208 mV vale *20,8 #sym.degree#h(0pt)C*. Os limiares que a faixa baixa consegue
expressar são estes:

#tab(
  columns: (auto, auto, auto, auto, auto),
  [`CVR<3:0>`], [0], [1], [2], [3],
  [Tensão], [0 V], [208 mV], [417 mV], [625 mV],
  [Temperatura], [0 #sym.degree#h(0pt)C], [20,8 #sym.degree#h(0pt)C], [41,7 #sym.degree#h(0pt)C], [62,5 #sym.degree#h(0pt)C],
)

Não é que 40 #sym.degree#h(0pt)C seja inatingível — o degrau 2 cai a 41,7, a menos
de dois graus. O problema é outro: *você não escolhe*. Um alvo de 35 ou de 50
#sym.degree#h(0pt)C não existe nesta escada. O passo do ajuste é de vinte graus.

A faixa alta é pior, e de um jeito que vale enunciar: ela *começa* em 1,25 V, ou
125 #sym.degree#h(0pt)C de LM35. É inteiramente inútil para este sensor.
]

#atencao[
Esta é uma limitação real do dispositivo, e não um detalhe de configuração.
Qualquer material que apresente o comparador como substituto direto do conversor
num termostato com LM35 está omitindo esta conta.
]

Há três saídas. Baixar a fonte da escada com `CVRSS` = 1 e alimentá-la com 1 V dá
degraus de 42 mV, ou pouco mais de 4 #sym.degree#h(0pt)C — melhora uma ordem de
grandeza, ainda não serve para controle fino, e consome RA3, que é a entrada de
C1. Amplificar o sensor por 5 divide o degrau por cinco, ao custo de um
amplificador externo e da precisão dele. Ou então:

#conceito[
*Usar o comparador para aquilo em que ele é insubstituível.* Um limiar de
segurança de sobretemperatura não precisa de precisão de um grau: precisa de
atuação rápida, independente de software e operante com o processador parado. Aqui
os 208 mV de degrau deixam de ser um problema.

É esta a saída que orienta o projeto do semestre. O conversor continua responsável
pela *medição* — o valor que vai ao display, à telemetria e à malha de controle. O
comparador assume a *proteção*: um limiar superior que corta o aquecedor por
caminho independente, mesmo com o firmware travado.

Não são alternativas concorrentes. São camadas com funções distintas, e é assim
que aparecem em equipamento real.
]

== Histerese em silício

Os comparadores do PIC18F4550 *não têm histerese programável*. Famílias mais
recentes trazem um bit para isso; esta não traz. Ela precisa ser construída.

O caminho clássico realimenta a saída para a entrada não inversora por um
resistor, formando com o resistor da referência um divisor cujo resultado depende
do estado da saída. Seja $V_"ref"$ ligada por $R_1$ e a saída realimentada por
$R_2$; a tensão no nó é a superposição das duas fontes:

$ V_+ = (V_"ref" dot.c R_2 + V_o dot.c R_1)/(R_1 + R_2) $

Com a saída baixa, $V_o = 0$, o limiar é $V_"TL" = (V_"ref" dot.c R_2) slash (R_1 + R_2)$;
com a saída alta, $V_o = V_"DD"$, ele sobe. A largura é a diferença:

$ Delta V = V_"TH" - V_"TL" = V_"DD" dot.c R_1/(R_1 + R_2) $

#conceito[
*A largura não depende da referência.* Só da razão entre os resistores e da
excursão da saída. É uma boa notícia de projeto: mover o limiar não mexe na
histerese — exatamente o contrário do que acontece na versão em software, onde
$h$ e o alvo são a mesma conta.

Para 2 #sym.degree#h(0pt)C com o LM35 são 20 mV. Com $V_"DD"$ = 5 V:

$ R_1/(R_1 + R_2) = 20 "mV" slash 5 "V" = 0,004 quad => quad R_2 approx 249 dot.c R_1 $

Com $R_1$ = 1 k#sym.Omega e o valor comercial $R_2$ = 240 k#sym.Omega, resulta
$Delta V$ = 20,7 mV, ou 2,1 #sym.degree#h(0pt)C.

Repare na ordem de grandeza: histereses estreitas exigem realimentação fraca, e
resistores muito desiguais. É a fonte de erro mais comum neste circuito.
]

Existe ainda uma alternativa puramente digital: quando a saída comuta, o tratador
de interrupção reprograma `CVR<3:0>` para o degrau vizinho, deslocando o limiar
contra novas comutações.

```c
/* Histerese por deslocamento da referencia programavel.
   A leitura de CMCON e obrigatoria antes de baixar o sinalizador. */
void tratar_comparador(void)
{
    uint8_t estado = CMCON;           /* leitura obrigatoria */

    if (estado & 0x40) {              /* C1OUT em nivel alto */
        CVRCON = (CVRCON & 0xF0) | DEGRAU_BAIXO;
    } else {
        CVRCON = (CVRCON & 0xF0) | DEGRAU_ALTO;
    }

    PIR2bits.CMIF = 0;
}
```

#divergencia[
O custo é reintroduzir o software na malha, e ele é alto o bastante para observar.

A largura passa a ser um degrau inteiro da escada — os mesmos 20,8
#sym.degree#h(0pt)C — largo demais para qualquer termostato útil. E a resposta
volta a depender da latência de interrupção, que é justamente a propriedade que
motivou usar o comparador.

Vale conhecer a técnica pelo que ela revela, não para usar aqui: as duas vantagens
do comparador foram devolvidas, uma de cada vez, por uma solução que parecia
elegante.
]

== O conversor mede, o comparador vigia

#tab(
  columns: (1fr, 1fr, 1fr),
  [Aspecto], [Comparador], [Conversor],
  [Informação produzida], [Um bit], [Palavra de dez bits],
  [Custo de processador], [Nenhum], [60 ciclos, mais o software],
  [Latência], [Centenas de ns], [Dezenas de µs],
  [Precisão do limiar], [Degraus de 20,8 #sym.degree#h(0pt)C], [Degraus de 0,49 #sym.degree#h(0pt)C],
  [Limiar ajustável por software], [Em degraus grosseiros], [Em qualquer valor],
  [Opera com o processador parado], [Sim], [Não],
  [Serve para display e telemetria], [Não], [Sim],
  [Permite filtragem e média], [Não], [Sim],
)

A regra prática sai da tabela: *o conversor mede, o comparador vigia.* Sempre que
for preciso saber o valor — para mostrar, transmitir, filtrar ou usar num
algoritmo de controle — a conversão é necessária. Sempre que bastar saber que um
limite foi ultrapassado, e sobretudo quando isso precisar acontecer rápido, com
baixo consumo ou independentemente do software, a comparação é a resposta.

#nota[
É por isso que o termostato deste curso usa o conversor: ele precisa do valor na
tela e na telemetria, e precisa de um alvo ajustável em qualquer temperatura. O
comparador entraria *por cima*, como limiar fixo de sobretemperatura — e num
produto real entraria.

Em várias famílias ARM Cortex-M essa camada fica ainda mais limpa: a saída do
comparador pode ser ligada internamente à entrada de desligamento de emergência do
temporizador que gera o PWM do encontro 6. Ao ultrapassar o limiar, o acionamento
é cortado *em hardware*, em nanossegundos, sem executar uma instrução — e a
proteção continua válida com o firmware travado. É bom tema de seminário.
]

= As duas medidas do R10

#conceito[
O roteiro não vai apenas fazer o termostato funcionar. Ele vai *medir* duas
grandezas, e as duas viram argumento no encontro 13.

*Amplitude de oscilação em torno do alvo.* Quanto a temperatura de fato varia,
em graus. É o que o usuário sente, e é maior que $2h$.

*Acionamentos por hora.* Quantas vezes o relé comuta. É o que a manutenção paga,
e converte diretamente em meses de vida útil.

Melhorar uma dessas grandezas piora a outra. É o primeiro compromisso genuíno de
controle do curso, e o aluno chega ao encontro 13 querendo resolver algo que ele
mediu — não algo que lhe foi afirmado.
]

= Previsão para o R10

#previsao[
*P1.* Com o aquecedor a 100% a partir da temperatura ambiente, qual taxa de
aquecimento você espera, em graus por minuto? Use os 3 W e um palpite de massa
térmica, e diga qual foi o palpite.

*P2.* Com $h = 0,5$ #sym.degree#h(0pt)C e as suas taxas, quantos acionamentos por
hora prevê? Escreva o número antes de rodar.

*P3.* A amplitude medida vai ser maior, igual ou menor que 1
#sym.degree#h(0pt)C? Justifique.

*P4.* Se você reduzir $h$ para 0,2 #sym.degree#h(0pt)C, o que espera que aconteça
com cada uma das duas medidas? Cuidado: há um efeito que a conta simples não
prevê.

*P5.* Desligue a ventoinha e repita. Qual das duas taxas muda, e o que isso faz
com a razão cíclica do ciclo limite?

*P6.* O comparador C1 vai vigiar o LM35 contra `CVREF`, na faixa baixa e com a
escada alimentada pelos 5 V. Qual é o degrau da referência, em milivolts e em
graus? Qual limiar de sobretemperatura você programaria, e o que acontece com o
corte do aquecedor se o firmware travar?
]

#semnota[
Leve esta folha preenchida. Este é o primeiro roteiro em que a medida leva mais
tempo que a montagem — organize-se para deixar o sistema rodando enquanto
escreve.
]

= Exercícios

#tarefa[
*Exercício 9.1.* Um termostato usa comparação direta, sem histerese, e amostra a
4 Hz.

(a) Estime os acionamentos por hora no pior caso.

(b) Quanto dura um relé de 100#h(1pt)000 operações?

(c) O problema desapareceria se a amostragem fosse feita a 0,5 Hz? Justifique.
]

#resposta[
(a) Uma comutação por amostra: $4 dot.c 3600 = 14#h(1pt)400$ por hora.

(b) $100#h(1pt)000 slash 14#h(1pt)400 approx 7$ horas.

(c) Não desapareceria: cairia para 1#h(1pt)800 por hora, ou 55 horas de vida.
Amostrar devagar *reduz* o sintoma sem tocar na causa, e paga por isso com um
controle que demora até dois segundos para reagir. A causa é a ausência de
memória na regra de decisão.

#docente[
A alínea (c) é a que interessa. Reduzir a taxa de amostragem é a primeira ideia
de quase todo mundo, e ela é uma troca ruim disfarçada de solução.
]
]

#tarefa[
*Exercício 9.2.* Um colega ajusta $h = 0,2$ #sym.degree#h(0pt)C esperando reduzir
a oscilação pela metade.

(a) O que acontece com o número de acionamentos por hora?

(b) O que acontece com a amplitude medida?

(c) Qual é o piso de $h$ imposto pelo conversor, e por quê?
]

#resposta[
(a) Dobra: o período do ciclo é proporcional a $2h$, então metade da faixa dá o
dobro das comutações.

(b) Quase não muda. A amplitude é $2h$ mais o sobressinal, e o sobressinal não
depende de $h$ — depende da inércia térmica e do atraso entre aquecedor e sensor.
Se o sobressinal for de 1 #sym.degree#h(0pt)C, reduzir a faixa de 1,0 para 0,4
leva a amplitude de 2,0 para 1,4, e não de 2,0 para 0,8.

(c) O piso é uma faixa da ordem de 1 LSB, ou 0,488 #sym.degree#h(0pt)C. Com
$2h = 0,4$, os dois limiares caem dentro do mesmo código do conversor: para o
programa, os dois limiares são o mesmo número, e a histerese deixa de existir.

#docente[
Ótimo lugar para insistir na diferença entre o modelo e a planta. A alínea (a)
sai do modelo; a (b) só sai de olhar a bancada. Quem responder (b) "cai pela
metade" está aplicando a fórmula onde ela não vale.
]
]

#tarefa[
*Exercício 9.3.* Explique por que a linha
`if ((uint16_t)(agora - desde) < MIN_ESTADO_MS)` está escrita com subtração e
conversão sem sinal, em vez de `if (agora < desde + MIN_ESTADO_MS)`.
]

#resposta[
Porque o contador de milissegundos dá a volta a cada 65#h(1pt)536 ms. Na segunda
forma, se `desde + MIN_ESTADO_MS` estourar dezesseis bits, o resultado é um
número pequeno, e a comparação passa a ser verdadeira quando deveria ser falsa —
ou o contrário, dependendo de onde a volta caiu.

Na primeira forma, a subtração sem sinal produz o intervalo decorrido
corretamente mesmo quando `agora` já deu a volta e `desde` não, porque a
aritmética modular cancela a volta. A condição é válida enquanto o intervalo
medido for menor que o período de repetição — 30 s contra 65,5 s.

#docente[
Vale demonstrar com números: `desde` = 60#h(1pt)000, `agora` = 2#h(1pt)000. A
diferença sem sinal dá 7#h(1pt)536 ms, que é o intervalo real. A soma dá
90#h(1pt)000, que não cabe.
]
]

#tarefa[
*Exercício 9.4.* O termostato precisa segurar 40 #sym.degree#h(0pt)C. Discuta se
cada mudança abaixo melhora ou piora *cada uma* das duas medidas do R10.

(a) Aumentar $h$ de 0,5 para 1,0 #sym.degree#h(0pt)C.

(b) Ligar a ventoinha permanentemente.

(c) Aproximar fisicamente o sensor do aquecedor.
]

#resposta[
(a) Acionamentos por hora: melhora, caem pela metade. Amplitude: piora, sobe cerca
de 1 #sym.degree#h(0pt)C. É o compromisso central da aula.

(b) Aumenta a taxa de resfriamento $b$. O período do ciclo encurta, então os
acionamentos por hora *aumentam*. A amplitude quase não muda. Além disso, o
aquecedor passa a trabalhar mais tempo para segurar o mesmo alvo — pior nas duas
contas que importam, e ainda gasta mais energia.

(c) Reduz o atraso de transporte, portanto reduz o sobressinal. *Melhora a
amplitude sem piorar os acionamentos.* É a única das três que melhora uma medida
de graça — e é uma mudança de montagem, não de código.

#docente[
A alínea (c) é o fecho da aula. Depois de duas horas discutindo algoritmo, a
melhoria mais barata veio de mover um sensor três centímetros. Vale deixar isso
no ar.
]
]

#nota[
*No encontro 10:* comunicação serial. As duas medidas desta aula têm um problema
prático — para contar acionamentos por hora é preciso observar por uma hora, e
para medir a amplitude é preciso registrar o valor ao longo do tempo.

O display mostra o instante; ele não guarda a história. A telemetria existe
exatamente para isso, e é ela que vai produzir os dados que o encontro 13 usa.
]

#tarefa[
*Exercício 9.5.* Um colega quer um termostato com ajuste de 30 a 60
#sym.degree#h(0pt)C em passos de 1 #sym.degree#h(0pt)C, e propõe usar o comparador
com `CVREF` para não gastar processador.

(a) Quantos valores distintos de limiar a faixa baixa oferece nessa janela?

(b) A proposta é viável? Se não, diga o que você usaria e por quê.
]

#resposta[
(a) Dois: o degrau 2, a 41,7 #sym.degree#h(0pt)C, e o degrau 3, a 62,5
#sym.degree#h(0pt)C — e o segundo já está fora da janela pedida. Na prática, *um*.

(b) Não é viável. O requisito é de passo de 1 #sym.degree#h(0pt)C e a escada tem
passo de 20,8. A especificação pede o conversor, cujo degrau é de 0,49
#sym.degree#h(0pt)C — mais de quarenta vezes mais fino que o necessário.

O comparador pode entrar em cima disso como camada de proteção, com um limiar fixo
de sobretemperatura no degrau 3. Aí a granularidade não incomoda, porque ninguém
precisa ajustar esse limite com precisão.
]

#tarefa[
*Exercício 9.6.* Você dimensionou histerese por realimentação positiva com
$R_1$ = 1 k#sym.Omega e $R_2$ = 240 k#sym.Omega, obtendo 2,1 #sym.degree#h(0pt)C.
Ao montar, trocou $R_2$ por 24 k#sym.Omega sem perceber.

(a) Qual passa a ser a largura da histerese, em graus?

(b) Que sintoma o termostato apresenta na bancada, e por que ele é difícil de
perceber?
]

#resposta[
(a) $Delta V$ = 5 V #sym.times 1/25 = 200 mV, ou *20 #sym.degree#h(0pt)C* — dez
vezes a largura pretendida.

(b) O aquecedor liga e desliga muito raramente, com excursão enorme: aquece até
vinte graus acima do ponto de desliga e só volta a ligar vinte graus abaixo.

É difícil de perceber porque o controle *parece* saudável — não oscila rápido, não
trepida, não castiga o relé. Todos os sintomas que a aula ensinou a procurar
apontam para o lado oposto. Só medir a temperatura ao longo do tempo revela o
erro, e ele é de um dígito num valor comercial.
]
