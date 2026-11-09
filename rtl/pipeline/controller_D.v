module controller_D (//D for decode stage
    input [6:0]op,//from InstrD
    input [2:0]funct3,//from InstrD
    input funct7b5,//from InstrD
    //input eq,
    //input lt,
    //input ltu,
    //output reg [1:0]PCSrc,
    output [1:0]ResultSrcD,
    output MemWriteD,
    output ALUSrcD,
    output [2:0]ImmSrcD,
    output RegWriteD,
    output [3:0]ALUControlD,
    output JumpD,
    output BranchD,
    
    output JalrD
);
    wire [1:0]ALUOp;
    //wire BranchTaken;
    //branchcond branchdecision (.BranchTaken(BranchTaken),.eq(eq),.lt(lt),.ltu(ltu),.funct3(funct3));
    //removed because it will come in controller_E
    maindec maindecoder (.op(op),.RegWrite(RegWriteD),.ImmSrc(ImmSrcD),.ALUSrc(ALUSrcD),.MemWrite(MemWriteD),.ResultSrc(ResultSrcD),.Branch(BranchD),.ALUOp(ALUOp),.Jump(JumpD),.Jalr(JalrD));
    aludec ALUdecoder (.ALUOp(ALUOp),.funct3(funct3),.funct7b5(funct7b5),.opb5(op[5]),.ALUControl(ALUControlD));

    //always @(*) begin    
    //    case ({op})
    //        7'b1100011: PCSrc = BranchTaken?2'd1:2'd0;//branch taken
    //        7'b1101111: PCSrc = 2'd1;//jump
    //        7'b1100111: PCSrc = 2'd2; //jalr
    //        default: PCSrc=2'd0;
    //    endcase
    //end

endmodule