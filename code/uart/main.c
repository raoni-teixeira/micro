/**
 * @file   main.c
 * @brief  Serial (EUSART) com fila e interrupção: envio sem bloquear e eco
 *         de linhas recebidas.
 *
 * Microcontroladores - DENE/UFMT - 2026/2
 * Exemplo da aula 10. PIC18F4550, cristal de 16 MHz, 9600 bit/s, 8N1.
 *
 * O QUE O PROGRAMA FAZ
 *   - Ao ligar, manda "Ola, serial!".
 *   - A cada segundo manda "t = N s".
 *   - Uma linha digitada no terminal (terminada em Enter) volta como
 *     "recebido: <linha>".
 *
 * NO PICSIMLAB
 *   - Relogio da placa em 16 MHz. Com 8 MHz a taxa cai para 4796 bit/s e o
 *     terminal mostra lixo repetido.
 *   - Peca "IO Virtual Term" ligada em RC6 (TX) e RC7 (RX), com final de
 *     linha (CR ou LF) ligado. Sem final de linha a resposta nunca vem.
 *
 * AS PARTES (explicadas em labs/serial-referencia.html)
 *   1. uart_iniciar(): taxa, formato e pinos. O 416 vem da conta da aula.
 *   2. a fila circular: o main poe bytes nela e segue em frente.
 *   3. a ISR: tira um byte da fila sempre que o transmissor fica livre,
 *      e guarda os bytes recebidos numa linha.
 *   4. ligar as interrupcoes (PEIE e GIE), em main().
 */

#include <xc.h>
#include <stdint.h>
#include <stdio.h>

#define _XTAL_FREQ 16000000UL       /* para __delay_ms */

/* Bits de configuracao: so no simulador, que comeca do zero. No XM118
   quem decide e o bootloader (ver code/interrupcao_1/README.md). */
#pragma config FOSC = HS, CPUDIV = OSC1_PLL2   // CPU = cristal, 16 MHz
#pragma config PLLDIV = 4, USBDIV = 1
#pragma config PWRT = ON, BOR = ON, BORV = 2, VREGEN = OFF
#pragma config WDT = OFF, LVP = OFF, PBADEN = OFF, MCLRE = ON, XINST = OFF

/* ------------------------------------------------------------ transmissao */

#define FILA 64                     /* potencia de 2: o % vira um AND */
static volatile uint8_t fila[FILA];
static volatile uint8_t entra = 0;  /* so o main escreve */
static volatile uint8_t sai = 0;    /* so a ISR escreve  */

void uart_iniciar(void)
{
    TRISCbits.TRISC6 = 0;      /* TX: saida */
    TRISCbits.TRISC7 = 1;      /* RX: entrada */

    BAUDCONbits.BRG16 = 1;     /* gerador de 16 bits           */
    TXSTAbits.BRGH    = 1;     /* alta velocidade -> divisor 4 */
    SPBRGH = 0x01;             /* 416 = 0x01A0                 */
    SPBRG  = 0xA0;

    TXSTAbits.SYNC = 0;        /* assincrono */
    RCSTAbits.SPEN = 1;        /* liga o periferico, assume os dois pinos */
    TXSTAbits.TXEN = 1;        /* habilita transmissao */
    RCSTAbits.CREN = 1;        /* habilita recepcao    */

    PIE1bits.RCIE = 1;         /* byte recebido pede interrupcao.
                                  TXIE fica desligado: so liga quando
                                  houver algo na fila. */
}

/* Chamada SO pelo main, nunca pela ISR: com a fila cheia ela espera a ISR
   esvaziar, e dentro da ISR essa espera nunca terminaria. */
void uart_enfileirar(uint8_t b)
{
    uint8_t prox = (uint8_t)((entra + 1u) % FILA);
    while (prox == sai) { }    /* fila cheia: raro, e aqui sim espera */
    fila[entra] = b;
    entra = prox;              /* so depois de o byte estar na fila */
    PIE1bits.TXIE = 1;         /* acorda o transmissor */
}

/* printf chama putch para cada caractere: basta defini-la. */
void putch(char c)
{
    uart_enfileirar((uint8_t)c);
}

/* -------------------------------------------------------------- recepcao */

static volatile char linha[24];
static volatile uint8_t n = 0;
static volatile uint8_t linha_pronta = 0;

/* -------------------------------------------- tratamento de interrupcao */

/* Sem IPEN, todas as fontes caem neste unico vetor (0x0008). */
void __interrupt() isr(void)
{
    /* Transmissao: TXIF = 1 quer dizer "TXREG livre". */
    if (PIE1bits.TXIE && PIR1bits.TXIF) {
        if (entra == sai) {
            PIE1bits.TXIE = 0;             /* nada a enviar: desliga a fonte */
        } else {
            TXREG = fila[sai];             /* escrever em TXREG limpa TXIF */
            sai = (uint8_t)((sai + 1u) % FILA);
        }
    }

    /* Recepcao. */
    if (PIE1bits.RCIE && PIR1bits.RCIF) {
        if (RCSTAbits.OERR) {              /* estouro: a recepcao PAROU */
            RCSTAbits.CREN = 0;
            RCSTAbits.CREN = 1;            /* religar e a unica saida   */
        }

        char c = RCREG;                    /* ler RCREG limpa RCIF */

        if (linha_pronta) {
            /* o main ainda nao leu a linha anterior: descarta */
        } else if (c == '\n' || c == '\r') {
            if (n > 0u) {                  /* ignora o \n de um \r\n */
                linha[n] = '\0';
                linha_pronta = 1;
                n = 0;
            }
        } else if (n < sizeof(linha) - 1u) {
            linha[n++] = c;
        }
    }
}

/* ------------------------------------------------------------------ main */

void main(void)
{
    uint16_t t = 0;
    uint8_t ms100 = 0;

    ADCON1 = 0x0F;              /* todos os pinos digitais (padrao do curso) */

    uart_iniciar();
    INTCONbits.PEIE = 1;        /* EUSART e periferica: precisa do PEIE */
    INTCONbits.GIE  = 1;        /* ... e do GIE. Sem estas duas linhas a
                                   fila enche e o programa trava no while. */

    printf("Ola, serial!\r\n");

    while (1) {
        __delay_ms(100);        /* o laco "trabalha"; a serial anda sozinha */

        if (++ms100 == 10u) {
            ms100 = 0;
            printf("t = %u s\r\n", ++t);
        }

        if (linha_pronta) {
            printf("recebido: %s\r\n", (const char *)linha);
            linha_pronta = 0;   /* so agora a ISR pode usar o buffer */
        }
    }
}
