#!/bin/sh
# sincronizar.sh -- copia o driver do display (code/lcd) para cada exemplo e
# refaz os zips publicados na pagina. Rode a partir de qualquer pasta:
#
#     sh code/sincronizar.sh
#
# O placa.h NAO e copiado: cada projeto escolhe a sua placa.
set -e
cd "$(dirname "$0")"

DRIVER="lcd.c lcd.h lcd_port.h lcd_port_picsimlab.c lcd_port_picsimlab.h
        lcd_port_xm118.c lcd_port_xm118.h lcd_port_test.c lcd_port_test.h"
EXEMPLOS="interrupcao_1"          # acrescente aqui os proximos exemplos

for ex in $EXEMPLOS; do
    for f in $DRIVER; do cp "lcd/$f" "$ex/$f"; done
    mkdir -p "$ex/teste"
    cp lcd/teste/Makefile lcd/teste/teste_lcd.c "$ex/teste/"
    echo "driver copiado para $ex"
done

for pasta in lcd $EXEMPLOS; do
    rm -f "$pasta.zip"
    zip -q -r "$pasta.zip" "$pasta" -x "*/out/*" "*/_build/*" "*/cmake/*" "*.bin"
    echo "$pasta.zip refeito"
done
