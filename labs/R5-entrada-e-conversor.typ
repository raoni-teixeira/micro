// R5 — O pino que não responde, e o conversor
// Microcontroladores (Laboratório) — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#show: conf.with(
  titulo: "R5 — O pino que não responde, e o conversor",
  subtitulo: "Eletrônica de entrada, quantização e o que a média não conserta",
  modo: "roteiro",
)

#objetivos[
- Reproduzir e diagnosticar o sintoma de um botão que não responde, e corrigi-lo pela causa.
- Medir o degrau do conversor na própria bancada e comparar com o valor derivado.
- Converter o código de dez bits em décimos de grau, sem ponto flutuante.
- Distinguir ruído aleatório de erro de quantização, e decidir o que a média resolve.
]

#kit[
#tab(
  columns: (auto, 1fr),
  [CH2-1 (LCD)], [ON — o display do R4 continua],
  [Chaves SWITCHS (PORTB)], [OFF; o botão usado é o de `INT0`],
  [CH5-3 e CH5-4], [OFF],
  [Sensor LM35], [Habilitado no canal analógico correspondente],
)

*A verificar antes da sessão:* em qual canal o LM35 está ligado, e se a referência
de fundo de escala é a própria alimentação. Todo número deste roteiro depende
dessas duas respostas.
]

= Parte 1 — o botão que não responde

#tarefa[
*Tarefa 1.* Escreva um programa que leia o botão de `INT0` e acenda um LED
enquanto ele estiver pressionado. *Não escreva nada em `ADCON1`.*

Grave, pressione o botão, e registre:

#tab(
  columns: (1fr, auto),
  [O que a previsão P1 dizia], [#lacuna(largura: 3cm)],
  [O que o LED faz com o botão solto], [#lacuna(largura: 3cm)],
  [O que o LED faz com o botão pressionado], [#lacuna(largura: 3cm)],
)
]

#tarefa[
*Tarefa 2.* Antes de corrigir, *meça*. Com o multímetro, e depois com o
osciloscópio, verifique a tensão no pino do botão nas duas posições.

O pino está mudando de tensão? #lacuna(largura: 6cm)

Então o defeito está no circuito ou no programa? #lacuna(largura: 6cm)
]

#conceito[
O pino muda de tensão e o programa lê sempre zero. O botão funciona, o fio
funciona, e a leitura não.

A causa está entre os dois: quando o canal analógico daquele pino está
habilitado, *o buffer de entrada digital é desligado*, e a leitura de `PORTB`
devolve 0 independentemente do que houver no fio.

Quem decide isso após o reset é um bit de configuração — `PBADEN` — que deixa RB0
a RB4 nascendo analógicos.
]

#kit[
E `PBADEN` não é ajustável por você: os bits de configuração pertencem ao
bootloader, e o `#pragma config` da sua aplicação é ignorado. É o princípio do
encontro 0 aparecendo pela terceira vez.

A correção é desfazer o efeito em tempo de execução:

```c
ADCON1 = 0x0F;    /* todos os canais em modo digital */
```

E o padrão do curso a partir de agora: *tudo digital na primeira linha, e o
analógico se declara explicitamente depois.*
]

#tarefa[
*Tarefa 3.* Acrescente a linha, grave, e confirme. Depois responda: *por que este
defeito é difícil de encontrar sozinho?*

Liste duas hipóteses erradas que um aluno testaria antes de chegar na causa.
]

= Parte 2 — o que existe atrás do pino

#tarefa[
*Tarefa 4.* Deixe o pino de entrada *solto* — sem botão, sem resistor, sem nada
ligado — e leia o estado num laço, exibindo no display.

O valor é estável? Aproxime a mão do pino sem tocar. O que acontece?
]

#conceito[
Um pino configurado como entrada é de *alta impedância*: ele observa sem
consumir. E um nó de alta impedância sem nada que o defina não tem nível — ele
adota o que a capacitância parasita e o ambiente elétrico lhe derem.

Aproximar a mão acopla ruído da rede, e o valor lido acompanha.

É por isso que toda entrada digital precisa de algo que a defina quando o botão
está solto: um resistor de elevação ou de descida, externo ou interno ao chip.
Deixar flutuando não é economia, é indefinição.
]

#tarefa[
*Tarefa 5.* Com o osciloscópio no pino do botão, aperte e solte devagar,
observando a transição.

A borda é limpa? Descreva o que vê entre os dois níveis: #lacuna(largura: 6cm)
]

#nota[
Duas coisas aparecem aqui, e vocês vão encontrá-las de novo.

O sinal leva um tempo *finito* para atravessar a faixa entre os dois níveis, e
nessa faixa o buffer de entrada não promete nada — é para isso que ele tem
histerese, com um limiar para subir e outro para descer.

E o contato mecânico não fecha uma vez: ele ricocheteia. Registre o que viu; o R7
volta a esse traço com o osciloscópio configurado para capturá-lo.
]

= Parte 3 — o conversor, em bruto

#tarefa[
*Tarefa 6.* Com o driver fornecido, mostre no display o valor bruto do conversor,
de 0 a 1023, atualizado a cada 500 ms.

#tab(
  columns: (1fr, auto, auto),
  [], [Previsto (P2)], [Observado],
  [Código à temperatura ambiente], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Código com o dedo no sensor, 10 s], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Variação por grau (P4)], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
)
]

#conceito[
Da referência de 5 V e dos dez bits:

#align(center)[1 LSB $= 5000 slash 1024 approx 4,88$ mV]

E o LM35 entrega 10 mV por grau, então:

#align(center)[1 LSB $approx 0,488$ #sym.degree#h(0pt)C]

*Meio grau.* Este é o degrau da sua bancada, e ele não melhora com código melhor.
]

#nota[
O manual informa que o LM35 fica montado *junto à resistência de aquecimento*.
Ele mede a temperatura do conjunto sensor-resistência, e não a do ar da sala —
uma diferença de alguns graus para mais é esperada, e não é erro de conversão.

Comparar com um termômetro da sala e concluir que "a conta está errada" é o erro
que este parágrafo existe para evitar.
]

= Parte 4 — a conversão, sem ponto flutuante

#conceito[
O LM35 entrega 10 mV por grau, e 1 mV equivale a 0,1 #sym.degree#h(0pt)C. Logo *o
valor em milivolts já é o valor em décimos de grau*, e não é preciso converter
duas vezes:

#align(center)[décimos de grau $=$ código $dot.c 625 slash 128$]

A fração é exata, e 128 é potência de dois — o que transforma a divisão num
deslocamento.
]

#tarefa[
*Tarefa 7.* Implemente e mostre a temperatura no formato `NN.N C`, com largura
fixa — como o R4 estabeleceu.

```c
int16_t adc_para_decimos(uint16_t leitura)
{
    uint32_t acumulador = (uint32_t) leitura * 625UL;
    return (int16_t)(acumulador >> 7);
}
```

*(a)* Por que o acumulador precisa ser de 32 bits? Calcule o maior produto
possível e compare com 65#h(1pt)535.

*(b)* A partir de que temperatura o defeito apareceria, se o acumulador fosse de
16 bits?
]

#atencao[
Troque o `uint32_t` por `uint16_t` de propósito, grave, e aqueça o sensor até
passar do ponto que você calculou em (b).

O programa não trava, não reinicia e não avisa. A temperatura exibida despenca e
volta a subir. *Registre o que viu* — é o modo de falha mais comum de aritmética
inteira em sistema embarcado, e vocês vão reconhecê-lo pelo resto da vida.
]

= Parte 5 — o ruído, e o que a média não conserta

#tarefa[
*Tarefa 8.* Com o kit imóvel e sem tocar no sensor, observe o último dígito por
trinta segundos.

Previsão P3 dizia quantos códigos distintos? #lacuna(largura: 3cm)

Quantos você contou? #lacuna(largura: 3cm)

A oscilação observada é compatível com 1 LSB? Mostre a comparação.
]

#tarefa[
*Tarefa 9.* Implemente a média de oito amostras e observe de novo.

```c
uint16_t adc_media(uint8_t n_pot2)
{
    uint32_t soma = 0;
    uint16_t total = (uint16_t)(1u << n_pot2);

    for (uint16_t i = 0; i < total; i++) {
        soma += adc_amostra();
    }
    return (uint16_t)(soma >> n_pot2);
}
```

A oscilação diminuiu? Desapareceu? E por que o número de amostras é potência de
dois?
]

#conceito[
A média reduz o ruído *aleatório*, que é o que faz o dígito oscilar. Ela não
reduz o erro de *quantização*, que é sistemático: se a tensão real cai entre dois
códigos, nenhuma quantidade de médias inventa o valor intermediário.

E há um caso que costuma surpreender: *se a leitura for perfeitamente estável, a
média não melhora nada* — oito amostras idênticas têm média igual a elas mesmas.
Um conversor limpo demais não pode ser melhorado por média.

Distinguir essas duas fontes de erro é o que separa quem filtra por hábito de
quem filtra por motivo.
]

#tarefa[
*Tarefa 10.* Meça o custo. Com um pino auxiliar levantado antes e baixado depois,
compare o tempo de uma leitura simples e o de uma média de oito.

#tab(
  columns: (1fr, auto, auto),
  [], [Tempo], [Ciclos],
  [Uma conversão], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Média de oito], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Atualização de tela (do R4)], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
)

Qual das três domina o laço?
]

= Parte 6 — o custo da representação

#tarefa[
*Tarefa 11.* Compile duas versões do mesmo programa: uma com a conversão inteira
e outra com

```c
float temp = leitura * 5000.0f / 1024.0f / 10.0f;
```

Compare o *tamanho do programa* no arquivo de mapa gerado pela compilação.

#tab(
  columns: (1fr, auto, auto),
  [], [Inteira], [Com `float`],
  [Bytes de programa], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Percentual dos 32 kB], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
)
]

#nota[
O número que sai daqui é o que justifica, retroativamente, a decisão do R0 de
representar temperatura como `int16_t` em décimos de grau.

Não foi preferência estética nem purismo: é o preço medido, no seu compilador, do
tipo que parecia mais natural.
]

= Entrega

#tarefa[
*Entrega.* As tabelas das Tarefas 6, 10 e 11; o registro do estouro provocado na
Parte 4; a contagem de códigos distintos da Tarefa 8.

Responda também:

*(a)* Por que o botão não respondia? Descreva a causa em termos do que existe
atrás do pino, e não em termos de "faltava uma linha".

*(b)* Você mediu quantos códigos distintos com o sistema parado. A média de oito
melhorou? Se não melhorou, o que isso diz sobre o ruído da sua bancada?

*(c)* Qual é o menor aquecimento que a sua bancada detecta (P4)? Compare com
0,488 #sym.degree#h(0pt)C e explique a diferença, se houver.

*(d)* Com os números da Tarefa 10, vale a pena fazer média de oito? Justifique
comparando com o custo do display.
]

#criterio[
Previsões preenchidas antes: 2,0.

Parte 1 completa, com a medida da Tarefa 2 feita *antes* da correção: 2,5 — o
ponto é diagnosticar, não corrigir. Descontar 1,0 de quem corrigiu primeiro e
mediu depois.

Parte 4 com o estouro provocado e registrado: 2,0. Parte 5 com a comparação
numérica contra 1 LSB: 2,0. Parte 6 com os dois tamanhos: 1,5.

Na alínea (b), aceitar "não melhorou" como resposta correta e bem fundamentada —
é o resultado esperado se o ruído da bancada for menor que 1 LSB.
]

#nota[
*No R6:* o PWM, e o mesmo sinal com dois significados. A ventoinha vai ler a razão
cíclica como energia, e o buzzer vai ler a frequência como nota — com o mesmo
código, mudando só uma chave.

E uma descoberta desconfortável: o módulo de PWM do chip não alcança o lá de 440
Hz que vocês tocaram no R3.
]
