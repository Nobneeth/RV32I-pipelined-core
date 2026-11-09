// RV32I ALU: add, sub, and, or, xor, slt, sltu, sll, srl, sra.
// ALUControl = {instr[30], funct3}; flags eq/lt/ltu feed branchcond.


module alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] ALUControl,
    output reg [31:0] ALUResult,//will be synthesized to wire if default given.
    output lt, output eq, output ltu
);
    //purely combinational. comparisons are unsigned by default (ports are unsigned), so lt needs $signed
    
    assign lt = $signed(a) < $signed(b)  ;
    assign eq = (a==b);
    assign ltu = (a<b);
    always @(*) begin
        case (ALUControl)
            4'd0: ALUResult = a+b;
            4'd8: ALUResult = a-b;
            4'd7: ALUResult = a&b;
            4'd6: ALUResult = a|b;
            4'd4: ALUResult = a^b;
            4'd2: ALUResult = {31'd0,lt};
            4'd3: ALUResult = {31'd0,ltu};
            4'd5: ALUResult = a >> b[4:0];
            4'd1: ALUResult = a << b[4:0];
            4'd13: ALUResult = $signed(a) >>> b[4:0];
            //>>> is arithmetic only on a signed operand
            default: ALUResult = 0;//did not want to infer latches
        endcase
    end

endmodule