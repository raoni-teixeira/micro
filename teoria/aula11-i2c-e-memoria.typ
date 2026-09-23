// Aula 11 — Barramento serial síncrono e memória não volátil
// Microcontroladores — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#import "figuras.typ": *
#show: conf.with(
  titulo: [Aula 11 — I#super[2]C e memória não volátil],
  subtitulo: [A mesma tarefa, por dois mecanismos],
)

#objetivos[
- Guardar e recuperar um valor entre reinicializações, usando a memória interna por registradores e a externa por barramento.
- Explicar o dreno aberto e justificar a necessidade dos resistores de elevação.
- Descrever o byte de controle e argumentar por que o endereço viajar no barramento é o que dispensa fios dedicados.
- Reconhecer o start repetido como prova de que escrita e leitura são fases de uma mesma transação.
- Comparar espera cega com confirmação pelo dispositivo, e estimar o custo de cada uma.
- Dimensionar a frequência de escrita a partir da vida útil da memória.
]

= O que não sobrevive ao reset

O usuário ajustou o alvo para 42 #sym.degree#h(0pt)C no botão do encontro 7. O
aquecedor ligou, a tensão caiu, e o encontro 8 mostrou o que acontece: reset por
subtensão. O programa recomeça, e o alvo volta a ser o que estava escrito no
código.

#conceito[
Toda variável deste curso mora na RAM, e a RAM é volátil por construção — ela
guarda carga, e carga sem alimentação se dissipa em milissegundos.

Guardar algo entre reinicializações exige uma tecnologia diferente, e o
PIC18F4550 dá acesso a duas: uma dentro do chip e outra fora dele. Elas resolvem
o mesmo problema por caminhos completamente diferentes, e é essa comparação que
organiza a aula.
]

= Dentro do chip: registradores num endereço

A memória não volátil interna tem 256 bytes e nenhum barramento. Fala-se com ela
como se fala com qualquer periférico do encontro 1: escrevendo em registradores
de função especial.

```c
uint8_t eeprom_ler(uint8_t end)
{
    EEADR = end;
    EECON1bits.EEPGD = 0;      /* memoria de dados, nao a Flash */
    EECON1bits.CFGS  = 0;      /* nao os bits de configuracao   */
    EECON1bits.RD    = 1;
    return EEDATA;             /* pronto no ciclo seguinte */
}

void eeprom_escrever(uint8_t end, uint8_t dado)
{
    EEADR  = end;
    EEDATA = dado;
    EECON1bits.EEPGD = 0;
    EECON1bits.CFGS  = 0;
    EECON1bits.WREN  = 1;      /* habilita escrita */

    uint8_t salvo = INTCONbits.GIE;
    INTCONbits.GIE = 0;        /* a sequencia abaixo nao pode ser interrompida */
    EECON2 = 0x55;
    EECON2 = 0xAA;
    EECON1bits.WR = 1;
    INTCONbits.GIE = salvo;

    while (EECON1bits.WR) { }  /* cerca de 4 ms */
    EECON1bits.WREN = 0;       /* desabilita de novo */
}
```

#conceito[
*A sequência 0x55, 0xAA existe por uma razão específica.* `EECON2` não é um
registrador de verdade: não guarda nada e não pode ser lido. Ele é uma fechadura.

Sem ela, um programa que perdeu o rumo — ponteiro errado, pilha corrompida,
retorno para um endereço qualquer — poderia escrever na memória não volátil por
acidente, e destruir a calibração ou a configuração do produto de campo.

Com ela, o acidente teria de executar exatamente três escritas na ordem certa,
sem nada no meio. É proteção contra código descontrolado, e é por isso que
`INTCONbits.GIE` precisa ser desligado ali: uma interrupção entre as duas metades
da chave anula a sequência.
]

#nota[
Repare no `while (EECON1bits.WR)`. São 4 ms de espera cega — três vezes uma
atualização de tela. Escrever na memória não volátil é a operação mais lenta que
este curso encontrou até agora, e ela vai ficar mais lenta ainda na versão
externa.
]

= Fora do chip: um contrato de barramento

A mesma tarefa, agora por dois fios.

== Dreno aberto

#fig(
  fig_dreno_aberto(),
  [Nenhum dispositivo empurra a linha para cima. Isso é o que permite que vários
  falem no mesmo par de fios sem risco de curto.],
)

#conceito[
Cada dispositivo tem apenas um transistor que puxa a linha para o terra. Ninguém
tem como forçá-la para cima; quem faz isso é um resistor.

A consequência é uma função lógica cablada: a linha está em 1 se e somente se
*todos* estiverem soltos. Se dois dispositivos falarem ao mesmo tempo, o que
disser 0 vence, e nada queima — enquanto num barramento com saídas empurrando dos
dois lados isso seria um curto-circuito entre a alimentação e o terra.

O preço é a velocidade. A subida da linha é feita por um resistor carregando uma
capacitância, e não por um transistor: por isso o barramento é assimétrico, com
descida rápida e subida lenta, e por isso existe um limite de capacitância total
que restringe quantos dispositivos e quanto fio o barramento aceita.
]

#kit[
*A verificar antes do R12.* A placa já traz os resistores de elevação em SDA e
SCL, ou o roteiro precisa incluí-los? E qual é a peça de memória — 24C02, 24C04 ou
24C16?

A resposta muda a aula: o tamanho da página, a quantidade de bits de endereço de
dispositivo e a existência de bits de seleção de bloco dependem da peça.
]

== O endereço viaja no barramento

#fig(
  fig_campos((
    ("família", "1010"), ("endereço do chip", "AAA"), ("R/W", "R"),
  ), w: 0.72cm),
  [O byte de controle. Quatro bits identificam a família de memórias, três
  escolhem o chip, e o último diz o sentido da transação.],
)

#conceito[
No barramento paralelo do encontro 3, a linha `RS` era um fio dedicado a dizer
*o que* o dado significava. Aqui não há fio dedicado: o endereço é o primeiro byte
que trafega.

É essa a resposta para a pergunta que o encontro 3 deixou aberta — por que o
paralelo precisa de tantos fios. Ele precisa porque coloca no espaço o que o
serial coloca no tempo.
]

#atencao[
*O erro número um de quem começa em I#super[2]C.* O endereço tem sete bits; o que
trafega é um byte de oito. A folha de dados de um sensor diz "endereço 0x48"; o
que precisa ir para o barramento é 0x48 deslocado uma casa à esquerda, mais o bit
de sentido — ou seja, 0x90 para escrever e 0x91 para ler.

Quem escrever 0x48 direto está endereçando o dispositivo 0x24 em modo de leitura.
Não há dispositivo nenhum ali, ninguém responde, e o sintoma é ausência de
reconhecimento — que se parece com fio solto, com pull-up faltando e com memória
queimada.

Metade das bibliotecas espera o endereço de sete bits e desloca por você; a outra
metade espera o byte já montado. Ler a documentação da biblioteca aqui não é
opcional.
]

== A transação, e o start repetido

#fig(
  fig_i2c(),
  [Ler um byte de um endereço qualquer da memória. Note que existe *uma*
  transação, e não duas.],
)

#conceito[
Para ler de um endereço arbitrário é preciso primeiro *escrever* esse endereço na
memória, e só então inverter o sentido. A tentação é fazer isso como duas
operações: escreve o endereço, encerra, começa de novo e lê.

Não funciona de forma confiável. Entre as duas, o barramento fica livre, e outro
mestre pode assumir e mexer no ponteiro interno da memória.

O start repetido resolve: emite-se uma nova condição de início *sem* soltar o
barramento. Escrita e leitura passam a ser duas fases de uma mesma transação
indivisível.
]

#nota[
Guarde a forma deste argumento. É a mesma da leitura de dezesseis bits do
encontro 7: uma operação que parece atômica é composta por partes, e o defeito
aparece quando alguém entra no meio.

Lá o intruso era a interrupção; aqui é outro mestre no barramento. A solução tem
o mesmo formato — tornar a sequência indivisível.
]

== O custo, e a espera que acabou

#tab(
  columns: (auto, auto, auto, 1fr),
  [Encontro], [Barramento], [Endereçamento], [Confirmação],
  [2], [pino direto], [—], [—],
  [3], [paralelo (HD44780)], [`RS` seleciona o registrador], [nenhuma — espera cega],
  [10], [UART], [— (ponto a ponto)], [nenhuma],
  [11], [I#super[2]C], [7 bits, no próprio barramento], [*ACK a cada byte*],
)

#conceito[
Depois de receber um byte, a memória puxa a linha para baixo por um tempo de bit.
Esse é o reconhecimento, e ele responde à pergunta que o HD44780 não sabia
responder: *chegou?*

E a mesma ideia resolve o problema maior. A escrita interna da memória leva cerca
de 5 ms, durante os quais ela não responde a nada. Em vez de esperar 5 ms às
cegas, o mestre simplesmente *pergunta*: emite um start e o byte de controle, e
observa se veio reconhecimento. Se não veio, ainda está ocupada; tenta de novo.

É a mesma espera do encontro 3 com uma diferença de qualidade: lá o processador
esperava o pior caso tabelado, aqui ele descobre o caso real. Numa escrita que
termina em 3 ms, sobram 2 ms de trabalho útil que o HD44780 teria jogado fora.
]

#nota[
A 100 kHz, cada byte ocupa o barramento por 90 µs. A transação inteira da figura —
quatro bytes mais as condições — custa cerca de 400 µs, ou 1600 ciclos de máquina.

Contra os 5#h(1pt)200 do display e os 60 do conversor. E, como na serial, o
processador só precisa aparecer entre os bytes.
]

= Página e vida útil

#conceito[
*Escrita por página.* A memória tem um pequeno registrador interno — 8 ou 16 bytes,
conforme a peça — e um único ciclo de gravação de 5 ms serve para tudo que estiver
nele. Gravar oito bytes em uma página custa os mesmos 5 ms que gravar um; gravar
oito bytes um a um custa 40 ms.

O detalhe que morde: o contador de endereço dentro da página *dá a volta*. Escrever
além do limite não avança para a página seguinte — sobrescreve o começo da mesma
página.
]

#atencao[
*A memória se gasta.* Uma memória desse tipo suporta da ordem de um milhão de
ciclos de escrita por posição; a interna do PIC, algo como cem mil.

Se o programa gravar o alvo uma vez por segundo:

#align(center)[$10^6 slash 86#h(1pt)400 approx 11,6$ dias]

Onze dias, e a posição está morta.

É a mesma conta da vida útil do relé no encontro 9, num componente sem partes
móveis. E a solução tem a mesma forma: *escrever só quando o valor muda*, que era
exatamente a estratégia adotada para o display no encontro 3.

Três problemas diferentes, uma resposta só.
]

= O protocolo acima do protocolo

Tudo nesta aula foi dito sobre uma memória, e nada dela é sobre memória.

#conceito[
Existem *dois* protocolos empilhados. O I#super[2]C diz como os bytes andam pelos
fios — início, endereço, reconhecimento, parada. O dispositivo diz o que os bytes
*significam*, e isso é assunto da folha de dados dele, não da especificação do
barramento.

E a convenção de significado é quase universal entre dispositivos I#super[2]C: um
*mapa de registradores*, alcançado por um byte de ponteiro. Escreve-se o número do
registrador, emite-se start repetido, e lê-se.

Que é exatamente a figura da seção 3.3. O "endereço interno" da memória e o
"número do registrador" de um sensor são o mesmo mecanismo com dois nomes.
]

Um sensor de temperatura I#super[2]C comum, o LM75A, tem quatro registradores:

#tab(
  columns: (auto, auto, 1fr),
  [Ponteiro], [Registrador], [Para que serve],
  [`0`], [temperatura], [Dois bytes, mais significativo primeiro],
  [`1`], [configuração], [Modo de operação, polaridade da saída de alerta],
  [`2`], [`Thyst`], [Limite de rearme],
  [`3`], [`Tos`], [Limite de disparo],
)

#nota[
Os dois últimos merecem atenção: `Tos` e `Thyst` são um limite superior e um
limite de rearme, e o sensor tem um pino que comuta entre eles.

Isso é o encontro 9 inteiro — controle liga-desliga com histerese — implementado
em silício, dentro de um sensor de vinte reais. Ligar esse pino ao aquecedor e
comparar com o termostato que a turma escreveu é a demonstração mais direta que
existe da fronteira entre o que é firmware e o que é hardware.
]

#atencao[
*Alongamento de relógio.* Alguns dispositivos, quando ainda não têm a resposta
pronta, seguram a linha `SCL` em nível baixo depois do reconhecimento. O mestre
precisa perceber que o relógio não subiu e esperar.

O módulo de hardware do PIC lida com isso. Um I#super[2]C escrito em software, que
apenas gera bordas em intervalos fixos, não lida — ele segue em frente e lê lixo.

Nem todo dispositivo alonga; memórias em geral não, vários sensores sim.
*Verifique na folha de dados do dispositivo, não na do barramento*, porque isso é
comportamento do dispositivo.
]

#opcional[
*Analógico contra digital, na mesma medição.* Vale a comparação porque o
resultado contraria o que a turma espera.

#tab(
  columns: (auto, auto, auto, auto),
  [], [LM35 + ADC de 10 bits], [LM75A], [MCP9808],
  [Resolução], [0,488 #sym.degree#h(0pt)C], [0,125 #sym.degree#h(0pt)C], [0,0625 #sym.degree#h(0pt)C],
  [Exatidão], [±0,5 #sym.degree#h(0pt)C do sensor, mais os erros da cadeia], [*±2 #sym.degree#h(0pt)C*], [±0,25 #sym.degree#h(0pt)C],
  [Fiação], [um canal analógico dedicado], [dois fios compartilhados], [dois fios compartilhados],
  [Fio longo], [o ruído vira erro de medida], [irrelevante], [irrelevante],
)

O sensor digital barato é *pior em exatidão* que a cadeia analógica. O que ele
compra é fiação e imunidade a ruído, não precisão — e a diferença entre o LM75A e
o MCP9808 mostra que isso é característica da peça, não da tecnologia.

Vale também como fecho do encontro 4: se o problema fosse resolução, existe o
ADS1115, que é um conversor de dezesseis bits acessado por este mesmo barramento.
A pergunta "como consigo mais resolução" tinha, o tempo todo, uma resposta que
não passava por melhorar o conversor interno.

Esta caixa pode ser pulada sem prejuízo para o restante do curso.
]

= A colisão de pinos

#kit[
O módulo de comunicação síncrona usa RB0 para SDA e RB1 para SCL. Esses dois
pinos já apareceram duas vezes neste curso:

são as entradas de interrupção externa `INT0` e `INT1`, candidatas naturais aos
botões do encontro 7;

são canais analógicos, e portanto o `PBADEN` do encontro 4 volta a importar —
quatro encontros depois, e pelo mesmo motivo.

*A verificar antes do R12:* como o teclado matricial e a memória convivem em
PORTB, e se há chaves na placa que isolem a memória do barramento.
]

= Previsão para o R12

#previsao[
*P1.* Escreva o alvo na memória, desligue a placa, ligue de novo. O que espera
ver no display no primeiro segundo?

*P2.* Meça no osciloscópio o tempo de subida de SDA. Ele é igual ao de descida?
Justifique antes de medir.

*P3.* Grave oito bytes um a um e depois os mesmos oito por página. Que razão entre
os dois tempos você espera?

*P4.* Faça o programa gravar o alvo a cada volta do laço principal. Estime em
quanto tempo a posição se esgotaria — e depois *não* deixe rodando.

*P5.* Compare o tempo de uma escrita na memória interna com o de uma escrita na
externa. Qual é mais rápida, e por quê?
]

#semnota[
Leve esta folha preenchida. Este roteiro grava memória de verdade: use posições
diferentes a cada tentativa e anote quais já foram usadas.
]

= Exercícios

#tarefa[
*Exercício 11.1.* Explique por que a sequência `0x55`, `0xAA` precisa rodar com as
interrupções desabilitadas, e o que aconteceria sem isso.
]

#resposta[
A fechadura só abre se as três escritas ocorrerem em sequência imediata. Uma
interrupção entre `0x55` e `0xAA` insere instruções no meio, e o hardware
descarta a sequência: a escrita simplesmente não acontece.

Sem desabilitar, o defeito é intermitente — depende de a interrupção cair ou não
naquela janela de poucos ciclos. Grava quase sempre, e falha de vez em quando,
que é a pior forma de um defeito se apresentar.

#docente[
Vale ligar isso ao Exercício 7.1: as duas questões são a mesma ideia. Uma
sequência que precisa ser indivisível, e um intruso que não sabe disso.
]
]

#tarefa[
*Exercício 11.2.* Um programa grava dezesseis bytes de configuração começando no
endereço 0x00 de uma memória com página de oito bytes, usando uma única operação
de escrita por página.

(a) O que fica gravado?

(b) Como corrigir?

(c) Quanto tempo leva a versão correta?
]

#resposta[
(a) Os oito primeiros bytes são escritos em 0x00–0x07, e os oito seguintes dão a
volta *dentro da mesma página*, sobrescrevendo 0x00–0x07. Ao final, a memória
contém os bytes 8 a 15 nas oito primeiras posições, e nada nas oito seguintes.

(b) Duas operações de página: uma em 0x00 e outra em 0x08, com os 5 ms de ciclo
entre elas.

(c) Cerca de 10 ms de ciclo de gravação, mais o tráfego de barramento — que a
100 kHz são cerca de 1,6 ms para os dezesseis bytes mais os cabeçalhos. Perto de
12 ms no total.

#docente[
O erro é comum e silencioso: nada acusa, e a leitura de volta parece
"embaralhada". Quem já viu uma vez nunca mais esquece.
]
]

#tarefa[
*Exercício 11.3.* Compare as duas memórias não voláteis quanto a: tempo de
escrita, número de fios, quantidade de bits de endereço, e o que acontece se o
dispositivo não responder.
]

#resposta[
*Interna:* cerca de 4 ms; zero fios; endereço de 8 bits em `EEADR`, portanto 256
posições; se não responder, o `while (WR)` nunca termina e o programa trava — não
há como o registrador "não estar lá".

*Externa:* cerca de 5 ms mais o tráfego; dois fios mais o terra; 7 bits de
endereço de dispositivo e mais bits de endereço interno conforme a peça; se não
responder, o mestre recebe ausência de reconhecimento e *sabe disso* — pode
tentar de novo, avisar, ou seguir sem gravar.

A diferença qualitativa está na última linha: o barramento permite que a falha
seja detectada, e o registrador não. O preço de detectar é o protocolo.
]

#tarefa[
*Exercício 11.4.* O termostato guarda o alvo e um contador de horas de
funcionamento. Proponha uma estratégia de gravação que respeite a vida útil da
memória, e justifique cada escolha.
]

#resposta[
*Alvo:* gravar apenas quando muda, e apenas depois de alguns segundos de
estabilidade — o usuário girando um botão gera dezenas de valores intermediários
que não interessam. Uma gravação por ajuste real; algumas por dia, no máximo.

*Contador de horas:* este é o caso perigoso, porque muda sozinho e para sempre.
Gravar a cada hora dá 8#h(1pt)760 escritas por ano, e o milhão de ciclos duraria
mais de um século — aceitável. Gravar a cada minuto daria dois anos, e a cada
segundo, onze dias.

Se fosse necessário gravar com mais frequência, a técnica seria distribuir as
escritas por várias posições em rodízio, multiplicando a vida útil pelo número de
posições usadas. É o princípio do nivelamento de desgaste, e é o que qualquer
cartão de memória faz internamente.

#docente[
A última parte não é exigida, mas é o gancho perfeito para os seminários dos
encontros 14 e 15: um cartão de memória é um microcontrolador dedicado a fazer
isso.
]
]

#tarefa[
*Exercício 11.5.* A folha de dados de um sensor informa que o endereço dele é
0x48. Um colega escreve `i2c_enviar(0x48)` logo após a condição de início e não
recebe reconhecimento.

(a) Que dispositivo ele endereçou, e em que sentido?

(b) O que deveria ter enviado, para escrita e para leitura?

(c) O sintoma observado é distinguível de um resistor de elevação ausente?
]

#resposta[
(a) 0x48 é `0100 1000`. Interpretado como byte de controle, os sete bits altos são
o endereço — `0100100`, ou 0x24 — e o bit menos significativo, que vale 0, é o
sentido: escrita. Ele endereçou o dispositivo 0x24 para escrita, e não existe
nenhum ali.

(b) `0x90` para escrever e `0x91` para ler, isto é, `0x48 << 1` com o bit de
sentido.

(c) *Não é distinguível pelo sintoma.* Nos dois casos falta reconhecimento. A
distinção sai do osciloscópio: sem resistor de elevação a linha não sobe até o
nível alto e as bordas ficam arredondadas ou ausentes; com o endereço errado as
formas de onda estão perfeitas e apenas o nono pulso de `SCL` encontra `SDA` em
nível alto.

#docente[
Esta é a alínea que vale a discussão. Dois defeitos de naturezas completamente
diferentes produzem o mesmo sintoma lógico, e separá-los exige olhar o *sinal*, e
não o dado. É o mesmo tipo de raciocínio do diagnóstico da serial no encontro 10 —
branco contra lixo periódico.
]
]

#nota[
*No encontro 12:* avaliação integradora II, cobrindo os encontros 7 a 11.

*E no encontro 13:* controle embarcado na prática. As peças estão todas na mesa —
uma planta que responde, um sensor que mede, uma chave que aplica potência, um
registro que atravessa o desligamento, e um enlace que leva os dados para fora.

Falta usar os números que o R10 mediu para responder à pergunta que ele levantou:
por que a temperatura oscila, e o que se faz a respeito.
]
