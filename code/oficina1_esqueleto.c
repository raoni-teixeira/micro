/* =====================================================================
 * musica_esqueleto.c — Oficina 1, Parte III
 * MCU: PIC18F4550 · nucleo a 16 MHz · XC8
 *
 * Este arquivo compila como esta. Ele so nao faz nada, porque as
 * quatro funcoes marcadas E1 a E4 estao vazias. Preencha-as na ordem.
 *
 * CHAVES:  CH3-6 ON  (BUZZER em RC2)
 *          CH3-5 OFF (COOLER disputa o mesmo pino)
 *          CH3-7 OFF (DAC disputa o mesmo pino)
 *          Nao pressionar SW2 nem SW3 (RC0/RC1).
 *
 * Sem bloco #pragma config: na XM118 o bootloader e o dono das
 * palavras de configuracao e as diretivas da aplicacao sao ignoradas.
 * ===================================================================== */

#define _XTAL_FREQ 16000000UL

#include <xc.h>
#include <stdint.h>

#define MODO_CALIBRACAO   1        /* 1 = tom continuo, 0 = melodia */

/* ---------------------------------------------------------------------
 * CALIBRACAO — ver secao 14.2 do roteiro
 *
 * Tempo de UMA iteracao de espera(), em DECIMOS de microssegundo.
 * O valor abaixo e um chute. Meca o seu:
 *
 *     DECIMOS_US_POR_ITER = 10000000 / (2 * f * UNIDADES_TESTE)
 *
 * onde f e a frequencia medida com MODO_CALIBRACAO = 1.
 * --------------------------------------------------------------------- */

#define DECIMOS_US_POR_ITER  25u   /* <<< AJUSTAR APOS MEDIR */
#define UNIDADES_TESTE      400u

/* ------------------------- mapeamento -------------------------------- */
#define BUZZER_LAT   LATCbits.LATC2      /* CH3-6 ON */
#define BUZZER_TRIS  TRISCbits.TRISC2

#define LEDS_LAT     LATD
#define LEDS_TRIS    TRISD

/* ---------------------------------------------------------------------
 * TABELA DE NOTAS — meio-periodo em microssegundos
 *     meio_periodo_us = 1000000 / (2 * frequencia_Hz)
 * --------------------------------------------------------------------- */
#define DO4   1911u      /* 261,63 Hz */
#define RE4   1703u      /* 293,66 Hz */
#define MI4   1517u      /* 329,63 Hz */
#define FA4   1432u      /* 349,23 Hz */
#define SOL4  1276u      /* 392,00 Hz */
#define LA4   1136u      /* 440,00 Hz */
#define SI4   1012u      /* 493,88 Hz */
#define DO5    956u      /* 523,25 Hz */
#define PAUSA    0u

/* Ode a Alegria — primeira frase. Beethoven, dominio publico. */
static const uint16_t MELODIA[] = {
    MI4,  MI4,  FA4,  SOL4,
    SOL4, FA4,  MI4,  RE4,
    DO4,  DO4,  RE4,  MI4,
    MI4,  RE4,  RE4
};

/* Duracao em unidades de 100 ms. */
static const uint8_t DURACAO[] = {
    4, 4, 4, 4,
    4, 4, 4, 4,
    4, 4, 4, 4,
    6, 2, 8
};

#define N_NOTAS  (sizeof(MELODIA) / sizeof(MELODIA[0]))


/* =====================================================================
 * E1 — laco de espera parametrizavel
 *
 * Execute exatamente `unidades` iteracoes. O corpo do laco DEVE conter
 * NOP(): sem ele o laco nao tem efeito observavel e o compilador tem
 * liberdade para elimina-lo — o atraso desapareceria.
 *
 * Nao use __delay_us() aqui: ela exige constante de compilacao.
 * ===================================================================== */
static void espera(uint16_t unidades)
{
    /* ESCREVA AQUI */
}


/* =====================================================================
 * E2 — onda quadrada de 50% no buzzer
 *
 *   unidades = iteracoes de espera() por meio-periodo
 *   ciclos   = numero de periodos completos
 *
 * Escreva no LAT, nunca no PORT.
 * ===================================================================== */
static void tom_bruto(uint16_t unidades, uint16_t ciclos)
{
    /* ESCREVA AQUI */
}


/* =====================================================================
 * E3 — tocar uma nota dada em meio-periodo (us) por uma duracao (ms)
 *
 *   unidades = (meio_periodo_us * 10) / DECIMOS_US_POR_ITER
 *   ciclos   = (duracao_ms * 500)     / meio_periodo_us
 *
 * Requisitos:
 *   - meio_periodo_us == PAUSA  ->  silencio, pino em nivel baixo,
 *     pela duracao pedida (use __delay_ms(1) num laco);
 *   - proteger as multiplicacoes contra estouro de 16 bits;
 *   - se unidades ou ciclos derem zero, forcar 1;
 *   - deixar o pino em nivel baixo ao sair.
 *
 * Antes de escrever, calcule a mao o maior valor de cada produto.
 * ===================================================================== */
static void nota(uint16_t meio_periodo_us, uint16_t duracao_ms)
{
    /* ESCREVA AQUI */
}


/* =====================================================================
 * E5 (opcional, secao 15) — mesma nota, timbres diferentes.
 * Mantenha (a + b) constante e varie a proporcao.
 * ===================================================================== */
#if 0
static void tom_assimetrico(uint16_t a, uint16_t b, uint16_t ciclos)
{
    /* ESCREVA AQUI */
}
#endif


/* --------------------------- ja escrito ------------------------------ */
static void saidas_init(void)
{
    /* estado seguro PRIMEIRO */
    LEDS_LAT   = 0x00;
    BUZZER_LAT = 0;

    /* so entao habilitar as saidas */
    LEDS_TRIS   = 0x00;
    BUZZER_TRIS = 0;
}


void main(void)
{
    saidas_init();

#if MODO_CALIBRACAO

    /* Tom continuo com numero fixo de iteracoes por meio-periodo.
       Meca a frequencia e aplique a formula do cabecalho.          */
    LEDS_LAT = 0xFF;
    while (1) {
        tom_bruto(UNIDADES_TESTE, 1000u);
    }

#else

    while (1) {

        /* =============================================================
         * E4 — percorra MELODIA[] e DURACAO[] em paralelo.
         *
         *   - duracao da nota i = DURACAO[i] * 100 milissegundos
         *     (cuidado com o tipo do produto);
         *   - silencio de 15 ms entre uma nota e a seguinte;
         *   - animacao dos LEDs, linha dada:
         *
         *         LEDS_LAT = (uint8_t)(1u << (i & 0x07u));
         * ============================================================= */

        /* ESCREVA AQUI */

        LEDS_LAT = 0x00;
        __delay_ms(2000);
    }

#endif
}
