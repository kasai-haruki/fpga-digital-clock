module CNT_DAY( RESET, CLK, CNT4, CNT10, ENABLE,
                CARRY_in, CARRY_out, month, is_leap);
input RESET, CLK, ENABLE, CARRY_in, is_leap; 
input [7:0] month;

output reg CARRY_out;
output [3:0] CNT10;
output [3:0] CNT4;
reg [3:0] CNT10;
reg [3:0] CNT4;
reg CARRY;


always @(posedge CLK or posedge RESET) 
begin 
    if (RESET == 1'b1) begin
           CNT10 <= 4'h1;
    end  
    else if (ENABLE == 1'b1 && CARRY_in == 1'b1) begin
        if (CARRY_out == 1'b1)
           CNT10 <= 4'h1; 
        else if(CARRY == 1'b1)
            CNT10 <= 4'h0; 
        else begin
           CNT10 <= CNT10 + 4'h1;
        end
    end 
end 
 
always @(CNT10 or CARRY_in or CNT4 or month or is_leap) 
begin  
         
    if ((((month == 8'h04 || month == 8'h06 || month == 8'h09 || month == 8'h11) && ({CNT4, CNT10} == 8'h30)) || 
        ((month == 8'h02) && ((is_leap == 1'b0) && ({CNT4, CNT10} == 8'h28))) ||
        (({CNT4, CNT10} == 8'h31) || (CNT10 == 4'h9))) && CARRY_in == 1'b1)
        CARRY <= 1'b1; 
    else 
        CARRY <= 1'b0;       
         
end  

always @(CNT4 or CARRY or CNT10 or is_leap) 
begin 
       
    if (CARRY == 1'b1 && ((CNT10 != 4'h9) || (((month == 8'h02) && (is_leap == 1'b1) && ({CNT4, CNT10} == 8'h29)))))
        CARRY_out <= 1'b1; 
    else 
        CARRY_out <= 1'b0;  
            
end  
 
always @(posedge CLK or posedge RESET) 
begin 
if (RESET == 1'b1) 
    begin 
       CNT4 <= 4'h0; 
    end 
else if (ENABLE == 1'b1 && CARRY == 1'b1)
    if(CARRY_out == 1'b1)      
       CNT4 <= 4'h0; 
   else 
       CNT4 <= CNT4 + 4'h1; 
end 
            

endmodule