module display_switch(  TOP_CURRENT_STATE, DIS_CURRENT_STATE, SET_CURRENT_STATE,
                        SEC_CNT10, SEC_CNT6, MIN_CNT10, MIN_CNT6, HOU_CNT10, HOU_CNT3, week_day,
                        DAY_CNT10, DAY_CNT4, MON_CNT10, MON_CNT2, YEA_CNT10_1, YEA_CNT10_2, YEA_CNT2,
                        C1_out, C2_out, C3_out, C4_out); 
input [1:0] TOP_CURRENT_STATE; 
input [6:0] DIS_CURRENT_STATE, SET_CURRENT_STATE;
input [3:0] SEC_CNT10, SEC_CNT6, MIN_CNT10, MIN_CNT6, HOU_CNT10, HOU_CNT3, week_day,
            DAY_CNT10, DAY_CNT4, MON_CNT10, MON_CNT2, YEA_CNT10_1, YEA_CNT10_2, YEA_CNT2;  
output reg [3:0] C1_out, C2_out, C3_out, C4_out;  

parameter   L1 = 7'b0000001,
            L2 = 7'b0000010,
            L3 = 7'b0000100,
            L4 = 7'b0001000,
            L5 = 7'b0010000,
            L6 = 7'b0100000,
            L7 = 7'b1000000;

always @(TOP_CURRENT_STATE or DIS_CURRENT_STATE or SET_CURRENT_STATE or
            SEC_CNT10 or SEC_CNT6 or MIN_CNT10 or MIN_CNT6 or HOU_CNT10 or HOU_CNT3 or week_day or
            DAY_CNT10 or DAY_CNT4 or MON_CNT10 or MON_CNT2 or YEA_CNT10_1 or YEA_CNT10_2 or YEA_CNT2)
begin
    if (TOP_CURRENT_STATE[0] == 1'b1 || (TOP_CURRENT_STATE[1] == 1'b1 && SET_CURRENT_STATE[0] ==1'b1)) 
    begin
        case(DIS_CURRENT_STATE)
            L1: begin
                C1_out = YEA_CNT10_1;
                C2_out = YEA_CNT10_2;
                C3_out = YEA_CNT2;
                C4_out = 4'h2;
            end
            L2: begin
                C1_out = MON_CNT10;
                C2_out = MON_CNT2;
                C3_out = YEA_CNT10_1;
                C4_out = YEA_CNT10_2;
            end
            L3: begin
                C1_out = week_day;
                C2_out = week_day;
                C3_out = MON_CNT10;
                C4_out = MON_CNT2;
            end
            L4: begin
                C1_out = DAY_CNT10;
                C2_out = DAY_CNT4;
                C3_out = week_day;
                C4_out = week_day;
            end
            L5: begin
                C1_out = HOU_CNT10;
                C2_out = HOU_CNT3;
                C3_out = DAY_CNT10;
                C4_out = DAY_CNT4;
            end
            L6: begin
                C1_out = MIN_CNT10;
                C2_out = MIN_CNT6;
                C3_out = HOU_CNT10;
                C4_out = HOU_CNT3;
            end
            L7: begin
                C1_out = SEC_CNT10;
                C2_out = SEC_CNT6;
                C3_out = MIN_CNT10;
                C4_out = MIN_CNT6;
            end
            default:    begin
                C1_out = YEA_CNT10_1;
                C2_out = YEA_CNT10_2;
                C3_out = YEA_CNT2;
                C4_out = 4'h2;
            end
        endcase
    end
    else if (TOP_CURRENT_STATE[1] == 1'b1) 
    begin
        case(SET_CURRENT_STATE)
            L2: begin
                C1_out = YEA_CNT10_1;
                C2_out = YEA_CNT10_2;
                C3_out = YEA_CNT2;
                C4_out = 4'h2;
            end
            L3: begin
                C1_out = MON_CNT10;
                C2_out = MON_CNT2;
                C3_out = YEA_CNT10_1;
                C4_out = YEA_CNT10_2;
            end
            L4: begin
                C1_out = DAY_CNT10;
                C2_out = DAY_CNT4;
                C3_out = MON_CNT10;
                C4_out = MON_CNT2;
            end
            L5: begin
                C1_out = HOU_CNT10;
                C2_out = HOU_CNT3;
                C3_out = DAY_CNT10;
                C4_out = DAY_CNT4;
            end
            L6: begin
                C1_out = MIN_CNT10;
                C2_out = MIN_CNT6;
                C3_out = HOU_CNT10;
                C4_out = HOU_CNT3;
            end
            L7: begin
                C1_out = SEC_CNT10;
                C2_out = SEC_CNT6;
                C3_out = MIN_CNT10;
                C4_out = MIN_CNT6;
            end
            default:    begin
                C1_out = YEA_CNT10_1;
                C2_out = YEA_CNT10_2;
                C3_out = YEA_CNT2;
                C4_out = 4'h2;
            end
        endcase
    end
end
 
endmodule