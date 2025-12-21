# 開発プロセスドキュメント

## 目次

1. [開発方針](#開発方針)
2. [3段階の開発フロー](#3段階の開発フロー)
3. [検証戦略](#検証戦略)
4. [テストベンチ実装](#テストベンチ実装)
5. [C言語との連携](#c言語との連携)
6. [デバッグ手法](#デバッグ手法)
7. [品質保証](#品質保証)

---

## 開発方針

### 基本原則

1. **段階的開発**: 小さな機能から始めて徐々に統合
2. **完全な検証**: 各段階で100%のテストを実施
3. **自力実装**: 既存コードに依存せず、すべて独自設計
4. **ドキュメント化**: 設計判断と実装の根拠を記録

### なぜ段階的開発か

**一度にすべてを実装するリスク**:
- バグの発生源が特定困難
- テストが複雑になる
- デバッグに膨大な時間
- モチベーションの低下

**段階的開発の利点**:
- 各段階での動作確認が容易
- バグの早期発見・修正
- 確実な進捗の実感
- 技術の段階的習得

---

## 3段階の開発フロー

### 全体像

```
Phase 1: 基本カウンタ（10進カウンタ）
    ↓
Phase 2: 24時間カウンタ（時・分・秒）
    ↓  → 86,400パターンの全網羅テスト
Phase 3: 年月日曜日カウンタ
    ↓  → 36,890パターンの全網羅テスト
Phase 4: 統合プロジェクト
    ↓  → 5機能の実装
    ↓  → 境界値テスト
完成
```

### Phase 1: 基本カウンタ（開発期間：3日）

**目的**: カウンタとデコーダの基本動作を確認

#### 実装モジュール

```
P1_UPDOWN.v          - 10進カウンタ（0-9）
P1_DECODER7.v        - 7セグメントデコーダ
P1_UPDOWN_7SEG.v     - 統合モジュール
P1_TEST_UPDOWN10.v   - テストベンチ
```

#### 実装内容

**P1_UPDOWN.v**:
```verilog
module UPDOWN(RESET, CLK, DEC, COUNT); 
    input RESET, CLK, DEC; 
    output reg [3:0] COUNT; 
    
    parameter SEC1_MAX = 125000000; // 125MHz 
    reg [26:0] tmp_count; 
    wire ENABLE; 
    
    // 1秒カウンタ
    always @(posedge CLK or posedge RESET) begin 
        if (RESET) 
            tmp_count <= 27'h000000; 
        else if (ENABLE) 
            tmp_count <= 27'h000000; 
        else 
            tmp_count <= tmp_count + 1; 
    end 
    
    assign ENABLE = (tmp_count == (SEC1_MAX - 1)) ? 1'b1 : 1'b0; 
    
    // 10進カウンタ
    always @(posedge CLK or posedge RESET) begin 
        if (RESET) 
            COUNT <= 4'h0; 
        else if (ENABLE) begin
            if (DEC == 1'b0) begin  // カウントアップ
                if (COUNT == 4'h9)
                    COUNT <= 4'h0; 
                else 
                    COUNT <= COUNT + 1; 
            end else begin          // カウントダウン
                if (COUNT == 4'h0)
                    COUNT <= 4'h9; 
                else 
                    COUNT <= COUNT - 1; 
            end
        end
    end 
endmodule
```

#### 学んだこと

1. **ENABLE信号の重要性**:
   - 全カウンタを同期させる基本
   - 1秒に1回だけHighにする制御

2. **BCD（Binary-Coded Decimal）表現**:
   - 4ビットで0-9を表現
   - 7セグメント表示に最適

3. **テストベンチでの可視化**:
   - TCL Consoleに7セグLEDの形を表示
   - シミュレーションでの動作確認

#### 成果

- ✅ 0-9のカウント動作確認
- ✅ カウントアップ/ダウン動作確認
- ✅ 7セグメント表示確認
- ✅ シミュレーション波形の読解習得

---

### Phase 2: 24時間カウンタ（開発期間：1週間）

**目的**: carry連鎖による複数カウンタの同期を習得

#### 実装モジュール

```
P2_CNT60.v           - 60進カウンタ（秒・分）
P2_CNT24.v           - 24時間カウンタ
P2_CNT246060_ALL.v   - 統合モジュール
P2_DECODER7.v        - 7セグメントデコーダ
P2_DCOUNT.v          - ダイナミック点灯制御
P2_display_switch.v  - 表示切替
P2_TEST_CNT246060_ALL.v  - テストベンチ
P2_CountReference.c  - リファレンスデータ生成
```

#### 実装の工夫

**1. carry連鎖の実装**:

```verilog
// CLOCK_ALL.v
CNT60 i0(.CLK(CLK), .RESET(RESET), .ENABLE(ENABLE),
         .CARRY_in(1'b1), .CARRY_out(CARRY), 
         .CNT10(SEC_CNT10), .CNT6(SEC_CNT6)); 

CNT60 i2(.CLK(CLK), .RESET(RESET), .ENABLE(ENABLE),
         .CARRY_in(CARRY), .CARRY_out(CARRY_2),
         .CNT10(MIN_CNT10), .CNT6(MIN_CNT6)); 

CNT24 i4(.CLK(CLK), .RESET(RESET), .ENABLE(ENABLE),
         .CARRY_in(CARRY_2), .CARRY_out(CARRY_3),
         .CNT10(HOU_CNT10), .CNT3(HOU_CNT3));
```

**2. リファレンスデータ生成**:

```c
// P2_CountReference.c
#include <stdio.h>

int main(void) {
    int h, m, s, hh, mm, ss;
    FILE* fp = fopen("ref.hex", "w");
    
    for (h = 0; h < 24; h++) {
        for (m = 0; m < 60; m++) {
            for (s = 0; s < 60; s++) {
                // BCD形式に変換
                hh = ((h / 10) << 4) | (h % 10);
                mm = ((m / 10) << 4) | (m % 10);
                ss = ((s / 10) << 4) | (s % 10);
                
                fprintf(fp, "%02X%02X%02X\n", hh, mm, ss);
            }
        }
    }
    
    fclose(fp);
    return 0;
}
```

**3. テストベンチ**:

```verilog
module TEST_CNT246060_ALL; 
    parameter MAX_NUM = 60*60*24;  // 86,400パターン
    reg [23:0] ref [0:MAX_NUM - 1]; 
    
    initial begin
        $readmemh("ref.hex", ref);  // リファレンス読込
    end
    
    // 検証ループ
    initial begin 
        // 初回
        @(posedge i1.ENABLE);
        @(negedge clk);
        if (cnt_value !== cnt_value_ref) begin
            $display("Error at step %d", 0);
            $stop;
        end
        
        // 2回目以降
        for (i = 1; i < MAX_NUM; i = i + 1) begin
            @(negedge i1.ENABLE);    // ENABLE立ち下がり検出
            cnt_value_ref = ref[i];   // リファレンス先読み
            @(posedge i1.ENABLE);     // ENABLE立ち上がり（更新）
            @(negedge clk);           // clk立ち下がり（確定待ち）
            
            if (cnt_value !== cnt_value_ref) begin
                $display("Error at step %d: cnt_value=%X expected=%X", 
                         i, cnt_value, ref[i]);
                $stop;
            end
            else
                ok_count = ok_count + 1;
        end
        
        $display("Total OK steps = %d", ok_count);
        $finish; 
    end
endmodule
```

#### 発見した問題と解決

**問題1: `==`演算子では不定値を検出できない**

```verilog
// 問題のあるコード
if (cnt_value == cnt_value_ref) begin
    // X（不定値）と 0 の比較で true が返される
    // テストが正しくエラーを検出できない
end
```

**解決策: `===`演算子を使用**

```verilog
// 正しいコード
if (cnt_value !== cnt_value_ref) begin
    // X（不定値）も含めて厳密に比較
    // 不定値があれば false を返す
    $display("Error at step %d", i);
    $stop;
end
```

**問題2: タイミング制御の難しさ**

最初は以下のような単純な方法を試みた:
```verilog
for (i = 0; i < MAX_NUM; i = i + 1) begin
    @(posedge i1.ENABLE);
    @(negedge clk);
    // 検証...
end
```

しかし、初回のループでclkがLowの状態からスタートすると、`@(negedge clk)`が即座に検出されてしまう問題が発生。

**解決策**: 初回をループ外で処理
```verilog
// 初回（ループ外）
@(posedge i1.ENABLE);
@(negedge clk);
// 検証...

// 2回目以降（ループ内）
for (i = 1; i < MAX_NUM; i = i + 1) begin
    @(negedge i1.ENABLE);
    cnt_value_ref = ref[i];
    @(posedge i1.ENABLE);
    @(negedge clk);
    // 検証...
end
```

#### 検証結果

```
シミュレーション実行：
- テストパターン: 86,400件
- 実行時間: 約30分（SIM_SEC1_MAX=4で高速化）
- 結果: Total OK steps = 86400 ✅

実機テスト：
- 00:00:00 から 23:59:59 まで正常動作確認
- carry連鎖の正確性確認
- ダイナミック点灯の動作確認
```

#### 学んだこと

1. **carry連鎖の設計**:
   - 組み合わせ回路によるcarry生成
   - 同期カウンタの重要性

2. **大規模検証の方法**:
   - C言語による自動データ生成
   - テストベンチの自動化

3. **タイミング制御の重要性**:
   - `@(negedge)`と`@(posedge)`の使い分け
   - リファレンスの先読みテクニック

4. **===演算子の重要性**:
   - 不定値の確実な検出
   - 初期化忘れの発見

---

### Phase 3: 年月日曜日カウンタ（開発期間：2週間）

**目的**: 複雑なカレンダーロジックの実装

#### 実装モジュール

```
P3_CNT_DAY.v         - 日カウンタ（月ごとの日数対応）
P3_CNT_MONTH.v       - 月カウンタ（1-12月）
P3_CNT_YEAR.v        - 年カウンタ（2000-2100年）
P3_leap_year.v       - うるう年判定
P3_weekday_calc.v    - 曜日計算（ブロックRAM使用）
P3_LED_WEEK.v        - 曜日LED表示
P3_SEC1.v            - 1秒クロック生成
P3_CNT_DMY.v         - 統合モジュール
P3_TEST_CNT_DMY.v    - テストベンチ
P3_DMY_ref.c         - リファレンスデータ生成
P3_weekday.c         - 曜日計算（Zellerの公式）
P3_weekday_coe.c     - .coeファイル生成
```

#### 実装の難所

**1. うるう年判定**:

```verilog
module leap_year(year_bcd, is_leap);
    input [11:0] year_bcd;   
    output is_leap;
    
    wire [3:0] ones = year_bcd[3:0];   
    wire [3:0] tens = year_bcd[7:4];   
    wire [3:0] hunds = year_bcd[11:8];  
    
    // 4で割り切れるか判定（掛け算なし）
    wire ones_div4 = (ones == 4'h0) || (ones == 4'h4) || (ones == 4'h8);
    wire tens_even = ~tens[0]; 
    wire ones_div4_2 = (ones == 4'h2) || (ones == 4'h6);
    wire tens_odd = tens[0]; 
    wire div4 = ((ones_div4 && tens_even) || (ones_div4_2 && tens_odd));
    
    // 100で割り切れない、または400で割り切れる
    assign is_leap = div4 && ~(hunds == 4'h1);
endmodule
```

**ルール**:
- 4で割り切れる年 → うるう年
- ただし、100で割り切れる年 → 平年
- ただし、400で割り切れる年 → うるう年

**例**:
- 2000年: 400で割り切れる → うるう年 ✅
- 2004年: 4で割り切れる → うるう年 ✅
- 2100年: 100で割り切れる → 平年 ❌

**2. 月ごとの日数処理**:

```verilog
// CNT_DAY.vの一部
always @(CNT10 or CARRY_in or CNT4 or month or is_leap) begin  
    if ((((month == 8'h04 || month == 8'h06 || month == 8'h09 || month == 8'h11) 
            && ({CNT4, CNT10} == 8'h30)) ||           // 4,6,9,11月は30日
        ((month == 8'h02) && ((is_leap == 1'b0) && 
            ({CNT4, CNT10} == 8'h28))) ||              // 2月は28日（平年）
        (({CNT4, CNT10} == 8'h31) || (CNT10 == 4'h9))) // その他は31日
        && CARRY_in == 1'b1) 
        CARRY <= 1'b1; 
    else 
        CARRY <= 1'b0;       
end
```

**3. 曜日計算の最適化**:

当初、Zellerの公式を直接実装しようとしたが：

```verilog
// 問題のある実装（Critical Pathが長い）
h = (q + (13*(m+1))/5 + K + K/4 + J/4 - 2*J) mod 7;
// 除算、剰余演算が必要 → 大量のLUT消費
```

**解決策**: ブロックRAMによるルックアップテーブル

手順：
1. C言語で2000-2100年の各月1日の曜日を計算（weekday.c）
2. .coeファイルを生成（weekday_coe.c）
3. Vivado IP CatalogでブロックRAMを生成
4. .coeファイルを初期値として設定
5. Verilogで高速ルックアップ実装

```verilog
// weekday_calc.v
// アドレス計算（掛け算なし）
bram_addr = (year_bin << 3) + (year_bin << 2) + (month_bin - 1);
// year*12 = year*8 + year*4

// BRAMから1日の曜日を取得
bram_dout = weekday_bram[bram_addr];

// 実際の日の曜日を計算
weekday = (bram_dout + day_bin - 1) % 7;
```

#### リファレンスデータ生成

```c
// P3_DMY_ref.c
#include <stdio.h>

int main(void) {
    int year, month, day, yy, mm, dd, max_day, week_day;
    week_day = 6;  // 2000/1/1は土曜日
    FILE* fp = fopen("ref.hex", "w");
    
    for (year = 0; year <= 100; year++) {
        for (month = 1; month <= 12; month++) {
            // 月ごとの最大日数
            max_day = (month == 4 || month == 6 || month == 9 || month == 11) ? 30 :
                      (month == 2) ? ((year % 4 == 0) ? 
                                      ((year % 100 == 0) ? 
                                       ((year == 0) ? 29 : 28) : 29) : 28) : 31;
            
            for (day = 1; day <= max_day; day++) {
                // BCD形式に変換
                yy = ((year / 100) << 8) | (((year % 100) / 10) << 4) | (year % 10);
                mm = ((month / 10) << 4) | (month % 10);
                dd = ((day / 10) << 4) | (day % 10);
                
                // 曜日を含めて出力
                fprintf(fp, "%01X%03X%02X%02X\n", week_day, yy, mm, dd);
                week_day = (week_day + 1) % 7;
            }
        }
    }
    
    fclose(fp);
    return 0;
}
```

#### 検証結果

```
シミュレーション実行：
- テストパターン: 36,890件（2000/01/01 ～ 2100/12/31）
- 実行時間: 約45分
- 結果: Total OK steps = 36890 ✅

境界値テスト（重点6パターン）：
1. 2000/02/28 → 2000/02/29 ✅ (うるう年)
2. 2000/02/29 → 2000/03/01 ✅ (うるう年2月末)
3. 2001/02/28 → 2001/03/01 ✅ (平年、2月29日スキップ)
4. 2000/12/31 → 2001/01/01 ✅ (年またぎ)
5. 2099/12/31 → 2100/01/01 ✅ (世紀またぎ)
6. 2100/12/31 → 2000/01/01 ✅ (101年ロールオーバー)
```

#### 学んだこと

1. **複雑なロジックの分割**:
   - うるう年判定を独立モジュール化
   - 曜日計算を独立モジュール化
   - 各モジュールの単独テスト

2. **Critical Path最適化**:
   - ブロックRAMの活用
   - 掛け算を使わないアドレス計算
   - 組み合わせ回路の最適化

3. **境界値テストの重要性**:
   - 特殊ケースの動作確認
   - バグの早期発見

4. **C言語との連携**:
   - 複雑なリファレンスデータの生成
   - .coeファイルの生成
   - データフォーマットの変換

---

### Phase 4: 統合プロジェクト（開発期間：1週間）

**目的**: すべての機能を統合し、5機能を実装

#### 実装モジュール

```
P4_CLOCK_ALL.v       - トップモジュール
P4_MAIN_MODE.v       - 動作モード管理（5状態）
P4_SET_MODE.v        - 設定モード処理（7状態）
P4_DIS_MODE.v        - 表示切替処理（7状態）
P4_CNT60.v           - 60進カウンタ（設定機能追加）
P4_CNT24.v           - 24時間カウンタ（設定機能追加）
P4_CNT_DAY.v         - 日カウンタ（設定機能追加）
P4_CNT_MONTH.v       - 月カウンタ（設定機能追加）
P4_CNT_YEAR.v        - 年カウンタ（設定機能追加）
P4_MSE.v             - 統合入力処理
P4_DECODER7.v        - デコーダ（曜日表示対応）
P4_DCOUNT.v          - ダイナミック点灯制御
P4_display_switch.v  - 表示データ切替
P4_leap_year.v       - うるう年判定
P4_weekday_calc.v    - 曜日計算
P4_SEC1.v            - クロック生成
```

#### 状態遷移設計

**MAIN_MODE（動作モード）**:
```
L1: 時刻表示モード ←→ L2: 時刻設定モード
                    ↓
L3: アラームモード（実装予定）
                    ↓
L4: ストップウォッチモード（実装予定）
                    ↓
L5: タイマーモード（実装予定）
```

**SET_MODE（設定モード）**:
```
L1: 通常動作 → L2: 年設定 → L3: 月設定 → L4: 日設定 → 
L5: 時設定 → L6: 分設定 → L7: 秒設定 → L1: 完了
```

**DIS_MODE（表示切替）**:
```
L1: 年 → L2: 年月 → L3: 月曜日 → L4: 曜日日 → 
L5: 日時 → L6: 時分 → L7: 分秒 → L1
```

#### 設定機能の実装

**ワンホットエンコーディングの活用**:

```verilog
// CNT60.v（秒カウンタ）
input [1:0] SET_CURRENT_STATE;
// [0]: 通常動作中（L1状態）
// [1]: この桁を設定中（L7状態）

always @(posedge CLK or posedge RESET) begin 
    if (RESET == 1'b1) begin
        CNT10 <= 4'h0; 
    end
    // 通常動作 または 設定中
    else if (((ENABLE == 1'b1 && CARRY_in == 1'b1) && SET_CURRENT_STATE[0] == 1'b1) ||
             (SET_CURRENT_STATE[1] == 1'b1 && INC_MODE == 1'b1)) begin
        if (CARRY == 1'b1) 
            CNT10 <= 4'h0; 
        else 
            CNT10 <= CNT10 + 4'h1; 
    end 
end
```

**利点**:
- 7ビットの状態レジスタから必要な2ビットだけ受け取る
- 配線削減
- 高速な状態判定（単一ビットチェック）

#### 曜日表示の実装

**オリジナルパターンの設計**:

```verilog
// DECODER7.v
if(TOP_CURRENT_STATE == 1'b1 && DIS_CURRENT_STATE[0] == 1'b1 && 
   SA[3:2] == 2'b00) begin
    case(SA[1:0])
        2'b01:  // 1桁目
            case(COUNT)
                4'b0000: LED <= 8'b0011100_0; // U (日曜日)
                4'b0001: LED <= 8'b0011101_0; // O (月曜日)
                4'b0010: LED <= 8'b0011100_0; // U (火曜日)
                4'b0011: LED <= 8'b1001111_0; // E (水曜日)
                4'b0100: LED <= 8'b0010111_0; // H (木曜日)
                4'b0101: LED <= 8'b0000101_0; // R (金曜日)
                4'b0110: LED <= 8'b1110111_0; // A (土曜日)
            endcase
        2'b10:  // 2桁目
            case(COUNT)
                4'b0000: LED <= 8'b0011011_0; // S (日曜日)
                4'b0001: LED <= 8'b1110110_0; // M (月曜日)
                4'b0010: LED <= 8'b0001111_0; // T (火曜日)
                4'b0011: LED <= 8'b0101010_0; // W (水曜日)
                4'b0100: LED <= 8'b0001111_0; // T (木曜日)
                4'b0101: LED <= 8'b1000111_0; // F (金曜日)
                4'b0110: LED <= 8'b0011011_0; // S (土曜日)
            endcase
    endcase
end
```

**表示パターン**:
- 日曜: SU
- 月曜: MO
- 火曜: TU
- 水曜: WE
- 木曜: TH
- 金曜: FR
- 土曜: SA

#### 実機テスト結果

```
機能テスト：
1. 時刻表示モード ✅
   - 年月日曜日・時分秒の表示確認
   - うるう年の動作確認
   - 101年ロールオーバー確認

2. 時刻設定モード ✅
   - 各桁の個別設定確認
   - 点滅表示の確認
   - 設定完了後の動作確認

3. 表示切替 ✅
   - 7種類の表示パターン確認
   - 曜日表示の確認

4. 入力処理 ✅
   - ボタン入力の安定性確認
   - チャタリング除去の確認
   - エッジ検出の確認
```

---

## 検証戦略

### 全網羅テストの重要性

**なぜ全パターンテストが必要か**:

1. **人間が確認できない規模**:
   - 86,400秒 = 24時間
   - 36,890日 = 101年
   - 手作業での確認は不可能

2. **境界値の確実な動作**:
   - 59→00の遷移
   - 23→00の遷移
   - 月末→月初の遷移
   - 年末→年初の遷移

3. **バグの早期発見**:
   - どのパターンで失敗したか即座に特定
   - 修正後の再テストが容易

### テスト自動化の仕組み

```
┌─────────────────────────────────┐
│ 1. C言語でリファレンス生成      │
│    - すべてのパターンを列挙     │
│    - BCD形式で出力              │
│    - ref.hexファイルに保存      │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 2. Verilogテストベンチで読込    │
│    - $readmemh()で配列に格納    │
│    - シミュレーション実行       │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 3. 1パターンずつ検証            │
│    - 実装値 vs リファレンス値   │
│    - ===演算子で厳密比較        │
│    - 不一致ならエラー表示       │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ 4. 結果レポート                 │
│    - Total OK steps表示         │
│    - エラー時は詳細情報表示     │
└─────────────────────────────────┘
```

---

## テストベンチ実装

### タイミング制御の詳細

**ENABLE信号の役割**:

```
125MHz CLK: ▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁▔▁

tmp_count:  0  1  2  3  ...  124999998  124999999  0  1  2

ENABLE:     ▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▔▁▁▁▁▁▁▁▁▁
                                    ↑
                            1clkだけHigh
```

**検証タイミングの制御**:

```
┌─────────────────────────────────┐
│ @(negedge ENABLE)               │
│  - ENABLEの立ち下がり検出       │
│  - 次のENABLE立ち上がりまで待機 │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ cnt_value_ref = ref[i]          │
│  - リファレンスデータを先読み   │
│  - まだ回路は動いていない       │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ @(posedge ENABLE)               │
│  - ENABLEの立ち上がり検出       │
│  - この瞬間にカウンタが更新     │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ @(negedge clk)                  │
│  - clkの立ち下がりで確定待機    │
│  - 出力が安定                   │
└─────────────────────────────────┘
            ↓
┌─────────────────────────────────┐
│ if (cnt_value !== cnt_value_ref)│
│  - 厳密比較（===演算子）        │
│  - エラーならstop               │
└─────────────────────────────────┘
```

### ===演算子の重要性

**==演算子の問題**:
```verilog
reg [3:0] a = 4'bxxxx;  // 不定値
reg [3:0] b = 4'b0000;

if (a == b)  // true と判定される！
    $display("Equal");  // これが実行されてしまう
```

**===演算子の正しい動作**:
```verilog
reg [3:0] a = 4'bxxxx;  // 不定値
reg [3:0] b = 4'b0000;

if (a === b)  // false と判定される
    $display("Equal");  // 実行されない

// 不定値の検出
if (a === 4'bxxxx)  // true
    $display("Undefined");  // これが実行される
```

**実際の使用例**:
```verilog
if (cnt_value !== cnt_value_ref) begin
    // 不一致または不定値の場合
    $display("Error at step %d: cnt_value=%X expected=%X", 
             i, cnt_value, ref[i]);
    $display("Total OK steps = %d", ok_count);
    $stop;
end
else begin
    // 完全一致の場合
    ok_count = ok_count + 1;
end
```

---

## C言語との連携

### データ生成の自動化

**24時間データ生成**:

```c
// P2_CountReference.c
#include <stdio.h>

int main(void) {
    int h, m, s, hh, mm, ss;
    FILE* fp = fopen("ref.hex", "w");
    if (!fp) return 1;

    // 3重ループで全パターン生成
    for (h = 0; h < 24; h++) {
        for (m = 0; m < 60; m++) {
            for (s = 0; s < 60; s++) {
                // 10進数→BCD変換
                hh = ((h / 10) << 4) | (h % 10);
                mm = ((m / 10) << 4) | (m % 10);
                ss = ((s / 10) << 4) | (s % 10);
                
                // 16進数で出力
                fprintf(fp, "%02X%02X%02X\n", hh, mm, ss);
            }
        }
    }

    fclose(fp);
    return 0;
}

// 出力例：
// 000000
// 000001
// 000002
// ...
// 235958
// 235959
```

**年月日データ生成**:

```c
// P3_DMY_ref.c
for (year = 0; year <= 100; year++) {
    for (month = 1; month <= 12; month++) {
        // 月ごとの最大日数を計算
        max_day = calculate_max_day(year, month);
        
        for (day = 1; day <= max_day; day++) {
            // BCD変換
            yy = convert_to_bcd_year(year);
            mm = convert_to_bcd(month);
            dd = convert_to_bcd(day);
            
            // 曜日を含めて出力
            fprintf(fp, "%01X%03X%02X%02X\n", 
                    week_day, yy, mm, dd);
            week_day = (week_day + 1) % 7;
        }
    }
}
```

### .coeファイル生成

**曜日データ生成**:

```c
// P3_weekday.c
int zeller(int y, int m, int d) {
    int i, j, goukei = 0, w;
    
    // 1年1月1日からの経過日数を計算
    for (i = 1; i < y; i++) {
        for (j = 1; j <= 12; j++) {
            goukei += daysofmonth(i, j);
        }
    }
    for (j = 1; j < m; j++) {
        goukei += daysofmonth(y, j);
    }
    
    w = (goukei + d) % 7;
    return w;  // 0=日, 1=月, ..., 6=土
}

// 2000-2100年の各月1日の曜日を計算
for (year = 2000; year <= 2100; year++) {
    for (month = 1; month <= 12; month++) {
        w = zeller(year, month, 1); 
        fprintf(fp, "%X\n", w); 
    }
}
```

**.coeファイル変換**:

```c
// P3_weekday_coe.c
int main(void) {
    int val, count = 0;
    FILE *fin = fopen("weekday.txt", "r");
    FILE *fout = fopen("weekday.coe", "w");

    // .coeヘッダー
    fprintf(fout, "memory_initialization_radix=16;\n");
    fprintf(fout, "memory_initialization_vector=\n");

    // データ変換
    while (fscanf_s(fin, "%d", &val) == 1) {
        fprintf(fout, "%d", val);
        count++;
        if (count < 1212) {
            fprintf(fout, ",");  // カンマ区切り
        }
        if (count % 16 == 0) {
            fprintf(fout, "\n");  // 改行
        }
    }

    fprintf(fout, ";\n");  // 終端
    fclose(fin);
    fclose(fout);
    return 0;
}

// 出力例（weekday.coe）:
// memory_initialization_radix=16;
// memory_initialization_vector=
// 6,2,3,6,1,4,0,2,5,1,3,5,0,3,5,0,
// 4,6,2,4,0,2,5,0,3,6,1,4,6,2,4,6,
// ...
// ;
```

---

## デバッグ手法

### TCL Consoleでの可視化

**7セグメントLEDの描画**:

```verilog
// TEST_UPDOWN10.v
always @(LED) begin
    // LED[7:0]の各ビットをセグメントに対応
    for (j = 7; j >= 0; j = j - 1) begin
        case (j)
            7: if (LED[j] === TURN_ON) 
                   A_DISP = "----";  // セグメントA
               else 
                   A_DISP = "    ";
            6: if (LED[j] === TURN_ON) 
                   B_DISP = "| ";    // セグメントB
            // ... 他のセグメントも同様 ...
        endcase
    end
    
    // 7セグメントの形で表示
    #5
    $display("");
    $display("  %s", A_DISP);          // ----
    $display(" %s   %s", F_DISP, B_DISP);  // |  |
    $display("  %s", G_DISP);          // ----
    $display(" %s   %s", E_DISP, C_DISP);  // |  |
    $display("  %s    %s", D_DISP, Dp_DISP);  // ----  .
    $display("");
end
```

**出力例**:

```
数字「8」の表示:
  ----
 |    |
  ----
 |    |
  ----

数字「0」の表示:
  ----
 |    |
     
 |    |
  ----
```

### 波形解析

**重要な観察ポイント**:

1. **ENABLE信号**:
   - 1秒に1回だけHighになっているか
   - パルス幅は1clkか

2. **carry信号連鎖**:
   - 秒→分→時の順にcarryが伝播しているか
   - 同じCLKエッジで判定されているか

3. **カウント値**:
   - BCD形式で正しくカウントされているか
   - carry発生時に正しく0に戻るか

4. **状態遷移**:
   - ワンホット形式で遷移しているか
   - 複数ビットが同時にHighになっていないか

---

## 品質保証

### 境界値テスト

**6つの重点テストパターン**:

1. **2000/02/28 23:59:59 → 2000/02/29 00:00:00**
   - うるう年の2月末 → 2月29日への遷移
   - is_leap = 1の確認
   - 29日が正しく存在することの確認

2. **2000/02/29 23:59:59 → 2000/03/01 00:00:00**
   - うるう年の2月29日 → 3月への遷移
   - 月またぎの確認
   - 曜日の正確性確認

3. **2001/02/28 23:59:59 → 2001/03/01 00:00:00**
   - 平年の2月末 → 3月への遷移
   - is_leap = 0の確認
   - 2月29日がスキップされることの確認

4. **2000/12/31 23:59:59 → 2001/01/01 00:00:00**
   - 年またぎ
   - 年・月・日・時・分・秒すべてがリセット
   - 曜日の正確性確認

5. **2099/12/31 23:59:59 → 2100/01/01 00:00:00**
   - 世紀またぎ
   - 2100年はうるう年ではないことの確認
   - 101年目への遷移

6. **2100/12/31 23:59:59 → 2000/01/01 00:00:00**
   - 101年のロールオーバー
   - 正しく2000年に戻ることの確認
   - 曜日の正確性確認

### コードレビュー

**チェックポイント**:

1. **同期設計**:
   - すべてのFFが同じCLKで動作しているか
   - 非同期リセットは適切に使用されているか

2. **組み合わせ回路**:
   - ラッチが生成されていないか
   - すべてのケースがカバーされているか

3. **タイミング**:
   - セットアップ/ホールドタイム違反はないか
   - Critical Pathは許容範囲内か

4. **リソース使用**:
   - 不要なLUTが生成されていないか
   - BRAMは効率的に使用されているか

---

この開発プロセスドキュメントは、プロジェクトの進め方、検証方法、デバッグ手法を詳細に記録したものです。就職活動において、組織的な開発能力、品質保証への意識、問題解決能力をアピールする材料として活用できます。

次のドキュメント:
- [モジュール仕様](./MODULES.md) - 各モジュールの詳細仕様
- [検証レポート](./VERIFICATION.md) - テスト結果、境界値テスト
