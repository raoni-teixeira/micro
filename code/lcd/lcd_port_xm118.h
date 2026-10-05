#ifndef LCD_PORT_XM118_H
#define LCD_PORT_XM118_H

/*
 * Mapa de pinos para a placa XM118 (PIC18F4550)
 *
 * Confirmado em bancada (nao apenas no manual): as tres linhas de controle
 * estao na PORTE e a via de dados na PORTD.
 */

#define LCD_BITS 4

/* Nesta placa R/W chega ao RE2: da para perguntar ao controlador se ele
   terminou. Deixe em 1 e compare com 0 - o Exercicio 3.8 da Aula 3 pede
   a medida. */
#define LCD_LER_OCUPADO 1

#define LCD_DADOS_LAT     LATD              /* escrita: o latch           */
#define LCD_DADOS_PORT    PORTD             /* leitura: o nivel do pino   */
#define LCD_DADOS_TRIS    TRISD

#define LCD_RS_LAT        LATEbits.LATE0    /* 0 = comando, 1 = dado      */
#define LCD_RS_TRIS       TRISEbits.TRISE0

#define LCD_E_LAT         LATEbits.LATE1    /* habilitacao                */
#define LCD_E_TRIS        TRISEbits.TRISE1

#define LCD_RW_LAT        LATEbits.LATE2    /* 0 = escrita, 1 = leitura   */
#define LCD_RW_TRIS       TRISEbits.TRISE2

#endif /* LCD_PORT_XM118_H */
