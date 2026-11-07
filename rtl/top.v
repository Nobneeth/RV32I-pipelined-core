// initially i though we dont need output because we just need connecting them and only clk and reset are needed.
//but realised that doing that caused wiping out whole design because synthesis will only make blocks that are required to find the output
//and that would require picking critical signals whtat need all the blocks in the design.
//they would be the memory based signals beacuse whole datapath flow and control path flow is needed


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