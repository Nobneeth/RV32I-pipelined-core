`timescale 1ns/1ps

// Pipelined CPU testbench. Runs each program for a fixed number of cycles, then compares
// x1..x31 and all data-memory words against the reference results from programs/rvasm.py.
// Expects: module top_pipe, instance names cpu (riscv_pipe) -> dp (datapath_pipe) -> Reg_File.
module pipe_tb ();
    logic        clk = 0, reset;
    logic [31:0] WriteData, DataAdr;
    logic        MemWrite;
    logic [31:0] expected [0:95];
    int          errors, total_errors = 0;
    localparam   CYCLES = 3000;

    top_pipe dut (.*);

    always #5 clk = ~clk;

    task automatic run(input string prog, input string exp_file);
        errors = 0;
        reset = 1;
        for (int i = 0; i < 32; i++)                       dut.cpu.dp.Reg_File.r[i] = 0;
        for (int i = 0; i < $size(dut.Data_mem.RAM); i++)  dut.Data_mem.RAM[i]      = 0;
        for (int i = 0; i < $size(dut.instr_mem.RAM); i++) dut.instr_mem.RAM[i]     = 0;
        $readmemh(prog, dut.instr_mem.RAM);
        $readmemh(exp_file, expected);
        repeat (2) @(negedge clk);
        reset = 0;
        repeat (CYCLES) @(negedge clk);

        for (int i = 1; i < 32; i++)
            if (dut.cpu.dp.Reg_File.r[i] !== expected[i]) begin
                errors++;
                $error("%s: x%0d = %h, expected %h", prog, i, dut.cpu.dp.Reg_File.r[i], expected[i]);
            end
        for (int i = 0; i < 64; i++)
            if (dut.Data_mem.RAM[i] !== expected[32+i]) begin
                errors++;
                $error("%s: mem[%0d] (addr %0d) = %h, expected %h", prog, i, 4*i, dut.Data_mem.RAM[i], expected[32+i]);
            end

        if (errors == 0) $display("PASS  %s", prog);
        else             $display("FAIL  %s  %0d mismatches", prog, errors);
        total_errors += errors;
    endtask

    initial begin
        // padding moves the jal return address, so the book's "25 at address 100" check does not apply here;
        // the full register + memory comparison covers it
        run("riscvtest_pad2.txt", "riscvtest_pad2_expected.txt");
        run("fulltest_pad2.txt",  "fulltest_pad2_expected.txt");

        if (total_errors == 0) $display("ALL TESTS PASSED");
        else                   $display("%0d MISMATCH(ES) IN TOTAL", total_errors);
        $finish;
    end
endmodule
