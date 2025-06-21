# FlowRegex C Implementation

FlowRegexのC言語実装版です。Ruby版と同じフロー正規表現法のアルゴリズムを高性能なC言語で実装しています。

**注意: これはテスト実装（PoC）です。本番環境での使用は想定していません。**

## 特徴

- **高性能**: C言語による最適化された実装
- **MatchMask最適化**: OptimizedTextによる事前計算で1.6x〜2.5xの性能向上
- **Shift操作排除**: 64ビットワード単位での効率的なビットマスク操作
- **メモリ効率**: 効率的なビットマスク操作
- **ReDoS耐性**: 線形時間保証による安全性
- **ポータブル**: 標準C99準拠

## ビルド方法

### 必要な環境
- GCC 4.9以上 (C99サポート)
- Make
- 標準Cライブラリ

### コンパイル

```bash
# 基本ビルド
make

# デバッグビルド
make debug

# リリースビルド（最適化）
make release

# テスト実行
make test

# クリーンアップ
make clean
```

### 追加ツール（オプション）

```bash
# 静的解析
make analyze

# メモリリークチェック（Valgrind必要）
make memcheck
```

## 使用方法

### コマンドライン

```bash
# 基本的な使用法
./flowregex "pattern" "text"

# デバッグモード
./flowregex -d "pattern" "text"

# ヘルプ表示
./flowregex -h
```

### 使用例

```bash
# リテラルマッチング
./flowregex "abc" "xabcyz"
# 出力: Match end positions: [4]

# クリーネ閉包
./flowregex "a*b" "aaab"
# 出力: Match end positions: [1, 2, 3, 4]

# 選択
./flowregex "a|b" "cat"
# 出力: Match end positions: [2, 3]

# 文字クラス
./flowregex "\\d+" "abc123def"
# 出力: Match end positions: [4, 5, 6]

# デバッグモード
./flowregex -d "a+" "aaa"
# ビットマスクの変化過程を表示
```

## API仕様

### 基本的な使用法

```c
#include "flowregex.h"

int main() {
    flowregex_error_t error;
    
    // 正規表現の作成
    flowregex_t *regex = flowregex_create("a+b", &error);
    if (!regex) {
        printf("Error: %s\n", flowregex_error_string(error));
        return 1;
    }
    
    // マッチング実行
    match_result_t *result = flowregex_match(regex, "aaab", false);
    if (result) {
        printf("Matches found: %zu\n", result->count);
        for (size_t i = 0; i < result->count; i++) {
            printf("Position: %d\n", result->positions[i]);
        }
    }
    
    // クリーンアップ
    match_result_destroy(result);
    flowregex_destroy(regex);
    
    return 0;
}
```

### 主要な関数

#### FlowRegex作成・破棄
```c
flowregex_t *flowregex_create(const char *pattern, flowregex_error_t *error);
void flowregex_destroy(flowregex_t *regex);
```

#### マッチング実行
```c
match_result_t *flowregex_match(flowregex_t *regex, const char *text, bool debug);
```

#### 結果処理
```c
match_result_t *match_result_create(void);
void match_result_destroy(match_result_t *result);
void match_result_add(match_result_t *result, int position);
```

#### エラーハンドリング
```c
const char *flowregex_error_string(flowregex_error_t error);
void flowregex_print_error(flowregex_error_t error);
```

## サポートする正規表現構文

### 基本構文
- **リテラル**: `a`, `b`, `c`
- **任意の文字**: `.` (改行以外)
- **連接**: `ab`
- **選択**: `a|b`
- **グループ化**: `(ab)`

### 量指定子
- **クリーネ閉包**: `a*` (0回以上)
- **プラス**: `a+` (1回以上)
- **クエスチョン**: `a?` (0回または1回)

### 文字クラス
- **数字**: `\d` (0-9), `\D` (数字以外)
- **空白**: `\s` (空白文字), `\S` (空白以外)
- **単語文字**: `\w` (英数字_), `\W` (単語文字以外)

### エスケープシーケンス
- **改行**: `\n`
- **タブ**: `\t`
- **キャリッジリターン**: `\r`
- **バックスラッシュ**: `\\`
- **ピリオド**: `\.`

## アーキテクチャ

### ファイル構成
```
c_implementation/
├── Makefile              # ビルド設定
├── README.md            # このファイル
├── src/                 # ソースコード
│   ├── flowregex.h      # メインヘッダー
│   ├── flowregex.c      # メイン実装
│   ├── bitmask.c        # ビットマスク操作
│   ├── regex_elements.c # 正規表現要素
│   ├── parser.c         # パーサー
│   └── main.c           # コマンドライン実行
└── tests/               # テストコード
    └── test_flowregex.c # 単体テスト
```

### 主要コンポーネント

#### BitMask
- 64ビット整数配列による効率的なビット操作
- 位置集合の管理とビット演算

#### RegexElement
- 正規表現の各要素を関数として実装
- 関数合成による処理の組み合わせ

#### Parser
- 再帰下降パーサーによる正規表現解析
- エラーハンドリングと構文チェック

## 性能特性

### 計算量
- **時間計算量**: O(N×M) (N: 文字列長, M: パターン長)
- **空間計算量**: O(N) (文字列長に比例)
- **ReDoS攻撃**: 線形時間保証により完全耐性

### メモリ使用量
- ビットマスク: 文字列長/8 バイト
- パターン解析木: パターンサイズに比例
- 作業領域: 最小限の一時的メモリ

## 最適化の詳細

### MatchMask最適化
- **OptimizedText**: 文字列の各文字に対する事前計算されたビットマスクを生成
- **性能向上**: 1.6x〜2.5xの処理速度向上を実現
- **メモリ効率**: 文字種ごとのマッチマスクをキャッシュして再利用

### Shift操作の排除
- **64ビットワード単位処理**: ビットマスクを64ビット単位で効率的に操作
- **ビット演算最適化**: シフト操作を排除してCPUキャッシュ効率を向上
- **並列処理**: 複数ビットを同時に処理する最適化

## 制限事項

- **文字列長上限**: 100000文字（FLOWREGEX_MAX_TEXT_LENGTH で設定変更可能）
- **Unicode**: 基本的なASCII文字のみサポート
- **高度な機能**: 後方参照、先読み等は未実装
- **テスト実装**: 本番環境での使用は想定していません

## テスト

### テスト実行
```bash
make test
```

### テスト内容
- 基本的なリテラルマッチング
- 量指定子（*, +, ?）
- 選択とグループ化
- 文字クラス
- エラーハンドリング
- ビットマスク操作

### テスト結果例
```
=== FlowRegex C Implementation Tests ===

Running test: literal_matching... PASSED
Running test: alternation... PASSED
Running test: kleene_star... PASSED
Running test: plus_quantifier... PASSED
Running test: question_quantifier... PASSED
Running test: any_character... PASSED
Running test: character_classes... PASSED
Running test: grouping... PASSED
Running test: complex_pattern... PASSED
Running test: error_handling... PASSED
Running test: bitmask_operations... PASSED

=== Test Results ===
Tests run: 11
Tests passed: 11
🎉 All tests passed!
```

## 今後の拡張予定

### 高優先度
- **文字クラス拡張**: `[a-z]`, `[^abc]` 等の完全サポート
- **量指定子拡張**: `{n}`, `{n,m}` の実装
- **Unicode対応**: UTF-8文字列の処理

### 性能最適化
- **SIMD最適化**: ビット演算の並列化
- **メモリプール**: 動的メモリ割り当ての最適化
- **コンパイル時最適化**: パターンの事前解析

### 機能拡張
- **先読み演算子**: `(?=...)`, `(?!...)` の実装
- **2段階マッチング**: 部分文字列抽出機能
- **ファジーマッチング**: 編集距離対応

## ライセンス

TBD (To Be Determined)

## 作者

Atsushi Yamamoto
