module DECODER7(COUNT, LED, TOP_CURRENT_STATE, DIS_CURRENT_STATE, SA); 
input TOP_CURRENT_STATE; 
input [1:0] DIS_CURRENT_STATE;
input [3:0] COUNT, SA; 
output reg [7:0] LED; 
  
always @(COUNT or TOP_CURRENT_STATE or DIS_CURRENT_STATE or SA) begin 
    if(TOP_CURRENT_STATE == 1'b1 && DIS_CURRENT_STATE[0] == 1'b1 && SA[3:2] == 2'b00) begin
        case(SA[1:0])
            2'b01:  case(COUNT)
                        4'b0000: LED <= 8'b0011100_0; 
                        4'b0001: LED <= 8'b0011101_0; 
                        4'b0010: LED <= 8'b0011100_0; 
                        4'b0011: LED <= 8'b1001111_0; 
                        4'b0100: LED <= 8'b0010111_0; 
                        4'b0101: LED <= 8'b0000101_0; 
                        4'b0110: LED <= 8'b1110111_0; 
                        default: LED <= 8'b0011100_0;
                    endcase
            2'b10:  case(COUNT)               
                        4'b0000: LED <= 8'b0011011_0; 
                        4'b0001: LED <= 8'b1110110_0; 
                        4'b0010: LED <= 8'b0001111_0; 
                        4'b0011: LED <= 8'b0101010_0; 
                        4'b0100: LED <= 8'b0001111_0; 
                        4'b0101: LED <= 8'b1000111_0; 
                        4'b0110: LED <= 8'b0011011_0; 
                        default: LED <= 8'b0011011_0;
                    endcase
            default: LED <= 8'b0000000_0;
        endcase                       
    end else if(TOP_CURRENT_STATE == 1'b1 && DIS_CURRENT_STATE[1] == 1'b1 && SA[1:0] == 2'b00) begin
        case(SA[3:2])
            2'b01:  case(COUNT)
                        4'b0000: LED <= 8'b0011100_0; 
                        4'b0001: LED <= 8'b0011101_0; 
                        4'b0010: LED <= 8'b0011100_0; 
                        4'b0011: LED <= 8'b1001111_0; 
                        4'b0100: LED <= 8'b0010111_0; 
                        4'b0101: LED <= 8'b0000101_0; 
                        4'b0110: LED <= 8'b1110111_0; 
                        default: LED <= 8'b0011100_0;
                    endcase
            2'b10:  case(COUNT)               
                        4'b0000: LED <= 8'b0011011_0; 
                        4'b0001: LED <= 8'b1110110_0; 
                        4'b0010: LED <= 8'b0001111_0; 
                        4'b0011: LED <= 8'b0101010_0; 
                        4'b0100: LED <= 8'b0001111_0; 
                        4'b0101: LED <= 8'b1000111_0; 
                        4'b0110: LED <= 8'b0011011_0; 
                        default: LED <= 8'b0011011_0;
                    endcase 
            default: LED <= 8'b0000000_0;
        endcase     
    end else begin                
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
end 
endmodule
