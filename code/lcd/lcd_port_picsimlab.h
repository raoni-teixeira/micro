#ifndef LCD_PORT_PICSIMLAB_H
#define LCD_PORT_PICSIMLAB_H

/*
 * Mapa de pinos para a placa PICGenios do PICSimLab (PIC18F4550)
 *
 * Referência:
 * https://lcgamboa.github.io/picsimlab_docs/stable/pdf/boards/PICGenios.pdf
*/

#define LCD_BITS 8

/* R/W esta ligado ao GND: o display so pode ser escrito, e o driver
   precisa esperar as cegas o pior caso da folha de dados. */
#define LCD_LER_OCUPADO 0

#define LCD_DADOS_LAT     LATD              /* escrita: o latch           */
#define LCD_DADOS_PORT    PORTD             /* leitura: o nivel do pino   */
#define LCD_DADOS_TRIS    TRISD

#define LCD_RS_LAT        LATEbits.LATE2    /* 0 = comando, 1 = dado      */
#define LCD_RS_TRIS       TRISEbits.TRISE2

#define LCD_E_LAT         LATEbits.LATE1    /* habilitacao                */
#define LCD_E_TRIS        TRISEbits.TRISE1

#endif /* LCD_PORT_PICSIMLAB_H */
