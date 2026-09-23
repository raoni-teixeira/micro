// R8 — Interrupções e repique
// Revisão 2026/2, alinhada à aula 7 (interrupções e ruído de contato). Substitui
// o antigo roteiro de interrupções, no formato novo.
//
// Seis tarefas com nota (8,0), previsões P1–P5 da aula 7 (2,0) e três extensões
// sem nota no fim. Sem relé: as chaves CH5 ficam desligadas.
//
// Compilação:  typst compile R8-interrupcoes.typ
//              typst compile --input gab=1 R8-interrupcoes.typ

#import "estilo.typ": *

#show: conf.with(
  titulo: "R8 — Interrupções e repique",
  subtitulo: "O hardware chama o programa, e o botão mente sobre quantas vezes foi apertado",
  modo: "roteiro",
)

// Espaço de resposta: linhas na versão do aluno, resposta no gabarito.
#let resp(n: 2, corpo) = if gab { resposta(corpo) } else {
  for i in range(n) { v(0.55em); lacuna(largura: 100%) }
}

#objetivos[
  - Fazer o hardware chamar o programa: uma base de tempo de 5 ms por interrupção, medida no osciloscópio.
  - Medir o repique de um botão real, e contar o que ele faz com uma interrupção de borda.
  - Implementar o filtro por confirmação da aula 7, e medir o que ele custa em atraso.
  - Mostrar que um sinalizador guarda "aconteceu", e não "quantas vezes".
  - Tocar o lá de 440 Hz por interrupção enquanto o display é atualizado.
]

#kit[
  #tab(columns: (auto, 1fr),
    [CH2-1 (LCD)], [ON — mostra as contagens],
    [CH5 (relés)], [*Todas em OFF* — não há relé neste curso de bancada],
    [Chaves SWITCHS (PORTB)], [OFF],
    [Botões], [`INT0` (SW12, RB0) é o botão medido; `INT1` (SW13, RB1) é o segundo, só para o osciloscópio],
    [CH3-6 (BUZZER)], [OFF até a Tarefa 6; então ON],
    [CH3-2 a CH3-5 e CH3-7], [OFF],
  )

  *A verificar antes da sessão:* o deslocamento de vetor que o bootloader do XM118
  usa, e se o projeto de exemplo do curso já traz o arquivo de ligação
  correspondente (aula 7). Se a interrupção nunca executar, é o primeiro
  suspeito. E em qual conector está RE2, o pino que marca o tique.
]

*Pontuação.* As seis tarefas somam 8,0, e as previsões P1 a P5 da aula 7,
preenchidas antes da sessão, valem 2,0. A nota de cada tarefa e de cada previsão
está na margem, ao lado dela. A seção _Se sobrar tempo_, no fim, não vale nota:
é para quem terminar antes.

#bancada[
  *Osciloscópio:* ponta em 10#sym.times, acoplamento DC, disparo *único* (single)
  na borda de descida do canal 1 para capturar o repique; base de tempo de 1 a
  2 ms/div.
]

= Previsões — entregues no início da sessão

As mesmas perguntas do fim da aula 7. Quem trouxe a folha preenchida copia aqui
as respostas; a nota é do raciocínio, não do número.

#prevista(nota: "0,4 pt")[
  *P1.* Capturando um toque no osciloscópio, quantos milissegundos de repique você
  espera ver? E quantas transições?
  #resp(n: 1)[Da ordem de 1 a 10 ms, com algumas a dezenas de transições. O número certo é o da captura.]
]

#prevista(nota: "0,4 pt")[
  *P2.* Contando eventos por toque sem filtro, quantos espera? Tocando dez vezes, o
  número se repete?
  #resp(n: 2)[Mais de um por toque, e não se repete: o repique é aleatório, e o contador conta cada borda.]
]

#prevista(nota: "0,4 pt")[
  *P3.* Com amostragem a 5 ms e confirmação de 3, qual é o atraso entre encostar no
  botão e o programa reagir? É perceptível?
  #resp(n: 1)[Entre 10 e 15 ms depois de o contato estabilizar — a primeira amostra cai em até 5 ms, e mais duas a confirmam. Imperceptível: o olho e o dedo não resolvem menos de ≈ 50 ms.]
]

#prevista(nota: "0,4 pt")[
  *P4.* Com confirmação de 10 amostras, o que melhora e o que piora? Dê os dois
  números.
  #resp(n: 2)[Melhora a imunidade: só um repique de mais de 50 ms passaria. Piora o atraso, para 45 a 50 ms, e um toque mais curto que ≈ 50 ms deixa de ser visto.]
]

#prevista(nota: "0,4 pt")[
  *P5.* O repique de dois botões diferentes da placa é o mesmo?
  #resp(n: 1)[Não: o repique é característico de cada contato, do desgaste e de como se aperta. Mede-se, não se copia.]
]

= O programa

Um programa só, para a sessão inteira. Três fontes de interrupção, um tratamento:

- *INT0*, na borda de descida de RB0: conta *toda* borda, sem filtro (`B`).
- *Timer0*, a cada 5 ms: inverte RE2, para medir o tique, e aplica o filtro por
  confirmação da aula 7 ao mesmo botão (`F`).
- *Timer1*, a cada meio período de 440 Hz: inverte RC2, o buzzer. Só é ligado na
  Tarefa 6.

O laço principal consome o sinalizador `borda` e conta os apertos que ele viu
(`A`). O display mostra os três números.

```c
#define _XTAL_FREQ 16000000UL
#include <xc.h>
#include <stdint.h>
#include "lcd.h"

#define PRECARGA_5MS  45536u          /* 65536 - 20000: 5 ms a 250 ns        */
#define PRECARGA_LA   60991u          /* 65536 - 4545: meio periodo de 440 Hz */
#define CONFIRMA      3u              /* amostras iguais para aceitar (T4)   */
#define BUZZER        0               /* 1 na Tarefa 6                        */
/* #define TAREFA()   __delay_ms(300)    -- Tarefa 5 */

volatile uint16_t brutos    = 0;      /* bordas vistas pelo INT0, sem filtro */
volatile uint16_t filtrados = 0;      /* apertos confirmados pelo filtro     */
volatile uint8_t  borda     = 0;      /* sinalizador: "houve um aperto"      */

void __interrupt() tratar(void)
{
    static uint8_t candidato = 1, iguais = 0, botao = 1;  /* so o tratamento ve */

    if (INTCONbits.INT0IF) {                  /* borda de descida em RB0 */
        INTCONbits.INT0IF = 0;
        brutos++;
    }

    if (INTCONbits.TMR0IF) {                  /* passaram 5 ms */
        INTCONbits.TMR0IF = 0;
        TMR0H = (uint8_t)(PRECARGA_5MS >> 8);
        TMR0L = (uint8_t)(PRECARGA_5MS & 0xFF);
        LATEbits.LATE2 ^= 1;                  /* marca o tique (T1) */

        uint8_t agora = PORTBbits.RB0;
        if (agora != candidato) {
            candidato = agora;
            iguais    = 1;
        } else if (iguais < CONFIRMA) {
            iguais++;
            if (iguais == CONFIRMA && candidato != botao) {
                botao = candidato;
                if (botao == 0u) {            /* pressionado, confirmado */
                    filtrados++;
                    borda = 1;
                }
            }
        }
    }

    if (PIR1bits.TMR1IF) {                    /* meio periodo do la (T6) */
        PIR1bits.TMR1IF = 0;
        TMR1H = (uint8_t)(PRECARGA_LA >> 8);
        TMR1L = (uint8_t)(PRECARGA_LA & 0xFF);
        LATCbits.LATC2 ^= 1;
    }
}

/* Leitura de 16 bits que o tratamento escreve: le duas vezes ate concordar. */
static uint16_t ler16(volatile uint16_t *p)
{
    uint16_t a, b;
    do {
        a = *p;
        b = *p;
    } while (a != b);
    return a;
}

void main(void)
{
    uint16_t aceitos = 0;             /* apertos que o laco consumiu */

    ADCON1 = 0x0F;                    /* RB0 (INT0) e RE0-RE2 digitais */
    TRISBbits.TRISB0 = 1;
    LATEbits.LATE2 = 0;  TRISEbits.TRISE2 = 0;
    LATCbits.LATC2 = 0;  TRISCbits.TRISC2 = 0;
    lcd_iniciar();

    TMR0H = (uint8_t)(PRECARGA_5MS >> 8);  TMR0L = (uint8_t)(PRECARGA_5MS & 0xFF);
    T0CON = 0x88;                     /* 16 bits, interno, sem divisor */
    INTCONbits.TMR0IF = 0;  INTCONbits.TMR0IE = 1;

    INTCON2bits.INTEDG0 = 0;          /* INT0 na borda de descida: ao apertar */
    INTCONbits.INT0IF = 0;  INTCONbits.INT0IE = 1;

    TMR1H = (uint8_t)(PRECARGA_LA >> 8);  TMR1L = (uint8_t)(PRECARGA_LA & 0xFF);
    T1CON = 0x81;                     /* 16 bits, 1:1, interno, ligado */
    PIR1bits.TMR1IF = 0;  PIE1bits.TMR1IE = BUZZER;

    INTCONbits.PEIE = 1;              /* o Timer1 e periferico */
    INTCONbits.GIE  = 1;

    for (;;) {
        if (borda) {                  /* trabalho diferido: le e zera */
            borda = 0;
            aceitos++;
        }

        lcd_posicao(0, 0);
        lcd_texto("B=");  lcd_numero(ler16(&brutos), 5);
        lcd_texto(" F=");  lcd_numero(ler16(&filtrados), 5);
        lcd_posicao(1, 0);
        lcd_texto("A=");  lcd_numero(aceitos, 5);

        /* TAREFA(); */
    }
}
```

#nota[
  O tratamento lê um pino, mexe em algumas variáveis e sai — nada de display,
  nada de divisão. `candidato`, `iguais` e `botao` são `static` e não `volatile`:
  só o tratamento os enxerga. `brutos`, `filtrados` e `borda` atravessam a
  fronteira, e por isso são `volatile`; os dois de 16 bits são lidos por `ler16`,
  porque `volatile` não os torna indivisíveis.
]

= Parte 1 — o hardware chama o programa

#tarefa(nota: "1,0 pt")[
  *Tarefa 1.* Grave o programa e meça RE2 no osciloscópio.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [Previsto], [Medido],
    [Período da onda em RE2], [#if gab [10 ms]], [],
    [Frequência], [#if gab [100 Hz]], [],
  )

  (a) Nenhuma linha do laço chama `tratar`. Quem chama, e em que instante?
  #resp(n: 2)[O hardware: ao fim da instrução em curso depois de `TMR0IF` subir, o processador empilha o PC e desvia para o vetor de interrupção. O bootloader reencaminha o vetor para o endereço da aplicação.]

  (b) No R6, o período em RD0 dependia da tarefa do laço. Aqui o laço escreve no
  display o tempo todo. O período mudou? Por quê?
  #resp(n: 2)[Não: a recarga acontece microssegundos depois do estouro, no tratamento, qualquer que seja o laço. A deriva do R6 some.]
]

= Parte 2 — o repique, medido e contado

#tarefa(nota: "1,5 pt")[
  *Tarefa 2.* Canal 1 no pino do botão `INT0` (RB0), disparo único na borda de
  descida. Aperte uma vez e congele a captura. Repita três vezes, e depois faça o
  mesmo com o botão `INT1` (RB1).

  #tab(columns: (1fr, 2.4cm, 2.4cm, 2.4cm),
    [], [Toque 1], [Toque 2], [Toque 3],
    [`INT0`: duração do repique], [], [], [],
    [`INT0`: número de transições], [], [], [],
    [`INT1`: duração do repique], [], [], [],
  )

  (a) Confere com a P1? E com a P5 — os dois botões repicam igual?
  #resp(n: 2)[A duração e o número de transições variam de toque para toque e de botão para botão. O valor típico fica em poucos milissegundos.]

  (b) Com base na maior duração medida, 5 ms de amostragem e 3 confirmações são
  suficientes? Justifique com os números.
  #resp(n: 2)[São, se o repique medido for menor que ≈ 10 ms: a confirmação exige três amostras iguais seguidas, 10 a 15 ms de nível estável, e nenhum repique desse tamanho sobrevive.]
]

#tarefa(nota: "1,5 pt")[
  *Tarefa 3.* Zere o kit. Aperte o botão `INT0` dez vezes, devagar, e registre `B`
  e `F`. Três rodadas, zerando entre elas.

  #tab(columns: (1fr, 2.4cm, 2.4cm, 2.4cm),
    [], [Rodada 1], [Rodada 2], [Rodada 3],
    [`B` (INT0, sem filtro)], [], [], [],
    [`F` (filtro, 3 × 5 ms)], [#if gab [10]], [#if gab [10]], [#if gab [10]],
  )

  (a) Confere com a P2? Por que `B` passa de dez e varia?
  #resp(n: 2)[O INT0 conta toda borda de descida, e o repique produz várias por toque — um número diferente a cada vez.]

  (b) O INT0 e o filtro leem o *mesmo* pino, no mesmo programa. Por que um conta
  errado e o outro certo?
  #resp(n: 3)[O INT0 reage a cada borda, no instante em que ela acontece. O filtro olha o pino a cada 5 ms e só aceita uma mudança que se mantenha por três amostras: o repique nunca fica estável esse tempo, e é ignorado.]
]

#conceito[
  Uma entrada de interrupção por borda é a pior forma de ler um botão mecânico: ela
  é rápida e fiel, e por isso conta o repique. A interrupção certa para um botão
  é a do *temporizador*, que amostra o pino num ritmo que o repique não
  acompanha.
]

= Parte 3 — o custo do filtro, e o limite do sinalizador

#tarefa(nota: "1,0 pt")[
  *Tarefa 4.* Troque `CONFIRMA` para 10 e grave. Faça dez toques normais, e depois
  dez toques o mais *rápidos* que conseguir.

  #tab(columns: (1fr, 3cm, 3cm),
    [], [`CONFIRMA` = 3], [`CONFIRMA` = 10],
    [`F` com toques normais], [#if gab [10]], [#if gab [10]],
    [`F` com toques rápidos], [#if gab [10]], [#if gab [menos de 10]],
  )

  Confere com a P3 e a P4? Qual é o atraso de confirmação em cada caso?
  #resp(n: 2)[Com 3, 10 a 15 ms; com 10, 45 a 50 ms. Um toque rápido fica pressionado menos que isso e não é confirmado: a imunidade foi paga com toques perdidos.]
]

#tarefa(nota: "1,0 pt")[
  *Tarefa 5.* Volte `CONFIRMA` a 3. Descomente as duas linhas de `TAREFA()`: o laço
  passa a demorar 300 ms por volta. Faça dez toques rápidos e registre `F` e `A`.

  #tab(columns: (1fr, 3cm),
    [`F` (confirmados pelo tratamento)], [],
    [`A` (consumidos pelo laço)], [],
  )

  (a) `F` e `A` deram iguais? Qual perdeu, e onde?
  #resp(n: 2)[`F` dá dez; `A` dá menos. O tratamento confirmou todos, mas `borda` é um bit: dois toques dentro da mesma volta de 300 ms levantam o sinalizador duas vezes, e o laço o consome uma vez só.]

  (b) Proponha a correção, em uma linha no tratamento e uma no laço.
  #resp(n: 2)[Trocar o sinalizador por um contador de pendentes: `pendentes++` no tratamento; no laço, consumir enquanto `pendentes` for maior que zero — com o cuidado de decrementar sem que o tratamento escreva no meio (desligando a interrupção por dois ciclos, ou lendo e zerando atomicamente).]
]

#conceito[
  Um `uint8_t` como sinalizador guarda "aconteceu", não "aconteceu duas vezes". O
  tratamento curto e o trabalho diferido continuam certos; o que a Tarefa 5
  mostra é que o canal entre os dois precisa ter a capacidade do que passa por
  ele — um bit, um contador, ou uma fila.
]

= Parte 4 — a nota que não depende da tela

#tarefa(nota: "1,0 pt")[
  *Tarefa 6.* Troque `BUZZER` para 1, ligue CH3-6 e grave (com `TAREFA()` ainda
  descomentada). O Timer1 inverte RC2 a cada 4545 ciclos, pela interrupção.

  Frequência medida em RC2: #lacuna(largura: 3cm)

  (a) A nota falha enquanto o display é atualizado, ou durante os 300 ms da
  tarefa? Por quê?
  #resp(n: 2)[Não: o Timer1 pede a interrupção no instante do estouro, e o tratamento inverte o pino ali, qualquer que seja o laço. O display e a tarefa só atrasam o laço, que não é quem gera a nota.]

  (b) A frequência medida fica um pouco abaixo de 440 Hz. De onde vem a diferença?
  #resp(n: 2)[Da recarga: entre o estouro e a escrita de `TMR1` passam a latência e as primeiras instruções do tratamento, e esses ciclos se somam a cada meio período — a mesma deriva do R6, agora de dezenas de ciclos em vez de milissegundos. Descontar esses ciclos da pré-carga corrige.]
]

= Armadilhas frequentes

#tab(columns: (1fr, 1.3fr),
  [Sintoma], [Causa provável],
  [O tratamento nunca executa], [Vetor da aplicação não bate com o do bootloader; ou `GIE` em 0],
  [O Timer1 não interrompe], [Faltou `PEIE = 1`: ele é periférico],
  [Programa "trava" logo ao ligar], [Um indicador não foi zerado no tratamento: ele volta a ser chamado para sempre],
  [`B` não conta], [`INT0IE` em 0, ou `ADCON1` não é `0x0F` e RB0 (AN12) está analógico],
  [Funciona em depuração, trava no normal], [Variável compartilhada sem `volatile`],
  [Número absurdo, raro, no display], [Leitura de 16 bits sem `ler16`: os dois bytes vieram de valores diferentes],
)

= Entrega

#tarefa[
  As tabelas das Tarefas 1 a 6 e as três capturas de repique da Tarefa 2.

  Responda também:

  (a) Divida o programa em "no tratamento" e "no laço". Por que o display e a
  divisão ficaram do lado do laço?
  #resp(n: 2)[No tratamento: ler pino, rearmar temporizador, incrementar, levantar sinalizador — o que é curto e de duração constante. Display e divisão são longos e de duração variável: no tratamento, atrasariam a nota e o filtro.]

  (b) O R6 mediu a deriva da recarga por consulta. Qual das tarefas de hoje mostra
  que ela sumiu, e qual mostra que ela não sumiu por completo?
  #resp(n: 2)[A Tarefa 1 (o período de RE2 não depende do laço) e a Tarefa 6(b) (a nota fica abaixo de 440 Hz pelos ciclos da latência).]
]

#criterio[
  Previsões P1 a P5: 0,4 cada, 2,0 no total, pelo raciocínio.

  Tarefa 1 (base de tempo por interrupção): 1,0. Tarefa 2 (repique no
  osciloscópio): 1,5. Tarefa 3 (INT0 contra filtro): 1,5. Tarefa 4 (custo do
  filtro): 1,0. Tarefa 5 (o sinalizador que perde): 1,0. Tarefa 6 (a nota por
  interrupção): 1,0.

  Na Tarefa 3(b), a resposta completa diz que o filtro amostra num ritmo que o
  repique não acompanha. "O filtro tira o ruído" vale metade.

  As extensões E1 a E3 não pontuam.
]

= Se sobrar tempo

#opcional[
  *E1 — o `volatile`, na prática.* Tire o `volatile` de `borda`, compile com
  otimização e grave. O laço ainda vê os apertos?
  #resp(n: 1)[Depende do compilador: com otimização, a leitura de `borda` pode sair do laço e o `A` para de contar. Se continuar funcionando, não prova nada — o defeito é intermitente por natureza.]
]

#opcional[
  *E2 — o filtro no simulador.* Com a captura da Tarefa 2 convertida em amostras de
  5 ms (1 = solto, 0 = apertado), rode a função de filtro no PICSimLab ou em
  Python e confira quantos apertos ela aceita. O simulador não tem repique; a
  captura dá a ele o repique da sua bancada.
  #resp(n: 1)[Um aperto por toque, desde que o repique capturado seja menor que o tempo de confirmação.]
]

#opcional[
  *E3 — o lá afinado.* Desconte da pré-carga os ciclos entre o estouro e a escrita
  de `TMR1` (medidos pela diferença entre 440 Hz e a frequência da Tarefa 6) e
  meça de novo.
  #resp(n: 1)[A frequência se aproxima de 440 Hz; o resíduo é a variação da latência, não o seu valor médio.]
]

#nota[
  No R9: o estágio de potência, e a pergunta de por que o processador reiniciou.
  No R11, a serial transmite pela mesma estrutura de hoje — o tratamento entrega
  um byte, o laço prepara a linha.
]
