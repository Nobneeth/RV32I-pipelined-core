module top_pipe (
    input clk,
    input reset,
    output [31:0]WriteData,
    output [31:0]DataAdr,
    output MemWrite
);
    wire [31:0]PC, Instr, ReadData;

    riscv_pipe cpu (.clk(clk),.reset(reset),.InstrF(Instr),.ReadDataM(ReadData),
                    .PCF(PC),.ALUResultM(DataAdr),.WriteDataM(WriteData),.MemWriteM(MemWrite));
    imem instr_mem (.a(PC),.rd(Instr),.clk(clk));
    dmem Data_mem (.a(DataAdr),.wd(WriteData),.rd(ReadData),.clk(clk),.we(MemWrite));
endmodule
