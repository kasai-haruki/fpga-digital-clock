module MAIN_MODE(CLK, RESET, MODE, CURRENT_STATE);
input CLK, RESET, MODE;
output reg [4:0] CURRENT_STATE;

parameter   L1 = 5'b00001,
            L2 = 5'b00010,
            L3 = 5'b00100,
            L4 = 5'b01000,
            L5 = 5'b10000;

reg [4:0] NEXT_STATE;            

always @(CURRENT_STATE or MODE) begin
case (CURRENT_STATE)
    L1:if(MODE == 1'b1)
        NEXT_STATE <= L2;
    else
        NEXT_STATE <= L1;
    L2:if(MODE == 1'b1)
        NEXT_STATE <= L3;
    else
        NEXT_STATE <= L2;
    L3:if(MODE == 1'b1)
        NEXT_STATE <= L4;
    else
        NEXT_STATE <= L3;
    L4:if(MODE == 1'b1)
        NEXT_STATE <= L5;
    else
        NEXT_STATE <= L4;
    L5:if(MODE == 1'b1)
        NEXT_STATE <= L1;
    else
        NEXT_STATE <= L5;
    default:NEXT_STATE <= L1;    
endcase             
end       
always@(posedge RESET or posedge CLK) begin
if(RESET == 1'b1)
    CURRENT_STATE <= L1;
else
    CURRENT_STATE <= NEXT_STATE; 
end 

endmodule