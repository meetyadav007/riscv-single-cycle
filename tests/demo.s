# Demo program: one idea per line, run it with run_demo.ps1
# --- arithmetic ---
addi x1, x0, 10          # x1 = 10
addi x2, x0, 3           # x2 = 3
add  x3, x1, x2          # x3 = 13
sub  x4, x1, x2          # x4 = 7
and  x5, x1, x2          # x5 = 2
or   x6, x1, x2          # x6 = 11
sll  x7, x1, x2          # x7 = 80
# --- memory ---
sw   x3, 0(x0)           # mem[0] = 13
sw   x4, 4(x0)           # mem[4] = 7
lw   x8, 0(x0)           # x8 = 13
lw   x9, 4(x0)           # x9 = 7
# --- branches ---
beq  x8, x3, eq_ok       # equal -> TAKEN, skips next line
addi x10, x0, 99         # (skipped)
eq_ok:
addi x10, x0, 1          # x10 = 1
bne  x8, x9, ne_ok       # different -> TAKEN, skips next line
addi x11, x0, 99         # (skipped)
ne_ok:
addi x11, x0, 2          # x11 = 2
# --- jumps ---
jal  x12, target         # jump forward, x12 = return address
addi x13, x0, 99         # (skipped)
target:
addi x13, x0, 3          # x13 = 3
auipc x14, 0             # x14 = address of this instruction
jalr x15, 12(x14)        # jump to x14+12, x15 = return address
addi x16, x0, 99         # (skipped)
addi x16, x0, 4          # x16 = 4
done:
jal  x0, done            # stop here (infinite loop)
