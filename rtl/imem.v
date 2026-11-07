module imem (
    input clk,
    input [31:0]a,
    output [31:0]rd
);

reg [31:0]RAM[0:63];//64 lines of 32 bit words
initial $readmemh("riscvtest.txt",RAM);
assign rd=RAM[a[7:2]];

//read only. cannotwrite
endmodule