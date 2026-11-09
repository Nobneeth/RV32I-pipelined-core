`timescale 1ns/1ps
module alu_tb ();
    logic [31:0]a,b,ALUResult;
    logic [3:0] ALUControl;
    logic lt,ltu, eq;

    alu DUT (.*);
    
    task automatic check(input logic [3:0] ctrl, input logic [31:0] ta, tb_, exp);
    a = ta; b = tb_; ALUControl= ctrl; 
    #1
    assert (ALUResult===exp) 
    else   $error("wrong output %h, expected output %h",ALUResult,exp);
    endtask

    initial begin
        //every operation with ordinary values
        check(4'd0,32'd12,32'd5,32'd17);//add
        check(4'd8,32'd12,32'd5,32'd7);//sub
        check(4'd7,32'd12,32'd5,32'd4);//and
        check(4'd6,32'd12,32'd5,32'd13);//or
        check(4'd4,32'd12,32'd5,32'd9);//xor
        check(4'd2,32'd5,32'd12,32'd1);//slt
        check(4'd3,32'd5,32'd12,32'd1);//sltu
        check(4'd5,32'd240,32'd2,32'd60);//srl
        check(4'd1,32'd3,32'd2,32'd12);//sll
        check(4'd13,32'd240,32'd2,32'd60);//sra

        //slt vs sltu on same inputs, a=-1 b=1
        check(4'd2,32'hFFFFFFFF,32'd1,32'd1);
        check(4'd3,32'hFFFFFFFF,32'd1,32'd0);

        //sra vs srl on a negative number
        check(4'd13,32'h80000000,32'd4,32'hF8000000);
        check(4'd5,32'h80000000,32'd4,32'h08000000);

        //shift amount uses only b[4:0], so 33 shifts by 1
        check(4'd1,32'd1,32'd33,32'd2);

        //shift by 31
        check(4'd1,32'd1,32'd31,32'h80000000);
        check(4'd5,32'h80000000,32'd31,32'd1);
        check(4'd13,32'h80000000,32'd31,32'hFFFFFFFF);

        //shift by 0
        check(4'd1,32'hA5A5A5A5,32'd0,32'hA5A5A5A5);
        check(4'd5,32'hA5A5A5A5,32'd0,32'hA5A5A5A5);
        check(4'd13,32'hA5A5A5A5,32'd0,32'hA5A5A5A5);

        //wrap around
        check(4'd0,32'hFFFFFFFF,32'd1,32'd0);
        check(4'd8,32'd0,32'd1,32'hFFFFFFFF);

        //flags: check task sets a and b, then the flags are read directly
        check(4'd0,32'd7,32'd7,32'd14);//equal pair
        assert (eq===1'b1 && lt===1'b0 && ltu===1'b0)
        else   $error("equal pair: eq=%b lt=%b ltu=%b",eq,lt,ltu);
        check(4'd0,32'hFFFFFFFF,32'd1,32'd0);//signed negative pair
        assert (eq===1'b0 && lt===1'b1 && ltu===1'b0)
        else   $error("signed negative pair: eq=%b lt=%b ltu=%b",eq,lt,ltu);
        check(4'd0,32'd1,32'h80000000,32'h80000001);//unsigned large pair
        assert (eq===1'b0 && lt===1'b0 && ltu===1'b1)
        else   $error("unsigned large pair: eq=%b lt=%b ltu=%b",eq,lt,ltu);

        $display("ALL TESTS DONE");
        $finish;
    end

endmodule