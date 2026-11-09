module maindec (
    input [6:0]op,
    output RegWrite,
    output [2:0]ImmSrc,
    output ALUSrc,
    output MemWrite,
    output [1:0]ResultSrc,
    output Branch,
    output [1:0]ALUOp,
    output Jump,
    output Jalr

);

reg [12:0]control;
assign {RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc[1:0],Branch,ALUOp[1:0],Jump,Jalr} = control;

always @(*) begin
    case (op)
        //                      RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_JALR
        7'b0000011: control = 13'b1_000_1_0_01_0_00_0_0; //lw
        7'b0100011: control = 13'b0_001_1_1_00_0_00_0_0; //sw
        7'b0110011: control = 13'b1_xxx_0_0_00_0_10_0_0; //R-type
        7'b1100011: control = 13'b0_010_0_0_00_1_01_0_0; //beq
        7'b0010011: control = 13'b1_000_1_0_00_0_10_0_0; //I-type ALU
        7'b1101111: control = 13'b1_100_x_0_10_0_xx_1_0; //jal
        7'b1100111: control = 13'b1_000_1_0_10_0_00_1_1; //jalr
        default:    control = 13'b0_000_0_0_00_0_00_0_0; //
    endcase
end

endmodule