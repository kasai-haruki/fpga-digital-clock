module leap_year(year_bcd, is_leap);

input [11:0] year_bcd;   
output is_leap;

wire [3:0] ones;   
wire [3:0] tens;   
wire [3:0] hunds;  
wire ones_div4, tens_even, div4, ones_div4_2, tens_odd;

assign ones = year_bcd[3:0];   
assign tens = year_bcd[7:4];   
assign hunds = year_bcd[11:8];  

assign ones_div4 = (ones == 4'h0) || (ones == 4'h4) || (ones == 4'h8);
assign tens_even = ~tens[0]; 
assign ones_div4_2 = (ones == 4'h2) || (ones == 4'h6);
assign tens_odd = tens[0]; 
assign div4 = ((ones_div4 && tens_even) || (ones_div4_2 && tens_odd));

assign is_leap = div4 && ~(hunds == 4'h1);

endmodule
