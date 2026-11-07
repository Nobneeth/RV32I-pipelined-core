`timescale 1ns/1ps

module controller_tb ();
    logic [31:0] instr;
    logic [6:0]  op;
    logic [2:0]  funct3;
    logic        funct7b5, eq, lt, ltu;
    logic [1:0]  PCSrc, ResultSrc;
    logic        MemWrite, ALUSrc, RegWrite;
    logic [2:0]  ImmSrc;
    logic [3:0]  ALUControl;
    int          errors = 0;

    assign op       = instr[6:0];
    assign funct3   = instr[14:12];
    assign funct7b5 = instr[30];

    controller dut (.*);

    // x in an expected value means "don't care" (==? treats x/z on the right as wildcards)
    task automatic check(input string name, input logic [31:0] i, input logic e, l, u,
                         input logic [1:0] pcsrc, rsrc, input logic mw, asrc,
                         input logic [2:0] isrc, input logic rw, input logic [3:0] actl);
        instr = i; eq = e; lt = l; ltu = u;
        #1;
        if (!((PCSrc ==? pcsrc) && (ResultSrc ==? rsrc) && (MemWrite ==? mw) && (ALUSrc ==? asrc) &&
              (ImmSrc ==? isrc) && (RegWrite ==? rw) && (ALUControl ==? actl))) begin
            errors++;
            $error("%s: got PCSrc=%b ResultSrc=%b MemWrite=%b ALUSrc=%b ImmSrc=%b RegWrite=%b ALUControl=%b",
                   name, PCSrc, ResultSrc, MemWrite, ALUSrc, ImmSrc, RegWrite, ALUControl);
        end
    endtask

    initial begin
        //                                     eq lt ltu  PCSrc ResSrc MW  ASrc ImmSrc  RW  ALUControl
        // R-type
        check("add",          32'h01498933, 0, 0, 0, 2'b00, 2'b00, 0, 0, 3'bxxx, 1, 4'b0000);
        check("sub",          32'h407302B3, 0, 0, 0, 2'b00, 2'b00, 0, 0, 3'bxxx, 1, 4'b1000);
        check("sra",          32'h4062D2B3, 0, 0, 0, 2'b00, 2'b00, 0, 0, 3'bxxx, 1, 4'b1101); // sra t0,t0,t1
        check("srl",          32'h0062D2B3, 0, 0, 0, 2'b00, 2'b00, 0, 0, 3'bxxx, 1, 4'b0101); // srl t0,t0,t1
        check("sltu",         32'h0062B2B3, 0, 0, 0, 2'b00, 2'b00, 0, 0, 3'bxxx, 1, 4'b0011); // sltu t0,t0,t1
        check("and",          32'h0062F2B3, 0, 0, 0, 2'b00, 2'b00, 0, 0, 3'bxxx, 1, 4'b0111); // and t0,t0,t1

        // I-type ALU
        check("addi +12",     32'h00C48413, 0, 0, 0, 2'b00, 2'b00, 0, 1, 3'b000, 1, 4'b0000);
        check("addi -1024",   32'hC0028293, 0, 0, 0, 2'b00, 2'b00, 0, 1, 3'b000, 1, 4'b0000); // bit30=1 must NOT give sub
        check("srai",         32'h41D3D313, 0, 0, 0, 2'b00, 2'b00, 0, 1, 3'b000, 1, 4'b1101);
        check("srli",         32'h01D3D313, 0, 0, 0, 2'b00, 2'b00, 0, 1, 3'b000, 1, 4'b0101);
        check("slli",         32'h005B9913, 0, 0, 0, 2'b00, 2'b00, 0, 1, 3'b000, 1, 4'b0001);
        check("xori -1",      32'hFFF2C293, 0, 0, 0, 2'b00, 2'b00, 0, 1, 3'b000, 1, 4'b0100); // bit30=1, funct3=100

        // memory
        check("lw",           32'hFFA9A383, 0, 0, 0, 2'b00, 2'b01, 0, 1, 3'b000, 1, 4'b0000);
        check("sw",           32'hFE79AD23, 0, 0, 0, 2'b00, 2'bxx, 1, 1, 3'b001, 0, 4'b0000);

        // branches: each one taken and not taken
        check("beq  taken",   32'h01E40863, 1, 0, 0, 2'b01, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("beq  not",     32'h01E40863, 0, 0, 0, 2'b00, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bne  taken",   32'hCB9C1263, 0, 0, 0, 2'b01, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bne  not",     32'hCB9C1263, 1, 0, 0, 2'b00, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("blt  taken",   32'h0062C463, 0, 1, 0, 2'b01, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx); // blt t0,t1,+8
        check("blt  not",     32'h0062C463, 0, 0, 1, 2'b00, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bge  taken eq",32'h0062D463, 1, 0, 0, 2'b01, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx); // equal must branch
        check("bge  not",     32'h0062D463, 0, 1, 0, 2'b00, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bltu taken",   32'h0062E463, 0, 0, 1, 2'b01, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bltu not",     32'h0062E463, 0, 1, 0, 2'b00, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bgeu taken",   32'h0062F463, 0, 1, 0, 2'b01, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);
        check("bgeu not",     32'h0062F463, 0, 0, 1, 2'b00, 2'bxx, 0, 0, 3'b010, 0, 4'bxxxx);

        // jumps (flags must not matter)
        check("jal",          32'h7F8A60EF, 0, 0, 0, 2'b01, 2'b10, 0, 1'bx, 3'b100, 1, 4'bxxxx);
        check("jal flags=1",  32'h7F8A60EF, 1, 1, 1, 2'b01, 2'b10, 0, 1'bx, 3'b100, 1, 4'bxxxx);
        check("jalr",         32'h000080E7, 0, 0, 0, 2'b10, 2'b10, 0, 1, 3'b000, 1, 4'b0000);

        // unknown opcode -> behaves as NOP, nothing writes
        check("illegal op",   32'h0000007F, 1, 1, 1, 2'b00, 2'bxx, 0, 1'bx, 3'bxxx, 0, 4'bxxxx);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
