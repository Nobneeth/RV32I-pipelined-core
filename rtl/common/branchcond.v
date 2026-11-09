module branchcond (
    //input [6:0]op,
    input [2:0]funct3,
    input eq,
    input lt,
    input ltu,
    output  reg BranchTaken
);
    always @(*) begin
           case (funct3)
                3'd0: BranchTaken = eq;
                3'd1: BranchTaken = !eq;
                3'd4: BranchTaken = lt;
                3'd5: BranchTaken = !lt;
                3'd6: BranchTaken = ltu;
                3'd7: BranchTaken = !ltu;
                default: BranchTaken = 0; 
            endcase
        end
        
endmodule