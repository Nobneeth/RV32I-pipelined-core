# Hazard test for the pipeline: every forwarding path, load-use stalls, and branch/jump flushes,
# with NO padding. x31 counts errors (must end 0). Expected values come from rvasm.py's reference model.
# ---- forwarding from M (distance 1), rs1 and rs2
        addi x1, x0, 10
        addi x2, x1, 1           # rs1 <- M
        addi x3, x0, 5
        sub  x4, x0, x3          # rs2 <- M
# ---- from W (distance 2) and from M in the same instruction
        addi x5, x0, 7
        addi x6, x0, 1
        add  x7, x5, x6          # rs1 <- W, rs2 <- M
# ---- M must win over W when both match
        addi x8, x0, 1
        addi x8, x0, 2
        add  x9, x8, x8          # must use 2, not 1  -> 4
# ---- x0 is never forwarded
        addi x0, x0, 55
        add  x10, x0, x0         # must be 0
# ---- load-use stalls
        addi x11, x0, 100        # base address
        sw   x1, 0(x11)          # store data <- forwarded? (x1 is old) ; mem[100]=10
        lw   x12, 0(x11)
        addi x13, x12, 1         # load-use on rs1 -> 11
        lw   x14, 0(x11)
        add  x15, x0, x14        # load-use on rs2 -> 10
        lw   x16, 0(x11)
        sw   x16, 4(x11)         # load-use into store data -> mem[104]=10
        addi x17, x0, 77
        sw   x17, 8(x11)         # store data <- M -> mem[108]=77
        sw   x3, 12(x11)         # mem[112]=5
        lw   x18, 0(x11)
        lw   x18, 12(x11)        # second load wins
        add  x19, x18, x0        # -> 5
# ---- branch whose operand comes from the instruction just before it (loop 3 times)
        addi x20, x0, 3
loop:   addi x21, x21, 1
        addi x20, x20, -1
        bne  x20, x0, loop       # rs1 <- M
# ---- branch on a just-loaded value (stall, then forward into the compare)
        lw   x22, 0(x11)         # 10
        beq  x22, x1, ok1
        addi x31, x31, 1
ok1:
# ---- taken branch must flush the two wrong-path instructions
        beq  x0, x0, skip
        addi x31, x31, 1
        addi x31, x31, 1
skip:
# ---- jal: flush + link value used at the target and after return
        jal  x23, func
        addi x24, x23, 0         # after return
        jal  x0, after
func:   addi x25, x23, 0         # link register used immediately at the target
        jalr x0, 0(x23)
        addi x31, x31, 1         # wrong path after jalr
        addi x31, x31, 1
after:
# ---- jalr whose base register comes from the instruction just before it
        jal  x27, j15            # x27 = address of j15
j15:    addi x27, x27, 16        # target = j15 + 16
        jalr x26, 0(x27)         # rs1 <- M
        addi x31, x31, 1         # j15+8: must be skipped
        addi x31, x31, 1         # j15+12: must be skipped
        addi x28, x0, 9          # j15+16: lands here
# ---- results
        sw   x31, 16(x11)
        sw   x21, 20(x11)
done:   beq  x0, x0, done
