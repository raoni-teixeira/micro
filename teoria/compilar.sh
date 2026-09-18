#!/bin/sh
# Compila as notas de aula nas duas versoes.
# A versao -gab fica fora do repositorio publico (ver .gitignore).
for f in aula0-*.typ aula1-*.typ aula2-*.typ aula3-*.typ aula4-*.typ aula5-*.typ \
         aula7-*.typ aula8-*.typ aula9-*.typ aula10-*.typ aula11-*.typ aula13-*.typ; do
  [ -e "$f" ] || continue
  b="${f%.typ}"
  typst compile --root . "$f" "$b.pdf"
  typst compile --root . --input gab=1 "$f" "$b-gab.pdf"
done
