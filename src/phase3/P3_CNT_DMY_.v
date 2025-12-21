module CNT_DMY(CLK, RESET, month, year); 
input CLK, RESET; 

reg [26:0] tmp_count; 

wire [3:0] CNT10, CNT4, CNT10_2, CNT2, CNT10_3, CNT10_4, CNT_2, week_day, CNT2_2, weekday_2; 
wire ENABLE, ENABLE_kHz; 
wire CARRY, CARRY_2, CARRY_3, is_leap;
output wire [7:0] month;
output wire [11:0] year;
wire [15:0] LED;

assign month = {CNT2, CNT10_2};
assign year = {CNT2_2, CNT10_4, CNT10_3};

parameter SEC1_MAX = 125000000; // 125MHz 
 
CNT_DAY i0(     .CLK(CLK), .RESET(RESET), .ENABLE(ENABLE), .CARRY_in(1'b1), .CARRY_out(CARRY),
                .CNT10(CNT10), .CNT4(CNT4), .month(month), .is_leap(is_leap)); 
CNT_MONTH i1(   .CLK(CLK), .RESET(RESET), .ENABLE(ENABLE), .CARRY_in(CARRY), .CARRY_out(CARRY_2),
                .CNT10(CNT10_2), .CNT2(CNT2));  
CNT_YEAR i2(    .CLK(CLK), .RESET(RESET), .ENABLE(ENABLE), .CARRY_in(CARRY_2), .CARRY_out(CARRY_3),
                .CNT10(CNT10_3), .CNT10_2(CNT10_4), .CNT2(CNT2_2));    
leap_year i3(   .year_bcd(year), .is_leap(is_leap));
//CNT_WEEK i4(    .clk(CLK), .reset(RESET), .day_in(1'b1), .week_day(week_day), .ENABLE(ENABLE), .weekday_in(weekday_2));
LED_WEEK i4(    .week_day(week_day), .LED(LED));
weekday_calc i5(.year_bcd(year), .month_bcd(month), .day_bcd({CNT4, CNT10}), .clk(CLK), .weekday(week_day));
SEC1 #(.SEC1_MAX(SEC1_MAX)) i6(.CLK(CLK), .RESET(RESET), .ENABLE(ENABLE), .ENABLE_kHz(ENABLE_kHz));


endmodule 