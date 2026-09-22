/* =========================================================================
 * lcd.h - display alfanumerico HD44780 no XM118
 * Microcontroladores - DENE/UFMT
 *
 * Driver de referencia do R4. Cada atraso daqui tem origem na folha de dados
 * do HD44780, e o R4 pede que voce a justifique.
 * ========================================================================= */

#ifndef LCD_H
#define LCD_H

#include <stdint.h>

/* -------------------------------------------------------------------------
 * MAPA DE PINOS - o unico lugar do projeto que sabe onde o display esta.
 *
 * Confirmado em bancada (nao apenas no manual): as tres linhas de controle
 * estao na PORTE e a via de dados na PORTD.
 * ---------------------------------------------------------------------- */
#define LCD_DADOS_LAT     LATD              /* escrita: o latch           */
#define LCD_DADOS_PORT    PORTD             /* leitura: o nivel do pino   */
#define LCD_DADOS_TRIS    TRISD

#define LCD_RS_LAT        LATEbits.LATE0    /* 0 = comando, 1 = dado      */
#define LCD_RS_TRIS       TRISEbits.TRISE0
#define LCD_E_LAT         LATEbits.LATE1    /* habilitacao                */
#define LCD_E_TRIS        TRISEbits.TRISE1
#define LCD_RW_LAT        LATEbits.LATE2    /* 0 = escrita, 1 = leitura   */
#define LCD_RW_TRIS       TRISEbits.TRISE2

/* -------------------------------------------------------------------------
 * ATENCAO - RE0, RE1 e RE2 sao tambem AN5, AN6 e AN7.
 *
 * Medido no R5: o bootloader grava PBADEN = 0, e o reset deixa
 * ADCON1 = 0x07 - AN0 a AN7 ANALOGICOS. Ou seja, RE0-RE2 saem do reset
 * como canais analogicos. O display funciona assim mesmo porque o driver
 * so ESCREVE nesses tres pinos: o modo analogico desliga o buffer de
 * ENTRADA digital, e nao o driver de saida. A leitura do display
 * (lcd_estado) usa PORTD, que nao tem canal analogico.
 *
 * O driver NAO escreve no ADCON1 de proposito: ADCON1 e um recurso global,
 * e um driver de display que o reconfigura por conta propria quebraria a
 * leitura do LM35 - de um jeito dificil de encontrar, porque o display
 * continuaria funcionando. O padrao do curso e ADCON1 = 0x0F na primeira
 * linha do main, e o analogico declarado explicitamente depois.
 * ---------------------------------------------------------------------- */

/* -------------------------------------------------------------------------
 * MODO DO BARRAMENTO
 *   4 -> nibbles em LCD_DADOS<7:4>, dois pulsos por byte, 7 pinos
 *   8 -> byte inteiro, um pulso por byte, 11 pinos
 * O R4 pede que voce meca os dois e decida com o numero.
 * ---------------------------------------------------------------------- */
#define LCD_BITS          4

/* -------------------------------------------------------------------------
 * LEITURA DO INDICADOR DE OCUPADO
 *
 *   1 -> pergunta ao controlador se ele terminou (tempo real)
 *   0 -> espera as cegas o pior caso da folha de dados
 *
 * So e possivel porque nesta placa R/W chega ao RE2. A maioria dos modulos
 * tem R/W no terra, e nesses o driver PRECISA usar 0. Deixe em 1 aqui e
 * compare os dois: o Exercicio 3.8 da Aula 3 pede a medida.
 * ---------------------------------------------------------------------- */
#define LCD_LER_OCUPADO   1

/* Teto de seguranca para a espera por consulta. Se o indicador nunca baixar
   - R/W no terra, mapa de pinos errado, modulo ausente - o programa segue
   em frente em vez de travar para sempre. Cada consulta custa ~6 us. */
#define LCD_MAX_CONSULTAS 20000u

/* -------------------------------------------------------------------------
 * TEMPOS - todos vem da folha de dados do HD44780. Nenhum foi copiado de
 * exemplo da internet, e o R4 pede a justificativa de cada um.
 * ---------------------------------------------------------------------- */
#define LCD_T_PULSO_US    1     /* PW_EH >= 230 ns @5V (450 ns @2,7V)      */
#define LCD_T_CICLO_US    1     /* t_cicE >= 500 ns entre bordas de subida */
#define LCD_T_COMANDO_US  40    /* execucao de um comando comum            */
#define LCD_T_LENTO_MS    2     /* limpar e voltar ao inicio: ~1,6 ms      */
#define LCD_T_ENERGIA_MS  50    /* estabilizacao da alimentacao            */

/* ------------------------------------------------------------------ API */
void lcd_iniciar(void);

void lcd_comando(uint8_t c);
void lcd_dado(uint8_t d);

void lcd_limpar(void);
void lcd_posicao(uint8_t linha, uint8_t coluna);

void lcd_texto(const char *s);
void lcd_numero(uint16_t v, uint8_t largura);   /* largura fixa, com espacos */
void lcd_decimos(int16_t d);                    /* 253 -> "25.3"            */

#if LCD_LER_OCUPADO
/* Exposta so para o R4: le o byte de estado (D7 = ocupado, D6..D0 = contador
   de enderecos). E o que prova, na bancada, que a leitura funciona. */
uint8_t lcd_estado(void);
#endif

#endif /* LCD_H */
