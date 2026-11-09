// initially i thought we dont need outputs, only clk and reset.
// but synthesis then removed the whole design, because it only keeps logic that drives an output.
// the memory signals need the whole datapath and control path, so they are brought out.


module top (
    input clk,
    input reset,
    output [31:0]WriteData,
    output [31:0]DataAdr,
    output MemWrite
);
    wire [31:0]PC, Instr, ReadData;

    riscv_single cpu (.clk(clk),.reset(reset),.Instr(Instr),.ReadData(ReadData),.PC(PC),.MemWrite(MemWrite),.ALUResult(DataAdr),.WriteData(WriteData));
    imem instr_mem (.a(PC),.rd(Instr),.clk(clk));
    dmem Data_mem (.a(DataAdr),.wd(WriteData),.rd(ReadData),.clk(clk),.we(MemWrite));

endmodule