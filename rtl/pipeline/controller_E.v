module controller_E (
    //input [6:0]op,
    input [2:0]funct3E,//from 
    //input funct7b5,
    input eq,//from alu
    input lt,//from alu
    input ltu,//from alu
    input JumpE,
    input BranchE,//from packet DtoE
    //input [1:0]ALUOp;
    input JalrE,//D-E
    output [1:0]PCSrcE
    //output [1:0]ResultSrc,
    //output MemWrite,
    //output ALUSrc,
    //output [2:0]ImmSrc,
    //output RegWrite,
    //output [3:0]ALUControl
);
    wire BranchTakenE;

    branchcond branchdecision (.BranchTaken(BranchTakenE),.eq(eq),.lt(lt),.ltu(ltu),.funct3(funct3E));
    
    //maindec maindecoder (.op(op),.RegWrite(RegWrite),.ImmSrc(ImmSrc),.ALUSrc(ALUSrc),.MemWrite(MemWrite),.ResultSrc(ResultSrc),.Branch(Branch),.ALUOp(ALUOp),.Jump(Jump),.Jalr(Jalr));
    //aludec ALUdecoder (.ALUOp(ALUOp),.funct3(funct3),.funct7b5(funct7b5),.opb5(op[5]),.ALUControl(ALUControl));

    assign PCSrcE = JalrE?2'b10:((BranchE & BranchTakenE)|JumpE)?2'b01:2'b00;

endmodule