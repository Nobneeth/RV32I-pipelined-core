module immgen (
    input [31:0] instr,
    input [2:0] Immsrc,
    output reg [31:0] ImmExt
);
    always @(*) begin
        case (Immsrc)
            3'd0: ImmExt ={{20{instr[31]}}, instr[31:20]};  //I
            3'd1: ImmExt ={{20{instr[31]}}, instr[31:25],instr[11:7]};  //S
            3'd2: ImmExt = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};  //B
            3'd3: ImmExt = {instr[31:12],12'd0};  //U
            3'd4: ImmExt = {{12{instr[31]}},instr[19:12],instr[20],instr[30:21],1'b0}; //J
            default: ImmExt ={{20{instr[31]}}, instr[31:20]};
        endcase
    end
endmodule