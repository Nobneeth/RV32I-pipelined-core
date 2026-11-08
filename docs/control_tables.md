# Control tables (single-cycle)

Generated from the RTL in `rtl/`. If the RTL changes, update these tables.

## Main decoder (`maindec.v`)

| Instruction | op | RegWrite | ImmSrc | ALUSrc | MemWrite | ResultSrc | Branch | ALUOp | Jump | Jalr |
|---|---|---|---|---|---|---|---|---|---|---|
| `lw` | 0000011 | 1 | 000 (I) | 1 | 0 | 01 (ReadData) | 0 | 00 | 0 | 0 |
| `sw` | 0100011 | 0 | 001 (S) | 1 | 1 | xx | 0 | 00 | 0 | 0 |
| R-type | 0110011 | 1 | xxx | 0 | 0 | 00 (ALUResult) | 0 | 10 | 0 | 0 |
| branches (all 6) | 1100011 | 0 | 010 (B) | 0 | 0 | xx | 1 | 01 | 0 | 0 |
| I-type ALU | 0010011 | 1 | 000 (I) | 1 | 0 | 00 (ALUResult) | 0 | 10 | 0 | 0 |
| `jal` | 1101111 | 1 | 100 (J) | x | 0 | 10 (PCPlus4) | 0 | xx | 1 | 0 |
| `jalr` | 1100111 | 1 | 000 (I) | 1 | 0 | 10 (PCPlus4) | 0 | 00 | 1 | 1 |
| unknown opcode | — | 0 | 000 | 0 | 0 | 00 | 0 | 00 | 0 | 0 |

An unknown opcode writes nothing and advances to PC + 4, so it behaves as a NOP.

## ALU control (`aludec.v` → `alu.v`)

`ALUControl = {instr[30], funct3}` for ALU instructions, with bit 3 masked:

| ALUOp | Used by | ALUControl |
|---|---|---|
| 00 | `lw`, `sw`, `jalr` | `0000` (add) |
| 01 | branches | `1000` (sub; flags are used, not the result) |
| 10 | R-type, I-type ALU | `{(op[5] \| funct3==101) & instr[30], funct3}` |

| ALUControl | Operation | ALUControl | Operation |
|---|---|---|---|
| `0000` | add | `0100` | xor |
| `1000` | sub | `0101` | srl |
| `0001` | sll | `1101` | sra |
| `0010` | slt | `0110` | or |
| `0011` | sltu | `0111` | and |

Why the mask: in I-type, `instr[30]` is an immediate bit (`addi x, x, -1024` has it set), so it may only select sub/sra for R-type (`op[5] = 1`) or for shifts (`funct3 = 101`).

## Branch condition (`branchcond.v`)

| funct3 | Instruction | BranchTaken |
|---|---|---|
| 000 | `beq` | `eq` |
| 001 | `bne` | `!eq` |
| 100 | `blt` | `lt` |
| 101 | `bge` | `!lt` |
| 110 | `bltu` | `ltu` |
| 111 | `bgeu` | `!ltu` |

## Next-PC select (`controller.v`)

| PCSrc | Next PC | When |
|---|---|---|
| 00 | `PCPlus4` | default, branch not taken |
| 01 | `PCTarget = PC + ImmExt` | `jal`, branch taken |
| 10 | `{ALUResult[31:1], 1'b0}` | `jalr` |

## Immediate formats (`immgen.v`)

| ImmSrc | Format | ImmExt |
|---|---|---|
| 000 | I | `{{20{instr[31]}}, instr[31:20]}` |
| 001 | S | `{{20{instr[31]}}, instr[31:25], instr[11:7]}` |
| 010 | B | `{{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0}` |
| 011 | U | `{instr[31:12], 12'b0}` (generated, not used yet) |
| 100 | J | `{{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0}` |
