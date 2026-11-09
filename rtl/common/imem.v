module imem #(
    parameter WORDS   = 256,              // number of 32-bit words
    parameter MEMFILE = "fulltest.mem"    // program image loaded at power-up (also used by synthesis)
)(
    input clk,                            // unused: read-only, combinational
    input [31:0]a,
    output [31:0]rd
);

localparam AW = $clog2(WORDS);           // word-index width, e.g. 256 words -> 8 bits

reg [31:0]RAM[0:WORDS-1];
initial $readmemh(MEMFILE,RAM);
assign rd=RAM[a[AW+1:2]];

endmodule
