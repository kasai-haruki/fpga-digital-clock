module DCOUNT(CLK, ENABLE, L1, L2, L3, L4, SA, L); 
input CLK, ENABLE; 
input [7:0] L1, L2, L3, L4; 
output [3:0] SA; 
output [7:0] L; 
 
parameter MAX_COUNT = 3'b111; 
reg [2:0] sa_count_tmp; 
reg [3:0] sa_count; 
reg [7:0] L_tmp; 
 
assign SA[3] = (sa_count[3]==1'b1)? 1'b1 : 1'b0; 
assign SA[2] = (sa_count[2]==1'b1)? 1'b1 : 1'b0; 
assign SA[1] = (sa_count[1]==1'b1)? 1'b1 : 1'b0; 
assign SA[0] = (sa_count[0]==1'b1)? 1'b1 : 1'b0; 
assign L = L_tmp; 
 
always @(posedge CLK) 
begin 
     if (ENABLE==1'b1)  
         if (sa_count_tmp==MAX_COUNT) 
             sa_count_tmp <= 3'b000; 
         else 
             sa_count_tmp <= sa_count_tmp + 1'b1; 
end 
 
always @(posedge CLK) 
begin 
     if (sa_count_tmp[0]==1'b0) 
         begin 
            sa_count <= 4'b0000;L_tmp <= L_tmp; 
         end 
     else 
         case (sa_count_tmp[2:1]) 
               2'b00:begin 
                         sa_count <= 4'b1000;L_tmp <= L4; 
                      end 
               2'b01:begin 
                         sa_count <= 4'b0100;L_tmp <= L3; 
                      end 
               2'b10:begin 
                         sa_count <= 4'b0010;L_tmp <= L2; 
                      end 
               2'b11:begin 
                         sa_count <= 4'b0001;L_tmp <= L1; 
                      end 
             default:begin 
                         sa_count <= 4'bxxxx;L_tmp <= 8'bxxxxxxxx; 
                     end 
         endcase 
end 
 
endmodule