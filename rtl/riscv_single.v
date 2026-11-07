module riscv_single (
    input clk,
    input reset,
    input [31:0]Instr,
    input [31:0]ReadData,
    output [31:0]PC,
    output MemWrite,
    output [31:0]ALUResult,
    output [31:0]WriteData
);
    wire eq, lt, ltu;
    wire RegWrite, ALUSrc;
    wire [1:0]PCSrc, ResultSrc;
    wire [2:0]ImmSrc;
    wire [3:0]ALUControl;

    controller ctrl (.op(Instr[6:0]),.funct3(Instr[14:12]),.funct7b5(Instr[30]),.eq(eq),.lt(lt),.ltu(ltu),
                     .PCSrc(PCSrc),.ResultSrc(ResultSrc),.MemWrite(MemWrite),.ALUSrc(ALUSrc),.ImmSrc(ImmSrc),.RegWrite(RegWrite),.ALUControl(ALUControl));

    datapath dp (.clk(clk),.reset(reset),.PCSrc(PCSrc),.RegWrite(RegWrite),.ALUSrc(ALUSrc),.ImmSrc(ImmSrc),.ALUControl(ALUControl),.ResultSrc(ResultSrc),
                 .eq(eq),.lt(lt),.ltu(ltu),.Instr(Instr),.ReadData(ReadData),.ALUResult(ALUResult),.PC(PC),.WriteData(WriteData));

endmodule
