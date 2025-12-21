module display_switch(  CLK, btn_switch, C1_in, C2_in, C3_in, C4_in,
                        C5_in, C6_in, C7_in, C8_in,
                        C1_out, C2_out, C3_out, C4_out); 
input btn_switch, CLK; 
input [3:0] C1_in, C2_in, C3_in, C4_in, C5_in, C6_in, C7_in, C8_in;  
output reg [3:0] C1_out, C2_out, C3_out, C4_out;  

always @(posedge CLK)
begin
    if (btn_switch == 1'b0) 
    begin
        C1_out <= C1_in;
        C2_out <= C2_in;
        C3_out <= C3_in;
        C4_out <= C4_in;
    end
    else 
    begin
        C1_out <= C5_in;
        C2_out <= C6_in;
        C3_out <= C7_in;
        C4_out <= C8_in;
    end
end
 
endmodule