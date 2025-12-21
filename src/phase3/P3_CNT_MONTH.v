module CNT_MONTH( RESET, CLK, CNT2, CNT10, ENABLE,
                CARRY_in, CARRY_out);
input RESET, CLK, ENABLE, CARRY_in; 
output reg CARRY_out;
output [3:0] CNT10;
output [3:0] CNT2;
reg [3:0] CNT10;
reg [3:0] CNT2;
reg CARRY;

always @(posedge CLK or posedge RESET) 
begin 
    if (RESET == 1'b1) begin
           CNT10 <= 4'h1;
    end  
    else if (ENABLE == 1'b1 && CARRY_in == 1'b1) begin
        if (CARRY_out == 1'b1)
           CNT10 <= 4'h1; 
        else if (CARRY == 1'b1) 
           CNT10 <= 4'h0; 
        else 
           CNT10 <= CNT10 + 4'h1;
    end 
end 
 
always @(CNT10 or CARRY_in or CNT2) 
begin  
         
    if ((CNT10 == 4'h9 || {CNT2,CNT10} == 8'h12) && CARRY_in == 1'b1) 
        CARRY <= 1'b1; 
    else 
        CARRY <= 1'b0;       
         
end  

always @(CNT2 or CARRY) 
begin 
       
    if (CNT2 == 4'h1 && CARRY == 1'b1) 
        CARRY_out <= 1'b1; 
    else 
        CARRY_out <= 1'b0;  
            
end  
 
always @(posedge CLK or posedge RESET) 
begin 
        if (RESET == 1'b1) 
            begin 
               CNT2 <= 4'h0; 
            end 
        else if (ENABLE == 1'b1 && CARRY == 1'b1)      
        begin 
           if (CARRY_out == 1'b1) 
               CNT2 <= 4'h0; 
           else 
               CNT2 <= CNT2 + 4'h1; 
        end 
            
end 

endmodule