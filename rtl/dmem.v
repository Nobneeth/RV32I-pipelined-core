module dmem (
    input clk,
    input we,
    input [31:0]a,
    output reg [31:0]rd,
    input [31:0]wd
);

reg [31:0]RAM[0:63];

always @(posedge clk ) begin
    if(we) RAM[a[7:2]]<=wd;
    else rd<=RAM[a[7:2]];
end
    
endmodule