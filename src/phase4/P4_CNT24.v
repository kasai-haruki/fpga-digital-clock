module CNT24(RESET, CLK, CNT3, CNT10, ENABLE, CARRY_in, CARRY_out, SET_CURRENT_STATE, INC_MODE);
input RESET, CLK, ENABLE, CARRY_in, INC_MODE;
input [1:0] SET_CURRENT_STATE;
output reg CARRY_out;
output [3:0] CNT10;
output [3:0] CNT3;
reg [3:0] CNT10;
reg [3:0] CNT3;
reg CARRY;
wire [3:0] max10;

always @(posedge CLK or posedge RESET) 
begin 
    if (RESET == 1'b1) 
             begin 
                CNT10 <= 4'h0; 
             end 
         else if (((ENABLE == 1'b1 && CARRY_in == 1'b1) && SET_CURRENT_STATE[0] == 1'b1) ||
                    (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1)) begin
//      else if (DEC == 1'b1) 
 
//             if (DEC == 1'b0) 
             begin
//                  if (CNT10 == 4'h9) 
                    if (CARRY == 1'b1) 
                        CNT10 <= 4'h0; 
                    else 
                        CNT10 <= CNT10 + 4'h1; 
             end           
//             else begin
//                  if (CNT10 == 4'h0) 
//                    if(CARRY == 1'b1)
//                        CNT10 <= (CNT3 == 4'h0) ? 4'h3 : 4'h9; 
//                    else
//                        CNT10 <= CNT10 - 4'h1;   
//                end  
         end  
end 
 
always @(CNT10 or CARRY_in or SET_CURRENT_STATE or INC_MODE) 
begin 
//         if (DEC == 1'b0) 
         begin
             if ((CNT10 == 4'h9 || {CNT3,CNT10} == 8'h23) && 
                    (CARRY_in == 1'b1 || (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1))) 
                 CARRY <= 1'b1; 
             else 
                 CARRY <= 1'b0;
         end        
//         else 
//         begin
//             if (CNT10 == 4'h0 && CARRY_in == 1'b1) 
//                 CARRY <= 1'b1; 
//             else 
//                 CARRY <= 1'b0; 
//         end    
end  

always @(CNT3 or CARRY) 
begin 
//         if (DEC == 1'b0) 
         begin
             if (CNT3 == 4'h2 && CARRY == 1'b1) 
                 CARRY_out <= 1'b1; 
             else 
                 CARRY_out <= 1'b0;  
         end        
//         else 
//         begin
//             if (CNT3 == 4'h0 && CARRY == 1'b1) 
//                 CARRY_out<= 1'b1; 
//             else 
//                 CARRY_out <= 1'b0; 
//         end    
end  
 
always @(posedge CLK or posedge RESET) 
begin 
         if (RESET == 1'b1) 
             begin 
                CNT3 <= 2'b00; 
             end 
         else if ((CARRY == 1'b1) && ((ENABLE == 1'b1 && SET_CURRENT_STATE[0] == 1'b1) ||
                    (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1)))    
         begin
//      else if (DEC == 1'b1) 
//             if (DEC == 1'b0) 
                 begin 
                    if (CNT3 == 2'h2) 
                        CNT3 <= 2'h0; 
                    else 
                        CNT3 <= CNT3 + 2'h1; 
                 end 
//             else 
//                 begin 
//                    if (CNT3 == 2'h0) 
//                        CNT3 <= 2'h2; 
//                    else 
//                        CNT3 <= CNT3 - 2'h1; 
//                 end 
         end
end 

endmodule