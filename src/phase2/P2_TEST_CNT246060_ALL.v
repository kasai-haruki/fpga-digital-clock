module TEST_CNT246060_ALL; 
parameter MAX_NUM = 60*60*24;
reg clk, reset, dec, btn_switch; 
wire [7:0] led; 
wire [3:0] sa; 
reg [23:0] ref [0:MAX_NUM - 1]; 
reg [23:0] cnt_value, cnt_value_ref;
integer i;
reg [16:0] ok_count;

parameter CYCLE = 100; 
parameter SIM_SEC1_MAX = 4; 
   
CNT246060_ALL #(.SEC1_MAX(SIM_SEC1_MAX)) i1(.RESET(reset), .CLK(clk), .DEC(dec), .btn_switch(btn_switch), .LED(led), .SA(sa)); 

always @(posedge clk) 
begin
cnt_value = {   2'b0, i1.CNT3, i1.CNT10_3,
                1'b0, i1.CNT6_2, i1.CNT10_2,
                1'b0, i1.CNT6, i1.CNT10};
end
   
always #(CYCLE/2) 
    clk = ~clk; 
   
initial 
begin
    $readmemh("ref.hex", ref);  
end

initial 
begin 
    reset = 1'b1; clk = 1'b0; dec = 1'b0; btn_switch = 1'b0; ok_count = 17'b0;
    cnt_value_ref = ref[0];
    #CYCLE reset = 1'b0;
    @(posedge i1.ENABLE);
    @(negedge clk);        
    if (cnt_value !== cnt_value_ref)begin
        $display("Error at step %d: cnt_value=%X expected=%X", 0, cnt_value, ref[0]);
        $display("Total OK steps = %d", ok_count);
        $stop;
        end
    else begin
        ok_count = ok_count + 1;  
    end 
    for (i = 1; i < MAX_NUM; i = i + 1) 
    begin
        @(negedge i1.ENABLE);
        cnt_value_ref = ref[i]; 
        @(posedge i1.ENABLE);
        @(negedge clk);        
        if (cnt_value !== cnt_value_ref)begin
            $display("Error at step %d: cnt_value=%X expected=%X", i, cnt_value, ref[i]);
            $display("Total OK steps = %d", ok_count);
            $stop;
            end
     	else
            ok_count = ok_count + 1;  
    end
	$display("Total OK steps = %d", ok_count);

    $finish; 
end
   
//initial 
//    $monitor($time,,"clk=%b reset=%b cnt_value=%b", clk, reset, cnt_value); 
   
endmodule 