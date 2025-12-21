module UPDOWN(RESET, CLK, DEC, COUNT); 
input RESET, CLK, DEC; 
output reg [3:0] COUNT; 

parameter SEC1_MAX = 125000000; // 125MHz 
 
reg [26:0] tmp_count; 
wire ENABLE; 
 
always @(posedge CLK or posedge RESET) begin 
    if (RESET) 
        tmp_count <= 27'h000000; 
    else if (ENABLE) 
        tmp_count <= 27'h000000; 
    else 
        tmp_count <= tmp_count + 1; 
end 
 
assign ENABLE = (tmp_count == (SEC1_MAX - 1)) ? 1'b1 : 1'b0; 
 
always @(posedge CLK or posedge RESET) begin 
    if (RESET) 
        COUNT <= 4'h0; 
    else if (ENABLE) begin
        if (DEC == 1'b0) begin
            if (COUNT == 4'h9)
                COUNT <= 4'h0; 
            else 
                COUNT <= COUNT + 1; 
        end else begin
            if (COUNT == 4'h0)
                COUNT <= 4'h9; 
            else 
                COUNT <= COUNT - 1; 
        end
    end
end 
endmodule
