module weekday_calc(
    input  wire [11:0] year_bcd,   // 年: 3桁BCD
    input  wire [7:0]  month_bcd,  // 月: 2桁BCD
    input  wire [7:0]  day_bcd,    // 日: 2桁BCD
    input  wire        clk,
    output reg  [3:0]  weekday     // 曜日 0=日曜, ..., 6=土曜
);

    // BCD → バイナリ変換 (掛け算なし)
    wire [11:0] year_bin;
    wire [7:0]  month_bin;
    wire [7:0]  day_bin;

    assign year_bin  = ((year_bcd[11:8] << 6) + (year_bcd[11:8] << 5) + (year_bcd[11:8] << 2) + // 百の位 *100 = 64+32+4
                        (year_bcd[7:4]  << 3) + (year_bcd[7:4]  << 1) +   // 十の位 *10 = 8+2
                        year_bcd[3:0]);                                    // 一の位

    assign month_bin = ((month_bcd[7:4] << 3) + (month_bcd[7:4] << 1) + month_bcd[3:0]); // 十の位*10 + 一の位
    assign day_bin   = ((day_bcd[7:4]   << 3) + (day_bcd[7:4]   << 1) + day_bcd[3:0]);   // 十の位*10 + 一の位

    // BRAMアドレス計算 (year*12 + (month-1)) 掛け算なし
    wire [11:0] bram_addr;
    assign bram_addr = (year_bin << 3) + (year_bin << 2) + (month_bin - 1);

    // BRAMインスタンス（初期化済み）
    wire [3:0] bram_dout;
    blk_mem_gen_0 weekday_bram (
        .clka(clk),
        .ena(1'b1),
        .wea(1'b0),
        .addra(bram_addr),
        .douta(bram_dout)
    );
    

    // 曜日計算（BRAMの1日データ + day-1 の7で割った余り）
    always @(posedge clk) begin
        weekday <= (bram_dout + day_bin - 1) % 7;
    end

endmodule
