// how data flows through
//control is complete. now how data flows through

module datapath_pipe (
    input clk,
    input reset,
    // Fetch
    input  [31:0]InstrF,          // from imem
    output [31:0]PCF,             // to imem
    input  [1:0]PCSrcE,           // from controller_E
    // Decode: InstrD goes out to controller_D, its control signals come back in
    output [31:0]InstrD,
    input RegWriteD,
    input MemWriteD,
    input ALUSrcD,
    input JalrD,
    input BranchD,
    input JumpD,
    input [2:0]ImmSrcD,
    input [3:0]ALUControlD,
    input [1:0]ResultSrcD,
    // Execute: signals for controller_E
    output eqE,
    output ltE,
    output ltuE,
    output [2:0]funct3E,
    output JumpE,
    output BranchE,
    output JalrE,
    // Memory: dmem interface
    output [31:0]ALUResultM,
    output [31:0]WriteDataM,
    output MemWriteM,
    input  [31:0]ReadDataM
);
// hazard signals, driven by hazard_unit
wire StallF, StallD, FlushD, FlushE;
wire [1:0]ForwardAE, ForwardBE;

// Fetch
reg  [31:0]PCNextF;
wire [31:0]PCPlus4F = PCF + 32'd4;
// Decode
wire [31:0]PCD, PCPlus4D;
wire [31:0]RD1D, RD2D, ImmExtD;
// Execute
wire RegWriteE, MemWriteE, ALUSrcE;
wire [1:0]ResultSrcE;
wire [3:0]ALUControlE;
wire [31:0]RD1E, RD2E, ImmExtE, PCE, PCPlus4E;
wire [4:0]Rs1E, Rs2E, RdE;
wire [31:0]PCTargetE, ALUResultE;
wire [31:0]SrcBE, WriteDataE;
reg  [31:0]SrcAE;
// Memory (ALUResultM, WriteDataM, MemWriteM, ReadDataM are ports)
wire RegWriteM;
wire [1:0]ResultSrcM;
wire [31:0]PCPlus4M;
wire [4:0]RdM;
// Writeback
wire RegWriteW;
wire [1:0]ResultSrcW;
wire [31:0]ALUResultW, ReadDataW, PCPlus4W;
wire [4:0]RdW;
reg [31:0]ResultW;

    always @(*) begin
        case (PCSrcE)
            2'd1:PCNextF=PCTargetE;
            2'd2:PCNextF= {ALUResultE[31:1],1'b0} ;
            default:PCNextF=PCPlus4F;
        endcase
    end

regfile Reg_File (.clk(clk),.rs1(InstrD[19:15]),.rs2(InstrD[24:20]),.d1out(RD1D),.d2out(RD2D),
                  .we(RegWriteW),.rd(RdW),.din(ResultW));
immgen Imm_gen (.ImmSrc(ImmSrcD),.instr(InstrD),.ImmExt(ImmExtD));
//PC with enable
flopenr #(32) pc_reg(.clk(clk),.reset(reset),.en(~StallF),.A(PCNextF),.B(PCF));
//F->D stage. both stall and flushing hence enrc.
// all three need stalling.. flushing only instr
flopenrc #(32) instrFD_reg(.clk(clk),.clear(FlushD),.reset(reset),.en(~StallD),.A(InstrF),.B(InstrD));
flopenr #(32) pcFD_reg(.clk(clk),.reset(reset),.en(~StallD),.A(PCF),.B(PCD));
flopenr #(32) pcplus4FD_reg(.clk(clk),.reset(reset),.en(~StallD),.A(PCPlus4F),.B(PCPlus4D));

//D->E. these only need clearing(flushing). that too not all only control signals enough.
//regwrite memwrite jump branch and Jalr enough.
floprc #(1) RegWrite_reg(.clk(clk),.reset(reset),.clear(FlushE),.A(RegWriteD),.B(RegWriteE));
floprc #(1) MemWrite_reg(.clk(clk),.reset(reset),.clear(FlushE),.A(MemWriteD),.B(MemWriteE));
floprc #(1) Jump_reg(.clk(clk),.reset(reset),.clear(FlushE),.A(JumpD),.B(JumpE));
floprc #(1) Branch_reg(.clk(clk),.reset(reset),.clear(FlushE),.A(BranchD),.B(BranchE));
floprc #(1) Jalr_reg(.clk(clk),.reset(reset),.clear(FlushE),.A(JalrD),.B(JalrE));
floprc #(2) ResultSrc_reg(.clk(clk),.reset(reset),.clear(FlushE),.A(ResultSrcD),.B(ResultSrcE));
//onlyreset
flopr #(4)  ALUControl_reg (.clk(clk),.reset(reset),.A(ALUControlD),  .B(ALUControlE));
flopr #(1)  ALUSrc_reg     (.clk(clk),.reset(reset),.A(ALUSrcD),      .B(ALUSrcE));
flopr #(3)  funct3_reg     (.clk(clk),.reset(reset),.A(InstrD[14:12]),.B(funct3E));
flopr #(32) RD1_reg        (.clk(clk),.reset(reset),.A(RD1D),         .B(RD1E));
flopr #(32) RD2_reg        (.clk(clk),.reset(reset),.A(RD2D),         .B(RD2E));
flopr #(32) ImmExt_reg     (.clk(clk),.reset(reset),.A(ImmExtD),      .B(ImmExtE));
flopr #(32) PCE_reg        (.clk(clk),.reset(reset),.A(PCD),          .B(PCE));
flopr #(32) PCPlus4E_reg   (.clk(clk),.reset(reset),.A(PCPlus4D),     .B(PCPlus4E));
flopr #(5)  Rs1E_reg       (.clk(clk),.reset(reset),.A(InstrD[19:15]),.B(Rs1E));
flopr #(5)  Rs2E_reg       (.clk(clk),.reset(reset),.A(InstrD[24:20]),.B(Rs2E));
flopr #(5)  RdE_reg        (.clk(clk),.reset(reset),.A(InstrD[11:7]), .B(RdE));
//added addresses of datas the regfile inputs and outputs 


//rest all are FLOPR
//E-M operations first.
//forwarding muxes: 00 regfile, 01 from W, 10 from M
always @(*) begin
    case (ForwardAE)
        2'b10:   SrcAE = ALUResultM;
        2'b01:   SrcAE = ResultW;
        default: SrcAE = RD1E;
    endcase
end
assign WriteDataE = (ForwardBE==2'b10) ? ALUResultM :
                    (ForwardBE==2'b01) ? ResultW : RD2E;
assign SrcBE=ALUSrcE?ImmExtE:WriteDataE;
assign PCTargetE = PCE+ImmExtE;
always @(*) begin
    case (ResultSrcW)
            2'd1: ResultW=ReadDataW;
            2'd2: ResultW=PCPlus4W;
            default: ResultW = ALUResultW;
        endcase
end
alu ALU (.a(SrcAE),.b(SrcBE),.ALUControl(ALUControlE),.eq(eqE),.lt(ltE),.ltu(ltuE),.ALUResult(ALUResultE));

//E-M regs
flopr #(1)  RegWriteEM_reg  (.clk(clk),.reset(reset),.A(RegWriteE),  .B(RegWriteM));
flopr #(2)  ResultSrcEM_reg (.clk(clk),.reset(reset),.A(ResultSrcE), .B(ResultSrcM));
flopr #(1)  MemWriteEM_reg  (.clk(clk),.reset(reset),.A(MemWriteE),  .B(MemWriteM));
flopr #(32) ALUResultEM_reg (.clk(clk),.reset(reset),.A(ALUResultE), .B(ALUResultM));
flopr #(32) WriteDataEM_reg (.clk(clk),.reset(reset),.A(WriteDataE), .B(WriteDataM));
flopr #(32) PCPlus4EM_reg   (.clk(clk),.reset(reset),.A(PCPlus4E),   .B(PCPlus4M));
flopr #(5)  RdEM_reg        (.clk(clk),.reset(reset),.A(RdE),        .B(RdM));

//M stage: dmem sits in top. ALUResultM, WriteDataM, MemWriteM go out, ReadDataM comes in.

//M-W regs
flopr #(1)  RegWriteMW_reg  (.clk(clk),.reset(reset),.A(RegWriteM),  .B(RegWriteW));
flopr #(2)  ResultSrcMW_reg (.clk(clk),.reset(reset),.A(ResultSrcM), .B(ResultSrcW));
flopr #(32) ALUResultMW_reg (.clk(clk),.reset(reset),.A(ALUResultM), .B(ALUResultW));
flopr #(32) ReadDataMW_reg  (.clk(clk),.reset(reset),.A(ReadDataM),  .B(ReadDataW));
flopr #(32) PCPlus4MW_reg   (.clk(clk),.reset(reset),.A(PCPlus4M),   .B(PCPlus4W));
flopr #(5)  RdMW_reg        (.clk(clk),.reset(reset),.A(RdM),        .B(RdW));

//hazard unit added
hazard_unit HU (.Rs1E(Rs1E),.Rs2E(Rs2E),.RdM(RdM),.RdW(RdW),.RegWriteM(RegWriteM),.RegWriteW(RegWriteW),
                .Rs1D(InstrD[19:15]),.Rs2D(InstrD[24:20]),.RdE(RdE),.ResultSrcE(ResultSrcE),.PCSrcE(PCSrcE),
                .ForwardAE(ForwardAE),.ForwardBE(ForwardBE),.StallF(StallF),.StallD(StallD),.FlushD(FlushD),.FlushE(FlushE));

endmodule