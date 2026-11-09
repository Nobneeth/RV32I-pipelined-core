module dmem #(
    parameter WORDS = 64                  // number of 32-bit words
)(
    input clk,
    input we,
    input [31:0]a,
    output [31:0]rd,
    input [31:0]wd
);

localparam AW = $clog2(WORDS);           // word-index width, e.g. 64 words -> 6 bits

reg [31:0]RAM[0:WORDS-1];
assign rd=RAM[a[AW+1:2]];
always @(posedge clk) begin
    if(we) RAM[a[AW+1:2]]<=wd;
end

endmodule
