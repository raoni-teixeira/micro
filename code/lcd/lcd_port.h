/* =========================================================================
 * lcd_port.h - camada de porta do LCD: o unico lugar que sabe ONDE o
 * display esta. O lcd.c so conhece estas funcoes.
 *
 * O header da placa define:
 *   - o mapa de pinos (LCD_*_LAT, LCD_*_TRIS, LCD_DADOS_PORT)
 *   - LCD_BITS          (4 ou 8)
 *   - LCD_LER_OCUPADO   (1 so se R/W estiver ligado a um pino)
 * ========================================================================= */

#ifndef LCD_PORT_H
#define LCD_PORT_H

#include <stdint.h>
#include "placa.h"

#if defined(PLACA_XM118)
  #include "lcd_port_xm118.h"
#elif defined(PLACA_PICSIMLAB)
  #include "lcd_port_picsimlab.h"
#elif defined(PLACA_TESTE)
  #include "lcd_port_test.h"
#else
  #error "Defina PLACA_XM118, PLACA_PICSIMLAB ou PLACA_TESTE"
#endif

#if !defined(LCD_BITS) || (LCD_BITS != 4 && LCD_BITS != 8)
  #error "O header da placa deve definir LCD_BITS como 4 ou 8"
#endif

#ifndef LCD_LER_OCUPADO
  #define LCD_LER_OCUPADO 0
#endif

void lcd_port_init(void);            /* LAT antes de TRIS; R/W = 0 se houver */
void lcd_port_rs(uint8_t nivel);     /* 0 = comando, 1 = dado */
void lcd_port_dados(uint8_t v);      /* 8 bits: v inteiro; 4 bits: v<7:4> em D4-D7 */
void lcd_port_pulso_en(void);        /* inclui PW_EH e t_cicE */
void lcd_port_espera_ms(uint8_t ms); /* laco de __delay_ms(1) */
void lcd_port_espera_40us(void);

#if LCD_LER_OCUPADO
/* Um ciclo de leitura (RS ja definido pelo chamador).
   8 bits: o byte inteiro; 4 bits: o nibble em <7:4>. */
uint8_t lcd_port_ler(void);
#endif

#endif /* LCD_PORT_H */
