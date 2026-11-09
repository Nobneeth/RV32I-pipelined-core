module controller (
    input [6:0]op,
    input [2:0]funct3,
    input funct7b5,
    input eq,
    input lt,
    input ltu,
    output reg [1:0]PCSrc,
    output [1:0]ResultSrc,
    output MemWrite,
    output ALUSrc,
    output [2:0]ImmSrc,
    output RegWrite,
    output [3:0]ALUControl
);
    wire Jump, Branch;
    wire [1:0]ALUOp;
    wire BranchTaken;
    wire Jalr;
    branchcond branchdecision (.BranchTaken(BranchTaken),.eq(eq),.lt(lt),.ltu(ltu),.funct3(funct3));
    maindec maindecoder (.op(op),.RegWrite(RegWrite),.ImmSrc(ImmSrc),.ALUSrc(ALUSrc),.MemWrite(MemWrite),.ResultSrc(ResultSrc),.Branch(Branch),.ALUOp(ALUOp),.Jump(Jump),.Jalr(Jalr));
    aludec ALUdecoder (.ALUOp(ALUOp),.funct3(funct3),.funct7b5(funct7b5),.opb5(op[5]),.ALUControl(ALUControl));

    always @(*) begin
        
        case ({op})
            7'b1100011: PCSrc = BranchTaken?2'd1:2'd0;//branchtaken aand branch
            7'b1101111: PCSrc = 2'd1;//jump
            7'b1100111: PCSrc = 2'd2; //jalr
            default: PCSrc=2'd0;
        endcase
    end
endmodule