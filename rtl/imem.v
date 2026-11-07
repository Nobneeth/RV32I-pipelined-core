module imem (
    input clk,
    input [31:0]a,
    output reg [31:0]rd
);

reg [31:0]RAM[0:63];//64 lines of 32 bit words
initial $readmemh("riscvtest.txt",RAM);

always @(posedge clk ) begin
    rd<=RAM[a[7:2]];
end
//read only. cannotwrite
endmodule