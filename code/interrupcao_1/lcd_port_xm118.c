/* =========================================================================
 * lcd_port_xm118.c - porta do LCD para a XM118
 *
 * Igual a da PICSimLab, mais o pino R/W e a leitura do controlador.
 * So e compilado quando placa.h escolhe PLACA_XM118.
 * ========================================================================= */

#include "placa.h"

#if defined(PLACA_XM118)

#include <xc.h>
#include "lcd.h"

void lcd_port_init(void)
{
    /* LAT antes de TRIS: encontro 2. Vale tambem para o R/W - se ele ficar
       flutuando, o modulo nao sabe se esta sendo lido ou escrito, e o
       display funciona ou nao conforme o dia. */
    LCD_RS_LAT = 0;
    LCD_E_LAT  = 0;
    LCD_RW_LAT = 0;
#if LCD_BITS == 4
    LCD_DADOS_LAT = (uint8_t)(LCD_DADOS_LAT & 0x0Fu);
#else
    LCD_DADOS_LAT = 0x00;
#endif

    LCD_RS_TRIS = 0;
    LCD_E_TRIS  = 0;
    LCD_RW_TRIS = 0;
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

/* =======================================================================
 * Um ciclo de leitura.
 *
 * Aqui - e SO aqui - PORTD esta certo e LATD estaria errado. E a mesma
 * regra de lcd_port_dados, lida ao contrario: la se queria o que o
 * programa escreveu, e o latch responde; aqui se quer o que OUTRO
 * circuito colocou no fio, e o latch nao sabe de nada. Ler LATD
 * devolveria o nibble que nos mesmos mandamos da ultima vez.
 *
 * Quem decorou "sempre LAT" erra exatamente nesta funcao.
 * ======================================================================= */
uint8_t lcd_port_ler(void)
{
    uint8_t v;

    /* Barramento vira entrada ANTES de pedir leitura. */
#if LCD_BITS == 4
    LCD_DADOS_TRIS |= 0xF0u;
#else
    LCD_DADOS_TRIS = 0xFFu;
#endif

    LCD_RW_LAT = 1;                 /* leitura */
    __delay_us(LCD_T_PULSO_US);

    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);
    v = (uint8_t)LCD_DADOS_PORT;    /* amostra com E alto */
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);

    /* Devolve o barramento ANTES de reconfigurar o TRIS.
       Nesta placa o modulo ja soltou os fios, porque ele so os dirige
       enquanto E esta alto - e E ja desceu. A ordem e disciplina, nao
       correcao de um defeito ativo: a alternativa e dois circuitos
       dirigindo o mesmo fio, a unica falha deste driver que estraga
       hardware em vez de produzir caractere errado. */
    LCD_RW_LAT = 0;
#if LCD_BITS == 4
    LCD_DADOS_TRIS &= 0x0Fu;
    v &= 0xF0u;
#else
    LCD_DADOS_TRIS = 0x00u;
#endif

    return v;
}

#endif /* PLACA_XM118 */
