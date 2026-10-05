# Testes do driver de LCD no PC: o lcd.c contra a "placa" lcd_port_test.c.
#
#   make            roda as quatro configuracoes
#   make t4         so 4 bits, sem leitura do ocupado (etc.)
#   make limpar

CC     ?= gcc
CFLAGS  = -std=c99 -Wall -Wextra -g -I.. -DPLACA_TESTE
FONTES  = teste_lcd.c ../lcd.c ../lcd_port_test.c

CONFIGS = t4 t8 t4_ocupado t8_ocupado

.PHONY: all limpar $(CONFIGS)
all: $(CONFIGS)

t4:         ; @$(CC) $(CFLAGS) -DLCD_BITS=4 -DLCD_LER_OCUPADO=0 $(FONTES) -o $@.bin && ./$@.bin
t8:         ; @$(CC) $(CFLAGS) -DLCD_BITS=8 -DLCD_LER_OCUPADO=0 $(FONTES) -o $@.bin && ./$@.bin
t4_ocupado: ; @$(CC) $(CFLAGS) -DLCD_BITS=4 -DLCD_LER_OCUPADO=1 $(FONTES) -o $@.bin && ./$@.bin
t8_ocupado: ; @$(CC) $(CFLAGS) -DLCD_BITS=8 -DLCD_LER_OCUPADO=1 $(FONTES) -o $@.bin && ./$@.bin

limpar:
	rm -f *.bin
