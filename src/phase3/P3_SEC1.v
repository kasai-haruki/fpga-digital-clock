module SEC1(CLK, RESET, ENABLE, ENABLE_kHz);
input CLK, RESET;
output ENABLE, ENABLE_kHz;
reg [26:0] tmp_count; 
parameter SEC1_MAX = 125000000; // 125MHz 
 
always @(posedge CLK) 
begin 
          if (RESET == 1'b1) 
                  tmp_count <= 27'h000000; 
          else if (ENABLE == 1'b1) 
                  tmp_count <= 27'h000000; 
          else 
                  tmp_count <= tmp_count + 27'h1; 
end 
 
assign ENABLE = (tmp_count == (SEC1_MAX - 1))? 1'b1 : 1'b0; 
assign ENABLE_kHz = (tmp_count[11:0] == 12'hFFF)? 1'b1 : 1'b0; 
endmodule