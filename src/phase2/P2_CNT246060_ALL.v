module CNT246060_ALL(CLK, RESET, DEC, LED, SA, btn_switch); 
input CLK, RESET, DEC, btn_switch; 
output [7:0] LED; 
output [3:0] SA; 
 
reg [26:0] tmp_count; 

wire [3:0] CNT10; 
wire [2:0] CNT6; 
wire [3:0] CNT10_2; 
wire [2:0] CNT6_2; 
wire [3:0] CNT10_3; 
wire [1:0] CNT3; 
wire [3:0] CNT_1, CNT_2, CNT_3, CNT_4; 
wire ENABLE, ENABLE_kHz; 
wire [7:0] L1, L2, L3, L4; 
wire CARRY, CARRY_2, CARRY_3;
 
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
assign ENABLE_kHz = (tmp_count[11:0] == 12'hfff)? 1'b1 : 1'b0; 

CNT60 i0(.CLK(CLK), .RESET(RESET), .DEC(DEC), .ENABLE(ENABLE), .CARRY_in(1'b1), .CARRY_out(CARRY), 
           .CNT10(CNT10), .CNT6(CNT6)); 
DECODER7 i1(.COUNT(CNT_1), .LED(L1)); 
DECODER7 i2(.COUNT(CNT_2), .LED(L2)); 
CNT60 i4(.CLK(CLK), .RESET(RESET), .DEC(DEC), .ENABLE(ENABLE), .CARRY_in(CARRY), .CARRY_out(CARRY_2), 
           .CNT10(CNT10_2), .CNT6(CNT6_2)); 
DECODER7 i5(.COUNT(CNT_3), .LED(L3)); 
DECODER7 i6(.COUNT(CNT_4), .LED(L4)); 
DCOUNT i3(.CLK(CLK), .ENABLE(ENABLE_kHz), .L1(L1), .L2(L2), 
          .L3(L3), .L4(L4), .SA(SA), .L(LED)); 
CNT24 i7(.CLK(CLK), .RESET(RESET), .DEC(DEC), .ENABLE(ENABLE), .CARRY_in(CARRY_2), .CARRY_out(CARRY_3), 
           .CNT10(CNT10_3), .CNT3(CNT3));  
display_switch i8(      .CLK(CLK), .btn_switch(btn_switch), 
                        .C1_in(CNT10), .C2_in({1'b0,CNT6}), .C3_in(CNT10_2), .C4_in({1'b0,CNT6_2}), 
                        .C5_in(CNT10_3), .C6_in({2'b00,CNT3}), .C7_in(4'b0000), .C8_in(4'b0000), 
                        .C1_out(CNT_1), .C2_out(CNT_2), .C3_out(CNT_3), .C4_out(CNT_4));                
 
endmodule 