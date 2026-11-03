//timescale first for simulations

`timescale 1ns/1ps //precison 1ps but time units in 1ns

module regfile_tb ();

logic clk,we;
logic [4:0]rd,rs1,rs2;
logic [31:0] din,d1out,d2out;
// in verilog testbenches you need regs for signals that testbench drives (inputs)
// in SV we just need logic.

regfile dut (.*);//(.clk(clk),.we(we), .rd(rd),.rs1(rs1),.rs2(rs2),.din(din),.d1out(d1out),.d2out(d2out));
    initial begin
        clk = 0;
        we = 0;
        din = 0;
        rd = 1;//because r0 cannot be written just in case.
    end

    always begin
        #5 clk = ~clk;
    end
    //assign clk = #5 ~clk; this is illegal 

task automatic write_reg(input logic [4:0]regaddr,input logic [31:0]wdata);
    @(negedge clk) begin
        we=1; rd=regaddr; din=wdata;
    end
    @(negedge clk)we=0;
endtask //automatic 
initial begin
    write_reg(5,32'hDEADBEEF);
    rs1=5 ;#1//because wait till reg is read in DUT
     $display("%h",d1out);#9 $finish;
end
endmodule