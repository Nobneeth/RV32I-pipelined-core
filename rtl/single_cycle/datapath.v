// single-cycle datapath (Harris Figure 7.15, extended for jalr and all six branches)

module datapath (
    input clk,
    input reset,
    input [1:0]PCSrc,
    input RegWrite,
    input ALUSrc,
    input [2:0]ImmSrc,
    input [3:0]ALUControl,
    input [1:0]ResultSrc,
    output eq,//ALU flags, to the controller
    output lt,
    output ltu,
    input [31:0]Instr,
    input [31:0]ReadData,
    output [31:0]ALUResult,
    output reg [31:0]PC,
    output [31:0]WriteData
);
wire [31:0]SrcA,ImmExt;
reg [31:0]PCNext, SrcB,Result;
wire [31:0] PCplus4 =  PC+32'd4;
    always @(*) begin
        case (PCSrc)
            2'd1:PCNext=PC+ImmExt;
            2'd2:PCNext= {ALUResult[31:1],1'b0} ;
            default:PCNext=PCplus4; 
        endcase

        case (ResultSrc)
            2'd1: Result=ReadData;
            2'd2: Result=PCplus4;
            default: Result = ALUResult;
        endcase

        SrcB=ALUSrc?ImmExt:WriteData;
    end
//dmem Data_mem (.a(ALUResult),.wd(WriteData),.rd(ReadData),.clk(clk),.we(MemWrite));
alu ALU (.a(SrcA),.b(SrcB),.ALUControl(ALUControl),.eq(eq),.lt(lt),.ltu(ltu),.ALUResult(ALUResult));
//imem instr_mem (.a(PC),.rd(Instr),.clk(clk));
regfile Reg_File (.rs1(Instr[19:15]),.rs2(Instr[24:20]),.clk(clk),.we(RegWrite),.rd(Instr[11:7]),.din(Result),.d1out(SrcA),.d2out(WriteData));
immgen Imm_gen (.ImmSrc(ImmSrc),.instr(Instr),.ImmExt(ImmExt));

    always @(posedge clk or posedge reset) begin
        if(reset) PC<=32'd0;
        else PC<=PCNext;
    end
endmodule