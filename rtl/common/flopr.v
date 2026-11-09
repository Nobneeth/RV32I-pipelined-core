module flopr #(
   parameter  width = 32
) (
    input clk,
    input reset,
    input [width-1:0]A,
    output reg [width-1:0]B
);
    
    always @(posedge clk or posedge reset ) begin
        if(reset) B <= 0;
        else B<=A;
    end
endmodule