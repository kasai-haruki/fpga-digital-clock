module UPDOWN_7SEG(RESET, CLK, DEC, LED, SA,/* COUNT*/); 
input RESET, CLK, DEC; 
output [7:0] LED; 
output [3:0] SA; 
/*output [3:0] COUNT;*/ 
 
wire [3:0] COUNT; 
parameter SEC1_MAX = 125000000; 
 
UPDOWN #(.SEC1_MAX(SEC1_MAX)) i0(.RESET(RESET), .CLK(CLK), .DEC(DEC), .COUNT(COUNT)); 
DECODER7 i1(.COUNT(COUNT), .LED(LED), .SA(SA)); 
 
endmodule
