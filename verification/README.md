# 検証用コード

このディレクトリには、FPGAデジタル時計プロジェクトの検証に使用したC言語プログラムが含まれています。

---

## 概要

**検証の目的**:
- すべての時刻パターンでの正確な動作を保証
- 人間が確認できない規模の自動検証
- バグの早期発見と修正

**検証規模**: 合計123,290パターン
- Phase 2: 86,400パターン（24時間）
- Phase 3: 36,890パターン（101年）

---

## ファイル一覧

### Phase 2: 24時間カウンタ検証

#### P2_CountReference.c
**機能**: 00:00:00 ～ 23:59:59の86,400パターンを生成

```c
// 3重ループで全パターン生成
for (h = 0; h < 24; h++) {
    for (m = 0; m < 60; m++) {
        for (s = 0; s < 60; s++) {
            // BCD形式に変換
            hh = ((h / 10) << 4) | (h % 10);
            mm = ((m / 10) << 4) | (m % 10);
            ss = ((s / 10) << 4) | (s % 10);
            
            // 16進数で出力（例：23:59:59 → 235959）
            fprintf(fp, "%02X%02X%02X\n", hh, mm, ss);
        }
    }
}
```

**出力ファイル**: `ref.hex`  
**フォーマット**: 1行に1パターン（6桁の16進数）  
**使用方法**: Verilogテストベンチで$readmemh()により読み込み

---

### Phase 3: 年月日曜日カウンタ検証

#### P3_DMY_ref.c
**機能**: 2000/01/01 ～ 2100/12/31の36,890パターンを生成

```c
week_day = 6;  // 2000/1/1は土曜日

for (year = 0; year <= 100; year++) {
    for (month = 1; month <= 12; month++) {
        // 月ごとの最大日数を計算（うるう年対応）
        max_day = calculate_max_day(year, month);
        
        for (day = 1; day <= max_day; day++) {
            // BCD変換 + 曜日を含めて出力
            yy = ((year / 100) << 8) | (((year % 100) / 10) << 4) | (year % 10);
            mm = ((month / 10) << 4) | (month % 10);
            dd = ((day / 10) << 4) | (day % 10);
            
            fprintf(fp, "%01X%03X%02X%02X\n", week_day, yy, mm, dd);
            week_day = (week_day + 1) % 7;
        }
    }
}
```

**出力ファイル**: `ref.hex`  
**フォーマット**: 1行に1パターン（曜日1桁 + 年3桁 + 月2桁 + 日2桁）  
**特徴**:
- うるう年の2月29日を正しく処理
- 月ごとの日数（28/29/30/31日）に対応
- 曜日の自動計算

#### P3_weekday.c
**機能**: 2000-2100年の各月1日の曜日を計算（Zellerの公式）

```c
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

**出力ファイル**: `weekday.txt`  
**フォーマット**: 1行に1個の曜日（0-6）  
**エントリ数**: 1,212個（101年 × 12ヶ月）

#### P3_weekday_coe.c
**機能**: `weekday.txt`をVivado用の.coeファイルに変換

```c
int main(void) {
    int val, count = 0;
    FILE *fin = fopen("weekday.txt", "r");
    FILE *fout = fopen("weekday.coe", "w");

    // .coeヘッダー
    fprintf(fout, "memory_initialization_radix=16;\n");
    fprintf(fout, "memory_initialization_vector=\n");

    // データ変換（カンマ区切り）
    while (fscanf_s(fin, "%d", &val) == 1) {
        fprintf(fout, "%d", val);
        count++;
        if (count < 1212) {
            fprintf(fout, ",");
        }
        if (count % 16 == 0) {
            fprintf(fout, "\n");
        }
    }

    fprintf(fout, ";\n");
    fclose(fin);
    fclose(fout);
    return 0;
}
```

**出力ファイル**: `weekday.coe`  
**用途**: Vivado IP Catalogでブロックメモリの初期値として使用  
**フォーマット**: Xilinx COE形式

---

### Phase 4: 統合プロジェクト検証

#### P4_weekday.c / P4_weekday_coe.c
Phase 3と同じコード。Phase 4でも曜日計算にブロックRAMを使用。

---

## 使用方法

### 1. コンパイル

```bash
# Phase 2のリファレンス生成
gcc P2_CountReference.c -o P2_CountReference
./P2_CountReference
# → ref.hex が生成される

# Phase 3のリファレンス生成
gcc P3_DMY_ref.c -o P3_DMY_ref
./P3_DMY_ref
# → ref.hex が生成される

# Phase 3の曜日データ生成
gcc P3_weekday.c -o P3_weekday
./P3_weekday
# → weekday.txt が生成される

gcc P3_weekday_coe.c -o P3_weekday_coe
./P3_weekday_coe
# → weekday.coe が生成される
```

### 2. Verilogテストベンチでの使用

```verilog
// テストベンチでリファレンスを読み込み
module TEST_CNT246060_ALL; 
    parameter MAX_NUM = 86400;
    reg [23:0] ref [0:MAX_NUM - 1]; 
    
    initial begin
        $readmemh("ref.hex", ref);  // C言語生成のファイルを読込
    end
    
    // 1パターンずつ検証
    for (i = 0; i < MAX_NUM; i = i + 1) begin
        // 実装値とリファレンス値を比較
        if (cnt_value !== ref[i]) begin
            $display("Error at step %d", i);
            $stop;
        end
    end
endmodule
```

---

## 検証の流れ

```
┌─────────────────────────────────┐
│ 1. C言語でリファレンス生成      │
│    - すべてのパターンを列挙     │
│    - BCD形式で出力              │
│    - .hexファイルに保存         │
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

## 検証結果

### Phase 2: 24時間カウンタ

```
Total test patterns:  86,400
Passed:               86,400 ✅
Failed:               0
Success rate:         100.00%
```

### Phase 3: 年月日曜日カウンタ

```
Total test patterns:  36,890
Passed:               36,890 ✅
Failed:               0
Success rate:         100.00%
```

### 総合

```
合計テストパターン: 123,290
合格パターン:       123,290 ✅
不合格パターン:     0
成功率:             100.00%
```

---

## 技術的ポイント

### 1. BCD（Binary-Coded Decimal）形式

10進数をそのまま2進数で表現する方法。

```c
// 23を BCD形式に変換
// 2 → 0010 (4bit)
// 3 → 0011 (4bit)
// 合計: 0x23 (8bit)

int h = 23;
int hh = ((h / 10) << 4) | (h % 10);  // 0x23
```

### 2. うるう年判定

```c
int is_leap(int year) {
    if (year % 4 != 0) return 0;      // 4で割り切れない → 平年
    if (year % 100 != 0) return 1;    // 100で割り切れない → うるう年
    if (year % 400 == 0) return 1;    // 400で割り切れる → うるう年
    return 0;                          // 100で割り切れる → 平年
}

// 例:
// 2000年: 400で割り切れる → うるう年
// 2004年: 4で割り切れる → うるう年
// 2100年: 100で割り切れる → 平年
```

### 3. 月ごとの日数

```c
int days_of_month(int year, int month) {
    switch(month) {
        case 1: case 3: case 5: case 7:
        case 8: case 10: case 12:
            return 31;
        case 4: case 6: case 9: case 11:
            return 30;
        case 2:
            return is_leap(year) ? 29 : 28;
    }
}
```

---

## まとめ

C言語による検証用コード生成は、以下の利点があります：

**利点**:
- ✅ 人間が確認できない規模の自動検証
- ✅ バグの早期発見
- ✅ 修正後の再テストが容易
- ✅ 100%の品質保証

**成果**:
- ✅ 123,290パターンの全網羅テスト成功
- ✅ すべてのパターンで正常動作を確認
- ✅ 実用レベルの品質を達成

この検証手法は、組込みシステム開発における品質保証の重要性を理解し、実践できる能力を示すものです。
