#!/bin/sh
# Compila as notas de aula da serie nova, nas duas versoes.
# A versao -gab fica fora do repositorio publico (ver .gitignore).
# A serie antiga (aula*-microcontroladores) nao entra: usa outro estilo.
AULAS="aula0-como-se-programa
aula1-memoria-e-datasheet
aula2-clock-e-execucao
aula3-paralelo-e-display
aula4-adc-e-lm35
aula5-temporizadores-e-pwm
aula7-interrupcoes-e-repique
aula8-potencia-e-reset
aula9-liga-desliga-e-histerese
aula10-comunicacao-serial
aula11-i2c-e-memoria
aula13-controle-embarcado"

# PENDENTES (fonte na outra maquina, nao recompilar por cima do PDF publicado):
#   aula3 — o PDF publicado tem 4909 palavras; esta fonte gera 3850.
#   aula4 — falta adc-circuito-pb.svg.
PENDENTES="aula3-paralelo-e-display aula4-adc-e-lm35"

for b in $AULAS; do
  [ -f "$b.typ" ] || { echo "faltando: $b.typ"; continue; }
  case " $PENDENTES " in *" $b "*) echo "pulando $b (fonte desatualizada)"; continue;; esac
  typst compile --root . "$b.typ" "$b.pdf" || echo "ERRO em $b"
  typst compile --root . --input gab=1 "$b.typ" "$b-gab.pdf" || echo "ERRO em $b (gab)"
done

# Minitestes
for f in M*.typ; do
  [ -e "$f" ] || continue
  b="${f%.typ}"
  typst compile --root . "$f" "$b.pdf" || echo "ERRO em $b"
  typst compile --root . --input gab=1 "$f" "$b-gab.pdf" || echo "ERRO em $b (gab)"
done
