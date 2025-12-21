# 詳細技術資料

## 目次

1. [システムアーキテクチャ](#システムアーキテクチャ)
2. [主要モジュール詳細](#主要モジュール詳細)
3. [技術的工夫の詳細](#技術的工夫の詳細)
4. [タイミング設計](#タイミング設計)
5. [リソース最適化](#リソース最適化)
6. [曜日計算の実装](#曜日計算の実装)
7. [入力処理の実装](#入力処理の実装)

---

## システムアーキテクチャ

### 全体ブロック図

```
┌─────────────────────────────────────────┐
│        トップモジュール CLOCK_ALL          │
├─────────────────────────────────────────┤
│ [入力] 4個のボタン → MSE x4 (安定化)      │
│ [クロック] 125MHz → SEC1 → ENABLE (1Hz)  │
├─────────────────────────────────────────┤
│              [モード制御]                 │
│  MAIN_MODE: 時刻表示/設定/アラーム/SW/タイマー │
│  SET_MODE: 設定中の桁を個別変更           │
│  DIS_MODE: 表示データ切替                │
├─────────────────────────────────────────┤
│         [カウンタチェーン (carry連鎖)]      │
│                                          │
│  CNT60(秒) ─carry→ CNT60(分) ─carry→    │
│  CNT24(時) ─carry→ CNT_DAY(日) ─carry→  │
│  CNT_MONTH(月) ─carry→ CNT_YEAR(年)      │
│                                          │
│  weekday_calc(曜日): ブロックRAM参照      │
│  leap_year(うるう年): 組み合わせ回路      │
├─────────────────────────────────────────┤
│              [表示制御]                   │
│  display_switch → DECODER7 → LED[7:0]    │
│  DCOUNT → SA[3:0] (桁選択信号)           │
│  ダイナミック点灯: 1桁ずつ高速切替        │
└─────────────────────────────────────────┘
           ↓
    4桁7セグメントLED表示
```

### 信号フロー詳細

#### クロック生成
```verilog
// SEC1.v
125MHz CLK → tmp_count (27-bit counter)
→ ENABLE = (tmp_count == 125M-1) ? 1 : 0
→ ENABLE_kHz = (tmp_count[11:0] == 12'hFFF) ? 1 : 0
```

#### Carry連鎖の仕組み

**重要な原則**: すべてのcarry信号は組み合わせ回路で生成され、すべてのカウンタは同じCLKエッジで更新される

```
時刻: 23:59:59 → 00:00:00 の遷移

[CLKの立ち上がり時点での状態]
tmp_count = 124999999 (ENABLEが立つ最後の瞬間)

秒カウンタ（CNT60）:
  CNT10 = 9, CNT6 = 5 (59のまま)
  CARRY_in = 1 (常に1)
  → CARRY = (9==9) && 1 = 1      ← 組み合わせ回路で即座に確定
  → CARRY_out = (5==5) && 1 = 1

分カウンタ（CNT60）:
  CNT10 = 9, CNT6 = 5 (59のまま)
  CARRY_in = 秒のCARRY_out = 1
  → CARRY = (9==9) && 1 = 1
  → CARRY_out = (5==5) && 1 = 1

時カウンタ（CNT24）:
  CNT10 = 3, CNT3 = 2 (23のまま)
  CARRY_in = 分のCARRY_out = 1
  → CARRY = ({2,3}==23) && 1 = 1
  → CARRY_out = (2==2) && 1 = 1

[すべて同じCLKエッジで同時に判定完了]
→ 次のCLKエッジで全カウンタが 00:00:00 に更新
→ 時間的な遅延なし、完全に同期
```

---

## 主要モジュール詳細

### 1. SEC1.v - クロック生成モジュール

**機能**: 125MHzシステムクロックから1Hz（1秒）と約1kHzの制御信号を生成

```verilog
module SEC1(CLK, RESET, ENABLE, ENABLE_kHz);
    input CLK, RESET;
    output ENABLE, ENABLE_kHz;
    reg [26:0] tmp_count; 
    parameter SEC1_MAX = 125000000; // 125MHz 
    
    always @(posedge CLK) begin 
        if (RESET == 1'b1) 
            tmp_count <= 27'h000000; 
        else if (ENABLE == 1'b1) 
            tmp_count <= 27'h000000; 
        else 
            tmp_count <= tmp_count + 27'h1; 
    end 
    
    assign ENABLE = (tmp_count == (SEC1_MAX - 1))? 1'b1 : 1'b0; 
    assign ENABLE_kHz = (tmp_count[11:0] == 12'hFFF)? 1'b1 : 1'b0; 
endmodule
```

**重要ポイント**:
- `ENABLE`は1秒に1回だけ1clkだけHighになる
- `ENABLE_kHz`は約1kHz（4096分周）でHighになる
- すべてのカウンタはこのENABLE信号で同期

### 2. CNT60.v - 60進カウンタ

**機能**: 0-59をカウント、59でcarry信号を出力

```verilog
module CNT60(RESET, CLK, CNT6, CNT10, ENABLE, CARRY_in, CARRY_out, 
             SET_CURRENT_STATE, INC_MODE);
    input RESET, CLK, ENABLE, CARRY_in, INC_MODE;
    input [1:0] SET_CURRENT_STATE;
    output reg CARRY_out;
    output [3:0] CNT10;
    output [3:0] CNT6;
    reg [3:0] CNT10;
    reg [3:0] CNT6;
    reg CARRY;

    // 1の位カウンタ (0-9)
    always @(posedge CLK or posedge RESET) begin 
        if (RESET == 1'b1) begin
            CNT10 <= 4'h0; 
        end
        else if (((ENABLE == 1'b1 && CARRY_in == 1'b1) && SET_CURRENT_STATE[0] == 1'b1) ||
                 (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1)) begin
            if (CARRY == 1'b1) 
                CNT10 <= 4'h0; 
            else 
                CNT10 <= CNT10 + 4'h1; 
        end 
    end 
    
    // 内部CARRY生成 (組み合わせ回路)
    always @(CNT10 or CARRY_in or SET_CURRENT_STATE or INC_MODE) begin 
        if (CNT10 == 4'h9 && (CARRY_in == 1'b1 || 
            (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1))) 
            CARRY <= 1'b1; 
        else 
            CARRY <= 1'b0;
    end  

    // CARRY_out生成 (組み合わせ回路)
    always @(CNT6 or CARRY) begin 
        if (CNT6 == 4'h5 && CARRY == 1'b1) 
            CARRY_out <= 1'b1; 
        else 
            CARRY_out <= 1'b0;  
    end  
    
    // 10の位カウンタ (0-5)
    always @(posedge CLK or posedge RESET) begin 
        if (RESET == 1'b1) begin 
            CNT6 <= 3'b000; 
        end 
        else if ((CARRY == 1'b1) && ((ENABLE == 1'b1 && SET_CURRENT_STATE[0] == 1'b1) ||
                 (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1))) begin 
            if (CNT6 == 3'b101) 
                CNT6 <= 3'b000; 
            else 
                CNT6 <= CNT6 + 3'b001; 
        end 
    end 
endmodule
```

**設計のポイント**:
1. **3つのCARRY信号の役割**:
   - `CARRY_in`: 上位から受け取る更新許可信号
   - `CARRY`: 内部信号（組み合わせ回路で生成）
   - `CARRY_out`: 下位に送る更新許可信号

2. **更新条件**:
   - 通常動作: `ENABLE && CARRY_in && SET_CURRENT_STATE[0]`
   - 設定モード: `SET_CURRENT_STATE[1] && INC_MODE`

3. **ワンホットエンコーディング**:
   - `SET_CURRENT_STATE[0]`: 通常動作中
   - `SET_CURRENT_STATE[1]`: 設定モード中（この桁）
   - 2ビットだけ受け取ることで配線削減

### 3. CNT24.v - 24時間カウンタ

**機能**: 0-23をカウント、23でcarry信号を出力

```verilog
// 内部CARRY生成の重要部分
always @(CNT10 or CARRY_in or SET_CURRENT_STATE or INC_MODE) begin 
    if ((CNT10 == 4'h9 || {CNT3,CNT10} == 8'h23) &&
        (CARRY_in == 1'b1 || (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1))) 
        CARRY <= 1'b1; 
    else 
        CARRY <= 1'b0;
end
```

**特殊処理**:
- 通常: `CNT10 == 9`でcarry
- 23時の場合: `{CNT3,CNT10} == 23`でcarry（特別処理）
- 次は`00`に戻る

### 4. CNT_DAY.v - 日カウンタ

**機能**: 月ごとの日数に対応（28/29/30/31日）

```verilog
// うるう年と月に応じた最大日数判定
always @(CNT10 or CARRY_in or CNT4 or month or is_leap or 
         SET_CURRENT_STATE or INC_MODE) begin  
    if ((((month == 8'h04 || month == 8'h06 || month == 8'h09 || month == 8'h11) 
            && ({CNT4, CNT10} == 8'h30)) || 
        ((month == 8'h02) && ((is_leap == 1'b0) && ({CNT4, CNT10} == 8'h28))) ||
        (({CNT4, CNT10} == 8'h31) || (CNT10 == 4'h9))) && 
        (CARRY_in == 1'b1 || (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1))) 
        CARRY <= 1'b1; 
    else 
        CARRY <= 1'b0;       
end
```

**月ごとの処理**:
- 4,6,9,11月: 30日
- 2月: うるう年28日、平年29日
- その他: 31日
- 1日からスタート（初期値: `CNT10 = 1`）

### 5. weekday_calc.v - 曜日計算モジュール

**機能**: 年月日から曜日を高速計算（ブロックRAM使用）

```verilog
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

    assign year_bin  = ((year_bcd[11:8] << 6) + (year_bcd[11:8] << 5) + 
                        (year_bcd[11:8] << 2) +   // 百の位 *100 = 64+32+4
                        (year_bcd[7:4]  << 3) + (year_bcd[7:4]  << 1) +   
                        year_bcd[3:0]);                                    

    assign month_bin = ((month_bcd[7:4] << 3) + (month_bcd[7:4] << 1) + 
                        month_bcd[3:0]); 
    assign day_bin   = ((day_bcd[7:4]   << 3) + (day_bcd[7:4]   << 1) + 
                        day_bcd[3:0]);   

    // BRAMアドレス計算 (year*12 + (month-1)) 掛け算なし
    wire [11:0] bram_addr;
    assign bram_addr = (year_bin << 3) + (year_bin << 2) + (month_bin - 1);
    // year*12 = year*8 + year*4 = (year<<3) + (year<<2)

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
```

**最適化のポイント**:
1. **掛け算を使わないアドレス計算**: `year*12 = (year<<3) + (year<<2)`
2. **BCD→バイナリ変換も掛け算なし**: シフトと加算のみ
3. **1サイクルでBRAMアクセス完了**: 高速動作
4. **LUT削減**: Zellerの公式の複雑な演算を回避

### 6. DECODER7.v - 7セグメントデコーダ

**機能**: BCDデータを7セグメントLED信号に変換、曜日表示にも対応

```verilog
module DECODER7(COUNT, LED, TOP_CURRENT_STATE, DIS_CURRENT_STATE, SA); 
    input TOP_CURRENT_STATE; 
    input [1:0] DIS_CURRENT_STATE;
    input [3:0] COUNT, SA; 
    output reg [7:0] LED; 
    
    always @(COUNT or TOP_CURRENT_STATE or DIS_CURRENT_STATE or SA) begin 
        // 曜日表示モード
        if(TOP_CURRENT_STATE == 1'b1 && DIS_CURRENT_STATE[0] == 1'b1 && 
           SA[3:2] == 2'b00) begin
            case(SA[1:0])
                2'b01:  case(COUNT)  // 1桁目 (U, O, U, E, H, R, A)
                    4'b0000: LED <= 8'b0011100_0; // U (日曜日)
                    4'b0001: LED <= 8'b0011101_0; // O (月曜日)
                    4'b0010: LED <= 8'b0011100_0; // U (火曜日)
                    4'b0011: LED <= 8'b1001111_0; // E (水曜日)
                    4'b0100: LED <= 8'b0010111_0; // H (木曜日)
                    4'b0101: LED <= 8'b0000101_0; // R (金曜日)
                    4'b0110: LED <= 8'b1110111_0; // A (土曜日)
                    default: LED <= 8'b0011100_0;
                endcase
                2'b10:  case(COUNT)  // 2桁目 (S, M, T, W, T, F, S)
                    4'b0000: LED <= 8'b0011011_0; // S (日曜日)
                    4'b0001: LED <= 8'b1110110_0; // M (月曜日)
                    4'b0010: LED <= 8'b0001111_0; // T (火曜日)
                    4'b0011: LED <= 8'b0101010_0; // W (水曜日)
                    4'b0100: LED <= 8'b0001111_0; // T (木曜日)
                    4'b0101: LED <= 8'b1000111_0; // F (金曜日)
                    4'b0110: LED <= 8'b0011011_0; // S (土曜日)
                    default: LED <= 8'b0011011_0;
                endcase
            endcase
        end 
        // 通常の数字表示
        else begin                
            case (COUNT)          // ABCDEFG Dp
                4'b0000: LED <= ~8'b0000001_1; 
                4'b0001: LED <= ~8'b1001111_1; 
                4'b0010: LED <= ~8'b0010010_1; 
                4'b0011: LED <= ~8'b0000110_1; 
                4'b0100: LED <= ~8'b1001100_1; 
                4'b0101: LED <= ~8'b0100100_1; 
                4'b0110: LED <= ~8'b0100000_1; 
                4'b0111: LED <= ~8'b0001101_1; 
                4'b1000: LED <= ~8'b0000000_1; 
                4'b1001: LED <= ~8'b0000100_1; 
                default: LED <= ~8'b0110000_1; 
            endcase 
        end
    end 
endmodule
```

**オリジナル曜日パターン**:
```
日曜 SU: S(0011011) U(0011100)
月曜 MO: M(1110110) O(0011101)
火曜 TU: T(0001111) U(0011100)
水曜 WE: W(0101010) E(1001111)
木曜 TH: T(0001111) H(0010111)
金曜 FR: F(1000111) R(0000101)
土曜 SA: S(0011011) A(1110111)
```

### 7. DCOUNT.v - ダイナミック点灯制御

**機能**: 4桁のLEDを高速に切り替えて表示

```verilog
module DCOUNT(CLK, ENABLE, L1, L2, L3, L4, SA, L); 
    input CLK, ENABLE; 
    input [3:0] L1, L2, L3, L4; 
    output [3:0] SA; 
    output [3:0] L; 
    
    parameter MAX_COUNT = 3'b111; 
    reg [2:0] sa_count_tmp; 
    reg [3:0] sa_count; 
    reg [3:0] L_tmp; 
    
    // SA信号生成（桁選択）
    assign SA[3] = (sa_count[3]==1'b1)? 1'b1 : 1'b0; 
    assign SA[2] = (sa_count[2]==1'b1)? 1'b1 : 1'b0; 
    assign SA[1] = (sa_count[1]==1'b1)? 1'b1 : 1'b0; 
    assign SA[0] = (sa_count[0]==1'b1)? 1'b1 : 1'b0; 
    assign L = L_tmp; 
    
    // カウンタ（どの桁を表示するか）
    always @(posedge CLK) begin 
        if (ENABLE==1'b1)  
            if (sa_count_tmp==MAX_COUNT) 
                sa_count_tmp <= 3'b000; 
            else 
                sa_count_tmp <= sa_count_tmp + 1'b1; 
    end 
    
    // 表示データ切替
    always @(posedge CLK) begin 
        if (sa_count_tmp[0]==1'b0) begin 
            sa_count <= 4'b0000;
            L_tmp <= L_tmp; 
        end 
        else begin
            case (sa_count_tmp[2:1]) 
                2'b00: begin 
                    sa_count <= 4'b1000;  // 4桁目
                    L_tmp <= L4; 
                end 
                2'b01: begin 
                    sa_count <= 4'b0100;  // 3桁目
                    L_tmp <= L3; 
                end 
                2'b10: begin 
                    sa_count <= 4'b0010;  // 2桁目
                    L_tmp <= L2; 
                end 
                2'b11: begin 
                    sa_count <= 4'b0001;  // 1桁目
                    L_tmp <= L1; 
                end 
                default: begin 
                    sa_count <= 4'bxxxx;
                    L_tmp <= 8'bxxxxxxxx; 
                end 
            endcase 
        end
    end 
endmodule
```

**動作原理**:
1. `ENABLE_kHz`（約1kHz）で桁カウンタを更新
2. 4桁を順番に切り替え（L4→L3→L2→L1）
3. 対応する`SA`信号で桁を選択
4. 高速切替により人間の目には同時点灯に見える

### 8. MSE.v - 統合入力処理モジュール

**機能**: メタステビリティ + チャタリング + エッジ検出を統合

```verilog
module MSE(CLK, MODE_IN, MODE, ENABLE_kHz);
    input CLK, MODE_IN, ENABLE_kHz;
    output MODE;
    reg [1:0] META;  // メタステーブル対策
    reg [3:0] SFT;   // チャタリング除去
    reg [1:0] ED;    // エッジ検出

    // ① メタステビリティ対策（2段フリップフロップ）
    always @(posedge CLK) begin
        META <= {META[0], MODE_IN};
    end

    // ② チャタリング対策（4ビットシフトレジスタ）
    always @(posedge CLK) begin
        if(ENABLE_kHz == 1'b1)
            SFT <= {SFT[2:0], META[1]};
    end

    // 4ビット全て1のときだけ有効
    wire CHATA = & SFT;

    // ③ エッジ検出（立ち上がり検出）
    always @(posedge CLK) begin
        ED <= {ED[0], CHATA};
    end

    // 立ち上がりエッジでパルス出力
    assign MODE = ED[0] & ~ED[1];
endmodule
```

**3つの機能の詳細**:

1. **メタステビリティ対策**
   - 外部入力を2段FFで受けて安定化
   - 非同期信号→同期信号への変換

2. **チャタリング対策**
   - `ENABLE_kHz`（約1kHz）でサンプリング
   - 4回連続で同じ値の時だけ有効
   - 高速なノイズは無視される

3. **エッジ検出**
   - 前回と今回の状態を比較
   - 0→1の瞬間だけ1clkパルス出力
   - 押しっぱなしでも1回だけカウント

---

## 技術的工夫の詳細

### 工夫1: 単層同期回路設計

#### 分周回路方式との比較

**❌ 分周回路方式（不採用）**
```
秒CLK (1Hz) ─┐
             ├→ 分カウンタ
分CLK (1/60Hz)─┘

問題点：
- 異なるクロック周波数使用
- クロック間のタイミングずれ発生
- CDC (Clock Domain Crossing) 問題
- デバッグが困難
```

**✅ 単層同期回路方式（採用）**
```
125MHz CLK ─┬→ 秒カウンタ (ENABLE && CARRY_in)
            ├→ 分カウンタ (ENABLE && CARRY_in)
            └→ 時カウンタ (ENABLE && CARRY_in)

利点：
- 全モジュールが同じCLKで動作
- CARRY信号は組み合わせ回路
- 時間的遅延ゼロ
- デバッグが容易
```

#### FPGAのタイミング特性

```
CLK立ち上がり時点での状態：
┌────────────────────────────┐
│ tmp_count = 124999999      │
│ ↓（この値で判定）           │
│ ENABLE = (tmp_count == 124999999) = 1  │
├────────────────────────────┤
│ CLK立ち上がり後（数ns後）： │
│ tmp_count = 0 に更新       │
│ ENABLE = 0 に変化          │
│ （次のCLKで認識される）     │
└────────────────────────────┘
```

この特性により、「124999999の最後の瞬間」にENABLE=1として判定可能

#### 23:59:59 → 00:00:00 の同時判定

```
CLKの立ち上がり時点：

秒カウンタ：
  CNT10=9, CNT6=5 (59のまま)
  CARRY_in = 1
  → CARRY = (9==9) && 1 = 1  ← 数ns以内に確定
  → CARRY_out = (5==5) && 1 = 1

分カウンタ：
  CNT10=9, CNT6=5 (59のまま)
  CARRY_in = 秒のCARRY_out = 1  ← 既に確定
  → CARRY = (9==9) && 1 = 1
  → CARRY_out = (5==5) && 1 = 1

時カウンタ：
  CNT10=3, CNT3=2 (23のまま)
  CARRY_in = 分のCARRY_out = 1  ← 既に確定
  → CARRY = ({2,3}==23) && 1 = 1
  → CARRY_out = (2==2) && 1 = 1

→ すべて同じCLKエッジで同時に判定完了
→ 次のCLKで全カウンタが00:00:00に更新
```

### 工夫2: ブロックRAMによる曜日計算最適化

#### 従来の方法の問題点

**Zellerの公式**:
```
h = (q + ⌊13(m+1)/5⌋ + K + ⌊K/4⌋ + ⌊J/4⌋ - 2J) mod 7

問題点：
- 除算・剰余演算が必要
- FPGAで実装すると大量のLUT消費
- 計算に複数サイクル必要
- Critical Pathが長くなる
```

#### ブロックRAM方式

**データ準備（C言語）**:
```c
// weekday.c
for (year = 2000; year <= 2100; year++) {
    for (month = 1; month <= 12; month++) {
        w = calculate_weekday(year, month, 1);  // 1日の曜日
        fprintf(fp, "%X\n", w); 
    }
}
// 合計: 101年 × 12ヶ月 = 1,212エントリ
```

**FPGA実装**:
```verilog
// アドレス計算（掛け算なし）
// year*12 = year*8 + year*4
bram_addr = (year_bin << 3) + (year_bin << 2) + (month_bin - 1);

// BRAMから1日の曜日を取得
bram_dout = weekday_bram[bram_addr];

// 実際の日の曜日を計算
weekday = (bram_dout + day_bin - 1) % 7;
```

**効果**:
- 1サイクルでBRAMアクセス完了
- LUT使用量を大幅削減
- Critical Path短縮

### 工夫3: ダイナミック点灯制御の最適化

#### 初期実装の問題

```
デコーダ4個使用：
DECODER7 i1(.COUNT(CNT_1), .LED(L1));
DECODER7 i2(.COUNT(CNT_2), .LED(L2));
DECODER7 i3(.COUNT(CNT_3), .LED(L3));
DECODER7 i4(.COUNT(CNT_4), .LED(L4));

データ幅：
wire [7:0] L1, L2, L3, L4;  // 合計32bit

問題点：
- デコーダ4個分のLUT消費
- 32bitのデータ幅
```

#### 最適化後

```
デコーダ1個：
DECODER7 i1(.COUNT(CNT), .LED(LED));

データ切替：
case (sa_count_tmp[2:1])
    2'b00: L_tmp <= L4;  // 4桁目
    2'b01: L_tmp <= L3;  // 3桁目
    2'b10: L_tmp <= L2;  // 2桁目
    2'b11: L_tmp <= L1;  // 1桁目
endcase

データ幅：
wire [3:0] CNT_1, CNT_2, CNT_3, CNT_4;  // 合計16bit

効果：
- デコーダ数: 4個 → 1個（75%削減）
- データ幅: 32bit → 16bit（50%削減）
```

### 工夫4: レジスタの統一

#### 従来の設計

```
表示用レジスタ：
reg [3:0] DISP_YEAR, DISP_MONTH, DISP_DAY, ...

設定用レジスタ：
reg [3:0] SET_YEAR, SET_MONTH, SET_DAY, ...

設定完了時：
DISP_YEAR <= SET_YEAR;
DISP_MONTH <= SET_MONTH;
...

問題点：
- レジスタ数が2倍
- コピー処理が必要
- 回路規模増大
```

#### 統一設計

```
共通レジスタ：
reg [3:0] YEAR, MONTH, DAY, ...

通常動作時：
ENABLE信号により自動的にカウント

設定モード時：
SET_CURRENT_STATE[1] == 1'b1
INC_MODE により該当桁を変更
他の桁は通常通りカウント継続

効果：
- レジスタ数50%削減
- コピー処理不要
- シームレスな動作
```

### 工夫5: ワンホットエンコーディング

#### バイナリ vs ワンホット

**バイナリ方式**:
```verilog
// 7状態を3ビットで表現
parameter STATE0 = 3'b000;
parameter STATE1 = 3'b001;
parameter STATE2 = 3'b010;
...

// 状態判定
if (CURRENT_STATE == 3'b010) begin
    // 3ビット全体を比較
    // デコード回路が必要
end
```

**ワンホット方式**:
```verilog
// 7状態を7ビットで表現
parameter L1 = 7'b0000001;
parameter L2 = 7'b0000010;
parameter L3 = 7'b0000100;
...

// 状態判定
if (SET_CURRENT_STATE[0] == 1'b1) begin
    // 1ビットのみチェック
    // デコード回路不要
end

// 必要なビットだけ配線
input [1:0] SET_CURRENT_STATE;  // 7ビット中2ビットだけ
```

**利点**:
- デコード回路不要 → LUT削減
- 配線削減（必要なビットのみ）
- 高速判定（単一ビットチェック）
- 波形で状態が一目瞭然

---

## タイミング設計

### クリティカルパス分析

```
最長遅延パス：
tmp_count[26:0] 
  → ENABLE生成 (組み合わせ回路)
  → CNT60 CARRY判定 (組み合わせ回路)
  → CNT60 CARRY_out生成 (組み合わせ回路)
  → CNT24 CARRY判定 (組み合わせ回路)
  → CNT24 更新判定
  → FFへの書き込み

遅延時間：
- tmp_count → ENABLE: ~2ns
- ENABLE → CARRY連鎖: ~3ns (3段)
- セットアップ時間: ~0.5ns
合計: ~5.5ns → 約180MHz動作可能

実際の動作周波数: 125MHz
マージン: 約45%
```

### タイミング制約

```tcl
# クロック制約
create_clock -period 8.000 -name CLK [get_ports CLK]
# 125MHz = 8.000ns

# 入力遅延
set_input_delay -clock CLK -max 2.0 [get_ports {btn_*}]

# 出力遅延  
set_output_delay -clock CLK -max 2.0 [get_ports {LED[*] SA[*]}]
```

---

## リソース最適化

### 最適化テクニック

1. **LUT削減**:
   - ブロックRAM使用（曜日計算）
   - ワンホットエンコーディング
   - デコーダ統合

2. **FF削減**:
   - レジスタ統一
   - 不要なパイプライン段削除

3. **配線削減**:
   - 必要なビットのみ配線
   - ローカル信号の活用

4. **BRAM活用**:
   - 曜日ルックアップテーブル
   - 初期化データの格納

### リソース使用内訳

```
Slice LUTs (390個):
- カウンタロジック: ~150
- 状態遷移: ~80
- デコーダ: ~60
- 制御ロジック: ~100

Slice Registers (154個):
- カウンタ: ~130
- 状態レジスタ: ~24

BRAM:
- 曜日テーブル: 0.5個（RAMB18E1）
```

---

この技術資料は、就職活動において技術的な深い理解をアピールするための詳細資料です。面接時の技術質問への回答や、技術的なディスカッションの際に参照できます。

次のドキュメント:
- [開発プロセス](./DEVELOPMENT.md) - 段階的開発手法、検証フロー
- [モジュール仕様](./MODULES.md) - 各モジュールの詳細仕様
- [検証レポート](./VERIFICATION.md) - テスト結果、境界値テスト
