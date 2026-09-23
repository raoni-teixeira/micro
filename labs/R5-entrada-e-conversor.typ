// R5 — O pino que não responde, e o conversor
// Revisão 2026/2, após medidas na bancada:
//   - ADCON1 herdado = 0x07 (bootloader grava PBADEN = 0): RB0–RB4 nascem digitais.
//   - Botão INT0 = SW12 em RB0, inferior direito da seção PUSH BUTTONS,
//     vizinho do RESET (SW9); LEDs de PORTD ativos em nível baixo.
//
// Focado exclusivamente no conversor e na convivência digital/analógica: sete
// tarefas com nota (8,0) e três extensões sem nota no fim.
//
// Compilação:  typst compile R5-entrada-e-conversor.typ
//              typst compile --input gab=1 R5-entrada-e-conversor.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R5 — O pino que não responde, e o conversor",
  subtitulo: "A fronteira analógico/digital, quantização e o que a média não conserta",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}

#objetivos[
  - Explicar por que o botão responde sem configuração, descobrindo o estado que o bootloader deixa no conversor.
  - Provocar e diagnosticar o sintoma do botão que não responde, e corrigi-lo pela causa.
  - Medir o degrau do conversor na própria bancada e comparar com o valor derivado.
  - Converter o código de dez bits em décimos de grau, sem ponto flutuante.
  - Distinguir ruído aleatório de erro de quantização, e decidir o que a média resolve.
]

#kit[
  #tab(columns: (auto, 1fr),
    [CH2-1 (LCD)], [ON — o display do R4 continua],
    [Chaves SWITCHS (PORTB)], [OFF],
    [Botão], [SW12, marcado `INT0`, em *RB0* — ativo em nível baixo; inferior direito, ao lado do `RESET`],
    [LEDs de PORTD], [ativos em nível baixo: `LATD0 = 0` acende],
    [CH5-3 e CH5-4], [OFF],
    [CH1-7 (TEMP)], [ON — LM35 em RA0/AN0],
    [CH1-1, CH1-5 e CH1-6], [OFF — também chegam ao RA0],
  )

  *A verificar antes da sessão:* a tensão real da alimentação, medida com o
  multímetro. O fundo de escala do conversor é a própria alimentação, e todo
  número da Parte 2 depende dela. Para a tabela completa de `PCFG` e o mapa de
  registradores, consulte a *folha de referência do ADC* na página do curso.
]

*Pontuação.* As sete tarefas somam 8,0, e a folha de previsões entregue
preenchida vale 2,0. A nota de cada tarefa está na margem, ao lado dela. A seção
_Se sobrar tempo_, no fim, não vale nota: é para quem terminar antes.

= Parte 1 — o botão que responde, e por quê

#bancada[
  *Onde fica o botão, e em que pino ele chega.* Na seção `PUSH BUTTONS`, na
  metade inferior da placa, seis botões em três linhas de dois. O `INT0` (SW12) é
  o *inferior direito* — e o vizinho imediato dele, à esquerda, é o `RESET` (SW9):

  #tab(columns: (auto, 1fr, 1fr),
    [], [Coluna esquerda], [Coluna direita],
    [Linha 1], [`CH0` (SW11)], [`INT2` (SW14)],
    [Linha 2], [`TMR1` (SW10)], [`INT1` (SW13)],
    [Linha 3], [*`RESET` (SW9)*], [*`INT0` (SW12)*],
  )

  Eletricamente, o SW12 chega ao *RB0* do microcontrolador — o mesmo pino que o
  datasheet também chama de *AN12*. Guardem esses dois nomes para o mesmo pino: é
  disso que trata a Parte 1 inteira.

  E cuidado com o vizinho. Apertar o `RESET` sem querer reinicia o programa, e o
  sintoma disso se parece com um defeito de código — o contador zera, o display
  volta ao início, o LED apaga. Antes de culpar o programa, confira qual dos dois
  botões o seu dedo alcançou.
]

#tarefa(nota: "0,5 pt")[
  *Tarefa 1.* Complete o programa abaixo, para que o LED de RD0 acenda enquanto o
  botão `INT0` estiver pressionado. *Não escreva nada em `ADCON1`* — é justamente
  o que esta parte vai investigar.

  ```c
  #include <xc.h>

  void main(void)
  {
      /* Nenhuma linha de ADCON1 aqui. */
      LATDbits.LATD0   = 1;   /* LED apagado: PORTD é ativo em nível baixo */
      TRISDbits.TRISD0 = 0;   /* RD0 como saída                            */
      TRISBbits.TRISB0 = 1;   /* RB0 como entrada: é lá que chega o SW12   */

      while (1) {
          /* Uma linha só, aqui: o botão pressionado leva RB0 a 0,
             e o LED aceso pede LATD0 = 0. */
      }
  }
  ```

  Grave, pressione o botão, e registre:

  #tab(columns: (1fr, 5.5cm),
    [O que a previsão P1 dizia], [],
    [O que o LED faz com o botão solto], [#if gab [apagado]],
    [O que o LED faz com o botão pressionado], [#if gab [aceso]],
  )
]

#resposta[
  A linha que falta é uma cópia direta:
  ```c
  LATDbits.LATD0 = PORTBbits.RB0;
  ```
  Vale perguntar em voz alta por que não há `!`. Botão e LED são ativos em nível
  baixo, e as duas inversões se cancelam — quem escreveu `!` fez o LED acender
  quando o botão está solto, e vai descobrir isso na bancada.

  O que importa é que o programa funciona *sem nenhuma configuração do conversor*.
  É essa surpresa que a Tarefa 2 vai explicar.
]

O datasheet diz que RB0 é também o canal analógico AN12, e que um canal
analógico habilitado não lê nível lógico. Mesmo assim, o botão respondeu.
Alguém configurou esse pino antes de você.

#tarefa(nota: "1,0 pt")[
  *Tarefa 2.* Descubra o que o conversor herdou. Grave um programa cuja
  *primeira* linha copie `ADCON1` para uma variável e a mostre nos LEDs:

  ```c
  unsigned char herdado = ADCON1;  /* 1a linha */
  LATD  = (unsigned char)~herdado; /* aceso = 1 */
  TRISD = 0x00;
  while (1);
  ```

  #tab(columns: 9,
    [bit], [7], [6], [5], [4], [3], [2], [1], [0],
    [nome], [—], [—], [`VCFG1`], [`VCFG0`], [`PCFG3`], [`PCFG2`], [`PCFG1`], [`PCFG0`],
    [lido], ..(if gab { ([0], [0], [0], [0], [0], [1], [1], [1]) } else { range(8).map(_ => []) }),
  )

  Valor de `ADCON1` em hexadecimal: #if gab [`0x07`] else [#lacuna()]

  Com a tabela de `PCFG` (na folha de referência do ADC): quais canais estão
  analógicos e quais digitais? Em qual grupo está RB0 (AN12)?
  #resp[AN0–AN7 analógicos (RA0–RA3, RA5, RE0–RE2); AN8–AN12 digitais, o que inclui RB0 a RB4. RB0 é digital, e por isso o botão respondeu.]

  O datasheet dá *dois* valores de `PCFG` após o reset, e quem escolhe entre eles
  é o bit de configuração `PBADEN`. Qual dos dois vocês leram? Então quanto vale
  `PBADEN` neste kit?
  #resp[`PBADEN = 1` faz `PCFG = 0000` (tudo analógico); `PBADEN = 0` faz `PCFG = 0111`. Lemos `0111`: `PBADEN = 0`.]

  O que os bits `VCFG` dizem sobre a referência do conversor?
  #resp(n: 1)[`VCFG1:VCFG0 = 00`: referências em VDD e VSS. O fundo de escala é a própria alimentação.]
]

#conceito[
  Vocês não escreveram `PBADEN`, e não poderiam: os bits de configuração
  pertencem ao bootloader, e o `#pragma config` da aplicação é ignorado. Quem
  gravou o bootloader escolheu `PBADEN = 0`, e o próprio reset carregou `0111`
  em `PCFG`. Não há código escondido escrevendo `ADCON1`: há um bit escolhido por
  outra pessoa, e o hardware obedecendo a ele.

  É o princípio do encontro 0 pela terceira vez — _o código que veio antes do
  seu_ —, agora na forma mais traiçoeira: um programa que *funciona* por causa de
  uma decisão que você não tomou, não vê e não controla.
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 3.* Agora provoque o sintoma. Acrescente, antes do laço da Tarefa 1:

  ```c
  ADCON1 = 0x00;   /* tudo analógico, até AN12 */
  ```

  Antes de gravar, preveja o que o LED fará nas duas posições do botão. Depois
  grave e registre:

  #tab(columns: (1fr, 5.5cm),
    [Previsão], [],
    [Botão solto], [#if gab [aceso]],
    [Botão pressionado], [#if gab [aceso]],
  )

  Antes de corrigir, meça: com o multímetro, verifique a tensão no pino do botão
  nas duas posições.

  O pino está mudando de tensão? #if gab [Sim: ≈ 5 V solto, ≈ 0 V pressionado.] else [#lacuna(largura: 5cm)]

  Então o defeito está no circuito ou no programa? #if gab [No programa — na configuração do pino.] else [#lacuna(largura: 4cm)]
]

#conceito[
  O pino muda de tensão e o programa lê sempre zero. O botão funciona, o fio
  funciona, e a leitura não.

  A causa está entre os dois: quando o canal analógico de um pino está
  habilitado, *o buffer de entrada digital é desligado*, e a leitura de `PORTB`
  devolve 0 independentemente do que houver no fio. Como o LED acende com 0, ele
  fica aceso o tempo todo: o sintoma aparece como "o LED não apaga", e não como
  "o botão não funciona".
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 4.* Troque `0x00` por `0x0F`, grave, e confirme que o botão voltou.

  Neste kit, o programa da Tarefa 1 funcionava sem essa linha. Por que, então,
  o padrão do curso passa a ser escrever `ADCON1 = 0x0F` na primeira linha?
  #resp(n: 3)[Porque sem ela o programa depende de um bit que o aluno não controla. O mesmo código num PIC18F4550 novo, gravado pelo programador e sem bootloader, falha: bit de configuração apagado vale 1, `PBADEN = 1`, RB0 nasce analógico. E no próprio kit o sintoma aparece assim que algum trecho — tipicamente o driver do conversor da Parte 2 — escreve em `ADCON1` um valor que habilita canais demais.]

  Com o valor herdado `0x07`, cite dois pinos do kit que *ainda* sofreriam o
  sintoma se fossem usados como entrada digital.
  #resp(n: 1)[Quaisquer de RA0–RA3, RA5, RE0–RE2 (AN0–AN7).]

  Por que este defeito é difícil de encontrar sozinho? Cite uma hipótese errada
  que um aluno testaria antes de chegar na causa.
  #resp(n: 2)[Botão defeituoso; chave DIP errada; `TRIS` errado; lógica invertida. É difícil porque o circuito está perfeito e a linha culpada pode estar longe — em outro arquivo, ou em outro programa.]
]

E o padrão do curso a partir de agora: *tudo digital na primeira linha*, e o
analógico se declara explicitamente depois, habilitando só o canal que se vai
usar. Não é superstição: é não depender do que veio antes.

= Parte 2 — o conversor, em bruto

#tarefa(nota: "1,0 pt")[
  *Tarefa 5.* Com o driver fornecido, mostre no display o valor bruto do
  conversor, de 0 a 1023, atualizado a cada 500 ms. Confira que o driver
  habilita *só* o AN0 (`ADCON1 = 0x0E`) — a Tarefa 4 explica por quê.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Previsto (P2)], [Observado],
    [Código à temperatura ambiente], [#if gab [≈ 55–65]], [],
    [Código com o dedo no sensor, 10 s], [#if gab [sobe alguns códigos]], [],
    [Variação por grau (P4)], [#if gab [≈ 2 códigos/°C]], [],
  )
]

#conceito[
  Da referência de 5 V e dos dez bits: 1 LSB = 5000/1024 ≈ 4,88 mV. E o LM35
  entrega 10 mV por grau, então 1 LSB ≈ 0,488 °C.

  Meio grau. Este é o degrau da sua bancada, e ele não melhora com código melhor.
]

#nota[
  O manual informa que o LM35 fica montado junto à resistência de aquecimento.
  Ele mede a temperatura do conjunto sensor-resistência, e não a do ar da sala —
  uma diferença de alguns graus para mais é esperada, e não é erro de conversão.
  Comparar com um termômetro da sala e concluir que "a conta está errada" é o erro
  que este parágrafo existe para evitar.
]

= Parte 3 — a conversão, sem ponto flutuante

#conceito[
  O LM35 entrega 10 mV por grau, e 1 mV equivale a 0,1 °C. Logo o valor em
  milivolts já é o valor em décimos de grau, e não é preciso converter duas
  vezes:
  #align(center)[décimos de grau = código · 625/128]
  A fração é exata, e 128 é potência de dois — o que transforma a divisão num
  deslocamento.
]

#tarefa(nota: "2,0 pt")[
  *Tarefa 6.* Implemente e mostre a temperatura no formato `NN.N C`, com largura
  fixa — como o R4 estabeleceu.

  ```c
  int16_t adc_para_decimos(uint16_t leitura)
  {
      uint32_t acumulador = (uint32_t) leitura * 625UL;
      return (int16_t)(acumulador >> 7);
  }
  ```

  (a) Por que o acumulador precisa ser de 32 bits? Calcule o maior produto
  possível e compare com 65535.
  #resp[1023 · 625 = 639 375, quase dez vezes 65 535.]

  (b) A partir de que temperatura o defeito apareceria, se o acumulador fosse de
  16 bits?
  #resp[Estoura quando código · 625 > 65 535, isto é, código ≥ 105. Código 105 ≈ 512 mV ≈ 51,2 °C; ali a leitura cai para ≈ 0,0 °C e volta a subir.]

  (c) Troque o `uint32_t` por `uint16_t` de propósito, grave, e aqueça o sensor
  até passar do ponto que você calculou em (b). Registre o que a tela mostrou, e
  compare com a sua previsão.
  #resp(n: 2)[A temperatura exibida despenca para perto de 0,0 °C e volta a subir, no código previsto em (b).]
]

#atencao[
  Repare no que o programa *não* fez na alínea (c): não travou, não reiniciou e
  não avisou. Ele continuou exibindo um número com toda a confiança. É o modo de
  falha mais comum de aritmética inteira em sistema embarcado, e vocês vão
  reconhecê-lo pelo resto da vida.
]

= Parte 4 — o ruído, e o que a média não conserta

#tarefa(nota: "1,5 pt")[
  *Tarefa 7.* Com o kit imóvel e sem tocar no sensor, observe o último dígito por
  trinta segundos.

  Previsão P3 dizia quantos códigos distintos? #lacuna(largura: 2cm) \
  Quantos você contou? #lacuna(largura: 2cm)

  A oscilação observada é compatível com 1 LSB?
  #resp(n: 1)[Tipicamente dois códigos adjacentes: a exibição alterna cerca de 0,5 °C, que é 1 LSB.]

  Agora implemente a média de oito amostras e observe de novo.

  ```c
  uint16_t adc_media(uint8_t n_pot2)
  {
      uint32_t soma  = 0;
      uint16_t total = (uint16_t)(1u << n_pot2);
      for (uint16_t i = 0; i < total; i++) {
          soma += adc_amostra();
      }
      return (uint16_t)(soma >> n_pot2);
  }
  ```

  A oscilação diminuiu? Desapareceu? E por que o número de amostras é potência de
  dois?
  #resp[Diminui se o ruído for aleatório; não desaparece se a tensão estiver entre dois códigos. Potência de dois transforma a divisão em deslocamento.]
]

#conceito[
  A média reduz o ruído aleatório, que é o que faz o dígito oscilar. Ela não
  reduz o erro de quantização, que é sistemático: se a tensão real cai entre dois
  códigos, nenhuma quantidade de médias inventa o valor intermediário.

  E há um caso que costuma surpreender: se a leitura for perfeitamente estável, a
  média não melhora nada — oito amostras idênticas têm média igual a elas mesmas.
  Um conversor limpo demais não pode ser melhorado por média.

  Distinguir essas duas fontes de erro é o que separa quem filtra por hábito de
  quem filtra por motivo.
]

= Entrega

#tarefa[
  As tabelas das Tarefas 2 e 5; o registro do sintoma provocado na Tarefa 3;
  o registro do estouro provocado na Tarefa 6; a contagem de códigos distintos da
  Tarefa 7.

  Responda também:

  (a) A partir do valor de `ADCON1` que você leu, explique por que o botão
  respondia sem nenhuma configuração, e por que parou de responder com
  `ADCON1 = 0x00`. Descreva a causa em termos do que existe atrás do pino, e não
  em termos de "faltava uma linha".
  #resp(n: 3)[`PBADEN = 0` (bootloader) faz o reset carregar `PCFG = 0111`: RB0 (AN12) nasce digital e o buffer de entrada está ligado. Com `0x00`, AN12 vira analógico, o buffer digital é desligado e a leitura devolve 0 qualquer que seja a tensão no fio.]

  (b) A tensão de alimentação medida no início alimenta o PIC e o LM35, e serve
  de referência para o conversor. Se na sua bancada ela mediu 4,80 V em vez de
  5,00 V, o degrau real do conversor é maior ou menor que 4,88 mV? O que acontece
  com a temperatura exibida?
  #resp(n: 2)[Menor: $4800 / 1024 approx 4,69$ mV por código. Como o cálculo da Tarefa 6 assume 5,00 V (fração 625/128), o conversor entrega um código cerca de 4% maior para a mesma tensão, e a temperatura exibida fica falsamente mais alta que a real.]

  (c) Você mediu quantos códigos distintos com o sistema parado. A média de oito
  melhorou? Se não melhorou, o que isso diz sobre o ruído da sua bancada?
  #resp(n: 2)[Se não melhorou, o ruído aleatório é menor que 1 LSB e o que resta é quantização.]
]

#criterio[
  Previsões preenchidas *antes* da sessão: 2,0.

  Tarefa 1 (o botão que responde): 0,5. Tarefa 2 (o valor herdado): 1,0. Tarefas
  3 e 4 (provocar, medir e corrigir): 2,0 — é a fronteira do digital com o analógico,
  e a nota está no diagnóstico, não na correção. Tarefa 5 (código bruto e LSB):
  1,0. Tarefa 6 (décimos de grau e o estouro provocado): 2,0. Tarefa 7 (ruído e
  média de oito): 1,5.

  Na Tarefa 4 e na alínea (a) da entrega, a resposta completa nomeia o buffer de
  entrada desligado. Dizer "faltava configurar" não vale a nota: é a descrição do
  conserto, não da causa.

  As extensões E1 a E3 não pontuam. Se a turma render, E3 é a que vale mais a
  pena puxar em voz alta — é o número que justifica a decisão do R0.
]

= Se sobrar tempo

#opcional[
  *E1 — a borda, de perto.* Com o osciloscópio no pino do botão `INT0`, aperte e
  solte devagar, observando a transição. A borda é limpa? Descreva o que vê entre
  os dois níveis.
  #resp[Não: a transição leva tempo finito e o contato ricocheteia, produzindo várias bordas.]
]

#opcional[
  *E2 — o custo da média.* Com um pino auxiliar levantado antes e baixado depois,
  compare o tempo de uma leitura simples e o de uma média de oito.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Tempo], [Ciclos],
    [Uma conversão], [], [],
    [Média de oito], [], [],
    [Atualização de tela (do R4)], [], [],
  )

  Qual das três domina o laço? Vale a pena fazer média de oito?
  #resp[A atualização de tela, na casa dos milhares de ciclos. A média de oito fica em torno de oito conversões com seus tempos de aquisição — pequeno perto de uma atualização de tela, e portanto vale a pena quando o ruído justificar.]
]

#opcional[
  *E3 — o custo da representação.* Compile duas versões do mesmo programa: uma
  com a conversão inteira da Tarefa 6 e outra com

  ```c
  float temp = leitura * 5000.0f / 1024.0f / 10.0f;
  ```

  Compare o tamanho do programa no arquivo de mapa gerado pela compilação.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Inteira], [Com float],
    [Bytes de programa], [], [],
    [Percentual dos 32 kB], [], [],
  )

  O número que sai daqui é o que justifica, retroativamente, a decisão do R0 de
  representar temperatura como `int16_t` em décimos de grau. Não foi preferência
  estética nem purismo: é o preço medido, no seu compilador, do tipo que parecia
  mais natural.
]

#nota[
  No R6: o PWM, e o mesmo sinal com dois significados. A ventoinha vai ler a razão
  cíclica como energia, e o buzzer vai ler a frequência como nota — com o mesmo
  código, mudando só uma chave. E uma descoberta desconfortável: o módulo de PWM
  do chip não alcança o lá de 440 Hz que vocês tocaram no R3.
]
