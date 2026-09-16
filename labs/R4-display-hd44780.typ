// R4 — O display, e o custo da espera
// Microcontroladores (Laboratório) — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#show: conf.with(
  titulo: "R4 — O display, e o custo da espera",
  subtitulo: "Um protocolo gerado por software, medido no pino",
  modo: "roteiro",
)

#objetivos[
- Justificar cada atraso do driver a partir dos mínimos da folha de dados, e não por cópia.
- Medir no osciloscópio o pulso de habilitação e o tempo de uma atualização de tela.
- Provocar, observar e explicar a falha intermitente causada por inicialização apressada.
- Comparar quatro bits contra oito bits *na mesma bancada*, e decidir com o número.
]

#kit[
#tab(
  columns: (auto, 1fr),
  [CH2-1 (LCD)], [*ON* — é o único roteiro em que ele entra],
  [CH5-3 e CH5-4], [*OFF, obrigatoriamente*],
  [Chaves SWITCHS (PORTB)], [Todas em OFF],
)

*A verificar antes desta sessão, e é bloqueante:* se as linhas de relé
compartilham PORTD com o barramento do display, cada escrita de dado chaveia relé.
CH5-3 e CH5-4 desligados é pré-requisito, não recomendação — conferir na
serigrafia.

*Também a verificar:* se a linha `R/W` do módulo está aterrada. Se estiver, o
indicador de ocupado é inacessível e toda a temporização por atraso fixo deste
roteiro é consequência dessa escolha de hardware.
]

= O primeiro periférico que não obedece na hora

Até o R3, escrever num pino produzia efeito imediato. O display não: ele tem
controlador próprio, oscilador próprio, e leva tempo para executar o que recebe.

#tab(
  columns: (auto, auto, 1fr),
  [Operação], [Tempo mínimo], [Em ciclos de máquina],
  [Comando comum ou caractere], [#sym.tilde.op 40 µs], [160],
  [Limpar o display], [#sym.tilde.op 1,6 ms], [6#h(1pt)400],
  [Energização inicial], [#sym.tilde.op 40 ms], [160#h(1pt)000],
)

A última linha é o mínimo da folha de dados. O driver espera 50 ms — a diferença é margem, e a Tarefa 5 mostra por que ela não é opcional.

#atencao[
Ignorar esses tempos produz o sintoma mais traiçoeiro do semestre: *o display
funciona às vezes*.

Um sistema que funciona quase sempre é mais perigoso que um que nunca funciona.
O defeito não aparece na bancada — aparece em campo, sob condições que ninguém
consegue reproduzir.
]

#nota[
E há um efeito colateral visível: no XM118 os dados do display usam *o mesmo
PORTD dos oito LEDs*. Escrever no display faz os LEDs piscarem.

Isso é comportamento esperado, não defeito, e ilustra o que a §3 do R1 já dizia:
pinos são recurso escasso, e o compartilhamento tem consequências visíveis.
]

= Parte 1 — o driver, lido antes de usado

O professor fornece `lcd.c` e `lcd.h`. *Leia antes de gravar qualquer coisa.*

Os comentários do fonte marcam com `[T#]` a tarefa que trata de cada trecho. Eles fazem as perguntas; nenhum as responde.

#tarefa[
*Tarefa 1.* Localize `lcd_pulso()` e responda:

*(a)* Por que existem dois atrasos, um com o pino `E` alto e outro depois de
baixá-lo?

*(b)* Cada um deles atende a qual mínimo da folha de dados do HD44780? Nomeie os
dois.

*(c)* A folha de dados pede 230 ns de largura de pulso. `__delay_us(1)` produz
1000 ns. Por que não usar um valor menor, já que um único ciclo de máquina — 250
ns — já bastaria?
]

#conceito[
A resposta de (c) é a que separa copiar de projetar.

Um ciclo de máquina atenderia quatro dos cinco mínimos. O `__delay_us(1)` é
escolhido por *margem*: dá folga de mais de quatro vezes sobre o pior caso, o que
absorve variação de módulo, de temperatura e de tensão sem que ninguém precise
medir nada.

E há uma razão concreta: módulos alimentados a 2,7 V, e boa parte dos clones
vendidos hoje, especificam 450 ns em vez de 230. Ainda cabe em 1000 ns; não
caberia num pulso de 250 ns.

*O ganho de "otimizar" o pulso seria de 750 ns por nibble. O preço seria um driver
que funciona na sua bancada e falha na do colega, com um módulo de outro lote.*
]

#tarefa[
*Tarefa 2.* Com o osciloscópio no pino `E`, disparo na borda de subida, meça:

#tab(
  columns: (1fr, auto, auto),
  [Grandeza], [Previsto (P4)], [Medido],
  [Largura do pulso de habilitação], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Intervalo entre dois pulsos consecutivos], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
  [Tempo entre os dois nibbles de um byte], [#lacuna(largura: 2.5cm)], [#lacuna(largura: 2.5cm)],
)

Compare com a previsão P4 da folha da aula 3.
]

= Parte 2 — a inicialização, e a falha intermitente

#tarefa[
*Tarefa 3.* Localize a sequência de inicialização e preencha:

#tab(
  columns: (auto, 1fr),
  [`0x30`, três vezes], [#lacuna(largura: 8cm)],
  [`0x20`], [#lacuna(largura: 8cm)],
  [`0x28`], [#lacuna(largura: 8cm)],
  [`0x0C`], [#lacuna(largura: 8cm)],
  [`0x06`], [#lacuna(largura: 8cm)],
  [`0x01`], [#lacuna(largura: 8cm)],
)
]

#tarefa[
*Tarefa 4.* Troque `0x0C` por `0x0F` e observe. O que mudou, e por quê?
]

#tarefa[
*Tarefa 5.* Remova o `__delay_ms(LCD_T_ENERGIA_MS)` de `lcd_iniciar()` — são
os 50 ms — e grave.

O display funciona? Funciona *sempre*? Ligue e desligue o kit três vezes:

#tab(
  columns: (auto, 1fr),
  [Tentativa 1], [#lacuna(largura: 8cm)],
  [Tentativa 2], [#lacuna(largura: 8cm)],
  [Tentativa 3], [#lacuna(largura: 8cm)],
)
]

#conceito[
Este teste é o ponto central do roteiro, e o resultado costuma ser: funciona duas
vezes e falha uma.

Os 50 ms não são para o display: são para a *alimentação*. O controlador só
garante o estado interno depois que a tensão estabiliza, e quem liga o kit pela
USB não controla quanto tempo isso leva. Em alguns arranques a tensão sobe rápido
o bastante; em outros, não.

*Você não pode testar a ausência dessa falha.* Só pode garantir a margem.
]

== Os três `0x30`

#tarefa[
*Tarefa 6.* Remova *uma* das três repetições de `0x30`. Grave, e ligue e desligue
o kit cinco vezes. Depois pressione o reset — sem desligar — mais cinco vezes.

Os dois casos se comportam igual? Confronte com a previsão P3 da folha da aula 3.
]

#conceito[
Não se comportam, e a diferença é o conteúdo da aula 3.

Ao *energizar*, o controlador está sempre no mesmo estado: acabou de nascer, em
oito bits. Duas repetições bastam, e a versão errada parece correta.

Ao *pressionar o reset*, o microcontrolador reinicia e o display não — ele
continua em quatro bits, e pode estar esperando o nibble alto ou o nibble baixo.
São três estados possíveis, e o terceiro só converge no terceiro pulso.

*Testar apenas na energização esconde exatamente o defeito que a terceira
repetição existe para evitar.* É o mesmo padrão da Tarefa 5, com outro
mecanismo.
]

= Parte 3 — números no display

O display recebe *caracteres*, não números. Para mostrar 37 é preciso enviar
`'3'` e depois `'7'`.

#tarefa[
*Tarefa 7.* Escreva a sua própria `lcd_u8(uint8_t v)`, que mostre um valor de 0 a
255, e use para exibir um contador incrementando a cada 500 ms.

Escreva a versão ingênua: só os dígitos que o número tem, sem nenhum cuidado com
o que já estava na tela. O driver traz uma `lcd_numero()` pronta — *não use ainda*,
e não a chame de dentro da sua.

Antes de escrever: por que `'0' + digito` funciona? O que garante que os dígitos
sejam consecutivos na tabela de caracteres?
]

#tarefa[
*Tarefa 8.* Deixe o contador passar de 100 para 99. O que aparece?

Compare com a previsão P1 da folha e explique. Depois corrija — *de duas formas
diferentes*, uma na função de escrita e outra na formatação do número.

Só então abra a `lcd_numero()` do driver e diga qual das duas correções ela usa,
e por que é ela que o resto do semestre vai chamar.
]

#nota[
Este é o mesmo defeito da P1, com outro número: a segunda cadeia é mais curta que
a primeira, e o display não apaga nada. Sobra o excedente do texto anterior.

A correção que o resto do semestre vai usar é largura fixa — o número ocupa
sempre as mesmas posições, completado com espaço à esquerda.
]

= Parte 4 — quatro bits contra oito, medido

O kit liga as oito linhas de dados ao PORTD, então os dois modos são possíveis
nesta bancada. A aula 3 argumentou que quatro bits economizam quatro pinos.
Agora vocês medem o que isso custa.

#tarefa[
*Tarefa 9.* Rode o mesmo texto nos dois modos e meça, com um pino auxiliar
levantado antes e baixado depois da escrita:

#tab(
  columns: (1fr, auto, auto),
  [], [Oito bits], [Quatro bits],
  [Pulsos de `E` por byte], [#lacuna(largura: 2cm)], [#lacuna(largura: 2cm)],
  [Tempo de um caractere], [#lacuna(largura: 2cm)], [#lacuna(largura: 2cm)],
  [Tempo de uma linha de 16], [#lacuna(largura: 2cm)], [#lacuna(largura: 2cm)],
  [Pinos ocupados], [#lacuna(largura: 2cm)], [#lacuna(largura: 2cm)],
)
]

#conceito[
O resultado costuma surpreender: *quatro bits quase não custam tempo*.

Cada byte gasta um pulso a mais, o que acrescenta poucos microssegundos — contra
os 40 µs de execução do comando, que o controlador consome de qualquer jeito. A
diferença fica na casa de 5%.

E economiza quatro pinos, que num projeto com sensor, aquecedor, ventoinha,
teclado e comunicação são a diferença entre caber e não caber.

*É por isso que quatro bits é o padrão*, e não porque alguém queira escrever mais
código. A decisão se justifica com os dois números medidos, e não com preferência.
]

= Parte 5 — o custo da tela inteira

#tarefa[
*Tarefa 10.* Meça o tempo de uma atualização completa: posicionar o cursor,
escrever dezesseis caracteres, posicionar de novo, escrever mais dezesseis.

Levante um pino auxiliar antes e baixe depois; meça a largura do pulso.

#tab(
  columns: (1fr, auto),
  [Tempo medido de uma atualização completa], [#lacuna(largura: 3cm)],
  [Em ciclos de máquina, a 250 ns], [#lacuna(largura: 3cm)],
  [Percentual do processador a cada 100 ms (P5)], [#lacuna(largura: 3cm)],
  [Percentual do processador a cada 500 ms (P5)], [#lacuna(largura: 3cm)],
)
]

#tarefa[
*Tarefa 11.* Acrescente `lcd_comando(0x01)` — limpar — antes de cada atualização,
e meça de novo. Depois olhe para a tela e descreva o que mudou visualmente.
]

#conceito[
Os dois efeitos aparecem juntos: o tempo sobe alguns milhares de ciclos, e a tela
*treme*, porque fica em branco por um instante a cada ciclo.

A prática correta é reposicionar o cursor e sobrescrever, com largura constante —
que é a mesma correção da Tarefa 8, agora por um segundo motivo.
]

#nota[
Guarde o número da Tarefa 10. Ele é o mais caro que este curso vai encontrar até o
encontro 10, e é a unidade de comparação de tudo o que vem depois: uma conversão
analógica custa sessenta ciclos, um tratamento de interrupção custa algumas
dezenas, e uma atualização de tela custa alguns milhares.
]

= Armadilhas frequentes

#tab(
  columns: (1fr, 1.2fr),
  [Sintoma], [Causa provável],
  [Display aceso, sem texto], [Contraste, ou CH2-1 em OFF],
  [Linha superior com quadrados escuros], [Inicialização incompleta],
  [Funciona às vezes], [Falta de atraso após a energização],
  [Caracteres embaralhados], [Falta de espera após o comando de limpar],
  [Texto na linha errada], [Endereço de cursor: a *segunda* linha começa em `0x40`],
  [Resíduo ao diminuir dígitos], [Largura variável; não limpou a posição anterior],
  [LEDs piscando junto], [Esperado — PORTD é compartilhado],
  [Relé chaveando a cada caractere], [CH5-3 ou CH5-4 ligado. *Desligue agora*],
)

= Entrega

#tarefa[
*Entrega.* As três tabelas de medida (Tarefas 2, 9 e 10), o registro das três
tentativas da Tarefa 5, e o resultado da Tarefa 6 nos dois casos — energização e
reset.

Responda também:

*(a)* Por que `__delay_us(1)` e não um único ciclo de máquina? Cite o mínimo que
justifica a escolha e a margem obtida.

*(b)* Na Tarefa 6, por que o defeito aparece no reset e não na energização?
Sua previsão P3 acertou a condição de falha?

*(c)* Com os números da Tarefa 9, você escolheria quatro ou oito bits para um
produto? Justifique com as duas grandezas.

*(d)* A previsão P2 dizia respeito a trocar `LATD` por `PORTD` no driver. Você
testou? O que aconteceu, e por quê?
]

#criterio[
Previsões preenchidas antes: 2,0.

Tarefa 2 (pulso medido): 1,5. Tarefas 5 e 6 (falha intermitente e os três
estados): 2,5 — é o centro do roteiro. Tarefas 7 e 8 (números e o resíduo): 1,5.
Tarefa 9 (quatro contra oito bits): 1,5. Tarefa 10 (custo da tela): 1,0.

Na alínea (b), a resposta completa nomeia os *três* estados possíveis e diz por
que a energização só produz um deles.
]

#nota[
*No R5:* a entrada e o conversor. Vocês vão ler um botão que não responde, e
descobrir por quê — a resposta está no que existe atrás do pino, e não no código.

E o LM35 entra: temperatura na tela, com a conta que vocês trouxeram da última
sessão.
]
