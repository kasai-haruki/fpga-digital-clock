module DECODER7(COUNT, LED); 
input [3:0] COUNT; 
output reg [7:0] LED; 
  
always @(COUNT) begin 
    case (COUNT)          // ABCDEFG Dp
        4'b0000: LED <= ~8'b0000001_1; 
        4'b0001: LED <= ~8'b1001111_1; 
        4'b0010: LED <= ~8'b0010010_1; 
        4'b0011: LED <= ~8'b0000110_1; 
        4'b0100: LED <= ~8'b1001100_1; 
        4'b0101: LED <= ~8'b0100100_1; 
        4'b0110: LED <= ~8'b0100000_1; 
        4'b0111: LED <= ~8'b0001101_1; 
        4'b1000: LED <= ~8'b0000000_1; 
        4'b1001: LED <= ~8'b0000100_1; 
        default: LED <= ~8'b0110000_1; 
    endcase 
end 
endmodule
