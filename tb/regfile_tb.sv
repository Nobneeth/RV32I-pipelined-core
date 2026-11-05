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
        rs1 = 0;
        rs2 = 0;
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
    assert (d1out===32'hDEADBEEF) 
    else   $error("TC1: d1out=%h,expected DEADBEEF",d1out);
    write_reg(6,32'hCAFEF00D);
    rs1=5;rs2=6;#1
    assert (d1out===32'hDEADBEEF)
    else   $error("TC2: d1out=%h,expected DEADBEEF",d1out);
    assert (d2out===32'hCAFEF00D)
    else   $error("TC2: d2out=%h,expected CAFEF00D",d2out);
    write_reg(0,32'h12345678);
    rs1=0;rs2=0;#1
    assert (d1out===32'd0)
    else   $error("TC3: d1out=%h,expected 0",d1out);
    assert (d2out===32'd0)
    else   $error("TC3: d2out=%h,expected 0",d2out);
    @(negedge clk) begin
        rd=5; din=32'h11111111; we=0;
    end
    @(posedge clk);
    rs1=5;#1
    assert (d1out===32'hDEADBEEF)
    else   $error("TC4: d1out=%h,expected DEADBEEF",d1out);
    write_reg(7, 32'h77777777);//known old value for TC5
    rs1=7;
    @(negedge clk) begin
        rd=7; din=32'hAAAA5555; we=1;
    end
    #4//1ns before posedge
    assert (d1out===32'h77777777)
    else   $error("TC5: d1out=%h,expected old value 77777777",d1out);
    @(posedge clk);
    #1
    assert (d1out===32'hAAAA5555)
    else   $error("TC5: d1out=%h,expected AAAA5555",d1out);
    @(negedge clk) we=0;

    $display("ALL TESTS DONE");
    #9 $finish;
end


endmodule