# Driver do display HD44780 — e um exemplo de C para PIC

Microcontroladores — DENE/UFMT. O driver de display usado da aula 3 até o fim do semestre, no PICSimLab e no XM118.

Ele serve para duas coisas. A primeira é óbvia: escrever no display. A segunda é ler o código como **exemplo de C embarcado de verdade** — organizado em camadas, configurado em tempo de compilação, com cada número justificado pela folha de dados e testado no PC sem placa nenhuma.

## Usar

Todas as funções estão em `lcd.h`:

| Função | O que faz |
|---|---|
| `lcd_iniciar()` | A sequência de inicialização da folha de dados. Chame uma vez, depois de `ADCON1 = 0x0F` |
| `lcd_limpar()` | Apaga a tela e volta o cursor ao início (≈ 1,6 ms) |
| `lcd_posicao(linha, coluna)` | Linha 0 ou 1; coluna de 0 a 15 |
| `lcd_texto("abc")` | Escreve uma cadeia de caracteres |
| `lcd_numero(v, largura)` | Número sem sinal, com **largura fixa**: completa com espaços à esquerda |
| `lcd_decimos(d)` | Décimos com sinal: `253` → `25.3`, `-47` → `-4.7`, sempre na mesma largura |
| `lcd_comando(c)`, `lcd_dado(d)` | Um byte cru, de comando ou de caractere |

```c
ADCON1 = 0x0F;          /* primeira linha do main: o driver nao mexe no ADCON1 */
lcd_iniciar();
lcd_posicao(0, 0);
lcd_texto("T = ");
lcd_decimos(temp_d);    /* 253 -> "25.3" */
```

O `exemplo.c` mostra as funções em uso.

## Levar para o seu projeto

1. Copie para a pasta do projeto **todos os arquivos desta pasta, menos `exemplo.c`**.
2. Em `placa.h`, deixe ativa **uma** placa: `PLACA_PICSIMLAB` ou `PLACA_XM118`.
3. Inclua `lcd.h` no seu `main.c`.

Nenhum outro arquivo muda de uma placa para a outra.

## Como está organizado

```
seu main.c ──> lcd.h / lcd.c ──> lcd_port.h ──┬──> lcd_port_picsimlab.c   (simulador)
              (o protocolo)     (o contrato)  ├──> lcd_port_xm118.c       (kit)
                                              └──> lcd_port_test.c        (PC, nos testes)
```

- **`lcd.c` não conhece nenhum registrador do PIC.** Ele sabe o *protocolo* do HD44780: a sequência de inicialização, os dois nibbles do modo de 4 bits, quanto esperar depois de cada comando.
- **`lcd_port.h` é o contrato:** seis funções — mudar RS, pôr dados no barramento, dar um pulso em E, esperar. É tudo o que o protocolo precisa do hardware.
- **Cada `lcd_port_<placa>` cumpre o contrato** para uma placa. É o único lugar que sabe *onde* o display está ligado.
- **`placa.h` escolhe a placa**, e o resto se ajusta em tempo de compilação.

| | PICSimLab (PICGenios) | XM118 |
|---|---|---|
| Barramento | 8 bits, RD0–RD7 | 4 bits, RD4–RD7 |
| RS | RE2 | RE0 |
| E | RE1 | RE1 |
| R/W | no terra: o driver espera às cegas | RE2: o driver pergunta se o display terminou |

## O que este código ensina de C embarcado

- **Separar o que muda do que não muda.** O protocolo é o mesmo em toda placa; os pinos não. Quem quiser levar o driver para outro microcontrolador reescreve só uma `lcd_port_<placa>.c`.
- **Configuração em tempo de compilação, não em tempo de execução.** `#if LCD_BITS == 4` escolhe o código de 4 ou de 8 bits *antes* de compilar: o código que não serve nem chega à memória de programa. Num chip com 32 kB, isso importa.
- **Nenhum número mágico.** Cada atraso em `lcd.h` diz de que linha da folha de dados ele vem e quanta margem tem.
- **LAT antes de TRIS** em `lcd_port_init`: o pino recebe o valor certo antes de virar saída (aula 2).
- **Ler o fio, não o latch.** Para saber se o display está ocupado, a leitura usa `PORT`, e não `LAT`: quer-se o que *outro* circuito pôs no barramento.
- **Nunca travar.** A espera pelo display tem um teto (`LCD_MAX_CONSULTAS`): se a leitura não funcionar, o programa segue com o display errado, em vez de parar para sempre.
- **Não mexer no que não é seu.** O driver não escreve em `ADCON1`: um registrador global, reconfigurado por um driver de display, quebraria a leitura do sensor de um jeito difícil de achar.
- **Inteiros, sem ponto flutuante.** `lcd_decimos` mostra 25,3 °C a partir do inteiro 253 — e trata até o caso de `-32768`, cujo oposto não cabe em `int16`.
- **Largura fixa.** O display não apaga nada: escrever "9" onde havia "37" deixa o "7". `lcd_numero` sempre escreve o mesmo número de posições.

## Testar no PC, sem placa

```
cd teste
make
```

O `lcd.c` é compilado com o `gcc` contra uma "placa" de mentira (`lcd_port_test.c`), que registra cada acesso com um relógio virtual. Cada caso de teste confere uma regra da folha de dados — 40 ms depois de energizar, 4,1 ms depois do primeiro `0x3`, a ordem dos nibbles — nas quatro configurações: 4 e 8 bits, com e sem leitura do ocupado. Quando um teste falha, ele imprime o registro e mostra *onde* a sequência saiu errada.

É a mesma ideia do simulador do curso: separar o hardware do resto permite testar o resto onde testar é barato.

## Acrescentar uma placa

1. Crie `lcd_port_<placa>.h` com o mapa de pinos, `LCD_BITS` e `LCD_LER_OCUPADO` — use os dois existentes como modelo.
2. Crie `lcd_port_<placa>.c` com as seis funções de `lcd_port.h`, dentro de `#if defined(PLACA_<PLACA>)`.
3. Acrescente a placa em `lcd_port.h` e em `placa.h`.

O `lcd.c` não muda.
