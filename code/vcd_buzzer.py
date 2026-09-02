#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
vcd_buzzer.py - converte um arquivo VCD (PICSimLab, spare part "VCD Dump")
em audio WAV e analisa as notas geradas.

Somente biblioteca padrao: roda nas maquinas Windows do laboratorio sem
instalar nada.

Uso tipico:

    python vcd_buzzer.py melodia.vcd
    python vcd_buzzer.py melodia.vcd --sinal RC1 --saida melodia.wav
    python vcd_buzzer.py melodia.vcd --notas

O modulo tambem pode ser importado. A representacao interna e uma lista de
transicoes [(t_segundos, nivel), ...], entao o pic18.py pode alimentar as
mesmas funcoes a partir do proprio rastreamento de pino:

    from vcd_buzzer import sintetiza, escreve_wav, analisa_notas
"""

import argparse
import math
import re
import struct
import sys
import wave

# ---------------------------------------------------------------------------
# Leitura do VCD
# ---------------------------------------------------------------------------

_UNIDADES = {
    "s": 1.0,
    "ms": 1e-3,
    "us": 1e-6,
    "ns": 1e-9,
    "ps": 1e-12,
    "fs": 1e-15,
}


def _parse_timescale(texto):
    """Converte o corpo de $timescale em segundos por unidade de tempo.

    Aceita "1ns", "10 ps", "100us" etc.
    """
    m = re.match(r"\s*(\d+)\s*([munpf]?s)\s*$", texto.strip())
    if not m:
        raise ValueError("timescale nao reconhecido: %r" % texto)
    return int(m.group(1)) * _UNIDADES[m.group(2)]


def ler_vcd(caminho, sinal=None):
    """Le um VCD e devolve (transicoes, sinais_disponiveis).

    transicoes: lista [(t_segundos, nivel), ...] ordenada, nivel em {0, 1}.
    sinais_disponiveis: lista de nomes encontrados no cabecalho.

    Se `sinal` for None, usa o primeiro sinal escalar de 1 bit do arquivo.
    A comparacao do nome e por substring, sem diferenciar maiusculas, para
    aceitar tanto "RC1" quanto "16  RC1".
    """
    ids = {}          # identificador curto -> nome legivel
    escala = 1e-9     # default defensivo caso falte $timescale
    achou_timescale = False

    transicoes = []
    alvo_id = None
    t = 0

    with open(caminho, "r", errors="replace") as f:
        # ---- cabecalho ----
        for linha in f:
            s = linha.strip()
            if s.startswith("$timescale"):
                corpo = s[len("$timescale"):]
                if "$end" not in corpo:
                    corpo += " " + next(f)
                corpo = corpo.split("$end")[0]
                escala = _parse_timescale(corpo)
                achou_timescale = True
            elif s.startswith("$var"):
                # $var wire 1 ! RC1 $end   /   $var wire 1 ! 16  RC1 $end
                partes = s.split()
                if len(partes) >= 5:
                    ident = partes[3]
                    nome = " ".join(partes[4:]).replace("$end", "").strip()
                    ids[ident] = nome
            elif s.startswith("$enddefinitions"):
                break

        if not ids:
            raise ValueError("nenhum $var encontrado em %s" % caminho)
        if not achou_timescale:
            print("aviso: $timescale ausente, assumindo 1ns", file=sys.stderr)

        # ---- escolhe o sinal ----
        if sinal is None:
            alvo_id = next(iter(ids))
        else:
            alvo = sinal.strip().lower()
            for ident, nome in ids.items():
                if alvo in nome.lower():
                    alvo_id = ident
                    break
            if alvo_id is None:
                raise ValueError(
                    "sinal %r nao encontrado; disponiveis: %s"
                    % (sinal, ", ".join(sorted(ids.values())))
                )

        # ---- corpo ----
        for linha in f:
            s = linha.strip()
            if not s:
                continue
            c = s[0]
            if c == "#":
                t = int(s[1:])
            elif c in "01xzXZ":
                ident = s[1:].strip()
                if ident == alvo_id:
                    nivel = 1 if c == "1" else 0
                    if not transicoes or transicoes[-1][1] != nivel:
                        transicoes.append((t * escala, nivel))
            # blocos $dumpvars / $end e vetores (b...) sao ignorados

    if not transicoes:
        raise ValueError(
            "nenhuma transicao para o sinal escolhido (%s)" % ids[alvo_id]
        )

    return transicoes, sorted(ids.values())


# ---------------------------------------------------------------------------
# Sintese do audio
# ---------------------------------------------------------------------------

def sintetiza(transicoes, taxa=44100, amplitude=0.35, duracao=None,
              corte_dc=True):
    """Converte transicoes em amostras de audio (lista de int16).

    Cada amostra e a MEDIA do nivel logico ao longo do seu intervalo, e nao
    uma leitura instantanea. Como as transicoes tem tempo exato, essa media
    e calculada analiticamente: e um filtro caixa perfeito, que ja faz o
    antialiasing da onda quadrada. Sem isso, uma nota de 2 kHz amostrada a
    44,1 kHz gera batimentos audiveis que nao existem no sinal original.
    """
    if not transicoes:
        return []

    t0 = transicoes[0][0]
    t_fim = duracao if duracao is not None else transicoes[-1][0] - t0
    n = int(t_fim * taxa)
    if n <= 0:
        return []

    dt = 1.0 / taxa
    amostras = []
    i = 0
    m = len(transicoes)

    for k in range(n):
        ini = t0 + k * dt
        fim = ini + dt

        # avanca ate a transicao vigente no inicio da janela
        while i + 1 < m and transicoes[i + 1][0] <= ini:
            i += 1

        # integra o nivel dentro da janela
        acc = 0.0
        pos = ini
        j = i
        while True:
            nivel = transicoes[j][1]
            prox = transicoes[j + 1][0] if j + 1 < m else float("inf")
            lim = prox if prox < fim else fim
            if nivel:
                acc += lim - pos
            pos = lim
            if pos >= fim:
                break
            j += 1

        amostras.append(acc / dt)  # fracao de tempo em nivel alto, 0..1

    # centraliza: 50% de duty vira silencio DC, nao offset
    if corte_dc:
        media = sum(amostras) / len(amostras)
        amostras = [a - media for a in amostras]
    else:
        amostras = [a - 0.5 for a in amostras]

    pico = max(abs(a) for a in amostras) or 1.0
    ganho = amplitude / pico
    return [int(max(-32767, min(32767, a * ganho * 32767))) for a in amostras]


def escreve_wav(caminho, amostras, taxa=44100):
    """Grava as amostras int16 em WAV mono."""
    with wave.open(caminho, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(taxa)
        w.writeframes(struct.pack("<%dh" % len(amostras), *amostras))


# ---------------------------------------------------------------------------
# Analise das notas
# ---------------------------------------------------------------------------

_NOMES = ["DO", "DO#", "RE", "RE#", "MI", "FA",
          "FA#", "SOL", "SOL#", "LA", "LA#", "SI"]


def nome_da_nota(f):
    """Nota temperada mais proxima e desvio em cents. LA4 = 440 Hz."""
    if f <= 0:
        return "-", 0.0
    semis = 12.0 * math.log2(f / 440.0)
    n = round(semis)
    cents = (semis - n) * 100.0
    midi = int(n) + 69
    return "%s%d" % (_NOMES[midi % 12], midi // 12 - 1), cents


def analisa_notas(transicoes, silencio_min=0.005, tol=0.25):
    """Segmenta as transicoes em notas e mede a frequencia de cada uma.

    Um segmento termina quando ha um intervalo maior que `silencio_min`
    (pausa) ou quando o meio-periodo muda mais que `tol` (nota nova).

    Devolve [{inicio, duracao, freq, ciclos, nota, cents}, ...].
    """
    if len(transicoes) < 3:
        return []

    meios = [(transicoes[i + 1][0] - transicoes[i][0], transicoes[i][0])
             for i in range(len(transicoes) - 1)]

    notas = []
    grupo = []

    def fecha():
        if len(grupo) < 4:
            return
        ini = grupo[0][1]
        total = sum(d for d, _ in grupo)
        meio = total / len(grupo)
        f = 1.0 / (2.0 * meio)
        nome, cents = nome_da_nota(f)
        notas.append({
            "inicio": ini,
            "duracao": total,
            "freq": f,
            "ciclos": len(grupo) // 2,
            "nota": nome,
            "cents": cents,
        })

    for d, t in meios:
        if d > silencio_min:
            fecha()
            grupo = []
            continue
        if grupo:
            ref = sum(x for x, _ in grupo) / len(grupo)
            if abs(d - ref) > tol * ref:
                fecha()
                grupo = []
        grupo.append((d, t))
    fecha()

    return notas


def relatorio(notas, esperado=None):
    """Tabela textual das notas medidas.

    `esperado` e a lista de meio-periodos NOMINAIS em us, na ordem da
    melodia (a mesma tabela MELODIA[] do firmware). Quando fornecida, a
    comparacao e posicional contra o valor pretendido.

    Sem ela, cada nota e comparada com a nota temperada mais proxima, o
    que fica AMBIGUO se o erro passar de 50 cents: uma melodia 60 cents
    baixa aparece como 40 cents alta do semitom de baixo. Para calibrar
    constante de tempo, use sempre --esperado.
    """
    if not notas:
        return "nenhuma nota detectada"

    usa_esp = esperado is not None and len(esperado) == len(notas)
    if esperado is not None and not usa_esp:
        cab = ["  aviso: %d notas medidas mas %d esperadas; comparando com "
               "a escala temperada" % (len(notas), len(esperado))]
    else:
        cab = []

    if usa_esp:
        linhas = cab + [
            "  #   inicio(s)  dur(ms)   medido(Hz)  nominal(Hz)  razao   desvio",
            "  --- ---------- --------- ----------- ----------- ------- ---------"]
        desvios = []
        for k, (n, mp) in enumerate(zip(notas, esperado), 1):
            fn = 1e6 / (2.0 * mp)
            razao = n["freq"] / fn
            c = 1200.0 * math.log2(razao)
            desvios.append(c)
            linhas.append("  %3d %10.4f %9.1f %11.2f %11.2f %7.4f %+7.1f c"
                          % (k, n["inicio"], n["duracao"] * 1e3,
                             n["freq"], fn, razao, c))
    else:
        linhas = cab + [
            "  #   inicio(s)  dur(ms)   freq(Hz)   nota    desvio",
            "  --- ---------- --------- ---------- ------- ---------"]
        desvios = []
        for k, n in enumerate(notas, 1):
            desvios.append(n["cents"])
            linhas.append("  %3d %10.4f %9.1f %10.2f %-7s %+7.1f c"
                          % (k, n["inicio"], n["duracao"] * 1e3,
                             n["freq"], n["nota"], n["cents"]))

    media = sum(desvios) / len(desvios)
    disp = max(desvios) - min(desvios)
    linhas.append("")
    linhas.append("  desvio medio: %+.1f cents   dispersao: %.1f cents"
                  % (media, disp))

    if usa_esp and len(notas) >= 3:
        # Ajuste de reta: mp_medido = a * mp_nominal + b   (us)
        #   a  = erro PROPORCIONAL (constante de tempo do laco errada)
        #   b  = overhead FIXO por meio-ciclo (instrucoes fora do laco)
        # E a generalizacao da calibracao de dois pontos da bancada.
        xs = [float(mp) for mp in esperado]
        ys = [1e6 / (2.0 * n["freq"]) for n in notas]
        mx = sum(xs) / len(xs)
        my = sum(ys) / len(ys)
        sxx = sum((x - mx) ** 2 for x in xs)
        sxy = sum((x - mx) * (y - my) for x, y in zip(xs, ys))
        if sxx > 0:
            a = sxy / sxx
            b = my - a * mx
            res = [y - (a * x + b) for x, y in zip(xs, ys)]
            rms = math.sqrt(sum(r * r for r in res) / len(res))
            linhas.append("")
            linhas.append("  ajuste  mp_medido = %.4f * mp_nominal %+.2f us"
                          "   (residuo rms %.2f us)" % (a, b, rms))
            if abs(b) < max(2.0, 3 * rms):
                linhas.append("  -> overhead fixo desprezivel; erro puramente "
                              "proporcional")
                linhas.append("  -> corrija a constante de tempo dividindo-a "
                              "por %.4f" % a)
            else:
                linhas.append("  -> ha overhead FIXO de %.1f us por meio-ciclo "
                              "alem do proporcional" % b)
                linhas.append("  -> so ajustar a constante nao resolve: as "
                              "notas agudas ficam mais desafinadas")

    return "\n".join(linhas)


# ---------------------------------------------------------------------------
# Grafico: frequencia x tempo
# ---------------------------------------------------------------------------

# paleta do curso
_NAVY = "#1B365D"
_AMBER = "#D98F00"
_CINZA = "#9AA5B1"
_GRID = "#E3E8EE"


def _esc(s):
    return (s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;"))


def grafico_svg(transicoes, notas, esperado=None, largura=960, altura=460,
                pontos=True, silencio_min=0.005):
    """Gera um SVG com frequencia (log) no eixo Y e tempo no eixo X.

    - pontos cinza: frequencia INSTANTANEA de cada meio-periodo. Mostram
      deriva dentro da nota, que a media do segmento esconde.
    - linha navy: frequencia media medida de cada nota.
    - tracejado ambar: valor nominal, quando `esperado` e fornecido.

    Eixo Y logaritmico porque a percepcao de altura e logaritmica: uma
    mesma distancia vertical vale o mesmo intervalo musical em qualquer
    regiao do grafico. Em escala linear o erro parece maior no agudo.
    """
    if not notas:
        raise ValueError("nenhuma nota para desenhar")

    ml, mr, mt, mb = 62, 18, 28, 46
    lp = largura - ml - mr
    ap = altura - mt - mb

    # ---- dados instantaneos ----
    inst = []
    if pontos:
        for i in range(len(transicoes) - 1):
            d = transicoes[i + 1][0] - transicoes[i][0]
            if 0 < d <= silencio_min:
                inst.append((transicoes[i][0], 1.0 / (2.0 * d)))
        passo = max(1, len(inst) // 1500)
        inst = inst[::passo]

    # ---- limites ----
    t0 = notas[0]["inicio"]
    t1 = max(n["inicio"] + n["duracao"] for n in notas)
    freqs = [n["freq"] for n in notas]
    if esperado and len(esperado) == len(notas):
        freqs += [1e6 / (2.0 * mp) for mp in esperado]
    if inst:
        freqs += [f for _, f in inst]
    fmin, fmax = min(freqs), max(freqs)
    # uma semitom de folga de cada lado
    lo = math.log2(fmin) - 1.0 / 12
    hi = math.log2(fmax) + 1.0 / 12

    def X(t):
        return ml + (t - t0) / (t1 - t0) * lp

    def Y(f):
        return mt + (hi - math.log2(f)) / (hi - lo) * ap

    o = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" '
         'width="%d" height="%d" font-family="Helvetica,Arial,sans-serif">'
         % (largura, altura, largura, altura),
         '<rect width="%d" height="%d" fill="white"/>' % (largura, altura)]

    # ---- grade horizontal: semitons ----
    n_lo = int(math.floor(12 * math.log2(fmin / 440.0))) - 1
    n_hi = int(math.ceil(12 * math.log2(fmax / 440.0))) + 1
    for n in range(n_lo, n_hi + 1):
        f = 440.0 * (2.0 ** (n / 12.0))
        if not (lo <= math.log2(f) <= hi):
            continue
        y = Y(f)
        midi = n + 69
        dO = (midi % 12 == 0)
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
                 'stroke-width="%s"/>'
                 % (ml, y, largura - mr, y, _GRID if not dO else _CINZA,
                    "1" if not dO else "1"))
        nome = "%s%d" % (_NOMES[midi % 12], midi // 12 - 1)
        if dO or (n_hi - n_lo) <= 20:
            o.append('<text x="%.1f" y="%.1f" font-size="10" fill="%s" '
                     'text-anchor="end">%s</text>'
                     % (ml - 6, y + 3.5, _NAVY if dO else _CINZA, nome))

    # ---- eixos ----
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
             'stroke-width="1.2"/>' % (ml, mt, ml, mt + ap, _NAVY))
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
             'stroke-width="1.2"/>'
             % (ml, mt + ap, largura - mr, mt + ap, _NAVY))

    # marcas de tempo
    span = t1 - t0
    passo_t = 10 ** math.floor(math.log10(span / 6.0))
    for mult in (1, 2, 5, 10):
        if span / (passo_t * mult) <= 9:
            passo_t *= mult
            break
    k = 0
    while t0 + k * passo_t <= t1 + 1e-9:
        t = t0 + k * passo_t
        x = X(t)
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s"/>'
                 % (x, mt + ap, x, mt + ap + 4, _NAVY))
        o.append('<text x="%.1f" y="%.1f" font-size="10" fill="%s" '
                 'text-anchor="middle">%g</text>'
                 % (x, mt + ap + 16, _NAVY, round(t, 3)))
        k += 1
    o.append('<text x="%.1f" y="%.1f" font-size="11" fill="%s" '
             'text-anchor="middle">tempo (s)</text>'
             % (ml + lp / 2, altura - 8, _NAVY))
    o.append('<text x="14" y="%.1f" font-size="11" fill="%s" '
             'text-anchor="middle" transform="rotate(-90 14 %.1f)">'
             'frequencia (escala log)</text>' % (mt + ap / 2, _NAVY, mt + ap / 2))

    # ---- pontos instantaneos ----
    for t, f in inst:
        if lo <= math.log2(f) <= hi:
            o.append('<circle cx="%.1f" cy="%.1f" r="1" fill="%s" '
                     'opacity="0.45"/>' % (X(t), Y(f), _CINZA))

    # ---- nominal (tracejado) ----
    usa_esp = esperado is not None and len(esperado) == len(notas)
    if usa_esp:
        for n, mp in zip(notas, esperado):
            fn = 1e6 / (2.0 * mp)
            o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" '
                     'stroke="%s" stroke-width="2.5" stroke-dasharray="5,3"/>'
                     % (X(n["inicio"]), Y(fn),
                        X(n["inicio"] + n["duracao"]), Y(fn), _AMBER))

    # ---- medido ----
    for n in notas:
        x1, x2, y = X(n["inicio"]), X(n["inicio"] + n["duracao"]), Y(n["freq"])
        # tique de ataque: separa visualmente notas repetidas adjacentes,
        # que senao se fundem numa linha so
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
                 'stroke-width="1.2"/>' % (x1, y - 7, x1, y + 7, _NAVY))
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
                 'stroke-width="3.5"/>' % (x1, y, x2, y, _NAVY))
        if x2 - x1 > 26:
            # rotulo do lado oposto ao nominal, senao colide com o tracejado
            dy = -10
            if usa_esp:
                yn = Y(1e6 / (2.0 * esperado[notas.index(n)]))
                dy = 15 if yn < y else -10
            o.append('<text x="%.1f" y="%.1f" font-size="9" fill="%s" '
                     'text-anchor="middle">%.0f Hz</text>'
                     % ((x1 + x2) / 2, y + dy, _NAVY, n["freq"]))

    # ---- legenda ----
    lx, ly = ml + 6, mt + 12
    o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
             'stroke-width="3.5"/>' % (lx, ly, lx + 22, ly, _NAVY))
    o.append('<text x="%.1f" y="%.1f" font-size="10" fill="%s">medido</text>'
             % (lx + 27, ly + 3.5, _NAVY))
    if usa_esp:
        o.append('<line x1="%.1f" y1="%.1f" x2="%.1f" y2="%.1f" stroke="%s" '
                 'stroke-width="2.5" stroke-dasharray="5,3"/>'
                 % (lx + 78, ly, lx + 100, ly, _AMBER))
        o.append('<text x="%.1f" y="%.1f" font-size="10" fill="%s">nominal'
                 '</text>' % (lx + 105, ly + 3.5, _AMBER))
    if inst:
        o.append('<circle cx="%.1f" cy="%.1f" r="1.6" fill="%s"/>'
                 % (lx + 172, ly, _CINZA))
        o.append('<text x="%.1f" y="%.1f" font-size="10" fill="%s">'
                 'meio-periodo</text>' % (lx + 179, ly + 3.5, _CINZA))

    o.append("</svg>")
    return "\n".join(o)


def main(argv=None):
    p = argparse.ArgumentParser(
        description="Converte VCD do PICSimLab em WAV e analisa as notas.")
    p.add_argument("vcd", help="arquivo .vcd gerado pelo spare part VCD Dump")
    p.add_argument("--sinal", default=None,
                   help="nome do sinal (ex.: RC1). Default: o primeiro.")
    p.add_argument("--saida", default=None,
                   help="arquivo .wav de saida. Default: mesmo nome do VCD.")
    p.add_argument("--taxa", type=int, default=44100,
                   help="taxa de amostragem do WAV (default 44100)")
    p.add_argument("--amplitude", type=float, default=0.35,
                   help="amplitude de pico, 0 a 1 (default 0.35)")
    p.add_argument("--notas", action="store_true",
                   help="imprime a tabela de notas medidas")
    p.add_argument("--esperado", default=None,
                   help="meio-periodos nominais em us, separados por virgula "
                        "(cole a tabela MELODIA[] do firmware). Ativa a "
                        "comparacao posicional, sem ambiguidade de semitom.")
    p.add_argument("--sem-wav", action="store_true",
                   help="apenas analisa, nao grava audio")
    p.add_argument("--svg", nargs="?", const="", default=None,
                   help="grava o grafico frequencia x tempo em SVG "
                        "(sem argumento, usa o nome do VCD)")
    p.add_argument("--listar", action="store_true",
                   help="lista os sinais do arquivo e sai")
    a = p.parse_args(argv)

    try:
        transicoes, sinais = ler_vcd(a.vcd, a.sinal)
    except (ValueError, OSError) as e:
        print("erro: %s" % e, file=sys.stderr)
        return 1

    if a.listar:
        print("sinais em %s:" % a.vcd)
        for s in sinais:
            print("  " + s)
        return 0

    dur = transicoes[-1][0] - transicoes[0][0]
    print("%d transicoes, %.3f s de sinal" % (len(transicoes), dur))

    esp = None
    if a.esperado:
        esp = [float(x) for x in a.esperado.replace(";", ",").split(",")
               if x.strip()]

    notas = None
    if a.notas or a.svg is not None:
        notas = analisa_notas(transicoes)

    if a.notas:
        print()
        print(relatorio(notas, esp))
        print()

    if a.svg is not None:
        alvo = a.svg or (a.vcd.rsplit(".", 1)[0] + ".svg")
        try:
            with open(alvo, "w") as f:
                f.write(grafico_svg(transicoes, notas, esp))
            print("gravado %s (%d notas)" % (alvo, len(notas)))
        except ValueError as e:
            print("erro no grafico: %s" % e, file=sys.stderr)

    if not a.sem_wav:
        saida = a.saida or (a.vcd.rsplit(".", 1)[0] + ".wav")
        amostras = sintetiza(transicoes, a.taxa, a.amplitude)
        escreve_wav(saida, amostras, a.taxa)
        print("gravado %s (%.2f s, %d Hz)"
              % (saida, len(amostras) / a.taxa, a.taxa))

    return 0


if __name__ == "__main__":
    sys.exit(main())