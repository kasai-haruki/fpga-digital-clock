module MSE(CLK, MODE_IN, MODE, ENABLE_kHz);
input CLK, MODE_IN, ENABLE_kHz;
reg [1:0] META;
reg [3:0] SFT;
wire CHATA;
reg [1:0] ED;
output MODE;

always @(posedge CLK) begin
META <= {META[0], MODE_IN};
end

always @(posedge CLK) begin
if(ENABLE_kHz == 1'b1)
SFT <= {SFT[2:0], META[1]};
end

assign CHATA =& SFT;

always @(posedge CLK) begin
ED <= {ED[0], CHATA};
end

assign MODE = ED[0] & ~ED[1];
endmodule