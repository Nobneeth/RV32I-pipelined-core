`timescale 1ns/1ps

module dmem_tb ();
    logic        clk = 0, we;
    logic [31:0] a, wd, rd;
    int          errors = 0;

    dmem dut (.*);

    always #5 clk = ~clk;

    // inputs change on the falling edge, so the rising edge samples stable values
    task automatic store(input logic [31:0] addr, data);
        @(negedge clk) begin we = 1; a = addr; wd = data; end
        @(negedge clk) we = 0;
    endtask

    task automatic expect_rd(input string name, input logic [31:0] addr, exp);
        a = addr; #1;
        if (rd !== exp) begin
            errors++;
            $error("%s: addr=%h rd=%h expected %h", name, addr, rd, exp);
        end
    endtask

    initial begin
        we = 0; a = 0; wd = 0;

        store(32'h00, 32'hDEADBEEF);
        store(32'h04, 32'hCAFEF00D);
        store(32'hFC, 32'h12345678);                                    // last word (63)
        expect_rd("word 0",           32'h00, 32'hDEADBEEF);
        expect_rd("word 1",           32'h04, 32'hCAFEF00D);
        expect_rd("last word",        32'hFC, 32'h12345678);

        // read is combinational: new address -> new data with no clock edge
        a = 32'h00; #1; a = 32'h04; #1;
        if (rd !== 32'hCAFEF00D) begin errors++; $error("read not combinational: rd=%h", rd); end

        // we=0 must not write
        @(negedge clk) begin we = 0; a = 32'h00; wd = 32'h11111111; end
        @(negedge clk);
        expect_rd("we=0 no write",    32'h00, 32'hDEADBEEF);

        // write happens at the rising edge, not before
        @(negedge clk) begin we = 1; a = 32'h08; wd = 32'hAAAA5555; end
        #4; if (rd === 32'hAAAA5555) begin errors++; $error("written before the clock edge"); end
        @(posedge clk); #1;
        if (rd !== 32'hAAAA5555) begin errors++; $error("not written at the clock edge: rd=%h", rd); end
        @(negedge clk) we = 0;

        // overwrite keeps neighbours intact
        store(32'h04, 32'h0BADF00D);
        expect_rd("overwrite",        32'h04, 32'h0BADF00D);
        expect_rd("neighbour below",  32'h00, 32'hDEADBEEF);
        expect_rd("neighbour above",  32'h08, 32'hAAAA5555);

        // word indexing ignores a[1:0] (all our accesses are aligned)
        expect_rd("a[1:0] ignored",   32'h06, 32'h0BADF00D);

        if (errors == 0) $display("ALL TESTS PASSED");
        else             $display("%0d TEST(S) FAILED", errors);
        $finish;
    end
endmodule
