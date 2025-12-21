module TEST_CNT_DMY; 
parameter MAX_NUM = 36890;
reg clk, reset; 
reg [31:0] ref [0:MAX_NUM - 1]; 
reg [31:0] cnt_value, cnt_value_ref;
integer i;
reg [16:0] ok_count;

parameter CYCLE = 100; 
parameter SIM_SEC1_MAX = 16; 
   
CNT_DMY #(.SEC1_MAX(SIM_SEC1_MAX)) i1(.RESET(reset), .CLK(clk)); 

always @(posedge clk) 
begin
cnt_value = {   i1.week_day, i1.CNT2_2, i1.CNT10_4, i1.CNT10_3,
                i1.CNT2, i1.CNT10_2,
                i1.CNT4, i1.CNT10};
end
   
always #(CYCLE/2) 
    clk = ~clk; 
   
initial 
begin
    $readmemh("ref.hex", ref);  
end

initial 
begin 
    reset = 1'b1; clk = 1'b0; ok_count = 17'b0;
    cnt_value_ref = ref[0];
    #(3*CYCLE) reset = 1'b0;
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