/**
 * @file   main.c
 * @brief  Relógio mm:ss no LCD, contado pela interrupção do Timer0.
 * @author raoni
 * @date   2026-10-05
 *
 * Microcontroladores - DENE/UFMT - 2026/2
 * Primeiro código da aula de interrupção.
 * PIC18F4550, cristal de 16 MHz. A placa (PICSimLab ou XM118) é escolhida
 * em placa.h; este arquivo não muda de uma para a outra.
 *
 * O TEMPORIZADOR
 * Um temporizador é um registrador que incrementa a cada pulso de uma
 * fonte de contagem, sem que a CPU execute nenhuma instrução. Ao passar do
 * valor máximo, ele volta a zero e levanta um indicador (TMR0IF). O
 * indicador não se apaga sozinho: a ISR precisa zerá-lo, senão a
 * interrupção dispara de novo assim que termina.
 *
 * A CONTA DE 1 SEGUNDO
 *   Fcy        = 16 MHz / 4         = 4 MHz
 *   contagem   = 4 MHz / 256 (pré)  = 15625 por segundo
 *   recarga    = 65536 - 15625      = 49911 = 0xC2F7
 * Em 16 bits, o Timer0 conta de 0xC2F7 até estourar: exatamente 1 s.
 *
 * DIVISÃO DO TRABALHO
 *   ISR  - só conta: recarrega o Timer0 e avança seg/min. É curta porque,
 *          enquanto ela roda, nenhuma outra interrupção é atendida.
 *   main - só mostra: copia seg/min e escreve no LCD. O LCD é lento
 *          (40 us por caractere) e por isso NUNCA é usado dentro da ISR.
 * seg e min são volatile porque mudam fora do fluxo do main: sem isso o
 * compilador pode guardar o valor num registrador e nunca reler.
 *
 * LIMITAÇÃO (para discutir em aula)
 * A recarga é feita por software, alguns ciclos depois do estouro, e
 * escrever em TMR0L zera o pré-divisor. As contagens perdidas a cada
 * segundo fazem o relógio atrasar alguns segundos por dia. Medir esse
 * atraso, e corrigi-lo, é exercício.
 */

#include <xc.h>
#include <stdint.h>

#include "placa.h"
#include "lcd.h"

/* Bits de configuracao: so no simulador, que comeca do zero. No XM118 eles
   foram gravados junto com o bootloader, e um #pragma config da aplicacao
   seria ignorado em silencio -- o codigo que veio antes do seu (aula 0).
   O bootloader tambem desloca o vetor de interrupcao (aula 7); o projeto do
   MPLAB do laboratorio ja faz esse deslocamento. */
#if defined(PLACA_PICSIMLAB)
// Cristal de 16 MHz direto na CPU (HS, sem PLL): Fosc = 16 MHz, Fcy = 4 MHz
#pragma config FOSC = HS, CPUDIV = OSC1_PLL2   // CPU = oscilador / 1
#pragma config PLLDIV = 4, USBDIV = 1          // 16 MHz / 4 = 4 MHz na PLL (nao usada)
#pragma config PWRT = ON                       // espera a alimentacao estabilizar no reset
#pragma config BOR = ON, BORV = 2              // reset se Vdd < 2,79 V
#pragma config VREGEN = OFF                    // regulador USB desligado
#pragma config WDT = OFF, LVP = OFF, PBADEN = OFF, MCLRE = ON, XINST = OFF
#endif

volatile uint8_t seg = 0; 
volatile uint8_t min = 0;

void setup(void) {
    ADCON1 = 0x0F; // Todos os pinos digitais (padrao do curso)

    // Pre-carga ANTES de ligar o Timer0: senao o primeiro intervalo comeca
    // de um valor qualquer. TMR0H primeiro (buffer), TMR0L transfere os dois.
    // 16 MHz / 4 / 256 = 15625 contagens/s -> 65536 - 15625 = 0xC2F7
    TMR0H = 0xC2;
    TMR0L = 0xF7;

    T0CON = 0x87; // Timer0 ligado (bit 7), 16 bits, interno, prescaler 1:256

    INTCONbits.TMR0IF = 0; // Limpa a flag de interrupção do Timer0
    INTCONbits.TMR0IE = 1; // Habilita a interrupção do Timer0
    INTCONbits.GIE = 1; // Habilita as interrupções globais
}

void __interrupt() isr(void){
    
    if (INTCONbits.TMR0IF) { // Verifica se a interrupção do Timer0 ocorreu
        INTCONbits.TMR0IF = 0; // Limpa a flag de interrupção
        TMR0H = 0xC2; // Recarrega o Timer0 para gerar uma interrupção a cada 1 segundo
        TMR0L = 0xF7;

        seg++; // Incrementa os segundos
        if (seg >= 60) { // Se os segundos chegarem a 60
            seg = 0; // Zera os segundos
            min++; // Incrementa os minutos
            if (min >= 60) { // Se os minutos chegarem a 60
                min = 0; // Zera os minutos
            }
        }
    }
}

static void mostrar_2dig(uint8_t v) {
    lcd_dado((uint8_t)('0' + v / 10u));
    lcd_dado((uint8_t)('0' + v % 10u));
}

void main(void){
    uint8_t s, m;
    uint8_t mostrado = 0xFF;   // nenhum segundo mostrado ainda: forca a 1a escrita

    setup();
    lcd_iniciar();

    lcd_posicao(0, 0);
    lcd_texto("Relogio");

    while(1) {
        // Copia min e seg juntos: sem isso a ISR pode virar 00:59 -> 01:00
        // entre as duas leituras e o display mostra 01:59.
        INTCONbits.TMR0IE = 0;
        s = seg;
        m = min;
        INTCONbits.TMR0IE = 1;

        // So escreve quando o segundo muda (aula 3): o resto do tempo o laco
        // fica livre para outra tarefa.
        if (s != mostrado) {
            mostrado = s;
            lcd_posicao(1, 0);
            mostrar_2dig(m);
            lcd_dado(':');
            mostrar_2dig(s);
        }
    }
}
