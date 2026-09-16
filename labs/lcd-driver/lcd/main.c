/* =====================================================================
 * main.c - R4: o display, e o custo da espera
 * MCU: PIC18F4550 - nucleo a 16 MHz - XC8
 * Microcontroladores - DENE/UFMT
 *
 * Este arquivo compila como esta. No MODO 1 ele mostra o texto fixo e um
 * contador que NAO aparece, porque lcd_u8() (Tarefa 7) esta vazia.
 *
 * CHAVES:  CH2-1 ON          (LCD - e o unico roteiro em que ele entra)
 *          CH5-3 e CH5-4 OFF, OBRIGATORIAMENTE (rele no PORTD)
 *          SWITCHS (PORTB)   todas em OFF
 *          CH3-6 OFF         (desliga o buzzer e libera RC2, ver adiante)
 *
 * Sem bloco #pragma config: na XM118 o bootloader e o dono das palavras
 * de configuracao e as diretivas da aplicacao sao ignoradas.
 * ===================================================================== */

#define _XTAL_FREQ 16000000UL

#include <xc.h>
#include <stdint.h>
#include "lcd.h"

/* ---------------------------------------------------------------------
 * O QUE ESTE PROGRAMA FAZ
 *
 *   1 -> Tarefa 7   contador crescente, escrito com a SUA lcd_u8()
 *   2 -> Tarefa 8   rampa que sobe e desce cruzando 100 -> 99
 *   3 -> Tarefa 9   um caractere e uma linha, medidos no pino auxiliar
 *   4 -> Tarefas 10 e 11   atualizacao completa de tela, medida
 * --------------------------------------------------------------------- */
#define MODO   1

/* Tarefa 11: 1 acrescenta lcd_limpar() DENTRO da regiao medida. */
#define LIMPAR_ANTES   0

/* ---------------------------------------------------------------------
 * PINO AUXILIAR DE MEDIDA (Tarefas 9, 10 e 11)
 *
 * Sobe antes do trecho a medir e desce depois: a largura do pulso na
 * ponta do osciloscopio E o tempo do trecho. Custa dois ciclos de
 * maquina, 500 ns - despreziveis diante dos 40 us de um comando, mas
 * some-os ao conferir a conta.
 *
 * RC2 e o pino do buzzer da Oficina 1, isolado pela CH3-6. Com a CH3-6
 * em OFF ele fica livre e da para prender a garra sem desmontar nada.
 * CONFIRME NA SERIGRAFIA - se na sua bancada RC2 nao servir, trocar as
 * duas linhas abaixo e o unico ajuste necessario.
 * --------------------------------------------------------------------- */
#define MEDIDA_LAT    LATCbits.LATC2
#define MEDIDA_TRIS   TRISCbits.TRISC2

#define MEDIDA_SOBE()   do { MEDIDA_LAT = 1; } while (0)
#define MEDIDA_DESCE()  do { MEDIDA_LAT = 0; } while (0)


/* =====================================================================
 * TAREFA 7 - o seu numero na tela
 *
 * Escreva um valor de 0 a 255 na posicao onde o cursor estiver.
 *
 * Escreva a versao INGENUA: so os digitos que o numero tem, sem nenhum
 * cuidado com o que ja estava na tela. Nao chame lcd_numero() do driver,
 * e nao olhe para ela ainda - a Tarefa 8 depende de voce ver primeiro o
 * que a sua versao faz.
 *
 * Antes de escrever, responda: por que '0' + digito funciona?
 *
 * Use lcd_dado() para mandar cada caractere.
 * ===================================================================== */
void lcd_u8(uint8_t v)
{
    (void)v;        /* apague esta linha ao escrever a funcao */

    /* ESCREVA AQUI */
}


/* --------------------------------------------------------------------- */
/*                          daqui para baixo, ja escrito                  */
/* --------------------------------------------------------------------- */

static void saidas_init(void)
{
    /* estado seguro PRIMEIRO, habilitar a saida DEPOIS - encontro 2 */
    MEDIDA_LAT  = 0;
    MEDIDA_TRIS = 0;
}

#if MODO == 4
/* Uma atualizacao completa: posiciona, escreve 16, posiciona, escreve 16.
   E a unidade de custo da Tarefa 10. */
static void tela_atualiza(uint8_t contador)
{
    lcd_posicao(0, 0);
    lcd_texto("Temp:      25.3 ");

    lcd_posicao(1, 0);
    lcd_texto("Ciclo:      ");
    lcd_numero(contador, 4);
}
#endif


void main(void)
{
    saidas_init();
    lcd_iniciar();

#if MODO == 1

    /* ---------------- Tarefa 7: contador crescente ------------------ */
    {
        uint8_t n = 0;

        lcd_posicao(0, 0);
        lcd_texto("Contador:");

        while (1) {
            lcd_posicao(1, 0);
            lcd_u8(n);              /* <<< a sua funcao */
            __delay_ms(500);
            n++;                    /* estoura de 255 para 0 de proposito */
        }
    }

#elif MODO == 2

    /* ---------------- Tarefa 8: a rampa que desce ------------------- */
    /* Sobe ate 105 e desce ate 95, sem parar. O que interessa acontece
       na descida, quando o contador passa de 100 para 99: olhe para a
       tela nesse instante e compare com a sua previsao P1.             */
    {
        uint8_t n = 95;
        int8_t  passo = 1;

        lcd_posicao(0, 0);
        lcd_texto("Sobe e desce:");

        while (1) {
            lcd_posicao(1, 0);
            lcd_u8(n);
            __delay_ms(500);

            if (n >= 105u) { passo = -1; }
            if (n <= 95u)  { passo =  1; }
            n = (uint8_t)(n + passo);
        }
    }

#elif MODO == 3

    /* ---------------- Tarefa 9: quatro bits contra oito -------------- */
    /* Rode este modo DUAS vezes: uma com LCD_BITS 4 em lcd.h, outra com
       8. Meca os dois pulsos e preencha a tabela.

       Pulso curto  = um caractere.
       Pulso longo  = uma linha de 16.

       Conte tambem os pulsos de E por byte, com a outra ponta em RE1.  */
    {
        uint8_t i;

        while (1) {

            lcd_posicao(0, 0);

            MEDIDA_SOBE();
            lcd_dado('A');
            MEDIDA_DESCE();

            __delay_ms(20);         /* separa os dois pulsos na tela */

            lcd_posicao(1, 0);

            MEDIDA_SOBE();
            for (i = 0; i < 16u; i++) {
                lcd_dado('X');
            }
            MEDIDA_DESCE();

            __delay_ms(200);        /* espaco para o disparo do osciloscopio */
        }
    }

#else

    /* ------------- Tarefas 10 e 11: o custo da tela inteira ---------- */
    /* O pulso mede a atualizacao completa. Anote a largura, converta em
       ciclos a 250 ns, e calcule o percentual do processador a cada
       100 ms e a cada 500 ms.

       Depois ponha LIMPAR_ANTES em 1, meca de novo, e OLHE PARA A TELA. */
    {
        uint8_t n = 0;

        while (1) {

            MEDIDA_SOBE();
#if LIMPAR_ANTES
            lcd_limpar();
#endif
            tela_atualiza(n);
            MEDIDA_DESCE();

            __delay_ms(100);
            n++;
        }
    }

#endif
}
