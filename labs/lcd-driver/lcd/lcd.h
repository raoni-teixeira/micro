/* =========================================================================
 * lcd.h - display alfanumerico HD44780 no XM118
 * Microcontroladores - DENE/UFMT
 *
 * Driver de referencia do R4.
 *
 * Os comentarios deste arquivo fazem perguntas, e nao as respondem. Todas
 * tem resposta na folha de dados do HD44780 e na aula 3, e o R4 pede que
 * voce as responda com o numero e a origem do numero - nao de memoria.
 * ========================================================================= */

#ifndef LCD_H
#define LCD_H

#include <stdint.h>

/* -------------------------------------------------------------------------
 * MAPA DE PINOS - o unico lugar do projeto que sabe onde o display esta.
 * Conferir na serigrafia antes de gravar.
 * ---------------------------------------------------------------------- */
#define LCD_DADOS_LAT     LATD          /* barramento de dados            */
#define LCD_DADOS_TRIS    TRISD
#define LCD_RS_LAT        LATEbits.LATE0    /* 0 = comando, 1 = dado      */
#define LCD_RS_TRIS       TRISEbits.TRISE0
#define LCD_E_LAT         LATEbits.LATE1    /* habilitacao                */
#define LCD_E_TRIS        TRISEbits.TRISE1

/* ATENCAO, e vale uma medida antes de acusar o driver: no PIC18F4550 os
 * pinos RE0 e RE1 acumulam funcao analogica (AN5 e AN6). Confira em que
 * estado o seu programa deixa ADCON1 antes de chamar lcd_iniciar(). */

/* -------------------------------------------------------------------------
 * MODO DO BARRAMENTO
 *   4 -> nibbles em LCD_DADOS<7:4>, dois pulsos por byte, 6 pinos
 *   8 -> byte inteiro, um pulso por byte, 10 pinos
 * O R4 Parte 4 pede que voce meca os dois e decida com o numero.
 * ---------------------------------------------------------------------- */
#define LCD_BITS          4

/* -------------------------------------------------------------------------
 * TEMPOS
 *
 * Todos vem da folha de dados do HD44780. Nenhum foi copiado de exemplo da
 * internet - e o R4 Tarefa 1 pede que voce reconstrua a origem de cada um.
 *
 * Para cada constante: qual minimo da folha de dados ela atende, qual o
 * valor desse minimo, e quanta margem sobra?
 * ---------------------------------------------------------------------- */
#define LCD_T_PULSO_US    1     /* largura do pulso de habilitacao   T1(b) */
#define LCD_T_CICLO_US    1     /* intervalo entre pulsos            T1(b) */
#define LCD_T_COMANDO_US  40    /* execucao de um comando comum            */
#define LCD_T_LENTO_MS    2     /* limpar e voltar ao inicio               */
#define LCD_T_ENERGIA_MS  50    /* ver lcd_iniciar - e o alvo da Tarefa 5  */

/* ------------------------------------------------------------------ API */
void lcd_iniciar(void);

void lcd_comando(uint8_t c);
void lcd_dado(uint8_t d);

void lcd_limpar(void);
void lcd_posicao(uint8_t linha, uint8_t coluna);  /* linha 0 = primeira */

void lcd_texto(const char *s);

/* lcd_numero escreve SEMPRE `largura` posicoes na tela. Por que isso
 * importa e o que a Tarefa 8 pede que voce descubra sozinho - nao use esta
 * funcao antes de chegar la. */
void lcd_numero(uint16_t v, uint8_t largura);
void lcd_decimos(int16_t d);                    /* 253 -> "25.3"          */

#endif /* LCD_H */
