`timescale 1ns/1ps

// Runs each program on the full single-cycle CPU, then compares all registers
// and all data-memory words against the reference results from programs/rvasm.py.
module top_tb ();
    logic        clk = 0, reset;
    logic [31:0] WriteData, DataAdr;
    logic        MemWrite;
    logic [31:0] expected [0:95];   // x0..x31, then dmem words 0..63
    int          errors, total_errors = 0;

    top dut (.*);

    always #5 clk = ~clk;

    // Book criterion (Section 7.6.3): riscvtest stores 25 to address 100
    logic book_ok;
    always @(negedge clk)
        if (MemWrite && DataAdr === 32'd100 && WriteData === 32'd25) book_ok = 1;

    task automatic run(input string prog, input string exp_file);
        int cycles;
        logic [31:0] last_pc;
        errors = 0; book_ok = 0;
        reset = 1;
        // testbench-only: start from a clean state so untouched registers compare as 0, not X
        for (int i = 0; i < 32; i++)                       dut.cpu.dp.Reg_File.r[i] = 0;
        for (int i = 0; i < $size(dut.Data_mem.RAM); i++)  dut.Data_mem.RAM[i]      = 0;
        for (int i = 0; i < $size(dut.instr_mem.RAM); i++) dut.instr_mem.RAM[i]     = 0;
        $readmemh(prog, dut.instr_mem.RAM);
        $readmemh(exp_file, expected);
        repeat (2) @(negedge clk);
        reset = 0;

        // run until the program reaches its 'done: beq x0,x0,done' self-loop
        last_pc = 32'hFFFFFFFF;
        cycles  = 0;
        while (cycles < 2000 && dut.PC !== last_pc) begin
            last_pc = dut.PC;
            @(negedge clk);
            cycles++;
        end
        if (cycles == 2000) begin errors++; $error("%s: timeout, PC=%h", prog, dut.PC); end

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

        if (errors == 0) $display("PASS  %-14s (%0d cycles)", prog, cycles);
        else             $display("FAIL  %-14s %0d mismatches", prog, errors);
        total_errors += errors;
    endtask

    initial begin
        run("riscvtest.txt", "riscvtest_expected.txt");
        if (!book_ok) begin total_errors++; $error("riscvtest: never stored 25 to address 100"); end
        run("fulltest.txt",  "fulltest_expected.txt");

        if (total_errors == 0) $display("ALL TESTS PASSED");
        else                   $display("%0d MISMATCH(ES) IN TOTAL", total_errors);
        $finish;
    end
endmodule
