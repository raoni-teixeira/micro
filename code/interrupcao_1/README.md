# Interrupção 1 — um relógio contado pelo Timer0

Microcontroladores — DENE/UFMT — 2026/2. Primeiro exemplo da aula de interrupção (aula 7).

O display mostra um relógio `mm:ss`. Quem conta o tempo é a **interrupção do Timer0**, uma vez por segundo; o programa principal só copia os segundos e escreve na tela. O mesmo código roda **no simulador (PICSimLab)** e **no kit (XM118)** — você escolhe a placa numa linha só.

## 1. Escolha a placa — uma linha, em `placa.h`

```c
#define PLACA_PICSIMLAB        /* simulador  */
/* #define PLACA_XM118 */      /* kit da bancada */
```

Deixe **uma** das duas ativa. Se ficarem as duas, ou nenhuma, a compilação para com uma mensagem dizendo isso.

Nenhum outro arquivo muda de uma placa para a outra. Se você se pegar editando pinos no `main.c` para "fazer funcionar no kit", pare: a diferença está toda em `placa.h` e nos arquivos `lcd_port_*`.

## 2. O que muda entre as duas placas

| | PICSimLab (placa PICGenios) | XM118 (kit da bancada) |
|---|---|---|
| Display | **8 bits**, dados em RD0–RD7 | **4 bits**, dados em RD4–RD7 |
| Pino RS | **RE2** | **RE0** |
| Pino E | RE1 | RE1 |
| Pino R/W | ligado ao terra (só escreve) | **RE2** (dá para ler se o display está ocupado) |
| Bits de configuração | o `#pragma config` do `main.c` vale | gravados pelo bootloader; o `#pragma config` é **ignorado** |
| Vetor de interrupção | o normal, em `0x0008` | deslocado pelo bootloader; o projeto do MPLAB do laboratório já trata |
| Como gravar | carregar o `.hex` no simulador | MPLAB do laboratório, pelo bootloader USB |

**A armadilha mais comum:** RE2 é **RS** no simulador e **R/W** no kit. Um programa feito para uma placa e gravado na outra liga o display com o pino errado — e o sintoma é tela em branco ou lixo, não uma mensagem de erro.

Por isso os `#pragma config` do `main.c` ficam dentro de `#if defined(PLACA_PICSIMLAB)`: o simulador começa do zero e precisa deles; no kit, quem decide os bits de configuração é o bootloader — o código que veio antes do seu.

## 3. Como rodar

**No PICSimLab:** `placa.h` com `PLACA_PICSIMLAB`. Compile, abra a placa PICGenios com o PIC18F4550 e carregue o `.hex` gerado em `out/`.

**No XM118:** `placa.h` com `PLACA_XM118`. Importe a pasta no MPLAB do laboratório, compile e grave pelo bootloader, como nos roteiros. Chaves do kit: CH2-1 (LCD) em ON e CH5 (relés) em OFF.

## 4. O que observar

- **A interrupção conta, o laço mostra.** A função `isr` só recarrega o Timer0 e soma os segundos — nada de display dentro dela, porque o display é lento. O `main` copia `min` e `seg` com a interrupção desligada por um instante: sem isso, a virada de `00:59` para `01:00` no meio da cópia apareceria como `01:59`.
- **`volatile`.** `seg` e `min` mudam fora do fluxo do `main`; sem `volatile`, o compilador pode ler uma vez e nunca mais.
- **A conta de 1 s.** 16 MHz / 4 / 256 = 15 625 contagens por segundo; a pré-carga é 65 536 − 15 625 = 49 911 = `0xC2F7`.
- **O relógio atrasa.** A recarga é feita por software, alguns ciclos depois do estouro, e escrever no Timer0 zera o pré-divisor. Deixe rodando contra um cronômetro: quanto atrasa por hora? Por quê? Como corrigir? (A folha de referência dos temporizadores tem uma saída.)

## 5. Os arquivos

| Arquivo | O que faz |
|---|---|
| `main.c` | O relógio: configuração do Timer0, a interrupção e o laço principal |
| `placa.h` | **A escolha da placa** e a frequência do cristal |
| `lcd.c`, `lcd.h` | O driver do display (HD44780), igual para as duas placas |
| `lcd_port.h` | Escolhe os pinos da placa certa |
| `lcd_port_picsimlab.*` | Pinos e acesso ao display no simulador |
| `lcd_port_xm118.*` | Pinos e acesso ao display no kit |
| `lcd_port_test.*`, `teste/` | Teste do driver no PC, sem placa nenhuma (`cd teste && make`) |

As pastas `out`, `_build`, `cmake` e `.vscode` são geradas pelo MPLAB; não precisam ser editadas.
