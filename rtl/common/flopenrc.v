module flopenrc #(
   parameter  width = 32
) (
    input clk,
    input clear,
    input en,
    input reset,
    input [width-1:0]A,
    output reg [width-1:0]B
);
    
    always @(posedge clk or posedge reset) begin
        if(reset) B <= 0;
        else if(clear)B<=0;
        else if(!en) B<=B;
        else B<=A;
    end
    

endmodule