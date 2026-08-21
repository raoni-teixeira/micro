/* ---------------------------------------------------------------
   Oficina 1 — painel de atuadores
   Acionamento digital simples. Nenhum controle ainda.
   --------------------------------------------------------------- */

#define _XTAL_FREQ 16000000UL   /* nucleo a 16 MHz — ver Aula 1 */

#include <xc.h>
#include <stdint.h>

/* --- mapeamento da bancada: SUBSTITUIR pelo bloco do R0 --------- */
#define LEDS_LAT      LATD
#define LEDS_TRIS     TRISD

#define BUZZER_LAT    LATCbits.LATC1
#define BUZZER_TRIS   TRISCbits.TRISC1

#define LAMPADA_LAT   LATCbits.LATC0
#define LAMPADA_TRIS  TRISCbits.TRISC0

#define COOLER_LAT    LATCbits.LATC2
#define COOLER_TRIS   TRISCbits.TRISC2
/* --------------------------------------------------------------- */

static void atuadores_init(void)
{
    /* 1) estado seguro PRIMEIRO: tudo desligado */
    LEDS_LAT    = 0x00;
    BUZZER_LAT  = 0;
    LAMPADA_LAT = 0;
    COOLER_LAT  = 0;

    /* 2) so entao habilitar as saidas */
    LEDS_TRIS    = 0x00;
    BUZZER_TRIS  = 0;
    LAMPADA_TRIS = 0;
    COOLER_TRIS  = 0;
}

void main(void)
{
    atuadores_init();

    while (1) {
        /* os experimentos entram aqui, um de cada vez */
    }
}
