#ifndef PLACA_H
#define PLACA_H

/* Escolha UMA placa. Os testes no PC (teste/Makefile) passam
   -DPLACA_TESTE na linha de comando e pulam esta escolha. */
#if !defined(PLACA_TESTE)
#define PLACA_PICSIMLAB
/* #define PLACA_XM118 */
#endif

#if !defined(PLACA_TESTE)
  #if defined(PLACA_PICSIMLAB) && defined(PLACA_XM118)
    #error "placa.h: escolha UMA placa, nao as duas"
  #endif
  #if !defined(PLACA_PICSIMLAB) && !defined(PLACA_XM118)
    #error "placa.h: escolha uma placa (PLACA_PICSIMLAB ou PLACA_XM118)"
  #endif
#endif

#define _XTAL_FREQ 16000000UL       /* usado por __delay_ms/__delay_us */

#endif /* PLACA_H */
