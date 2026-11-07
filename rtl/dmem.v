module dmem (
    input clk,
    input we,
    input [31:0]a,
    output [31:0]rd,
    input [31:0]wd
);

reg [31:0]RAM[0:63];
assign rd=RAM[a[7:2]];
always @(posedge clk ) begin
    if(we) RAM[a[7:2]]<=wd;
     
end
    
endmodule