module aludec (
    input [1:0]ALUOp,
    input [2:0]funct3,
    input funct7b5,//instr[30]
    input opb5,//op[5]or instr[5]
    output reg [3:0]ALUControl
);

always @(*) begin
    case (ALUOp)
        2'd0: begin ALUControl=4'd0;  end
        2'd1: begin ALUControl= 4'd8; end
        2'd2: begin ALUControl= {(opb5|(funct3==3'b101)) &funct7b5,funct3}; end
        default: ALUControl=4'd0;//letting addition be primary operation
    endcase
end
    
endmodule