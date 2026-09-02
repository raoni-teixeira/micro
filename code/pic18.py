"""
pic18.py — um simulador mínimo do núcleo PIC18, em Python.
Este código é parte do material didático da disciplina de Microcontroladores, 
ministrada pelo Prof. Raoni Teixeira, no Departamento de Engenharia Elétrica da UFMT em 2026.

Suporta apenas as instruções que aparecem nos programas da Aula 2.
A ideia é criar um simulador simples, que permita testar programas curtos, 
sem precisar de hardware.

Trata-se de um simulador didático para ajudar a entender o funcionamento do 
microcontrolador, sem periféricos. A memória de dados é modelada, mas não há timers, 
ADC, UART, etc. O barramento de dados é modelado parcialmente, apenas para permitir 
a execução de programas curtos.
O barramento de instruções é modelado parcialmente, apenas para permitir 
a execução de programas curtos.

Uso:
    python3 pic18.py programa.hex            executa e resume
    python3 pic18.py programa.hex --trace 40 mostra as 40 primeiras instruções
    python3 pic18.py programa.hex --pino D,0 mede as comutações de RD0
    python3 pic18.py programa.hex --pino D,0 --wav saida.wav
                                              grava a oscilação de RD0 como
                                              áudio, via vcd_buzzer.py, sem
                                              precisar do PICSimLab. Grava
                                              DURACAO_WAV_PADRAO (10 s) de
                                              áudio, ou até o programa parar
                                              sozinho, o que vier primeiro
    python3 pic18.py programa.hex --pino D,0 --wav saida.wav --duracao 30
                                              mesma coisa, mas gravando até
                                              30 s de áudio em vez do default
                                              (útil para loops infinitos que
                                              tocam a música e ficam parados)
"""
import sys

TCY_US = 0.25          # 250 ns por ciclo de instrução, a 16 MHz


# ---------------------------------------------------------------- memória
#
# O PIC18F4550 tem TRES memorias, em espacos separados:
#
#   Flash    32 KB   0x0000-0x7FFF   outro barramento (Harvard). Aqui: self.flash
#                                    So' alcancavel por TBLRD -- nao modelado.
#   RAM       2 KB   ver mapa abaixo  o que esta classe representa
#   EEPROM   256 B   NAO enderecavel  chega-se por EECON1/EEADR/EEDATA -- nao modelada
#
# O espaco de enderecamento de dados tem 12 bits = 4096 posicoes, mas nem todas
# existem fisicamente:
#
#   0x000-0x7FF   2048 B   RAM de uso geral (os 2 KB do anuncio)
#                          0x400-0x7FF pode ser RAM de porta dupla do USB
#   0x800-0xF5F   1888 B   NAO IMPLEMENTADO: le zero, escrita descartada
#   0xF60-0xFFF    160 B   Registradores especiais (LATD, TRISD, ADCON0, ...)
#
# O banco de acesso reune 0x000-0x05F (96 B de RAM) com 0xF60-0xFFF (160 B de
# SFR), totalizando as 256 posicoes que o campo de 8 bits do opcode alcanca.

GPR_FIM     = 0x7FF        # ultima posicao de RAM de uso geral
SFR_INICIO  = 0xF60        # primeiro registrador especial


class Memoria:
    """O espaco de dados de 4096 posicoes, com as lacunas do dispositivo real."""

    def __init__(self, avisar=True):
        self.dados = bytearray(4096)
        self.avisar = avisar
        self.fora = 0                 # contador de acessos a regiao inexistente

    def existe(self, endereco):
        return endereco <= GPR_FIM or endereco >= SFR_INICIO

    # Função devolve um endereço de 12 bits, a partir do campo f do opcode e 
    # do bit de acesso.
    # O PIC18F4550 tem 2 KB de RAM, mas o campo f do opcode tem apenas 8 bits.
    # A solução é usar o bit de acesso para selecionar entre a RAM e os SFR.
    # Por exemplo, se f = 0x20 e acesso = True, o endereço resolvido será 0xF20.

    def resolve(self, f, acesso):
        # Banco de acesso: f < 0x60 vai para a RAM baixa; o resto, para os SFR.
        if acesso:
            return f if f < 0x60 else 0xF00 | f
        return f                      # sem BSR neste simulador

    # Leitura e escrita de uma posição de memória, com aviso se a região não existir.
    def ler(self, f, acesso=True):
        end = self.resolve(f, acesso)
        if not self.existe(end):
            self.fora += 1
            return 0                  # regiao inexistente le zero
        return self.dados[end]

    def escrever(self, f, valor, acesso=True):
        end = self.resolve(f, acesso)
        if not self.existe(end):
            self.fora += 1
            if self.avisar:
                print(f"  aviso: escrita em 0x{end:03X}, regiao nao implementada "
                      f"-- descartada")
            return                    # escrita descartada, sem erro
        self.dados[end] = valor & 0xFF


# Implementação básica do núcleo
class PIC18:
    def __init__(self, flash):
        self.flash = flash            # dict: endereço de byte -> byte
        self.mem = Memoria()
        self.W = 0 # W é o registrador de trabalho, usado para operações aritméticas e lógicas.
        self.PC = 0 # o entry point do programa é 0x0000.
        self.pilha = [] # pilha de retorno, para sub-rotinas (call/return)
        self.ciclos = 0
        self.parou = False

    # Lê uma palavra (2 bytes) da memória flash. A função recebe o endereço 
    # do primeiro byte, e devolve a palavra little-endian.
    def palavra(self, endereco):
        return self.flash.get(endereco, 0xFF) | (self.flash.get(endereco + 1, 0xFF) << 8)

    # as funções implementam o laço buscar-decodificar-executar -------------------------
    def passo(self):
        pc = self.PC
        op = self.palavra(pc)
        self.PC += 2 # cada instrução ocupa 2 bytes, exceto goto/call que ocupam 4
        texto, custo = self.executa(op, pc)
        self.ciclos += custo
        return pc, op, texto, custo

    def executa(self, op, pc):
        alto = op >> 12
        f = op & 0xFF
        a = (op >> 8) & 1             # 0 = banco de acesso
        d = (op >> 9) & 1             # 0 = resultado em W, 1 = de volta em f
        b = (op >> 9) & 7             # número do bit, nas instruções de bit
        acesso = (a == 0)

        # ---- instruções de bit: bsf, bcf, btg, btfsc, btfss ----------
        if alto == 0b1000:
            v = self.mem.ler(f, acesso) | (1 << b)
            self.mem.escrever(f, v, acesso)
            return f"bsf   0x{f:02X},{b}", 1
        if alto == 0b1001:
            v = self.mem.ler(f, acesso) & ~(1 << b)
            self.mem.escrever(f, v, acesso)
            return f"bcf   0x{f:02X},{b}", 1
        if alto == 0b0111:
            v = self.mem.ler(f, acesso) ^ (1 << b)
            self.mem.escrever(f, v, acesso)
            return f"btg   0x{f:02X},{b}", 1
        if alto == 0b1011:            # btfsc: pula se o bit for zero
            bit = (self.mem.ler(f, acesso) >> b) & 1
            return (f"btfsc 0x{f:02X},{b}", 1 + self.pula(bit == 0))
        if alto == 0b1010:            # btfss: pula se o bit for um
            bit = (self.mem.ler(f, acesso) >> b) & 1
            return (f"btfss 0x{f:02X},{b}", 1 + self.pula(bit == 1))

        # ---- literais: movlw ----------------------------------------
        if op & 0xFF00 == 0x0E00:
            self.W = f
            return f"movlw {f}", 1

        # ---- movwf / clrf -------------------------------------------
        if op & 0xFE00 == 0x6E00:
            self.mem.escrever(f, self.W, acesso)
            return f"movwf 0x{f:02X}", 1
        if op & 0xFE00 == 0x6A00:
            self.mem.escrever(f, 0, acesso)
            return f"clrf  0x{f:02X}", 1

        # ---- movf ----------------------------------------------------
        if op & 0xFC00 == 0x5000:
            v = self.mem.ler(f, acesso)
            if d: self.mem.escrever(f, v, acesso)
            else: self.W = v
            return f"movf  0x{f:02X},{'f' if d else 'w'}", 1

        # ---- decfsz: decrementa, e pula se der zero -------------------
        if op & 0xFC00 == 0x2C00:
            v = (self.mem.ler(f, acesso) - 1) & 0xFF
            if d: self.mem.escrever(f, v, acesso)
            else: self.W = v
            return (f"decfsz 0x{f:02X},{'f' if d else 'w'}", 1 + self.pula(v == 0))

        # ---- EXERCICIO: incf, addwf e movff nao estao implementadas.
        #      Veja o miniteste.
        
        # ---- incf: incrementa f -------------------------------------
        '''
        if op & 0xFC00 == 0x2800:
            #Seu codigo aqui
            return f"incf  0x{f:02X},{'f' if d else 'w'}", 1
        '''
        # ---- addwf: soma W com f ------------------------------------
        if op & 0xFC00 == 0x2400:
            v = (self.W + self.mem.ler(f, acesso)) & 0xFF
            if d: self.mem.escrever(f, v, acesso)
            else: self.W = v
            return f"addwf  0x{f:02X},{'f' if d else 'w'}", 1

        # ---- movff: move de um endereco de dados para outro (2 palavras)
        if op & 0xF000 == 0xC000:
            f_origem = op & 0xFFF                        # 12 bits de origem
            w2 = self.palavra(pc + 2)                    # lê a 2ª palavra da instrução
            f_destino = w2 & 0xFFF                       # 12 bits de destino
            
            # Lê diretamente usando o endereço de 12 bits completo (acesso=False)
            val = self.mem.ler(f_origem, acesso=False)
            self.mem.escrever(f_destino, val, acesso=False)
            
            self.PC += 2                                 # avança a palavra extra da instrução
            return f"movff  0x{f_origem:03X}, 0x{f_destino:03X}", 2
        # ---- desvios --------------------------------------------------
        if op & 0xF800 == 0xD000:     # bra: desvio relativo
            n = op & 0x7FF
            if n & 0x400: n -= 0x800
            self.PC = pc + 2 + 2 * n
            return f"bra   0x{self.PC:04X}", 2
        if op & 0xFF00 == 0xEF00:     # goto: duas palavras
            k = (op & 0xFF) | ((self.palavra(pc + 2) & 0xFFF) << 8)
            self.PC = k * 2
            return f"goto  0x{self.PC:04X}", 2
        if op & 0xFE00 == 0xEC00:     # call: duas palavras
            k = (op & 0xFF) | ((self.palavra(pc + 2) & 0xFFF) << 8)
            self.pilha.append(pc + 4)
            self.PC = k * 2
            return f"call  0x{self.PC:04X}", 2
        if op == 0x0012:              # return
            self.PC = self.pilha.pop() if self.pilha else 0
            return "return", 2
        if op == 0x0000:
            return "nop", 1

        self.parou = True
        return f"??? 0x{op:04X} (nao implementada)", 1

    def pula(self, condicao):
        """Custo extra do salto. Uma palavra custa +1; duas palavras, +2."""
        if not condicao:
            return 0
        seguinte = self.palavra(self.PC)
        duas = ((seguinte & 0xFF00) == 0xEF00) or ((seguinte & 0xFE00) == 0xEC00)
        self.PC += 4 if duas else 2
        return 2 if duas else 1



# ---------------------------------------------------------------- montador
MNEM = {
    'movlw': lambda k, **_: [0x0E00 | (k & 0xFF)],
    'movwf': lambda f, **_: [0x6E00 | (f & 0xFF)],
    'clrf':  lambda f, **_: [0x6A00 | (f & 0xFF)],
    'movf':  lambda f, d=0, **_: [0x5000 | (d << 9) | (f & 0xFF)],
    'incf':  lambda f, d=1, **_: [0x2800 | (d << 9) | (f & 0xFF)],
    'decf':  lambda f, d=1, **_: [0x0400 | (d << 9) | (f & 0xFF)],
    'addwf': lambda f, d=1, **_: [0x2400 | (d << 9) | (f & 0xFF)],
    'decfsz':lambda f, d=1, **_: [0x2C00 | (d << 9) | (f & 0xFF)],
    'bsf':   lambda f, b=0, **_: [0x8000 | (b << 9) | (f & 0xFF)],
    'bcf':   lambda f, b=0, **_: [0x9000 | (b << 9) | (f & 0xFF)],
    'btg':   lambda f, b=0, **_: [0x7000 | (b << 9) | (f & 0xFF)],
    'btfsc': lambda f, b=0, **_: [0xB000 | (b << 9) | (f & 0xFF)],
    'btfss': lambda f, b=0, **_: [0xA000 | (b << 9) | (f & 0xFF)],
    'return': lambda **_: [0x0012],
    'nop':    lambda **_: [0x0000],
}
SFR = {'LATA': 0x89, 'LATB': 0x8A, 'LATC': 0x8B, 'LATD': 0x8C, 'LATE': 0x8D,
       'TRISA': 0x92, 'TRISB': 0x93, 'TRISC': 0x94, 'TRISD': 0x95, 'TRISE': 0x96}


def monta(texto):
    """Montador mínimo. Aceita rótulos, 'bra rotulo', 'goto rotulo', 'call rotulo'.
       Registradores por nome (LATD) ou número (0x20). Sufixos ,f ,w ou numero de bit."""
    linhas = []
    for bruta in texto.splitlines():
        linha = bruta.split(';')[0].strip()
        if not linha:
            continue
        # aceita "rotulo:" sozinho ou "rotulo: instrucao" na mesma linha
        if ':' in linha:
            rot, _, resto = linha.partition(':')
            if ' ' not in rot.strip():
                linhas.append(rot.strip() + ':')
                linha = resto.strip()
                if not linha:
                    continue
        linhas.append(linha)

    rotulos, pc = {}, 0
    for linha in linhas:                       # 1a passagem: posições
        if linha.endswith(':'):
            rotulos[linha[:-1]] = pc
            continue
        mn = linha.split()[0].lower()
        pc += 4 if mn in ('goto', 'call', 'movff') else 2   # duas palavras

    flash, pc = {}, 0
    for linha in linhas:                       # 2a passagem: código
        if linha.endswith(':'):
            continue
        partes = linha.replace(',', ' ').split()
        mn, args = partes[0].lower(), partes[1:]
        if mn in ('goto', 'call'):
            alvo = rotulos[args[0]] if args[0] in rotulos else int(args[0], 0)
            k = alvo // 2
            palavras = [(0xEF00 if mn == 'goto' else 0xEC00) | (k & 0xFF),
                        0xF000 | ((k >> 8) & 0xFFF)]
        elif mn == 'bra':
            alvo = rotulos[args[0]] if args[0] in rotulos else int(args[0], 0)
            palavras = [0xD000 | (((alvo - (pc + 2)) // 2) & 0x7FF)]
        elif mn == 'movff':
            org = SFR.get(args[0].upper(), None)
            org = 0xF00 | org if org else int(args[0], 0)
            dst = SFR.get(args[1].upper(), None)
            dst = 0xF00 | dst if dst else int(args[1], 0)
            palavras = [0xC000 | (org & 0xFFF), 0xF000 | (dst & 0xFFF)]
        else:
            kw = {}
            if args:
                a0 = args[0].upper()
                primeiro = SFR[a0] if a0 in SFR else int(args[0], 0)
                kw['k' if mn == 'movlw' else 'f'] = primeiro
            for extra in args[1:]:
                if extra.lower() == 'f':   kw['d'] = 1
                elif extra.lower() == 'w': kw['d'] = 0
                elif extra.lower() != 'c': kw['b'] = int(extra, 0)
            if mn not in MNEM:
                raise ValueError(f"mnemonico desconhecido: {mn}")
            palavras = MNEM[mn](**kw)
        for i, w in enumerate(palavras):
            flash[pc + 2 * i] = w & 0xFF
            flash[pc + 2 * i + 1] = (w >> 8) & 0xFF
        pc += 2 * len(palavras)
    return flash


def despeja(cpu, inicio=0x00, quantos=96):   # 96 = a RAM do banco de acesso
    """Mostra um trecho da memoria de dados, mais W e a pilha."""
    print(f"\n  W = {cpu.W}   pilha = {cpu.pilha}   ciclos = {cpu.ciclos}")
    print(f"  memoria 0x{inicio:03X}..0x{inicio+quantos-1:03X}:")
    for base in range(inicio, inicio + quantos, 16):
        celulas = ' '.join(f"{cpu.mem.dados[base+i]:02X}" for i in range(16))
        print(f"    {base:03X}:  {celulas}")


# ---------------------------------------------------------- audio (vcd_buzzer)
#
# PICSimLab produz musica gravando um .vcd com o spare part "VCD Dump" e
# depois passando o arquivo pelo vcd_buzzer.py. Aqui pulamos o arquivo
# intermediario: a simulacao em Python ja sabe exatamente quando o pino
# comuta, entao geramos a mesma lista [(tempo_em_segundos, nivel), ...] que
# vcd_buzzer.ler_vcd() devolveria, e entregamos direto para vcd_buzzer.
#
# O limite natural para audio e em SEGUNDOS de tempo simulado, nao em
# instrucoes: quanto mais rapido o pino oscila (periodos curtos), menos
# instrucoes cabem num segundo de som, entao um teto fixo de instrucoes da
# duracoes bem diferentes dependendo da musica. Um teto de instrucoes so
# entra como trava de seguranca, para o caso (anormal) de a simulacao nunca
# alcancar `duracao` segundos -- por exemplo se TCY_US estiver errado ou o
# programa nunca tocar o pino.
DURACAO_WAV_PADRAO = 10.0            # segundos de audio, se nada for pedido
LIMITE_INSTRUCOES_SEGURANCA = 40_000_000


def rastreia_pino(cpu, endereco, bit, duracao=DURACAO_WAV_PADRAO,
                   limite_instrucoes=LIMITE_INSTRUCOES_SEGURANCA):
    """Executa `cpu` ate parar, ate acumular `duracao` segundos de tempo
    simulado, ou ate `limite_instrucoes` (trava de seguranca), registrando
    toda comutacao do pino (endereco, bit) do LAT correspondente.

    Devolve (transicoes, motivo). `transicoes` esta no mesmo formato de
    vcd_buzzer.ler_vcd() -- [(t_segundos, nivel), ...], com uma entrada
    inicial em t=0 para o nivel de partida, senao a primeira nota perderia
    o trecho antes da 1a comutacao. `motivo` e um destes:
        "parou"      o programa parou sozinho (cpu.parou) -- caso normal
        "duracao"    completou os segundos pedidos; o programa continua
                     rodando (ex.: loop infinito tocando a musica de novo)
        "seguranca"  a trava de instrucoes disparou ANTES de completar
                     `duracao` segundos -- isso nao deveria acontecer em
                     uso normal e indica que algo esta errado
    """
    nivel = (cpu.mem.dados[endereco] >> bit) & 1
    transicoes = [(0.0, nivel)]
    for _ in range(limite_instrucoes):
        cpu.passo()
        t = cpu.ciclos * TCY_US * 1e-6
        novo = (cpu.mem.dados[endereco] >> bit) & 1
        if novo != nivel:
            nivel = novo
            transicoes.append((t, nivel))
        if cpu.parou:
            return transicoes, "parou"
        if t >= duracao:
            return transicoes, "duracao"
    return transicoes, "seguranca"


def gera_audio(fonte, porta, bit, saida=None, duracao=DURACAO_WAV_PADRAO,
               limite_instrucoes=LIMITE_INSTRUCOES_SEGURANCA,
               taxa=44100, amplitude=0.35):
    """Simula `fonte` (.hex ou .asm/.s) e grava a oscilacao de porta,bit
    como WAV, usando a sintese de vcd_buzzer.py.

    Equivale a: PICSimLab + VCD Dump + `python vcd_buzzer.py arquivo.vcd`,
    mas sem gravar o .vcd -- util para ouvir a melodia a cada ajuste do
    codigo, sem precisar abrir o PICSimLab.
    """
    import vcd_buzzer

    flash = (monta(open(fonte).read()) if fonte.endswith(('.s', '.asm'))
              else carrega_hex(fonte))
    cpu = PIC18(flash)
    if flash:
        cpu.PC = min(flash.keys())

    endereco = 0xF89 + "ABCDE".index(porta.upper())   # LATA=0xF89, LATB=0xF8A, ...
    transicoes, motivo = rastreia_pino(cpu, endereco, bit, duracao,
                                        limite_instrucoes)

    amostras = vcd_buzzer.sintetiza(transicoes, taxa, amplitude)
    if saida is None:
        saida = fonte.rsplit(".", 1)[0] + ".wav"
    vcd_buzzer.escreve_wav(saida, amostras, taxa)
    print(f"gravado {saida} ({len(amostras)/taxa:.2f} s de audio, "
          f"{len(transicoes)} comutacoes, {cpu.ciclos} ciclos simulados)")
    if motivo == "duracao":
        print(f"  o programa continua rodando apos {duracao:.1f}s "
              f"(provavelmente um loop) -- use --duracao para gravar mais.")
    elif motivo == "seguranca":
        print(f"  aviso: trava de seguranca de {limite_instrucoes} "
              f"instrucoes disparou antes de completar {duracao:.1f}s de "
              f"audio (so {transicoes[-1][0]:.3f}s simulados) -- a musica "
              f"esta cortada. O pino oscila devagar demais, ou o programa "
              f"nao esta comutando-o.")
    return transicoes, amostras


# ---------------------------------------------------------------- Intel HEX
def carrega_hex(caminho):
    flash = {}
    for linha in open(caminho):
        linha = linha.strip()
        if not linha.startswith(':'):
            continue
        b = bytes.fromhex(linha[1:])
        if (sum(b) & 0xFF) != 0:
            raise ValueError("checksum invalido: " + linha)
        n, end, tipo = b[0], int.from_bytes(b[1:3], 'big'), b[3]
        if tipo == 0:
            for i in range(n):
                flash[end + i] = b[4 + i]
    return flash


# código principal do simulador
# lê o arquivo de entrada, monta ou carrega a memória flash, e executa o programa
def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    fonte = sys.argv[1]
    flash = monta(open(fonte).read()) if fonte.endswith(('.s', '.asm')) else carrega_hex(fonte)
    cpu = PIC18(flash)

    if flash:
        cpu.PC = min(flash.keys())  # No seu caso, vai definir cpu.PC = 0x7FD8 (32728)

    trace = 0
    pino = None
    if '--trace' in sys.argv:
        trace = int(sys.argv[sys.argv.index('--trace') + 1])
    if '--pino' in sys.argv:
        porta, bit = sys.argv[sys.argv.index('--pino') + 1].split(',')
        pino = (0xF89 + "ABCDE".index(porta.upper()), int(bit))   # LATA = 0xF89

    anterior, comutacoes, ciclo_anterior, intervalos = None, 0, 0, []
    LIMITE = 20_000_000
    if '--passos' in sys.argv:
        LIMITE = int(sys.argv[sys.argv.index('--passos') + 1])

    if '--wav' in sys.argv:
        if pino is None:
            print("erro: --wav precisa de --pino PORTA,BIT")
            return
        idx = sys.argv.index('--wav') + 1
        saida_wav = (sys.argv[idx] if idx < len(sys.argv)
                     and not sys.argv[idx].startswith('--') else None)
        duracao = DURACAO_WAV_PADRAO
        if '--duracao' in sys.argv:
            duracao = float(sys.argv[sys.argv.index('--duracao') + 1])
        gera_audio(fonte, porta, int(bit), saida=saida_wav, duracao=duracao)
        return

    for n in range(LIMITE):
        if pino:
            atual = (cpu.mem.dados[pino[0]] >> pino[1]) & 1
        pc, op, texto, custo = cpu.passo()
        if n < trace:
            print(f"  {pc:04X}  {op:04X}  {texto:<22} {custo} ciclo(s)   "
                  f"W={cpu.W:3d}  total={cpu.ciclos}")
        if pino:
            novo = (cpu.mem.dados[pino[0]] >> pino[1]) & 1
            if anterior is not None and novo != anterior:
                comutacoes += 1
                if comutacoes > 1:
                    intervalos.append(cpu.ciclos - ciclo_anterior)
                ciclo_anterior = cpu.ciclos
            anterior = novo
        if cpu.parou:
            print("  parou:", texto)
            break
        if len(intervalos) >= 6:
            break

    print(f"\n  instrucoes executadas : {n+1}")
    print(f"  ciclos                : {cpu.ciclos}")
    if cpu.mem.fora:
        print(f"  acessos fora da RAM   : {cpu.mem.fora}  (regiao nao implementada)")
    print(f"  tempo                 : {cpu.ciclos * TCY_US / 1000:.3f} ms")
    if '--dump' in sys.argv:
        despeja(cpu)
    if intervalos:
        meio = sum(intervalos) / len(intervalos)
        print(f"\n  meio periodo  : {meio:.0f} ciclos = {meio*TCY_US:.1f} us")
        print(f"  frequencia    : {1e6/(2*meio*TCY_US):.2f} Hz")


if __name__ == '__main__':
    main()
    