// Aula 9 — Controle liga-desliga e histerese
// Microcontroladores — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#import "figuras.typ": *
#show: conf.with(
  titulo: "Aula 9 — Controle liga-desliga e histerese",
  subtitulo: "A regra mais simples possível, e o que ela cobra",
)

#objetivos[
- Prever o comportamento de uma regra de comparação direta perto do alvo, e estimar a taxa de comutação resultante.
- Descrever a histerese como a introdução de memória na regra de decisão, e relacioná-la ao disparador Schmitt do encontro 4.
- Derivar o período do ciclo limite a partir das taxas de aquecimento e resfriamento, e converter em acionamentos por hora.
- Justificar um piso para a faixa de histerese a partir da resolução do conversor.
- Distinguir amplitude prevista de amplitude medida, e atribuir a diferença à inércia térmica.
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
em software e a largura é sua. É a mesma ideia, duas vezes, em camadas
diferentes — e vale dizer isso à turma em voz alta.
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
resposta ao degrau do R9 — aquecedor a 100% a partir da temperatura ambiente — e
todo número desta seção deve ser refeito com eles.

O aquecedor é um resistor de cimento de 47 #sym.Omega dissipando cerca de 3 W, e
o resfriamento é passivo somado à ventoinha. Nada aqui é rápido.
]

#atencao[
A conta de vida útil muda de escala junto: 100#h(1pt)000 operações a 16 por hora
dão 6#h(1pt)250 horas, ou cerca de *oito meses de operação contínua*.

Nenhuma escolha de firmware compra tanto quanto essa. É por isso que o número de
acionamentos por hora é uma das duas grandezas que o R9 vai medir — ele tem
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

Registrar a assimetria agora, com o número medido no R9, é o que torna aquela
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
volatile uint16_t comutacoes = 0;  /* a segunda medida do R9 */

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

= As duas medidas do R9

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

= Previsão para o R9

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
cada mudança abaixo melhora ou piora *cada uma* das duas medidas do R9.

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
