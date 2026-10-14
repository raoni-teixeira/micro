# Replanejamento do curso de Microcontroladores — 2027/1

DENE/UFMT — Raoni F. S. Teixeira
Rascunho de trabalho. Revisar antes de virar ementa.

---

## 1. Motivação

Após 3 dos 16 encontros de 2026/2, ficou claro que o início do curso mistura
apresentação, arquitetura e linguagem C sem um fio condutor. O replanejamento
adota o **simulador `pic18.py` como espinha dorsal dos quatro primeiros
encontros**: cada aula abre uma camada dele, e cada camada aberta é
imediatamente confrontada com a bancada.

Arco pedagógico da abertura:

> **usa o simulador (0) → abre a memória dele (1) → abre a execução (2) →
> confronta com um periférico real (3)**

---

## 2. Decisões travadas

### Encontro 0 — Como se programa um microcontrolador

Não é aula só de regras. Tem conteúdo e tem demonstração.

**Componentes:**

- Regras, formato, avaliação, páginas do curso, calendário. (~30 min)
- **Demonstração dupla:** o mesmo pisca-LED rodando em (a) PIC18F4550 nu na
  protoboard — chip, alimentação, desacoplamento, resistor, LED — e (b) na
  XM118. Mensagem: *é a mesma coisa; uma tem quarenta periféricos soldados em
  volta.* A protoboard responde visualmente "o que é um microcontrolador"
  melhor do que qualquer slide, justamente porque o kit esconde isso.
- **Caminho Python → C → micro.** Mesma lógica escrita nas três formas, com o
  simulador como ponte. Escopo máximo: piscar um LED. Nada além disso.

**Decisões de conteúdo:**

- **Não usar `__delay_ms` no encontro 0.** É macro, exige constante em tempo de
  compilação, e explicar isso consome 15 min de um assunto que não é o assunto.
  Usar laço vazio contado: `for (i = 0; i < N; i++);`
  O período fica *deliberadamente desconhecido*. No encontro 2, com
  Tcy = 250 ns e contagem de ciclos, o aluno volta e calcula o valor que na
  semana 0 apenas chutou. A dívida é quitada no R3, na bancada.
- **Dois caminhos de gravação aparecem já na semana 0.** O chip nu não tem
  bootloader — a demo exige o MPLAB Snap. Não esconder: *"existem duas formas
  de colocar código lá dentro; vocês vão usar a fácil, e eu vou mostrar a que
  revela o que a fácil esconde."*

**Riscos:**

- Semana 0 tem matrícula em movimento. O material de C precisa estar publicado
  na página do curso desde o primeiro dia, para quem chegar atrasado não perder
  o alicerce.

---

### Encontro 1 — Memória e datasheet

Definir microcontrolador e ir direto ao datasheet, seção de organização de
memória.

**Achado central (descoberta, não exposição):** o endereço de dados tem 12 bits
(3 dígitos hexa), mas a instrução carrega só 8. O aluno deriva o **BSR** dessa
conta. Na sequência vêm:

- região não implementada (0x800–0xEFF, lê 0);
- SFRs em 0xF00–0xFFF;
- access bank de 96 bytes como atalho (e o `,c` do BSF/BCF).

Isso justifica hexa e binário sem motivação artificial: são os dígitos do
endereço.

**Codificação em aula:** distribuir o **esqueleto da classe de memória com os
testes prontos** (asserts ou pytest). Escrever do zero em 2 h com turma que
nunca viu arquitetura não fecha; preencher lacunas com feedback imediato fecha.

Largura de barramento entra aqui, de graça: 12 bits ⇒ tamanho do espaço
endereçável.

---

### Encontro 2 — PC e o ciclo de busca-execução

Fecha a arquitetura. Ao final do encontro o micro do simulador **executa** e os
pinos ligam e desligam.

Detalhes que dão liga:

- PC de 21 bits com LSB fixo em 0;
- palavra de 16 bits em memória endereçada por byte;
- **reset em 0x0000**, fixo em hardware — *não* o menor endereço presente no
  HEX (divergem em aplicação com offset de bootloader; isso já causou bug no
  simulador);
- instruções de duas palavras.

Com `BSF / BCF / MOVLW / MOVWF / GOTO / NOP` já se pisca um LED.

**O pino é só um endereço:** escrever em 0xF8C acende o LED. É neste ponto que
"LAT antes de TRIS" deixa de ser regra decorada e passa a ser consequência.

Aqui também se paga a dívida do encontro 0: contagem de ciclos, Tcy = 250 ns,
custo de desvio tomado (2 ciclos) e de salto condicional sobre instrução de
duas palavras (3 ciclos).

---

### Encontro 3 — Interfaceamento paralelo e display

**Título:** Interfaceamento Paralelo e Display — o controlador HD44780 e o custo
da espera.

**Objetivos (texto aprovado):**

- Reconhecer um barramento paralelo como um contrato de temporização entre
  linhas de dado, de endereço e de habilitação — e distingui-lo do acionamento
  direto de pino do encontro 2.
- Descrever a organização do controlador HD44780: memória de exibição, gerador
  de caracteres e a separação entre registrador de instrução e registrador de
  dados.
- Implementar a comunicação em quatro bits justificando cada atraso da sequência
  de inicialização a partir do datasheet, e não por cópia.
- Estimar em ciclos de máquina o tempo consumido por uma atualização de tela e
  reconhecer o display como o periférico mais lento do sistema.
- Aplicar estratégias de atualização que evitam tremulação e reduzem o bloqueio
  do processador.

**Por que funciona:** o par IR/DR é a mesma ideia dos SFRs do encontro 1
(registrador acessível por um endereço), realizada por outro mecanismo (linha RS
em vez de barramento de endereços). E "custo da espera em ciclos" continua
diretamente o encontro 2. A aula não só expande — fecha duas voltas.

**Pontos de atenção:**

- **Conflito de PORTD.** Se o LCD compartilha PORTD com o barramento de LEDs e
  as linhas de relé, cada escrita de dado chaveia relé. **CH5-3 e CH5-4
  desligados viram pré-requisito do roteiro**, não recomendação. Verificar
  serigrafia antes de escrever o R4.
- **A sequência de inicialização é a parte cara do tempo de aula.** Enviar 0x3
  três vezes existe porque o estado do controlador no power-up é desconhecido —
  é ressincronizar uma máquina de estados cega. Excelente momento pedagógico e
  justifica o objetivo "a partir do datasheet, não por cópia", mas consome tempo
  real. Reservar espaço.

**Display antes de ADC:** decidido. O LCD é a saída de depuração de tudo que vem
depois; a aula de ADC melhora muito quando o aluno lê o número na tela em vez de
piscar LED em binário.

---

## 3. Mapa dos 16 encontros (proposta)

Encontros 0–3 travados. De 4 em diante é proposta e precisa de revisão.

São **16 encontros de teoria e 16 de laboratório**. O laboratório passa a
**implementar a teoria da semana anterior**, não a do mesmo dia (ver §3.1).

| # | Teoria | Lab | Miniteste |
|---|--------|-----|-----------|
| 0 | Como se programa um micro (Python→C, demo protoboard + XM118) | R0 — C, do PC ao micro; binário e hexa | — |
| 1 | Memória e datasheet (BSR, access bank, mapa) | R1 — o kit XM118: componentes, medidas, bits | M1 |
| 2 | PC e ciclo busca-execução; pino como endereço | R2 — classe de memória em Python | M2 |
| 3 | Barramento paralelo e HD44780 | R3 — LED, atraso e frequência (osciloscópio) | M3 |
| 4 | **Entrada digital: o pino como sensor** (pull-up, Schmitt, PBADEN, repique, debounce por varredura) | R4 — display HD44780 em 4 bits | M4 |
| 5 | Aquisição analógica: ADC e LM35 | **R5 — entrada digital na protoboard: chip nu, pull-up, repique no osciloscópio** | M5 |
| 6 | Temporizadores e razão cíclica | R6 — ADC e LM35 no LCD | M6 |
| 7 | **Avaliação integradora I** (teoria) | R7 — PWM no cooler | — |
| 8 | Interrupções: o mesmo botão, sem varredura | **Avaliação prática I** (bancada) | M8 |
| 9 | Estágio de potência e atuadores | R8 — teclado matricial e interrupção | M9 |
| 10 | Controle liga-desliga e histerese | R9 — aquecedor e relé | M10 |
| 11 | Comunicação serial | R10 — termostato liga-desliga + oscilação e acionamentos/hora | M11 |
| 12 | Barramento serial síncrono: I2C e memória não volátil | R11 — telemetria UART | M12 |
| 13 | **Avaliação integradora II** (teoria) | R12 — setpoint na EEPROM interna e na I2C | — |
| 14 | Controle embarcado na prática: do liga-desliga ao PI, e onde entra IA | **Avaliação prática II** (bancada) | — |
| 15 | **Seminários comparativos (duplas)** + encerramento | R13 — sintonia PI contra planta simulada, validação na bancada | — |

Contagem: **R0–R13 = 14 roteiros e 2 avaliações práticas em 16 slots.**
R0 e R1 são introdutórios e **sem nota**.

**Custo da inserção do encontro 4.** A entrada digital ganhou um encontro de
teoria e um roteiro próprio (antes dividia o R5 com o ADC). O slot veio de duas
fontes:

- **Seminários em um encontro só (15)**, em vez de dois. Viável se o número de
  duplas couber em uma sessão; **confirmar com o tamanho da turma** antes de
  travar.
- **A folga de laboratório desapareceu.** O plano B do termostato passa a ser o
  que antes era a segunda linha: se o R10 atrasar, o **R13 vira demonstração
  conduzida** no encontro 15 (a sintonia roda em Python de qualquer jeito), e o
  slot é usado para fechar o termostato.

Alternativa, se os seminários precisarem de dois encontros: fundir 9 (potência)
e 10 (liga-desliga) em uma aula, com potência como pré-leitura.

### 3.0 Os dois roteiros introdutórios

**R0 — C, do PC ao micro (sem nota).** Mesma lógica em Python e em C, com o
simulador como ponte. Escopo máximo: piscar um LED. Binário e hexa entram aqui
como representação, e os operadores bit a bit aparecem em C. Atraso por laço
contado, sem `__delay_ms`. Fecha com toolchain, SW9 e bootloader — o aluno sai
com código gravado no kit.

**R1 — o kit XM118 (sem nota).** O aluno **constrói a tabela da camada placa**
(§8) em vez de recebê-la pronta. Primeira parte, **placa desligada**:
multímetro em continuidade para mapear cada chave DIP até o pino do PIC e até o
periférico que ela conecta (LED, botão, LCD, relé, sensor). Segunda parte,
placa ligada: chaves e LEDs como leitura e escrita de bits — a máscara aparece
com algo físico para mascarar —, e medida com osciloscópio. É também onde entra
a segurança de bancada — garra de terra nunca nos pontos de 12 V (LAMP,
HEATER, COOLER), SW2 e SW3 não pressionadas durante experimentos com atuadores.

Efeito colateral: as pendências de serigrafia (CH4-7/CH4-8, CH5-3/CH5-4, §4.3)
viram atividade da turma, e a tabela consolidada vira o `placa_xm118.h` (§8).

Os dois absorvem a folga de matrícula das duas primeiras semanas e permitem que
o aluno erre antes de qualquer nota.

### 3.1 O laboratório atrasa uma semana

Consequência de ter dois roteiros introdutórios na frente: R2 implementa a
teoria do encontro 1, R3 a do encontro 2, e assim por diante.

Isso **quebra a regra de 2026/2** ("teoria e lab no mesmo dia") e precisa ser
assumido explicitamente, não descoberto no meio do semestre. O saldo é
positivo: o aluno chega na bancada com uma semana de decantação, e o miniteste
da semana seguinte já pode cobrar o que ele *fez*, não só o que ouviu.

**As oficinas de 2026/2 deixam de existir como slots separados.** O conteúdo de
binário, hexa e máscaras se dissolve entre R0 (bits em C) e R1 (bits medidos no
kit) — que é onde há algo concreto para mascarar. Não há oficina 2.

**Display antes de ADC, preservado.** Com a entrada digital no meio, a ordem
fica display (R4) → entrada digital (R5) → ADC (R6). O ADC chega com o LCD
pronto para mostrar o número e com o pino já entendido como entrada.

### 3.2 As duas avaliações práticas

Novidade que os 16 slots de bancada permitem: hoje as integradoras são só
teóricas, e a prática — metade do curso — nunca é avaliada diretamente.

- **Avaliação prática I** (encontro 8): cobre R0–R7. Bancada com tarefa fechada:
  ler um botão ou um valor, mostrar no display, acionar uma saída.
- **Avaliação prática II** (encontro 14): cobre R8–R12, com o termostato como
  objeto.

Elas caem uma semana depois das integradoras teóricas (7 e 13), o que dá ao
aluno a semana intermediária para consolidar.

---

### Encontro 4 — Entrada digital: o pino como sensor

**Motivação.** Em 2026/2 o primeiro código de botão foi escrito sem nenhuma aula
sobre o que é ler um pino. Os três defeitos que apareceram no código dos alunos
— pino flutuante, estado inicial presumido, repique — são todos de entrada
digital, e nenhum depende de interrupção. A eletrônica do pino estava só no
laboratório, dividindo roteiro com ADC; o repique estava no encontro de
interrupções, como se fosse assunto dela.

**Sequência da aula** (na ordem em que os problemas aparecem na bancada):

1. **Pino de entrada é alta impedância.** Solto, não lê 0 nem 1 — lê o que
   estiver por perto. Demonstração: pino flutuante no osciloscópio, mão
   chegando perto.
2. **Pull-up e pull-down.** Quem define o nível ativo é o circuito, não o
   código. Inverter `== 0` para `== 1` sem mudar a ligação não funciona. O
   PIC18F4550 tem pull-up fraco em PORTB (RBPU) e não tem pull-down: daí a
   convenção de ativo baixo.
3. **Pull-up não é instantâneo.** Constante RC do pull-up fraco contra Tcy =
   250 ns. Regra que sai daqui: **o estado inicial é lido, nunca presumido.**
   Caso real: `button_state = RELEASED` no início conta um aperto fantasma no
   PICSimLab (PICGenios), porque a primeira leitura de RB0 ainda é 0.
4. **Schmitt trigger e diodos de proteção.** O mesmo pino tem buffers diferentes
   conforme a função: no PIC18F4550, RB0 lido como E/S digital passa por buffer
   **TTL**; como INT0 (e SDA), por **Schmitt (ST)** — conferir na tabela de
   PORTB do datasheet. A histerese limpa borda lenta e ruído perto do limiar,
   mas **não resolve repique**: cada quique cruza os dois limiares com folga.
   "O Schmitt limpa cada borda, mas não sabe quantas bordas deveriam existir."
5. **PBADEN e ADCON1.** Pino com canal analógico ativo lê 0 sempre — o botão
   que "não funciona". `PBADEN` define o estado no reset; `ADCON1` sobrescreve
   em tempo de execução. Volta no encontro 12 (I2C em RB0/RB1).
6. **Repique.** Física de contato mecânico (ver §5).
7. **Debounce por varredura.** Máquina de estados RELEASED/PRESSED; contar na
   borda *e confirmar* antes de contar. A versão que conta e depois espera
   aceita um pulso espúrio; a que espera e confirma não.

**Gancho para o encontro 8.** O `__delay_ms(30)` do debounce bloqueia o
processador. Interrupção chega como resposta a um custo que o aluno já sentiu,
não como mecanismo novo sem problema.

**Caixa `divergencia` (corrigida):** o PICSimLab **simula repique** — verificado
em 2026/2 na PICGenios: o debounce por INT0 + Timer0 contava de novo na
soltura até o teste de RB0 entrar no fim da janela. A duração e a forma do
repique simulado não são as de um botão real, então a constante continua sendo
medida na bancada. O pino solto, por sua vez, tem valor fixo no simulador em
vez de ruído.

**Ordem de demonstração** (sai pronta do código de 2026/2): versão sem o teste
de RB0 conta certo com clique rápido e conta dobrado ao segurar e soltar;
versão com o teste conta certo nos dois casos. O aluno descobre que o repique
acontece nos dois sentidos e que a janela tinha que começar na *soltura*.

**Miniteste M4 — candidata:** "Dado o código A (conta e espera) e o código B
(espera e confirma), descreva um sinal no pino que A conta e B não."

---

### R5 — Entrada digital na protoboard

**Decisão:** o aluno grava um PIC18F4550 nu e o liga na protoboard **no meio do
curso, no R5**, e não na primeira semana. No encontro 0 a protoboard continua
como *demonstração* do professor. Feita pelo aluno antes de ele saber o que é
pull-up, config bit ou oscilador, a montagem vira seguir esquema, e erro de
fiação fica indistinguível de erro de código.

**Por que aqui:** a protoboard é onde a camada placa (§8) deixa de ser tabela e
vira algo que o aluno constrói. Cada coisa que o kit fazia por ele aparece como
problema:

- **Config bits voltam a importar.** Sem bootloader, o `#pragma config` deixa de
  ser ignorado; "o código que veio antes do seu" desaparece.
- **Pull-up:** o botão da protoboard não tem resistor externo (no XM118, todo
  pino de PORTB tem). Sem `RBPU = 0`, o pino flutua de verdade.
- **Repique real** no osciloscópio, de um botão que ele mesmo ligou.
- **Clock:** com o oscilador interno de 8 MHz (sem cristal), Tcy = 500 ns e
  todos os atrasos dobram. "Tcy = 250 ns" era fato do kit, não do PIC.
- **MCLR, desacoplamento, alimentação:** o mínimo para um micro existir.

**Escopo mínimo** (os alunos não terminam roteiros longos): chip, alimentação,
desacoplamento, MCLR, um LED com resistor e um botão. Sem cristal, sem LCD. O
mesmo firmware do encontro 4 roda primeiro no simulador, depois no kit, depois
na protoboard — mudando só o `placa_*.h`.

**Custos a resolver antes de travar:**

- **Gravadores ICSP** (Snap/PICkit): quantos há? Com poucos, chips
  pré-gravados com um pisca de teste e só a gravação final em fila.
- **Chips e protoboards** por bancada.
- **Slot:** substitui o R5 anterior em vez de somar roteiro; o mapa não tem
  folga.

---

### Encontro 12 — Barramento serial síncrono: I2C e memória não volátil

A XM118 traz EEPROM I2C na placa, então o roteiro sai sem hardware externo.

**Ideia estruturante da aula:** *a mesma tarefa, por dois mecanismos.* Gravar e
recuperar o setpoint do termostato usando (a) a EEPROM **interna** do
PIC18F4550, via SFRs — `EEADR`, `EEDATA`, `EECON1` —, e (b) a EEPROM
**externa**, via barramento I2C. Registrador num endereço (encontro 1) contra
contrato de barramento (encontro 3), lado a lado, resolvendo o mesmo problema.

**Progressão de barramentos que o curso passa a ter:**

| Encontro | Barramento | Fios | Endereçamento | Confirmação |
|---|---|---|---|---|
| 2 | pino direto | 1 por sinal | — | — |
| 3 | paralelo (HD44780) | 6+ | RS seleciona registrador | nenhuma (espera cega) |
| 11 | UART | 2 | — (ponto a ponto) | nenhuma |
| 12 | I2C | 2 | endereço de 7 bits no barramento | ACK/NACK por byte |

**Pontos de conteúdo:**

- Dreno aberto e por que o barramento precisa de resistores de pull-up: o
  dispositivo só sabe puxar para baixo. Retoma diretamente o pull-up do
  encontro 4.
- Byte de controle `1010 A2A1A0 R/W` — o endereço vive *no barramento*, não em
  um fio dedicado. É a resposta ao "por que o paralelo precisa de tantos fios".
- **Start repetido na leitura aleatória.** Escreve-se o endereço interno sem
  soltar o barramento, e só então inverte-se o sentido. É a joia conceitual da
  aula: prova que "escrita" e "leitura" são fases de uma mesma transação, não
  operações independentes.
- **ACK polling durante o ciclo interno de escrita (~5 ms).** Fecha diretamente
  o "custo da espera" do encontro 3: no HD44780 o processador espera às cegas
  por um tempo fixo; aqui o dispositivo *avisa* quando terminou. Mesmo problema,
  duas soluções de qualidade diferente.
- Escrita por página contra escrita por byte, e o custo em tempo de cada uma.

**Conflito de pinos a verificar antes de escrever o R12:** no PIC18F4550 o
MSSP usa **RB0 (SDA) e RB1 (SCL)**. Isso colide com dois pontos do curso:

1. RB0/RB1 são as entradas INT0/INT1 e são candidatas naturais aos botões do
   encontro 8 — se o teclado matricial ocupar PORTB, os dois roteiros brigam.
2. RB0/RB1 são canais analógicos, então **PBADEN volta a importar** aqui, oito
   encontros depois de ter sido tratado na entrada digital (encontro 4). Isso é
   bom pedagogicamente (revisita), mas precisa estar previsto no roteiro.

### Encontro 14 — Controle embarcado na prática

**Escopo, explicitado antes de tudo:** esta não é uma aula de teoria de
controle. O objetivo é mostrar que **controle é feito em microcontrolador, e é
assim que se faz no mundo real** — o termostato da bancada é o mesmo objeto que
existe dentro de um ar-condicionado inverter, de uma estufa ou de uma incubadora.
Sem Laplace, sem lugar das raízes, sem critério de estabilidade formal. Tudo
empírico e medido.

**Gancho:** o R10 (liga-desliga) passa a *medir* duas coisas — a amplitude de
oscilação em torno do setpoint e o número de acionamentos de relé por hora. O
aluno chega no encontro 14 querendo resolver algo que ele mediu, não algo que
foi afirmado. E o segundo número tem consequência física direta: vida útil de
contato.

**Sequência da aula:**

1. Por que o liga-desliga oscila, com o dado do R10 na mesa.
2. Proporcional: reduz a oscilação, deixa erro em regime.
3. Integral: elimina o erro. Anti-windup como necessidade prática, não
   refinamento — a planta satura o tempo todo.
4. Por que o termo derivativo não funciona aqui (ver abaixo).
5. Onde isso aparece na indústria, e onde entra IA.

**Dois problemas técnicos que a planta impõe — ambos são conteúdo:**

- **O termo D é inviável, e o fracasso é didático.** LM35 a 10 mV/°C com ADC de
  10 bits dá degrau de 4,88 mV ≈ **0,49 °C**. Derivar um sinal quantizado em
  meio grau, numa planta lenta, produz ruído e não informação. **PI é a resposta
  honesta.** Sobreamostrar ou filtrar vira o passo seguinte, e abre a discussão
  de resolução efetiva.
- **A planta é lenta demais para sintonizar em 2 h de bancada.** Fluxo do R13:
  identificar uma vez em hardware (resposta ao degrau, ~10 min) → sintonizar
  contra a **planta simulada em Python** (dezenas de iterações em segundos) →
  descer à bancada só para confirmar os ganhos vencedores. Reaproveita o fio do
  simulador que atravessa o curso inteiro.

**Assimetria da planta:** o aquecedor injeta energia; o resfriamento é passivo
somado ao ventilador. O ganho depende do sentido, e um PI linear único não dá
conta bem. É o ponto de entrada natural para o que vem a seguir.

**IA — enquadramento honesto:**

O 4550 não treina nada e quase não infere. Mas ele **executa o que foi
aprendido**, e essa separação — treino fora, execução dentro — é o padrão
industrial real, não uma limitação didática. É exatamente o que existe num
ar-condicionado inverter ou numa geladeira com compressor de velocidade
variável.

Fluxo que fecha com o resto do curso:

- dataset vem da telemetria do **R11**;
- identificação e ajuste rodam em Python, fora do micro;
- o que desce para o micro são **coeficientes em ponto fixo**, uma tabela, ou um
  controlador **fuzzy** — historicamente o que mais se usa em controle de
  temperatura embarcado;
- opcional: rede minúscula (2–3 neurônios, inferência em `int16`) em algumas
  centenas de bytes, como demonstração honesta do limite da plataforma;
- os ganhos são gravados na EEPROM do **R12**.

**Risco a evitar:** IA virar ornamento. Se for 20 min de slide sobre redes
neurais, é ruído. Se o aluno **computar** o coeficiente e vê-lo mudar o
comportamento da planta, é aula.

**Efeito colateral positivo:** os encontros 11 e 12 ganham motivação nova sem
mudar de conteúdo — a telemetria passa a existir para coletar o dataset, e a
EEPROM passa a guardar os ganhos, não só o setpoint. E a ponte para o STM32
(seminários do encontro 15) sai de dentro do conteúdo: o termo derivativo,
o filtro e a inferência são justamente o que o PIC não roda bem.

## 4. Consequências para o material já produzido

### 4.1 Renumeração e divisão de arquivos

O atual `aula2-de-c-a-maquina.typ` **se divide em dois**:

- a parte de linguagem C (Python → C → micro, pisca) migra para o **encontro
  0**;
- a parte de máquina (ciclo busca-execução, PC, contagem de ciclos) permanece no
  **encontro 2**.

`R2-osciloscopio-cronometro.typ` passa a **R3** (LED, atraso e frequência).
`M2-simulador.typ` precisa ser reavaliado: as questões de ciclos continuam no 2,
mas o que for de C desce para o 0 ou some.

Conteúdo de PBADEN, comportamento analógico de PORTB e eletrônica do pino
migra para o **encontro 4** (entrada digital) e para o **R5**. O ADC (encontro
5, R6) só o retoma.

Material de 2026/2 sobre botões e repique que estava atrelado a interrupções
precisa ser **separado**: fenômeno, pull-up e debounce por varredura vão para o
encontro 4; debounce por timer/interrupção fica no encontro 8.

### 4.2 Versionamento do `pic18.py`

Passa a exigir **três estados congelados**, cada um com versão de referência e
versão de aluno:

| Tag | Estado | Encontro |
|-----|--------|----------|
| `v0-memoria` | mapa de memória, sem execução | 1 |
| `v1-execucao` | + ciclo busca-execução + pinos | 2 |
| `v2-barramento` | + temporização de periférico | 3 |

Sem tags no repositório, o estado do encontro 1 terá que ser reconstruído no
meio do semestre.

**Candidato a quarto estado:** `v3-entrada` — pino de entrada com injeção de
sequência de amostras (para testar o debounce, §5). Decidir se entra como tag
própria ou como extensão do `v1-execucao`.

### 4.3 Pendências de bancada que o replanejamento não resolve

- Contagem de ciclos do M2 depende do `blink.hex` específico usado.
- Erro de frequência da melodia (~3,4% abaixo do esperado) — verificar em
  hardware antes de fechar a demonstração.
- Inconsistência no `toca()`: comentário cita RC2, `#define` aponta
  `LATDbits.LATD0`.
- Serigrafia CH4-7 / CH4-8 (mapeamento RC7/RX) — verificação física em aberto
  desde as primeiras sessões.
- Serigrafia CH5-3 / CH5-4 e o conflito de PORTD com o LCD — bloqueia o R4.

---

### 4.4 Novos itens de verificação

- **Parte da EEPROM I2C da XM118** (24C02? 24C04? 24C16?). Determina tamanho de
  página, quantos bits do byte de controle são endereço e quantos são endereço
  de bloco. Ler a marcação do chip.
- **Pull-ups em SDA/SCL**: a placa já tem, ou o roteiro precisa incluí-los?
- **Chaves DIP** que conectam ou isolam a EEPROM do barramento.
- **Colisão RB0/RB1** entre I2C (encontro 12) e botões/teclado (encontro 8).
- ~~Botões da XM118 têm pull-up externo?~~ **Resolvido:** todo pino de PORTB tem
  resistor externo no kit (RB6/PGC para baixo, os demais para cima); o RBPU é
  redundante. O pino flutuante só aparece na protoboard — mais um motivo para
  o R5 ser lá.

---

## 5. Repique e debouncing — onde cada parte fica

Debouncing simula bem, mas só metade dele. A divisão:

- **Fenômeno → bancada (R5).** Osciloscópio no botão, captura do trem de
  repiques, medida da duração real em milissegundos. Não simula: é física de
  contato mecânico, e o número que sai é daquele botão específico.
- **Algoritmo → simulador (R5).** Injeta-se uma sequência de amostras no pino e
  testa-se o filtro. Determinístico e repetível, e o aluno enxerga o que o
  osciloscópio mostra rápido demais.
- **Debounce sem bloqueio → encontro 8 / R8.** Mesmo filtro, agora por timer ou
  interrupção, liberando o processador.

**Fechamento do R5:** capturar o traço real no osciloscópio e alimentar o
simulador com ele. A constante de 20–30 ms deixa de ser copiada da internet e
passa a ser medida.

**Caixa `divergencia`:** o PICSimLab simula repique, mas não o de um botão
real; o pino solto tem valor fixo, não ruído. Saber *onde* o simulador difere
da placa é parte do conteúdo (ver encontro 4 e §8).

---

## 6. Lacunas remanescentes (inventário)

Após incluir I2C no encontro 12 e entrada digital no encontro 4, o que ainda
fica de fora:

| Assunto | Custo | Onde caberia | Prioridade |
|---|---|---|---|
| USB | alto (não cabe inteiro) | 20 min de desmistificação — realocar, o 14 agora é controle | alta — é a feature que dá nome ao 4550 e os alunos usam toda semana no bootloader sem saber o que é |
| EEPROM interna | ~30 min | absorvida no encontro 12 | resolvida |
| Eletrônica do pino | aula inteira | encontro 4 | resolvida |
| Fontes de reset e watchdog (RCON) | ~meia aula | encontro 9 ou 12 | média — "por que ele reiniciou?" é pergunta de bancada |
| CCP em modo captura | ~meia aula | encontro 6, junto com PWM | média-alta para ênfase em Sistemas de Potência: é o dual do compare, mede período e frequência de sinal de entrada |
| SPI | baixo, se o MSSP já foi visto | menção comparativa no encontro 12 | baixa |

---

## 7. Princípios que o replanejamento preserva

- Cada seção de teoria tem consequência observável na bancada — a partir de
  2027/1, na semana seguinte, não no mesmo dia (§3.1).
- O sintoma de laboratório abre a aula; a previsão ou a tabela de payoff fecha.
- O aluno deriva o porquê; não recebe o porquê pronto.
- Miniteste não cobra conteúdo ainda não coberto.
- Uma aula de mecanismo (interrupção, timer) só vem depois que o aluno sentiu o
  problema que o mecanismo resolve.
- A aula habilita o aluno a programar: todo conceito termina em código que roda
  no simulador.
- Cada afirmação diz de qual camada ela é: conceito, chip, placa ou ferramenta
  (§8).

---

## 8. Separar as camadas: conceito, chip, placa, ferramenta

**Problema observado em 2026/2.** Quase todo erro de depuração vinha de uma
camada lida como se fosse outra. O aluno recebia tudo como "o jeito de fazer" e,
quando o código funcionava no kit e falhava no simulador, não tinha como saber
se errou o conceito, o chip ou só a placa.

| Fato de 2026/2 | Camada |
|---|---|
| Flag liga mesmo com a interrupção desabilitada | conceito |
| `RBPU` ativo baixo; RB0 é TTL na leitura e ST na INT0 | chip (PIC18F4550) |
| Todo pino de PORTB com resistor externo; LED de RD0 ativo baixo; `#pragma config` ignorado pelo bootloader | placa (XM118) |
| Pull-up depende do RBPU; teclado em PORTB | placa (PICGenios) |
| Repique com forma que não é a de um botão real | ferramenta (PICSimLab) |

**Divisão de papéis:**

- **Teoria** ensina o PIC (conceito + chip) e **ilustra tudo no simulador**,
  dizendo o que é do PIC e o que é do simulador.
- **Prática** começa entendendo o kit (R1, continuidade com a placa desligada)
  e, a partir daí, adapta para a bancada o código que já rodou no simulador.
- **Protoboard** (R5) remove a última camada: o aluno vê o que a placa fazia
  por ele.

**Rótulos no `estilo.typ`:** conceito sem rótulo (é o conteúdo); `#pic` para o
chip; `#kit` (já existe) e `#genios` para placa; `#sim` para a ferramenta.
Pergunta-hábito em sala: *isso mudaria se trocássemos de chip? de placa? de
ferramenta?*

**Um `.h` por placa.** As diferenças de placa ficam isoladas num cabeçalho; o
aluno continua escrevendo registradores do PIC.

```c
// placa_xm118.h            // placa_genios.h
#define LEDS(v) (LATD = (uint8_t)~(v))   // LED ativo baixo no kit
// ...                                   // #define LEDS(v) (LATD = (v))
```

Conteúdo mínimo: polaridade de LEDs e botões, pinos de botão/LCD/sensores,
pull-ups presentes, clock (`_XTAL_FREQ`), e se config bits valem. O
`placa_xm118.h` sai da tabela que a turma monta no R1; o `placa_genios.h` vem
pronto; o `placa_proto.h` é escrito no R5.

**Página de referência por plataforma** (XM118, PICGenios, protoboard) com a
mesma tabela de divergências. O `CONTRATO-LAB.md` já cobre parte disso para o
kit; falta a coluna do simulador. Facilita a migração para STM32: conceito e
ferramenta sobrevivem, chip e placa são trocados.

**Correção registrada:** o material de 2026/2 e as versões anteriores deste
plano diziam que o botão do PICSimLab é ideal. Não é — ver encontro 4.