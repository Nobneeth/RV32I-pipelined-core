# Full single-cycle test: every supported instruction, every branch taken AND not taken,
# signed vs unsigned, negative immediates, x0 writes, a backward loop, jal + jalr (incl. odd target).
# x30 counts correct fall-throughs, x31 counts errors (must end 0).
        addi x1, x0, -1          # x1 = 0xFFFFFFFF
        addi x2, x0, 1
        addi x3, x0, 5
        addi x4, x0, -8
        addi x0, x0, 123         # x0 must stay 0
# ---- R-type
        add  x5, x3, x2          # 6
        sub  x6, x2, x3          # -4
        and  x7, x1, x3          # 5
        or   x8, x4, x2          # -7
        xor  x9, x1, x3          # ~5
        sll  x10, x2, x3         # 32
        srl  x11, x4, x2         # 0x7FFFFFFC
        sra  x12, x4, x2         # -4
        slt  x13, x1, x2         # 1  (-1 < 1 signed)
        sltu x14, x1, x2         # 0  (0xFFFFFFFF > 1 unsigned)
# ---- I-type ALU
        addi  x15, x3, -1024     # bit 30 set: must add, not sub
        andi  x16, x1, 0x7F0
        ori   x17, x0, -2048
        xori  x18, x3, -1        # not 5
        slti  x19, x4, -7        # 1
        sltiu x20, x2, -1        # 1  (1 < 0xFFFFFFFF)
        slli  x21, x3, 31
        srli  x22, x1, 28        # 0xF
        srai  x23, x4, 2         # -2
# ---- memory
        addi x24, x0, 64
        sw   x1, 0(x24)
        sw   x5, 4(x24)
        lw   x25, 0(x24)
        lw   x26, 4(x24)
        sw   x26, -4(x24)        # negative store offset -> address 60
        sw   x15, 252(x0)        # last data word
# ---- branches: taken cases skip an error increment
        beq  x2, x2, t1
        addi x31, x31, 1
t1:     bne  x2, x3, t2
        addi x31, x31, 1
t2:     blt  x1, x2, t3          # -1 < 1 signed
        addi x31, x31, 1
t3:     bge  x2, x2, t4          # equal must branch
        addi x31, x31, 1
t4:     bge  x2, x1, t5          # 1 >= -1 signed
        addi x31, x31, 1
t5:     bltu x2, x1, t6          # 1 < 0xFFFFFFFF unsigned
        addi x31, x31, 1
t6:     bgeu x1, x2, t7
        addi x31, x31, 1
t7:     bgeu x2, x2, n1          # equal must branch
        addi x31, x31, 1
# ---- branches: not-taken cases fall through and count
n1:     beq  x2, x3, bad
        addi x30, x30, 1
        bne  x2, x2, bad
        addi x30, x30, 1
        blt  x2, x1, bad         # 1 < -1 false (signed)
        addi x30, x30, 1
        blt  x2, x2, bad
        addi x30, x30, 1
        bge  x1, x2, bad         # -1 >= 1 false
        addi x30, x30, 1
        bltu x1, x2, bad         # 0xFFFFFFFF < 1 false (unsigned)
        addi x30, x30, 1
        bgeu x2, x1, bad
        addi x30, x30, 1
# ---- backward branch loop: x29 = 2 * 3
        addi x28, x0, 3
loop:   addi x29, x29, 2
        addi x28, x28, -1
        bne  x28, x0, loop
# ---- jal / jalr
        jal  x27, func           # call, x27 = return address
        addi x26, x26, 100       # runs after return
        jal  x0, finish
func:   addi x25, x25, 7
        jalr x0, 1(x27)          # odd offset: bit 0 must be cleared
bad:    addi x31, x31, 16        # reached only by a wrongly taken branch
finish: sw   x31, 8(x24)
        sw   x30, 12(x24)
        sw   x29, 16(x24)
done:   beq  x0, x0, done
