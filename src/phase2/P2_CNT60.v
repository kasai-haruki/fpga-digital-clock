module CNT60(RESET, CLK, DEC, CNT6, CNT10, ENABLE, CARRY_in, CARRY_out);
input RESET, CLK, DEC, ENABLE, CARRY_in;
output reg CARRY_out;
output [3:0] CNT10;
output [3:0] CNT6;
reg [3:0] CNT10;
reg [3:0] CNT6;
reg CARRY;

always @(posedge CLK or posedge RESET) 
begin 
    if (RESET == 1'b1) 
             begin 
                CNT10 <= 4'h0; 
             end 
         else if (ENABLE == 1'b1 && CARRY_in == 1'b1) 
//      else if (DEC == 1'b1) 
 
             if (DEC == 1'b0) 
                 begin 
//                  if (CNT10 == 4'h9) 
                    if (CARRY == 1'b1) 
                        CNT10 <= 4'h0; 
                    else 
                        CNT10 <= CNT10 + 4'h1; 
                 end 
             else 
                 begin 
//                  if (CNT10 == 4'h0) 
                    if (CARRY == 1'b1) 
                        CNT10 <= 4'h9; 
                    else 
                        CNT10 <= CNT10 - 4'h1; 
                 end 
end 
 
always @(CNT10 or DEC or CARRY_in) 
begin 
         if (DEC == 1'b0) 
         begin
             if (CNT10 == 4'h9 && CARRY_in == 1'b1) 
                 CARRY <= 1'b1; 
             else 
                 CARRY <= 1'b0;
         end        
         else 
         begin
             if (CNT10 == 4'h0 && CARRY_in == 1'b1) 
                 CARRY <= 1'b1; 
             else 
                 CARRY <= 1'b0; 
         end    
end  

always @(CNT6 or DEC or CARRY) 
begin 
         if (DEC == 1'b0) 
         begin
             if (CNT6 == 4'h5 && CARRY == 1'b1) 
                 CARRY_out <= 1'b1; 
             else 
                 CARRY_out <= 1'b0;  
         end        
         else 
         begin
             if (CNT6 == 4'h0 && CARRY == 1'b1) 
                 CARRY_out<= 1'b1; 
             else 
                 CARRY_out <= 1'b0; 
         end    
end  
 
always @(posedge CLK or posedge RESET) 
begin 
         if (RESET == 1'b1) 
             begin 
                CNT6 <= 3'b000; 
             end 
         else if (ENABLE == 1'b1 && CARRY == 1'b1) 
//      else if (DEC == 1'b1) 
             if (DEC == 1'b0) 
                 begin 
                    if (CNT6 == 3'b101) 
                        CNT6 <= 3'b000; 
                    else 
                        CNT6 <= CNT6 + 3'b001; 
                 end 
             else 
                 begin 
                    if (CNT6 == 3'b000) 
                        CNT6 <= 3'b101; 
                    else 
                        CNT6 <= CNT6 - 3'b001; 
                 end 
end 

endmodule