"""Tiny RV32I assembler + reference simulator for the rv32i-pipelined-core subset.
Usage: python rvasm.py prog.s [--pad N]
  -> writes prog.txt (imem image) and prog_expected.txt (final x0..x31, then dmem words 0..63)
  --pad N inserts N NOPs (addi x0,x0,0) after every instruction and writes prog_padN.*
"""
import re, sys

REGS = {f'x{i}': i for i in range(32)}
ABI = 'zero ra sp gp tp t0 t1 t2 s0 s1 a0 a1 a2 a3 a4 a5 a6 a7 s2 s3 s4 s5 s6 s7 s8 s9 s10 s11 t3 t4 t5 t6'.split()
REGS.update({n: i for i, n in enumerate(ABI)}); REGS['fp'] = 8

R = {'add': (0, 0), 'sub': (0, 0x20), 'sll': (1, 0), 'slt': (2, 0), 'sltu': (3, 0), 'xor': (4, 0),
     'srl': (5, 0), 'sra': (5, 0x20), 'or': (6, 0), 'and': (7, 0)}
I = {'addi': 0, 'slti': 2, 'sltiu': 3, 'xori': 4, 'ori': 6, 'andi': 7}
SH = {'slli': (1, 0), 'srli': (5, 0), 'srai': (5, 0x20)}
B = {'beq': 0, 'bne': 1, 'blt': 4, 'bge': 5, 'bltu': 6, 'bgeu': 7}

def num(s): return int(s, 0)
def reg(s): return REGS[s.strip()]

def parse(src, pad=0):
    lines, labels, pc = [], {}, 0
    for raw in src.splitlines():
        line = raw.split('#')[0].strip()
        while ':' in line:
            lab, line = line.split(':', 1); labels[lab.strip()] = pc; line = line.strip()
        if line:
            lines.append((pc, line, raw.strip())); pc += 4
            for _ in range(pad):
                lines.append((pc, 'addi x0, x0, 0', 'nop (padding)')); pc += 4
    return lines, labels

def encode(pc, line, labels):
    m = line.split(None, 1); op = m[0]; args = [a.strip() for a in m[1].split(',')] if len(m) > 1 else []
    def imm_or_label(s): return labels[s] - pc if s in labels else num(s)
    if op in R:
        f3, f7 = R[op]; rd, rs1, rs2 = map(reg, args)
        return f7 << 25 | rs2 << 20 | rs1 << 15 | f3 << 12 | rd << 7 | 0x33
    if op in I:
        rd, rs1, imm = reg(args[0]), reg(args[1]), num(args[2]); assert -2048 <= imm < 2048
        return (imm & 0xFFF) << 20 | rs1 << 15 | I[op] << 12 | rd << 7 | 0x13
    if op in SH:
        f3, f7 = SH[op]; rd, rs1, sh = reg(args[0]), reg(args[1]), num(args[2])
        return f7 << 25 | (sh & 31) << 20 | rs1 << 15 | f3 << 12 | rd << 7 | 0x13
    if op in ('lw', 'sw', 'jalr'):
        r0 = reg(args[0]); mm = re.match(r'(-?\w+)\((\w+)\)', args[1]); imm, rs1 = num(mm.group(1)), reg(mm.group(2))
        if op == 'lw':   return (imm & 0xFFF) << 20 | rs1 << 15 | 2 << 12 | r0 << 7 | 0x03
        if op == 'jalr': return (imm & 0xFFF) << 20 | rs1 << 15 | 0 << 12 | r0 << 7 | 0x67
        i = imm & 0xFFF
        return (i >> 5) << 25 | r0 << 20 | rs1 << 15 | 2 << 12 | (i & 31) << 7 | 0x23
    if op in B:
        rs1, rs2, off = reg(args[0]), reg(args[1]), imm_or_label(args[2]); i = off & 0x1FFF
        return ((i >> 12) & 1) << 31 | ((i >> 5) & 0x3F) << 25 | rs2 << 20 | rs1 << 15 | B[op] << 12 | ((i >> 1) & 0xF) << 8 | ((i >> 11) & 1) << 7 | 0x63
    if op == 'jal':
        rd, off = reg(args[0]), imm_or_label(args[1]); i = off & 0x1FFFFF
        return ((i >> 20) & 1) << 31 | ((i >> 1) & 0x3FF) << 21 | ((i >> 11) & 1) << 20 | ((i >> 12) & 0xFF) << 12 | rd << 7 | 0x6F
    raise ValueError(f'unsupported: {line}')

def sx(v, bits): v &= (1 << bits) - 1; return v - (1 << bits) if v >> (bits - 1) else v
def s32(v): return sx(v, 32)

def simulate(words, max_steps=10000):
    x = [0] * 32; mem = [0] * 64; pc = 0
    for _ in range(max_steps):
        w = words[pc >> 2]; op = w & 0x7F; rd = (w >> 7) & 31; f3 = (w >> 12) & 7
        rs1 = (w >> 15) & 31; rs2 = (w >> 20) & 31; f7 = w >> 25
        a, b = x[rs1], x[rs2]; npc = pc + 4; res = None
        immI = sx(w >> 20, 12); immS = sx((f7 << 5) | rd, 12)
        immB = sx(((w >> 31) << 12) | (((w >> 7) & 1) << 11) | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1), 13)
        immJ = sx(((w >> 31) << 20) | (((w >> 12) & 0xFF) << 12) | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1), 21)
        alu = lambda f3, a, b, alt: {0: (a - b) if alt else (a + b), 1: a << (b & 31), 2: int(s32(a) < s32(b)), 3: int(a < b),
                                     4: a ^ b, 5: (s32(a) >> (b & 31)) if alt else (a >> (b & 31)), 6: a | b, 7: a & b}[f3] & 0xFFFFFFFF
        if op == 0x33: res = alu(f3, a, b, f7 == 0x20)
        elif op == 0x13: res = alu(f3, a, immI & 0xFFFFFFFF, f3 == 5 and f7 == 0x20)
        elif op == 0x03: res = mem[((a + immI) & 0xFF) >> 2]
        elif op == 0x23: mem[((a + immS) & 0xFF) >> 2] = b
        elif op == 0x63:
            t = {0: a == b, 1: a != b, 4: s32(a) < s32(b), 5: s32(a) >= s32(b), 6: a < b, 7: a >= b}[f3]
            if t: npc = pc + immB
        elif op == 0x6F: res = pc + 4; npc = pc + immJ
        elif op == 0x67: res = pc + 4; npc = (a + immI) & ~1
        else: raise ValueError(f'bad op at pc {pc:#x}')
        if res is not None and rd: x[rd] = res & 0xFFFFFFFF
        npc &= 0xFFFFFFFF
        if npc == pc: return x, mem, pc          # 'done: beq x0,x0,done' self-loop
        pc = npc
    raise RuntimeError('program did not reach a self-loop')

if __name__ == '__main__':
    src = open(sys.argv[1]).read(); base = sys.argv[1].rsplit('.', 1)[0]
    pad = int(sys.argv[sys.argv.index('--pad') + 1]) if '--pad' in sys.argv else 0
    if pad: base += f'_pad{pad}'
    lines, labels = parse(src, pad)
    words = [encode(pc, l, labels) for pc, l, _ in lines]
    with open(base + '.txt', 'w') as f:
        for (pc, _, raw), w in zip(lines, words): f.write(f'{w:08x}  // {pc:3x}: {raw}\n')
    x, mem, endpc = simulate(words)
    with open(base + '_expected.txt', 'w') as f:
        for v in x + mem: f.write(f'{v:08x}\n')
    print(f'{len(words)} instructions, ends at pc {endpc:#x}')
