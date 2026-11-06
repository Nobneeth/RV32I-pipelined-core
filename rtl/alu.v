//what all does an ALU needs to do in riscV?
//add , sub, and, or, xor
//setl less than SLT, Unsigned set less thanSLTU
//srl,sll,sra


module alu (
    input [31:0] a,
    input [31:0] b,
    input [3:0] ALUControl,
    output reg [31:0] ALUresult,//will be synthesized to wire if default given.
    output lt, output eq, output ltu
);
    //ALU is purely combinational block
    //assuming ADD 0000 sub 0001 and 0010 or 0011 xor 0100 slt 0101 sltu 1101(giving this so that the 4th bit can be used for unsigned for combination _101)
    //srl 1000, sll 1001, sra 1010
    // not using case statements because it can infer latches. using with default
    // the comparisions are always unsigned byy default. because default for ports is unsigned
    
    assign lt = $signed(a) < $signed(b)  ;
    assign eq = (a==b);
    assign ltu = (a<b);
    always @(*) begin
        case (ALUControl)
            4'd0: ALUresult = a+b;
            4'd1: ALUresult = a-b;
            4'd2: ALUresult = a&b;
            4'd3: ALUresult = a|b;
            4'd4: ALUresult = a^b;
            4'b0101: ALUresult = {31'd0,lt};
            4'b1101: ALUresult = {31'd0,ltu};
            4'd8: ALUresult = a >> b[4:0];
            4'd9: ALUresult = a << b[4:0];
            4'd10: ALUresult = $signed(a) >>> b[4:0];
            //>>> works only for signed expression
            default: ALUresult = 0;//did not want to infer latches
        endcase
    end

    // can use case statements but it could create latch.
    
endmodule