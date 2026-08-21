#include <xc.h>
#define _XTAL_FREQ 16000000UL

void main(void) {
    LATD  = 0xFF;
    TRISD = 0x00;

    while (1) {
        LATDbits.LATD0 = 1;
        __delay_ms(500);
        LATDbits.LATD0 = 0;
        __delay_ms(500);
    }
}