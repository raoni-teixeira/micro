/* =========================================================================
 * lcd_port_test.c - "placa" de teste: registra eventos em vez de pinos
 *
 * So e compilado quando PLACA_TESTE e definido (teste/Makefile).
 * ========================================================================= */

#include "placa.h"

#if defined(PLACA_TESTE)

#include <stdio.h>
#include <stdlib.h>
#include "lcd.h"

/* Custo de um pulso de E, como na porta real: PW_EH + t_cicE. */
#define T_PULSO_TOTAL_US  (LCD_T_PULSO_US + LCD_T_CICLO_US)

lcd_ev_t lcd_teste_ev[LCD_TESTE_MAX_EV];
uint32_t lcd_teste_n;
uint32_t lcd_teste_perdidos;
uint32_t lcd_teste_leituras;
uint32_t lcd_teste_t_us;

static uint8_t  rs_atual;
static uint32_t ocupado_restante;
static uint8_t  nibble_baixo;     /* 4 bits: a proxima leitura e o 2o nibble */

static void registra(lcd_ev_tipo_t tipo, uint32_t valor)
{
    if (lcd_teste_n < LCD_TESTE_MAX_EV) {
        lcd_ev_t *e = &lcd_teste_ev[lcd_teste_n++];
        e->tipo  = tipo;
        e->valor = valor;
        e->rs    = rs_atual;
        e->t_us  = lcd_teste_t_us;
    } else {
        lcd_teste_perdidos++;
    }
}

void lcd_teste_limpar(void)
{
    lcd_teste_n = 0;
    lcd_teste_perdidos = 0;
    lcd_teste_leituras = 0;
}

void lcd_teste_ocupado(uint32_t n_ocupado)
{
    ocupado_restante = n_ocupado;
    nibble_baixo = 0;
}

/* ------------------------------------------------- a porta propriamente */
static uint8_t barramento;

void lcd_port_init(void)
{
    rs_atual = 0;
    barramento = 0;
    registra(EV_INIT, 0);
}

void lcd_port_rs(uint8_t nivel)
{
    rs_atual = nivel ? 1u : 0u;
    registra(EV_RS, rs_atual);
}

void lcd_port_dados(uint8_t v)
{
#if LCD_BITS == 4
    barramento = (uint8_t)(v & 0xF0u);   /* so D4-D7 existem */
#else
    barramento = v;
#endif
    registra(EV_DADOS, barramento);
}

void lcd_port_pulso_en(void)
{
    registra(EV_PULSO, barramento);
    lcd_teste_t_us += T_PULSO_TOTAL_US;
}

void lcd_port_espera_ms(uint8_t ms)
{
    registra(EV_ESPERA, (uint32_t)ms * 1000u);
    lcd_teste_t_us += (uint32_t)ms * 1000u;
}

void lcd_port_espera_40us(void)
{
    registra(EV_ESPERA, LCD_T_COMANDO_US);
    lcd_teste_t_us += LCD_T_COMANDO_US;
}

#if LCD_LER_OCUPADO
uint8_t lcd_port_ler(void)
{
    uint8_t ocupado = (ocupado_restante != 0u);
    uint8_t v;

#if LCD_BITS == 4
    /* 1o nibble: D7..D4 (D7 = ocupado); 2o nibble: D3..D0 = 0. */
    v = (uint8_t)((!nibble_baixo && ocupado) ? 0x80u : 0x00u);
    if (nibble_baixo && ocupado && ocupado_restante != LCD_TESTE_SEMPRE_OCUPADO) {
        ocupado_restante--;
    }
    nibble_baixo = (uint8_t)!nibble_baixo;
#else
    v = (uint8_t)(ocupado ? 0x80u : 0x00u);
    if (ocupado && ocupado_restante != LCD_TESTE_SEMPRE_OCUPADO) {
        ocupado_restante--;
    }
#endif

    lcd_teste_leituras++;
    registra(EV_LER, v);

    /* Um driver sem teto ficaria preso aqui para sempre - e o teste com
       ele. Melhor uma falha com explicacao do que um terminal parado. */
    if (lcd_teste_leituras > 4u * LCD_MAX_CONSULTAS) {
        printf("  [FALHA] mais de %u leituras seguidas do indicador de "
               "ocupado: falta o teto (LCD_MAX_CONSULTAS) em lcd_esperar\n",
               (unsigned)(4u * LCD_MAX_CONSULTAS));
        exit(2);
    }
    lcd_teste_t_us += T_PULSO_TOTAL_US + LCD_T_PULSO_US;   /* + t_AS */
    return v;
}
#endif

/* ------------------------------------------------------------ depuracao */
void lcd_teste_imprimir(void)
{
    static const char *nome[] = { "INIT", "RS", "DADOS", "PULSO", "ESPERA", "LER" };
    uint32_t i;

    for (i = 0; i < lcd_teste_n; i++) {
        const lcd_ev_t *e = &lcd_teste_ev[i];
        printf("    %4u  t=%8u us  RS=%u  %-6s 0x%02X (%u)\n",
               (unsigned)i, (unsigned)e->t_us, (unsigned)e->rs,
               nome[e->tipo], (unsigned)e->valor, (unsigned)e->valor);
    }
    if (lcd_teste_perdidos != 0u) {
        printf("    ... mais %u eventos fora do buffer\n",
               (unsigned)lcd_teste_perdidos);
    }
}

#endif /* PLACA_TESTE */
