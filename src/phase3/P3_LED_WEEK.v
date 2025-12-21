module LED_WEEK(week_day, LED);
input [3:0] week_day; 
output reg [15:0] LED; 
  
always @(week_day) begin 
    case (week_day)          
        4'b0000: LED <= 16'b0011011_0_0011100_0; 
        4'b0001: LED <= 16'b1110110_0_0011101_0; 
        4'b0010: LED <= 16'b0001111_0_0011100_0; 
        4'b0011: LED <= 16'b0101010_0_1001111_0; 
        4'b0100: LED <= 16'b0001111_0_0010111_0; 
        4'b0101: LED <= 16'b1000111_0_0000101_0; 
        4'b0110: LED <= 16'b0011011_0_1110111_0; 
        default: LED <= 16'b0011011_0_0011100_0;
    endcase 
end 

endmodule