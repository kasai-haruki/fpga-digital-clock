module CNT_WEEK(clk, reset, day_in, week_day, ENABLE, weekday_in);

input clk, reset, day_in, ENABLE;
output reg [3:0] week_day;
input [3:0] weekday_in;

always @(posedge clk or posedge reset) begin
if (reset == 1'b1) 
    week_day <= weekday_in; 
else if (day_in == 1'b1 && ENABLE == 1'b1) 
if (week_day == 4'h6)
    week_day <= 4'h0; 
else
    week_day <= week_day + 4'h1;
end

endmodule
