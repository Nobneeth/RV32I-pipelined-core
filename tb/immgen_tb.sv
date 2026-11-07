`timescale 1ns/1ps

module immgen_tb();
logic [31:0] instr,ImmExt;
logic [2:0] ImmSrc;

immgen DUT (.*);

task automatic check( input logic [2:0]testsrc,input logic [31:0]testin,testout);
    instr = testin;
    ImmSrc=testsrc;
    #1
    assert (ImmExt === testout) 
    else   $error("erroneous value: %h, Expected value: %h",ImmExt,testout);
endtask //automaticheckinput [31:0]testin,testout

initial begin
    check(3'd0,32'hFFA9A383,32'hFFFFFFFA);//lw t2,-6
    check(3'd0,32'h41D3D313,32'h0000041D);//srai t1,t2,29
    check(3'd1,32'hFE79AD23,32'hFFFFFFFA);//sw t2,-6(s3)
    check(3'd2,32'h01E40863,32'h00000010);//beq s0,t5,L1 (+16)
    check(3'd2,32'hCB9C1263,32'hFFFFF4A4);//bne s8,s9,L1 (-2908)
    check(3'd3,32'h8CDEFAB7,32'h8CDEF000);//lui s5,0x8CDEF
    check(3'd4,32'h7F8A60EF,32'h000A67F8);//jal ra,func1
    $display("ALL TESTS DONE");
    $finish;
end

endmodule
