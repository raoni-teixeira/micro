/* =========================================================================
 * lcd_port_test.h - "placa" de teste: roda no PC, com gcc
 *
 * Em vez de escrever em LAT, cada funcao de porta REGISTRA um evento num
 * buffer, com um relogio virtual em microssegundos. Os casos de teste em
 * teste/ leem esse registro e conferem a sequencia contra a folha de
 * dados do HD44780 - antes de qualquer tela em branco na bancada.
 *
 * LCD_BITS e LCD_LER_OCUPADO podem vir da linha de comando
 * (-DLCD_BITS=8 -DLCD_LER_OCUPADO=1): o mesmo teste cobre todas as
 * combinacoes que as placas reais usam.
 * ========================================================================= */

#ifndef LCD_PORT_TEST_H
#define LCD_PORT_TEST_H

#include <stdint.h>

#ifndef LCD_BITS
#define LCD_BITS 4
#endif

#ifndef LCD_LER_OCUPADO
#define LCD_LER_OCUPADO 0
#endif

typedef enum {
    EV_INIT,        /* lcd_port_init                                     */
    EV_RS,          /* lcd_port_rs:     valor = nivel                    */
    EV_DADOS,       /* lcd_port_dados:  valor = byte posto no barramento */
    EV_PULSO,       /* lcd_port_pulso_en: valor = barramento na descida  */
    EV_ESPERA,      /* espera_ms / espera_40us: valor = microssegundos   */
    EV_LER          /* lcd_port_ler:    valor = o que o "display" deu    */
} lcd_ev_tipo_t;

typedef struct {
    lcd_ev_tipo_t tipo;
    uint32_t      valor;
    uint8_t       rs;       /* nivel de RS no momento do evento */
    uint32_t      t_us;     /* relogio virtual no momento do evento */
} lcd_ev_t;

#define LCD_TESTE_MAX_EV 4096u

/* Registro (preenchido pelas funcoes de porta). */
extern lcd_ev_t lcd_teste_ev[LCD_TESTE_MAX_EV];
extern uint32_t lcd_teste_n;          /* eventos guardados              */
extern uint32_t lcd_teste_perdidos;   /* eventos alem do buffer         */
extern uint32_t lcd_teste_leituras;   /* chamadas a lcd_port_ler, total */
extern uint32_t lcd_teste_t_us;       /* relogio virtual                */

/* Zera o registro (o relogio continua andando). */
void lcd_teste_limpar(void);

/* Respostas de lcd_port_ler: as primeiras 'n_ocupado' LEITURAS DE ESTADO
   devolvem o indicador de ocupado (D7 = 1); as seguintes, livre.
   Em 4 bits, uma leitura de estado sao duas chamadas a lcd_port_ler.
   Use LCD_TESTE_SEMPRE_OCUPADO para simular um display que nao responde. */
#define LCD_TESTE_SEMPRE_OCUPADO 0xFFFFFFFFu
void lcd_teste_ocupado(uint32_t n_ocupado);

/* Imprime o registro, um evento por linha - para ver ONDE falhou. */
void lcd_teste_imprimir(void);

#endif /* LCD_PORT_TEST_H */
