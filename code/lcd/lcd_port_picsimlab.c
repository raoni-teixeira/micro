/* =========================================================================
 * lcd_port_picsimlab.c - porta do LCD para a PICGenios (PICSimLab)
 *
 * Aqui so ha pinos e atrasos. A sequencia de inicializacao do HD44780 e
 * protocolo, nao hardware, e por isso fica no lcd.c.
 * So e compilado quando placa.h escolhe PLACA_PICSIMLAB.
 * ========================================================================= */

#include "placa.h"

#if defined(PLACA_PICSIMLAB)

#include <xc.h>
#include "lcd.h"

void lcd_port_init(void)
{
    /* LAT antes de TRIS: o pino ja nasce saida no nivel certo. */
    LCD_RS_LAT = 0;
    LCD_E_LAT  = 0;
#if LCD_BITS == 4
    LCD_DADOS_LAT = (uint8_t)(LCD_DADOS_LAT & 0x0Fu);
#else
    LCD_DADOS_LAT = 0x00;
#endif

    LCD_RS_TRIS = 0;
    LCD_E_TRIS  = 0;
#if LCD_BITS == 4
    LCD_DADOS_TRIS &= 0x0Fu;         /* so os quatro bits altos viram saida */
#else
    LCD_DADOS_TRIS = 0x00;
#endif
}

void lcd_port_rs(uint8_t nivel)
{
    LCD_RS_LAT = nivel ? 1 : 0;
}

/* Le LATD e nao PORTD: LATD devolve o que o programa escreveu, PORTD
   devolve o nivel eletrico do pino. Com carga nos quatro bits baixos, a
   leitura-modificacao-escrita por PORTD apaga bits que ninguem pediu. */
void lcd_port_dados(uint8_t v)
{
#if LCD_BITS == 4
    LCD_DADOS_LAT = (uint8_t)((LCD_DADOS_LAT & 0x0Fu) | (v & 0xF0u));
#else
    LCD_DADOS_LAT = v;
#endif
}

/* O display le o barramento na borda de DESCIDA de E. */
void lcd_port_pulso_en(void)
{
    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);     /* largura minima do pulso        */
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);     /* intervalo minimo ate o proximo */
}

/* __delay_ms exige constante; o laco permite um argumento variavel. */
void lcd_port_espera_ms(uint8_t ms)
{
    while (ms-- != 0u) {
        __delay_ms(1);
    }
}

void lcd_port_espera_40us(void)
{
    __delay_us(LCD_T_COMANDO_US);
}

#endif /* PLACA_PICSIMLAB */
