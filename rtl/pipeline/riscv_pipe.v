module riscv_pipe (
    input clk,
    input reset,
    input  [31:0]InstrF,
    input  [31:0]ReadDataM,
    output [31:0]PCF,
    output [31:0]ALUResultM,
    output [31:0]WriteDataM,
    output MemWriteM
);
    wire [31:0]InstrD;
    wire RegWriteD, MemWriteD, ALUSrcD, JalrD, BranchD, JumpD;
    wire [2:0]ImmSrcD;
    wire [3:0]ALUControlD;
    wire [1:0]ResultSrcD;
    wire eqE, ltE, ltuE, JumpE, BranchE, JalrE;
    wire [2:0]funct3E;
    wire [1:0]PCSrcE;

    controller_D ctrlD (.op(InstrD[6:0]),.funct3(InstrD[14:12]),.funct7b5(InstrD[30]),
                        .ResultSrcD(ResultSrcD),.MemWriteD(MemWriteD),.ALUSrcD(ALUSrcD),.ImmSrcD(ImmSrcD),
                        .RegWriteD(RegWriteD),.ALUControlD(ALUControlD),.JumpD(JumpD),.BranchD(BranchD),.JalrD(JalrD));

    controller_E ctrlE (.funct3E(funct3E),.eq(eqE),.lt(ltE),.ltu(ltuE),
                        .JumpE(JumpE),.BranchE(BranchE),.JalrE(JalrE),.PCSrcE(PCSrcE));

    datapath_pipe dp (.clk(clk),.reset(reset),.InstrF(InstrF),.PCF(PCF),.PCSrcE(PCSrcE),.InstrD(InstrD),
                      .RegWriteD(RegWriteD),.MemWriteD(MemWriteD),.ALUSrcD(ALUSrcD),.JalrD(JalrD),.BranchD(BranchD),
                      .JumpD(JumpD),.ImmSrcD(ImmSrcD),.ALUControlD(ALUControlD),.ResultSrcD(ResultSrcD),
                      .eqE(eqE),.ltE(ltE),.ltuE(ltuE),.funct3E(funct3E),.JumpE(JumpE),.BranchE(BranchE),.JalrE(JalrE),
                      .ALUResultM(ALUResultM),.WriteDataM(WriteDataM),.MemWriteM(MemWriteM),.ReadDataM(ReadDataM));
endmodule
