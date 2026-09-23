// Aula 8 — Estágio de potência, atuadores e fontes de reset
// Microcontroladores — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#import "figuras.typ": *
#show: conf.with(
  titulo: "Aula 8 — Estágio de potência e fontes de reset",
  subtitulo: "Por que ele reiniciou",
)

#objetivos[
- Comparar a capacidade de corrente de um pino com a exigida pelos atuadores do projeto, e concluir que nenhum deles pode ser acionado diretamente.
- Escolher entre relé, transistor bipolar e MOSFET a partir de isolação, queda em condução, velocidade e vida útil.
- Desenhar o acionamento em lado baixo com canal N, justificando a posição da carga, do diodo de retorno e do resistor de descida.
- Estimar a tensão gerada pela abertura de uma carga indutiva e explicar por que ela destrói a chave e reinicia o processador.
- Diagnosticar a causa de um reset a partir de `RCON`, e distinguir as cinco origens possíveis.
]

= Nenhum pino aciona nada

Até aqui todo pino moveu LEDs e um display, que consomem miliampères. Os
atuadores do termostato não.

#tab(
  columns: (auto, auto, auto, 1fr),
  [], [Tensão], [Corrente], [Contra o pino],
  [Pino do PIC18F4550], [5 V], [25 mA (máximo absoluto)], [—],
  [Aquecedor — 47 #sym.Omega], [12 V], [255 mA], [10#sym.times a corrente, e a tensão errada],
  [Ventoinha], [12 V], [ordem de 150 mA], [6#sym.times a corrente],
  [Bobina de relé], [12 V], [ordem de 70 mA], [3#sym.times a corrente],
)

#conceito[
Note que *até o relé* precisa de uma chave para ser acionado. Ele é uma chave
comandada por uma bobina, e a bobina já excede o pino.

Isso desmonta uma ideia comum: "uso um relé para não precisar de transistor". O
relé não substitui o transistor; ele se soma a ele. O que o relé traz de
próprio é isolação galvânica.
]

#atencao[
Os 25 mA são o *máximo absoluto* de um pino, e há um segundo limite que costuma
passar despercebido: a corrente total que entra por VDD e sai por VSS, da ordem
de 200 mA. Oito LEDs a 20 mA já consomem 160 deles.

Máximo absoluto não é ponto de operação. É o valor além do qual o fabricante não
promete nada — nem o funcionamento, nem a vida útil.
]

= Três chaves

#tab(
  columns: (auto, 1fr, 1fr, 1fr),
  [], [Relé], [MOSFET canal N], [Bipolar NPN],
  [Isolação], [*Sim*, galvânica], [Não], [Não],
  [Comando], [Corrente de bobina], [Tensão de porta, quase sem corrente], [Corrente de base],
  [Queda em condução], [Alguns mV], [$I dot.c R_"DS(on)"$], [0,2 a 0,5 V],
  [Velocidade], [ordem de 10 ms], [ordem de µs], [ordem de µs],
  [Aceita PWM], [*Não*], [Sim], [Sim],
  [Vida útil], [Finita — contato mecânico], [Ilimitada], [Ilimitada],
  [Boa para], [Carga em rede elétrica, isolação exigida], [Corrente alta, comutação rápida], [Corrente baixa, incluindo a bobina do relé],
)

#conceito[
*Por que comutar, e não regular.* Um transistor operando na região linear
entregaria os mesmos 255 mA ao aquecedor dissipando a diferença de tensão. Para
metade da potência, ele largaria 6 V:

#align(center)[$P = 6 "V" dot.c 255 "mA" = 1,53$ W]

Um MOSFET comutando, com $R_"DS(on)"$ da ordem de 22 m#sym.Omega, dissipa:

#align(center)[$P = I^2 R = (0,255)^2 dot.c 0,022 = 1,4$ mW]

Mil vezes menos. Esta é a razão de o mundo inteiro comutar em vez de regular, e é
o que dá sentido ao PWM do encontro 6: a razão cíclica não é uma conveniência de
software, é o que permite controlar potência sem dissipá-la.
]

= O acionamento em lado baixo

#fig(
  fig_estagio(),
  [O arranjo que o R8 usa. A carga fica acima da chave, e o terra é comum ao
  microcontrolador — é isso que permite comandar 12 V com um sinal de 5 V.],
)

#conceito[
*Por que a carga fica em cima.* O que liga o MOSFET é a tensão entre porta e
fonte, $V_"GS"$. Com a fonte no terra, $V_"GS"$ é simplesmente a tensão do pino:
5 V, e acabou.

Se a carga ficasse *abaixo* da chave — acionamento em lado alto —, a fonte
flutuaria junto com a carga, e para manter $V_"GS"$ seria preciso um potencial
acima dos 12 V da alimentação. Existem circuitos para isso, e nenhum deles é
gratuito.

Lado baixo é a escolha padrão quando o terra pode ser comum. O preço é que a
carga fica permanentemente ligada aos 12 V: ela nunca está eletricamente
isolada, apenas sem caminho de retorno.
]

#nota[
*O resistor de descida não é decoração.* Entre o reset e a primeira escrita em
`TRIS`, o pino está em alta impedância — o encontro 4 mostrou o que existe atrás
dele. A porta do MOSFET é capacitiva e não tem para onde escoar carga; sem o
resistor, ela flutua e pode ligar o aquecedor sozinha.

É o mesmo argumento do "LAT antes de TRIS" do encontro 2, agora com uma carga de
três watts na outra ponta.
]

== O chute indutivo

Bobina de relé e motor de ventoinha são cargas indutivas, e indutor não aceita
que a corrente mude instantaneamente.

#conceito[
#align(center)[$v = L (d i) / (d t)$]

Uma bobina de 50 mH conduzindo 70 mA, interrompida em 1 µs:

#align(center)[$v = 0,05 dot.c (0,07 slash 10^(-6)) = 3500$ V]

Não é erro de conta. A energia armazenada no campo magnético precisa ir para
algum lugar, e se não houver caminho ela sai como uma tensão altíssima sobre o
que abriu o circuito.
]

O diodo de retorno é esse caminho. Ligado em antiparalelo com a carga — catodo
para a alimentação, anodo para o dreno —, ele fica reversamente polarizado
enquanto a chave conduz e passa a conduzir no instante em que ela abre,
recirculando a corrente até que ela se extinga.

#atencao[
Sem o diodo, três coisas acontecem, e nesta ordem de gravidade:

O MOSFET recebe 3500 V entre dreno e fonte e perfura — falha permanente, em
geral em curto, o que deixa o aquecedor ligado para sempre.

O pulso se propaga pela alimentação e derruba VDD abaixo do limiar de detecção de
subtensão. *O processador reinicia*, e é aqui que esta aula muda de assunto.

Se a carga for um relé comandando outra coisa, o arco no contato queima a
superfície e reduz a vida útil de centenas de milhares de operações para
algumas milhares.
]

#nota[
O diodo tem um custo: ele prolonga a corrente na bobina, e o relé demora mais
para abrir. Onde esse atraso importa, usa-se um diodo Zener ou um resistor em
série com ele — a corrente cai mais rápido, ao preço de uma tensão maior, que
ainda assim fica dentro do que a chave suporta.

Não existe escolha sem contrapartida. Existe escolha com contrapartida conhecida.
]

= Por que ele reiniciou

O aluno que chega na bancada com o aquecedor ligado descobre, mais cedo ou mais
tarde, que o programa recomeçou sozinho. A pergunta parece imponderável e não é:
o processador *sabe* por que reiniciou, e guarda a resposta.

#tab(
  columns: (auto, 1fr, 1fr),
  [Origem], [O que aconteceu], [Causa provável neste projeto],
  [Energização], [VDD subiu de zero], [Você acabou de ligar a placa],
  [Subtensão], [VDD caiu abaixo do limiar com a placa ligada], [Partida do aquecedor, chute do relé, fonte fraca],
  [`MCLR`], [O pino de reset foi para nível baixo], [Botão, ou ruído acoplado no fio],
  [Watchdog], [O programa parou de alimentar o cão de guarda], [Laço travado, espera que nunca termina],
  [Pilha], [Estouro ou esvaziamento da pilha de retorno], [Recursão, ou `RETFIE` a mais no tratamento],
)

#fig(
  fig_campos((
    ("IPEN", "1"),
    ("SBOR", "0"),
    ("—", "-"),
    ("/RI", "1"),
    ("/TO", "1"),
    ("/PD", "1"),
    ("/POR", "0"),
    ("/BOR", "0"),
  ), w: 0.8cm, fonte_rotulo: 6.6pt),
  [`RCON` logo após uma energização. Os indicadores são *ativos em nível baixo* e
  *não se limpam sozinhos*: quem os coloca de volta em 1 é o seu programa.],
)

#conceito[
A leitura de `RCON` só serve se for feita *antes* de qualquer outra coisa, e se
os bits forem devolvidos a 1 em seguida. Um bit que ninguém reergueu fica em 0
para sempre, e a partir daí todo reset parece ser o primeiro.

Este é um caso raro em que o registrador precisa ser escrito para continuar
informando. Ele não é um sensor: é um bloco de notas que só você apaga.
]

```c
uint8_t causa_reset;               /* guardado para exibir depois */

void main(void)
{
    causa_reset = RCON;            /* antes de tudo */

    RCONbits.NOT_POR = 1;          /* reergue os indicadores para a proxima vez */
    RCONbits.NOT_BOR = 1;
    RCONbits.NOT_RI  = 1;
    RCONbits.NOT_TO  = 1;

    configurar();
    lcd_mostrar_causa(causa_reset);   /* dois segundos na tela, e segue */

    for (;;) {
        ...
        CLRWDT();                  /* so aqui: no laco principal */
    }
}
```

#atencao[
*Nunca alimente o cão de guarda dentro de um tratamento de interrupção.*

Parece conveniente — o tratamento roda periodicamente, então o `CLRWDT` sairia de
graça. Mas o watchdog existe para detectar que o *programa principal* travou, e um
tratamento de temporizador continua rodando alegremente com o laço principal
parado num `while` que nunca termina.

Alimentar o cão na interrupção transforma o watchdog num enfeite que garante
apenas que as interrupções ainda funcionam — que é justamente a parte que
raramente trava.
]

= Previsão para o R8

#previsao[
*P1.* Antes de ligar o aquecedor, meça a resistência dele. Que corrente espera em
12 V? Que potência?

*P2.* Com o osciloscópio no dreno do MOSFET e o diodo de retorno *no lugar*,
desenhe a forma de onda que espera ver no instante do desligamento.

*P3.* Repita a previsão para o caso sem o diodo. Qual é a tensão de pico que você
espera, e o que espera que aconteça com o processador?

*P4.* Ligue o aquecedor em degrau e observe o display. Se o programa reiniciar,
qual bit de `RCON` você espera encontrar em zero?

*P5.* Qual é a temperatura da carcaça do MOSFET depois de cinco minutos com o
aquecedor a 100%? Justifique o número a partir da conta de dissipação.
]

#semnota[
Leve esta folha preenchida. A P3 é de previsão apenas — *não* vamos remover o
diodo na bancada.
]

= Exercícios

#tarefa[
*Exercício 8.1.* Um colega aciona a ventoinha ligando-a diretamente entre um pino
e o terra. Ela gira devagar e o microcontrolador esquenta.

(a) Que corrente o pino está fornecendo?

(b) Por que a ventoinha gira devagar?

(c) O circuito vai falhar imediatamente ou depois de um tempo? Justifique.
]

#resposta[
(a) No máximo o que o pino consegue entregar, algo abaixo de 25 mA — não os
150 mA que a ventoinha pede.

(b) Porque o pino é uma fonte limitada: ele não sustenta a tensão sob essa
corrente, e a tensão sobre a ventoinha desaba. Além disso, o pino entrega 5 V, e
a ventoinha é de 12 V.

(c) Pode funcionar por um tempo. Operar continuamente no máximo absoluto não
provoca falha instantânea; provoca degradação. É o pior tipo de defeito: o
circuito parece funcionar na demonstração e falha semanas depois, sem causa
aparente.

#docente[
A alínea (c) é o ponto. A turma tende a achar que "queimou" ou "não queimou" são
as duas únicas possibilidades. Vale nomear a terceira: degradação acelerada.
]
]

#tarefa[
*Exercício 8.2.* O termostato reinicia toda vez que o aquecedor liga, e apenas
nesse instante.

(a) Que bit de `RCON` você espera encontrar em zero?

(b) Cite três causas físicas possíveis, em ordem do que você investigaria
primeiro.

(c) Por que o defeito não aparece quando o aquecedor *desliga*, se o chute
indutivo acontece na abertura?
]

#resposta[
(a) `/BOR` — reset por subtensão.

(b) *Primeiro:* fonte subdimensionada, incapaz do surto de partida. *Segundo:*
fiação de terra compartilhada, com a corrente do aquecedor caindo sobre a
resistência do fio comum e deslocando o terra do microcontrolador. *Terceiro:*
ausência ou insuficiência de capacitor de desacoplamento perto do chip.

(c) Porque a carga resistiva do aquecedor não produz chute na abertura — o chute
é de carga indutiva. O que ela produz é um degrau de corrente na *ligação*, e é
esse degrau que derruba a tensão. Se o defeito ocorresse na abertura, a suspeita
mudaria de fonte para indutância.

#docente[
A alínea (c) separa quem entendeu de quem decorou. O aquecedor é resistivo: o
problema dele é o degrau de corrente, não o chute. Quem responder "chute
indutivo" para o aquecedor não leu o circuito.
]
]

#tarefa[
*Exercício 8.3.* Justifique, com números, por que se comuta em vez de regular
linearmente. Suponha a carga de 47 #sym.Omega em 12 V, operando a meia potência.
]

#resposta[
*Linear a meia potência:* para dissipar metade, a tensão na carga cai para
$12 slash sqrt(2) approx 8,5$ V, e a corrente para 180 mA. O transistor larga os
3,5 V restantes: $P = 3,5 dot.c 0,18 approx 0,63$ W, dissipados nele.

*Comutando a 50%:* o MOSFET conduz metade do tempo com $R_"DS(on)"$ de 22
m#sym.Omega e 255 mA: $P = (0,255)^2 dot.c 0,022 dot.c 0,5 approx 0,7$ mW.

Quase mil vezes menos, e sem dissipador. O preço é o ruído de comutação e o
diodo, que o arranjo linear não precisa.
]

#tarefa[
*Exercício 8.4.* Um programa alimenta o cão de guarda dentro do tratamento do
Timer0, que roda a cada 5 ms. O laço principal trava num `while` que espera um
indicador que nunca vem.

(a) O watchdog reinicia o sistema?

(b) O que o usuário observa?

(c) Onde o `CLRWDT` deveria estar, e por quê?
]

#resposta[
(a) Não. O tratamento continua rodando e continua alimentando o cão, que nunca
estoura.

(b) Um sistema aparentemente vivo e inútil: o LED de atividade pisca, a nota do
buzzer continua tocando, o relógio de milissegundos avança — e a temperatura
exibida congela, os botões não respondem e o controle não atua.

Este é o pior modo de falha possível, porque parece funcionamento.

(c) No laço principal, no ponto em que se pode afirmar que ele deu a volta
inteira. O watchdog precisa ser alimentado por quem ele deve vigiar.

#docente[
Se houver tempo, vale a variação: e se houver duas tarefas no laço principal? A
resposta é alimentar o cão só quando *ambas* tiverem reportado progresso, e é a
porta de entrada para a ideia de watchdog cooperativo. Meia página do Ganssle.
]
]

#nota[
*No encontro 9:* controle liga-desliga e histerese. Agora existe uma chave capaz
de aplicar três watts à planta, e um sensor capaz de medir meio grau. Falta a
regra que liga um ao outro — e a primeira versão dela, a mais simples possível,
já produz um comportamento que ninguém pediu: a temperatura oscila em torno do
alvo, para sempre.
]
