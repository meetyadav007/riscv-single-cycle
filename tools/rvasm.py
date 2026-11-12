#!/usr/bin/env python3
"""Tiny RV32I assembler -> program.hex (one 32-bit hex word per line).

Usage: python tools/rvasm.py tests/test_program.s program.hex
Supports the instructions implemented by this core, numeric registers (x0-x31),
labels, '#' comments and decimal/hex immediates.
"""
import re
import sys

R = {'add': (0, 0), 'sub': (0, 0x20), 'sll': (1, 0), 'slt': (2, 0), 'sltu': (3, 0),
     'xor': (4, 0), 'srl': (5, 0), 'sra': (5, 0x20), 'or': (6, 0), 'and': (7, 0)}
I = {'addi': 0, 'slti': 2, 'sltiu': 3, 'xori': 4, 'ori': 6, 'andi': 7}
SH = {'slli': (1, 0), 'srli': (5, 0), 'srai': (5, 0x20)}
LD = {'lb': 0, 'lh': 1, 'lw': 2, 'lbu': 4, 'lhu': 5}
ST = {'sb': 0, 'sh': 1, 'sw': 2}
BR = {'beq': 0, 'bne': 1, 'blt': 4, 'bge': 5, 'bltu': 6, 'bgeu': 7}


def reg(s):
    m = re.fullmatch(r'x(\d+)', s.strip())
    if not m or int(m.group(1)) > 31:
        raise ValueError('bad register ' + s)
    return int(m.group(1))


def num(s):
    return int(s.strip(), 0)


def fits(v, bits, what):
    if not -(1 << (bits - 1)) <= v < (1 << (bits - 1)):
        raise ValueError(f'{what} {v} out of range for {bits}-bit signed')


def enc_r(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(imm, rs1, f3, rd, op):
    fits(imm, 12, 'imm')
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(imm, rs2, rs1, f3, op):
    fits(imm, 12, 'imm')
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | ((imm & 0x1F) << 7) | op


def enc_b(imm, rs2, rs1, f3, op):
    fits(imm, 13, 'branch offset')
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | op


def enc_u(imm, rd, op):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | op


def enc_j(imm, rd, op):
    fits(imm, 21, 'jump offset')
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | \
           (((imm >> 12) & 0xFF) << 12) | (rd << 7) | op


def assemble(lines):
    labels, items = {}, []
    for raw in lines:
        line = raw.split('#')[0].strip()
        while ':' in line:
            lab, line = line.split(':', 1)
            labels[lab.strip()] = len(items) * 4
            line = line.strip()
        if line:
            items.append(line)

    words = []
    for idx, line in enumerate(items):
        pc = idx * 4
        mn, _, rest = line.partition(' ')
        mn = mn.lower()
        a = [x.strip() for x in rest.split(',')] if rest.strip() else []

        def target(t):
            return labels[t] - pc if t in labels else num(t)

        def memop(t):
            m = re.fullmatch(r'(.*)\((x\d+)\)', t.strip())
            return num(m.group(1) or '0'), reg(m.group(2))

        if mn in R:
            f3, f7 = R[mn]
            w = enc_r(f7, reg(a[2]), reg(a[1]), f3, reg(a[0]), 0x33)
        elif mn in I:
            w = enc_i(num(a[2]), reg(a[1]), I[mn], reg(a[0]), 0x13)
        elif mn in SH:
            f3, f7 = SH[mn]
            w = enc_r(f7, num(a[2]) & 31, reg(a[1]), f3, reg(a[0]), 0x13)
        elif mn in LD:
            off, rs1 = memop(a[1])
            w = enc_i(off, rs1, LD[mn], reg(a[0]), 0x03)
        elif mn in ST:
            off, rs1 = memop(a[1])
            w = enc_s(off, reg(a[0]), rs1, ST[mn], 0x23)
        elif mn in BR:
            w = enc_b(target(a[2]), reg(a[1]), reg(a[0]), BR[mn], 0x63)
        elif mn == 'jal':
            w = enc_j(target(a[1]), reg(a[0]), 0x6F)
        elif mn == 'jalr':
            off, rs1 = memop(a[1])
            w = enc_i(off, rs1, 0, reg(a[0]), 0x67)
        elif mn == 'lui':
            w = enc_u(num(a[1]), reg(a[0]), 0x37)
        elif mn == 'auipc':
            w = enc_u(num(a[1]), reg(a[0]), 0x17)
        elif mn == 'nop':
            w = 0x00000013
        else:
            raise ValueError(f'unknown instruction: {line}')
        words.append(w & 0xFFFFFFFF)
    return words, labels


if __name__ == '__main__':
    src, dst = sys.argv[1], sys.argv[2]
    words, labels = assemble(open(src).read().splitlines())
    with open(dst, 'w', newline='\n') as f:
        for w in words:
            f.write(f'{w:08X}\n')
    print(f'{len(words)} instructions -> {dst}')
    for k, v in labels.items():
        print(f'  {k} = 0x{v:X}')
