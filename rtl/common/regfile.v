module regfile(
    input clk,
    input [4:0]rd,
    input [4:0]rs1,
    input [4:0]rs2,
    input we,
    input [31:0]din,
    output  [31:0]d1out,
    output  [31:0]d2out
);
reg [31:0]r[31:0];
//asper RV32I, the r0 is always 0. 
//we can hardwire it to 0 inside clk but it costs heavily because we are assigning 0 to 32 bits every clock cycle.
//hence instead we choose to output 0 whenever rs1/rs2 = 0.

assign d2out=(rs2==0)?32'b0:r[rs2];
assign d1out=(rs1==0)?32'b0:r[rs1];
//combinationally because they dont depend on clock. only write does

always @(negedge clk) begin
    //reads dont need to be clocked like in FIFO 
    if (we && rd!=0) begin
        r[rd]<=din;
    end
end

endmodule