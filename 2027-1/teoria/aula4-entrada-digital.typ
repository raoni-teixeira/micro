// Aula 4 — Entrada digital: o pino como sensor
// 2027/1 — aula nova (planejamento, Encontro 4). Esqueleto: so a estrutura.
// Material a aproveitar de 2026/2:
//   teoria/aula4-adc-e-lm35.typ   — "Entrada digital: PORTx e o buffer"
//   teoria/aula7-interrupcoes-e-repique.typ — "O ruido de contato"
//   labs/O1-um-pino-dois-significados.typ   — PBADEN e ADCON1
//   labs/R5-entrada-e-conversor.typ          — Parte 1
// Microcontroladores — DENE/UFMT — Raoni F. S. Teixeira

#import "estilo.typ": *
#import "figuras.typ": *
#show: conf.with(
  titulo: "Aula 4 — Entrada digital: o pino como sensor",
  subtitulo: "Pino flutuante, estado inicial e repique",
)

#objetivos[
- Explicar por que um pino de entrada solto não lê nem 0 nem 1, e escolher entre pull-up e pull-down pelo circuito, não pelo código.
- Estimar o tempo de subida do pull-up fraco contra $T_"cy"$ e justificar a regra: o estado inicial é lido, nunca presumido.
- Usar $V_"IL"$, $V_"IH"$ e o tipo de buffer do pino (TTL ou Schmitt) para dizer o que a entrada garante com borda lenta, e por que o Schmitt não resolve o repique.
- Diagnosticar um botão que "não funciona" por canal analógico ativo (`PBADEN`, `ADCON1`).
- Escrever um debounce por varredura que espera e confirma, e mostrar um sinal que a versão "conta e espera" aceita.
]

= Três defeitos, nenhum de interrupção
// Pino flutuante, estado inicial presumido, repique: os defeitos do código de 2026/2.

= O pino de entrada é alta impedância
// Demonstração: pino flutuante no osciloscópio, mão chegando perto.

= Pull-up e pull-down
// RBPU: pull-up fraco só em PORTB, sem pull-down — daí o ativo baixo.
// No XM118 todo pino de PORTB já tem resistor externo (RB6/PGC para baixo, os
// demais para cima): lá o RBPU é redundante e o pino flutuante não aparece. Ele só
// aparece na protoboard (R5).

= O pull-up não é instantâneo
// Constante RC do pull-up fraco contra Tcy = 250 ns.
// Caso real: button_state = RELEASED conta um aperto fantasma no PICGenios.

= O que a folha de dados garante
// O mesmo pino tem buffers diferentes conforme a função: RB0 lido como E/S
// digital passa por buffer TTL; como INT0 (e SDA), por Schmitt (ST). Conferir na
// tabela de PORTB. VIL e VIH; diodos de proteção.
// A histerese limpa borda lenta e ruído perto do limiar, mas não o repique: cada
// quique cruza os dois limiares com folga. "O Schmitt limpa cada borda, mas não
// sabe quantas bordas deveriam existir." 

= O botão que não funciona: `PBADEN` e `ADCON1`
// Volta no encontro 12 (I2C em RB0/RB1).

= Repique
// Física do contato mecânico; duração medida no R5, na protoboard.
// Ordem de demonstração (código de 2026/2, INT0 + Timer0): a versão sem o teste de
// RB0 conta certo com clique rápido e conta dobrado ao segurar e soltar; a versão
// com o teste conta certo nos dois casos. O repique acontece nos dois sentidos, e
// a janela tinha que começar na soltura.

= Debounce por varredura
// Máquina RELEASED/PRESSED. "Conta e espera" contra "espera e confirma".

#divergencia[
  O PICSimLab simula repique, mas a duração e a forma não são as de um botão real: a constante do filtro se mede na bancada. E o pino solto tem valor fixo no simulador, em vez de ruído.
]

= O custo da espera
// O __delay_ms(30) bloqueia o processador: gancho para o encontro 8.

= Previsão para o R5

= Exercícios
// Candidata ao M4: dado o código A (conta e espera) e o B (espera e confirma),
// descreva um sinal no pino que A conta e B não.
