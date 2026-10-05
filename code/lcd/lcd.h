/* =========================================================================
 * lcd.h - display alfanumerico HD44780 (XM118 e PICSimLab)
 * Microcontroladores - DENE/UFMT
 *
 * Driver de referencia do R4. Cada atraso daqui tem origem na folha de dados
 * do HD44780, e o R4 pede que voce a justifique.
 * ========================================================================= */

#ifndef LCD_H
#define LCD_H

#include "lcd_port.h"
/* -------------------------------------------------------------------------
 * MAPA DE PINOS, MODO DO BARRAMENTO e LEITURA DO OCUPADO ficam no header
 * da placa (lcd_port_<placa>.h), escolhido em placa.h:
 *
 *   LCD_BITS
 *     4 -> nibbles em LCD_DADOS<7:4>, dois pulsos por byte, 7 pinos
 *     8 -> byte inteiro, um pulso por byte, 11 pinos
 *     O R4 pede que voce meca os dois e decida com o numero.
 *
 *   LCD_LER_OCUPADO
 *     1 -> pergunta ao controlador se ele terminou (tempo real)
 *     0 -> espera as cegas o pior caso da folha de dados
 *     So e possivel com R/W ligado a um pino (XM118: RE2). Com R/W no
 *     terra (PICGenios do PICSimLab) o driver PRECISA usar 0.
 *
 * ATENCAO - no PIC18F4550, RE0, RE1 e RE2 sao tambem AN5, AN6 e AN7, e
 * com PBADEN = 0 o reset deixa ADCON1 = 0x07 (AN0 a AN7 analogicos). O
 * display funciona assim mesmo porque o driver so ESCREVE nesses pinos:
 * o modo analogico desliga o buffer de ENTRADA digital, nao a saida.
 *
 * O driver NAO escreve no ADCON1 de proposito: ADCON1 e um recurso global,
 * e um driver de display que o reconfigura por conta propria quebraria a
 * leitura do LM35 - de um jeito dificil de encontrar, porque o display
 * continuaria funcionando. O padrao do curso e ADCON1 = 0x0F na primeira
 * linha do main, e o analogico declarado explicitamente depois.
 * ---------------------------------------------------------------------- */

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
