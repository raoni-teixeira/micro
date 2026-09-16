# Driver do display — R4

`lcd.c` e `lcd.h` para o HD44780 no XM118. Compilam em XC8.

Os dois arquivos entram no mesmo projeto do MPLAB X. Este driver é usado do R4
até o fim do semestre — o que você ajustar aqui, leva adiante.

## Antes de gravar: conferir o mapa de pinos

Tudo o que o driver sabe sobre a placa está num único bloco no topo de `lcd.h`:

```c
#define LCD_DADOS_LAT   LATD
#define LCD_RS_LAT      LATEbits.LATE0
#define LCD_E_LAT       LATEbits.LATE1
```

**Confirme na serigrafia da sua placa.** Se o display não acender nada, este é o
primeiro lugar a olhar — antes de suspeitar do código.

Confira também em que estado o seu programa deixa `ADCON1`: no PIC18F4550 os
pinos RE0 e RE1 acumulam função analógica (AN5 e AN6).

## Quatro ou oito bits

Uma linha:

```c
#define LCD_BITS   4     /* ou 8 */
```

Em quatro bits, os nibbles saem em `LCD_DADOS<7:4>` e só esses pinos viram
saída. A Parte 4 do R4 pede que você meça os dois modos e decida com o número.

## Chaves do kit

| Chave | Estado |
|---|---|
| CH2-1 (LCD) | **ON** |
| CH5-3 e CH5-4 | **OFF, obrigatoriamente** |
| SWITCHS (PORTB) | Todas em OFF |

Se um relé chavear a cada caractere escrito, CH5-3 ou CH5-4 ficou ligado.
Desligue antes de continuar.

Os LEDs do PORTD piscarem junto com a escrita é **esperado**: o barramento de
dados do display e os oito LEDs são o mesmo PORTD.

## Como ler o fonte

Os comentários marcados com `[T#]` apontam a tarefa do R4 que trata daquele
trecho. Eles fazem as perguntas — as respostas são suas, e saem da folha de
dados do HD44780 e da bancada.

Três pontos do driver o roteiro manda quebrar de propósito (Tarefas 5 e 6, e a
previsão P2). Todos são de uma linha. Guarde o original antes de mexer.

## Funções

```c
void lcd_iniciar(void);
void lcd_comando(uint8_t c);
void lcd_dado(uint8_t d);
void lcd_limpar(void);
void lcd_posicao(uint8_t linha, uint8_t coluna);   /* linha 0 = primeira */
void lcd_texto(const char *s);
void lcd_numero(uint16_t v, uint8_t largura);
void lcd_decimos(int16_t d);                       /* 253 -> "25.3" */
```

`lcd_numero` e `lcd_decimos` só entram na Tarefa 8 — a Tarefa 7 pede que você
escreva a sua própria versão primeiro, e o roteiro depende disso.
