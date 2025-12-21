module DIS_MODE(CLK, RESET, MODE, CURRENT_STATE, main_state_active);
input CLK, RESET, MODE, main_state_active; 
output reg [6:0] CURRENT_STATE;

parameter   L1 = 7'b0000001,
            L2 = 7'b0000010,
            L3 = 7'b0000100,
            L4 = 7'b0001000,
            L5 = 7'b0010000,
            L6 = 7'b0100000,
            L7 = 7'b1000000;

reg [6:0] NEXT_STATE;            

always @(CURRENT_STATE or MODE or main_state_active) begin
case (CURRENT_STATE)
    L1:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L2;
    else
        NEXT_STATE <= L1;
    L2:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L3;
    else
        NEXT_STATE <= L2;
    L3:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L4;
    else
        NEXT_STATE <= L3;
    L4:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L5;
    else
        NEXT_STATE <= L4;
    L5:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L6;
    else
        NEXT_STATE <= L5;
    L6:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L7;
    else
        NEXT_STATE <= L6;
    L7:if(MODE == 1'b1 && main_state_active == 1'b1)
        NEXT_STATE <= L1;
    else
        NEXT_STATE <= L7;
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