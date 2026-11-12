# Self-checking test program for the single-cycle RV32I core.
# tb_top.v checks the final register / data-memory state.

# ---------- Arithmetic / logic ----------
addi x1, x0, 10          # x1  = 10
addi x2, x0, 3           # x2  = 3
add  x3, x1, x2          # x3  = 13
sub  x4, x1, x2          # x4  = 7
and  x5, x1, x2          # x5  = 2
or   x6, x1, x2          # x6  = 11
xor  x7, x1, x2          # x7  = 9
sll  x8, x1, x2          # x8  = 80
srl  x9, x1, x2          # x9  = 1
addi x10, x0, -16        # x10 = 0xFFFFFFF0
sra  x11, x10, x2        # x11 = 0xFFFFFFFE
srl  x12, x10, x2        # x12 = 0x1FFFFFFE
slt  x13, x10, x1        # x13 = 1   (-16 < 10 signed)
sltu x14, x10, x1        # x14 = 0   (unsigned compare)
slli x15, x1, 4          # x15 = 160
srai x16, x10, 2         # x16 = 0xFFFFFFFC
lui  x17, 0x12345        # x17 = 0x12345000
addi x17, x17, 0x678     # x17 = 0x12345678
auipc x18, 0             # x18 = address of this instruction (0x44)

# ---------- Memory access ----------
sw   x17, 0(x0)          # mem[0]  = 0x12345678
lw   x19, 0(x0)          # x19 = 0x12345678
lb   x20, 0(x0)          # x20 = 0x78
sb   x10, 5(x0)          # mem[1]  = 0x0000F000
lw   x21, 4(x0)          # x21 = 0x0000F000
lb   x22, 5(x0)          # x22 = 0xFFFFFFF0 (sign-extended)
lbu  x23, 5(x0)          # x23 = 0x000000F0
sh   x10, 10(x0)         # mem[2]  = 0xFFF00000
lw   x24, 8(x0)          # x24 = 0xFFF00000
lh   x25, 10(x0)         # x25 = 0xFFFFFFF0
lhu  x26, 10(x0)         # x26 = 0x0000FFF0
lb   x27, 1(x0)          # x27 = 0x56
lh   x28, 2(x0)          # x28 = 0x1234
sw   x1, 16(x0)          # mem[4]  = 10
lw   x29, 16(x0)         # x29 = 10

# ---------- Branches (results stored at 0x40 + 4*n) ----------
# slot stays 0 when branch correctly TAKEN (store skipped),
# slot = 5 when branch correctly NOT taken (store executed).
addi x30, x0, 5
addi x31, x0, -1
beq  x30, x30, b1
sw   x31, 0x40(x0)
b1:
beq  x30, x31, b2
sw   x30, 0x44(x0)
b2:
bne  x30, x31, b3
sw   x31, 0x48(x0)
b3:
bne  x30, x30, b4
sw   x30, 0x4C(x0)
b4:
blt  x31, x30, b5
sw   x31, 0x50(x0)
b5:
blt  x30, x31, b6
sw   x30, 0x54(x0)
b6:
bge  x30, x31, b7
sw   x31, 0x58(x0)
b7:
bge  x31, x30, b8
sw   x30, 0x5C(x0)
b8:
bltu x30, x31, b9
sw   x31, 0x60(x0)
b9:
bltu x31, x30, b10
sw   x30, 0x64(x0)
b10:
bgeu x31, x30, b11
sw   x31, 0x68(x0)
b11:
bgeu x30, x31, b12
sw   x30, 0x6C(x0)
b12:
# backward branch: count to 4
addi x30, x0, 0
addi x31, x0, 4
loop:
addi x30, x30, 1
bne  x30, x31, loop
sw   x30, 0x70(x0)       # 4

# ---------- Jumps ----------
addi x30, x0, 0
jal  x31, func           # call; x31 = return address
sw   x30, 0x74(x0)       # 77 (written by func)
sw   x31, 0x78(x0)       # return address
jal  x0, after_func
func:
addi x30, x0, 77
jalr x0, 0(x31)          # return
sw   x1, 0x74(x0)        # must never execute
after_func:
auipc x30, 0             # x30 = A
jalr x31, 12(x30)        # jump to A+12, x31 = A+8
sw   x30, 0x7C(x0)       # skipped
sw   x31, 0x7C(x0)       # target: stores A+8
done:
jal  x0, done            # halt
