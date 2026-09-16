/* =========================================================================
 * lcd.c - display alfanumerico HD44780 no XM118
 * Microcontroladores - DENE/UFMT
 *
 * Leia este arquivo ANTES de gravar qualquer coisa. Os comentarios marcados
 * com [T#] sao as perguntas do R4: nenhuma delas esta respondida aqui, e
 * todas tem resposta na folha de dados ou na bancada.
 * ========================================================================= */

#include <xc.h>
#include "lcd.h"

#ifndef _XTAL_FREQ
#define _XTAL_FREQ 16000000UL       /* 16 MHz: o bootloader e quem manda */
#endif

/* =======================================================================
 * O pulso de habilitacao.
 *
 * O display nao le o barramento quando o valor aparece nos fios: ele le na
 * borda de descida de E.
 *
 * [T1a] Sao dois atrasos, um com E alto e outro depois de baixa-lo. Por que
 *       dois, e por que em lugares diferentes?
 * [T1b] Cada um atende a um minimo DIFERENTE da folha de dados. Nomeie os
 *       dois e escreva os valores.
 * [T1c] Um ciclo de maquina (250 ns a 16 MHz) ja seria maior que o minimo
 *       de largura de pulso. Por que o driver gasta 1 us - quatro vezes
 *       mais - em vez de um unico ciclo?
 * [T2]  Meca os dois no osciloscopio, disparo na borda de subida de E.
 * ======================================================================= */
static void lcd_pulso(void)
{
    LCD_E_LAT = 1;
    __delay_us(LCD_T_PULSO_US);
    LCD_E_LAT = 0;
    __delay_us(LCD_T_CICLO_US);
}

/* =======================================================================
 * Meio byte no barramento.
 *
 * [P2] A linha abaixo le LCD_DADOS_LAT, e nao PORTD. Troque por PORTD,
 *      grave, e explique o que acontece a partir do que esta ligado ao
 *      PORTD deste kit. A previsao P2 da aula 3 e sobre isto.
 * ======================================================================= */
#if LCD_BITS == 4
static void lcd_nibble(uint8_t valor)
{
    LCD_DADOS_LAT = (uint8_t)((LCD_DADOS_LAT & 0x0Fu) | (valor & 0xF0u));
    lcd_pulso();
}
#endif

/* =======================================================================
 * Um byte, comando ou dado.
 *
 * [T9]  Em quatro bits sao dois pulsos por byte; em oito, um so. Conte os
 *       pulsos no osciloscopio e confirme antes de medir tempo.
 * [Ex3.6] A espera de execucao esta AQUI, uma vez por byte - e nao dentro
 *       de lcd_pulso. Calcule o que aconteceria com o tempo da interface
 *       se ela estivesse la, e confira com a medida da Tarefa 9.
 * ======================================================================= */
static void lcd_byte(uint8_t valor, uint8_t eh_dado)
{
    LCD_RS_LAT = eh_dado ? 1 : 0;

#if LCD_BITS == 4
    lcd_nibble(valor);
    lcd_nibble((uint8_t)(valor << 4));
#else
    LCD_DADOS_LAT = valor;
    lcd_pulso();
#endif

    __delay_us(LCD_T_COMANDO_US);
}

void lcd_comando(uint8_t c)
{
    lcd_byte(c, 0);
    if (c == 0x01u || c == 0x02u) {
        __delay_ms(LCD_T_LENTO_MS);  /* limpar e voltar ao inicio sao lentos */
    }
}

void lcd_dado(uint8_t d)
{
    lcd_byte(d, 1);
}

/* =======================================================================
 * Inicializacao.
 *
 * [T3] Preencha, comando a comando, o que cada valor abaixo configura.
 * [T4] Troque 0x0C por 0x0F e descreva o que mudou na tela, e por que.
 * [T5] Remova o __delay_ms(LCD_T_ENERGIA_MS) - sao os 50 ms. O display
 *      funciona? Funciona SEMPRE? Ligue e desligue o kit tres vezes antes
 *      de responder. Depois explique para quem e essa espera: para o
 *      controlador do display, ou para outra coisa?
 * [T6] Remova UMA das tres repeticoes de 0x30. Teste de dois jeitos:
 *      energizando o kit cinco vezes, e depois apertando o reset cinco
 *      vezes sem desligar. Os dois casos se comportam igual? Se nao,
 *      quantos estados diferentes o display pode estar ocupando quando o
 *      microcontrolador reinicia sozinho? Nomeie cada um.
 * ======================================================================= */
void lcd_iniciar(void)
{
    LCD_DADOS_LAT = 0x00;            /* LAT antes de TRIS: encontro 2 */
    LCD_RS_LAT    = 0;
    LCD_E_LAT     = 0;

#if LCD_BITS == 4
    LCD_DADOS_TRIS &= 0x0Fu;         /* so os quatro bits altos viram saida */
#else
    LCD_DADOS_TRIS = 0x00;
#endif
    LCD_RS_TRIS = 0;
    LCD_E_TRIS  = 0;

    __delay_ms(LCD_T_ENERGIA_MS);    /* [T5] */

#if LCD_BITS == 4
    lcd_nibble(0x30); __delay_ms(5);     /* [T6] */
    lcd_nibble(0x30); __delay_us(150);   /* [T6] */
    lcd_nibble(0x30); __delay_us(150);   /* [T6] */
    lcd_nibble(0x20);                    /* [T3] */
    lcd_comando(0x28);                   /* [T3] */
#else
    lcd_comando(0x30); __delay_ms(5);    /* [T6] */
    lcd_comando(0x30); __delay_us(150);  /* [T6] */
    lcd_comando(0x30); __delay_us(150);  /* [T6] */
    lcd_comando(0x38);                   /* [T3] */
#endif

    lcd_comando(0x0C);                   /* [T3] [T4] */
    lcd_comando(0x06);                   /* [T3] */
    lcd_comando(0x01);                   /* [T3] */
}

/* ================================================================= texto */
void lcd_limpar(void)
{
    lcd_comando(0x01);
}

/* A primeira linha da tela comeca no endereco 0x00 e a segunda em 0x40 -
   nao em 0x10. O endereco e da memoria do controlador, e nao da posicao
   na tela. Aqui, `linha` vale 0 para a primeira e 1 para a segunda. */
void lcd_posicao(uint8_t linha, uint8_t coluna)
{
    uint8_t base = (linha == 0u) ? 0x00u : 0x40u;
    lcd_comando((uint8_t)(0x80u | (base + coluna)));
}

void lcd_texto(const char *s)
{
    while (*s != '\0') {
        lcd_dado((uint8_t)(*s++));
    }
}

/* =======================================================================
 * Numero com largura fixa.
 *
 * [T8] Chegue aqui SO DEPOIS de ter escrito o seu lcd_u8() da Tarefa 7 e
 *      de ter visto o que ele faz quando o contador cai de 100 para 99.
 *      Entao compare: o que esta funcao faz de diferente, e por que isso
 *      resolve o que voce viu na tela?
 * ======================================================================= */
void lcd_numero(uint16_t v, uint8_t largura)
{
    char buf[6];
    uint8_t n = 0;

    do {
        buf[n++] = (char)('0' + (v % 10u));
        v /= 10u;
    } while (v != 0u && n < sizeof(buf));

    while (largura > n) {                 /* preenche a esquerda */
        lcd_dado(' ');
        largura--;
    }
    while (n != 0u) {
        lcd_dado((uint8_t) buf[--n]);
    }
}

/* 253 -> "25.3" ; -47 -> "-4.7"
   A parte inteira sai com a largura que ela realmente ocupa: com largura
   fixa em 2, um valor de um digito so viria precedido de espaco, e o sinal
   ficaria separado do numero. */
void lcd_decimos(int16_t d)
{
    uint16_t inteiro;

    if (d < 0) {
        lcd_dado('-');
        d = (int16_t)(-d);
    }

    inteiro = (uint16_t)(d / 10);
    lcd_numero(inteiro, (inteiro > 9u) ? 2u : 1u);
    lcd_dado('.');
    lcd_dado((uint8_t)('0' + (d % 10)));
}
