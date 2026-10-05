/* =========================================================================
 * exemplo.c - o driver do display em uso: texto, numero de largura fixa e
 * decimos de grau. Escolha a placa em placa.h e compile.
 *
 * Para levar o driver a outro projeto, copie todos os arquivos desta pasta
 * MENOS este (o seu projeto ja tem um main).
 * Microcontroladores - DENE/UFMT
 * ========================================================================= */

#include <xc.h>
#include <stdint.h>

#include "placa.h"
#include "lcd.h"

/* Bits de configuracao: so no simulador. No XM118 eles pertencem ao
   bootloader, e um #pragma config da aplicacao seria ignorado. */
#if defined(PLACA_PICSIMLAB)
#pragma config FOSC = HS, CPUDIV = OSC1_PLL2, PLLDIV = 4, USBDIV = 1
#pragma config PWRT = ON, BOR = ON, BORV = 2, VREGEN = OFF
#pragma config WDT = OFF, LVP = OFF, PBADEN = OFF, MCLRE = ON, XINST = OFF
#endif

void main(void)
{
    uint16_t n = 0;
    int16_t  d = -99;              /* decimos: comeca em -9.9 */

    ADCON1 = 0x0F;                 /* tudo digital: o driver nao mexe no ADCON1 */
    lcd_iniciar();

    lcd_limpar();
    lcd_posicao(0, 0);
    lcd_texto("Driver HD44780");

    for (;;) {
        lcd_posicao(1, 0);
        lcd_numero(n, 5);          /* largura fixa: o numero nao "danca" */
        lcd_texto("   ");
        lcd_decimos(d);            /* -9.9 ... 99.9, sempre na mesma largura */

        n++;
        d = (int16_t)(d + 7);
        if (d > 999) {
            d = -99;
        }
        __delay_ms(200);           /* aqui pode: o exemplo so faz isto */
    }
}
