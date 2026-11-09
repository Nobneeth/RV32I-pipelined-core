module hazard_unit (
    // forwarding: sources of the instruction in Execute vs destinations in M and W
    input [4:0]Rs1E,
    input [4:0]Rs2E,
    input [4:0]RdM,
    input [4:0]RdW,
    input RegWriteM,
    input RegWriteW,
    // load-use: sources of the instruction in Decode vs a load in Execute
    input [4:0]Rs1D,
    input [4:0]Rs2D,
    input [4:0]RdE,
    input [1:0]ResultSrcE,
    // control hazard: branch/jump taken in Execute
    input [1:0]PCSrcE,
    output reg [1:0]ForwardAE,
    output reg [1:0]ForwardBE,
    output StallF,
    output StallD,
    output FlushD,
    output FlushE
);

// forwarding. 10: from M (ALUResultM), 01: from W (ResultW), 00: register file. M wins (most recent).
always @(*) begin
    if ((Rs1E == RdM) && RegWriteM && (Rs1E != 0)) begin
        ForwardAE=2'b10;
    end else if((Rs1E == RdW) && RegWriteW && (Rs1E != 0)) begin
        ForwardAE=2'b01;
    end
    else ForwardAE = 2'b00;

    if((Rs2E == RdM) && RegWriteM && (Rs2E != 0))ForwardBE=2'b10;
    else if((Rs2E == RdW) && RegWriteW && (Rs2E != 0))ForwardBE=2'b01;
    else ForwardBE=2'b00;
end

// load-use: lw in Execute (ResultSrcE = 01) and the instruction in Decode reads its rd.
// hold F and D one cycle, send a bubble into E; the value is then forwarded from W.
wire lwStall = (ResultSrcE == 2'b01) && ((Rs1D == RdE) || (Rs2D == RdE));

// control hazard: a taken branch/jump in E means the 2 instructions fetched after it are wrong-path.
wire Redirect = (PCSrcE != 2'b00);

assign StallF = lwStall;
assign StallD = lwStall;
assign FlushD = Redirect;
assign FlushE = lwStall | Redirect;

endmodule
