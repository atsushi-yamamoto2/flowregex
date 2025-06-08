# FlowRegex テスト実行ガイド

FlowRegexの良さ悪さを実際に体験するためのテスト方法を説明します。

## 基本テスト

### 1. 動作確認テスト
```bash
ruby test/test_flow_regex.rb
```
**期待結果**: 全てのテストが通ること（✓マーク）

### 2. 基本使用例
```bash
ruby examples/basic_usage.rb
```
**期待結果**: 様々なパターンのマッチング結果とデバッグ出力

## 性能比較テスト

### 3. ReDoS耐性テスト
```bash
ruby test/benchmark_redos.rb
```
**見るべきポイント**:
- FlowRegexは常に安定した時間
- Ruby正規表現は場合により変動（ただし現代版は対策済み）

### 4. 計算量分析テスト
```bash
ruby test/complexity_analysis.rb
```
**見るべきポイント**:
- 文字列長が増加してもFlowRegexの処理時間が線形増加
- 「線形性指標」が一定値を保つ

### 5. 極端なReDoS攻撃テスト
```bash
ruby test/extreme_redos_demo.rb
```
**見るべきポイント**:
- 恣意的な攻撃パターンでの動作
- FlowRegexの安定性

### 6. ReDoS対策回避テスト
```bash
ruby test/bypass_redos_protection.rb
```
**見るべきポイント**:
- 現代の対策を回避する巧妙な攻撃
- FlowRegexの根本的安全性

### 7. 高度な攻撃テスト
```bash
ruby test/advanced_redos_bypass.rb
```
**見るべきポイント**:
- 多項式時間攻撃での比較
- メモリ使用量の予測可能性

## 個別テスト方法

### 手動テスト1: 基本マッチング
```ruby
require_relative 'lib/flow_regex'

# 簡単なテスト
regex = FlowRegex.new("abc")
puts regex.match("xabcyz")  # => [4]

# デバッグモード
result = regex.match("xabcyz", debug: true)
# ビットマスクの変化過程が表示される
```

### 手動テスト2: 複雑なパターン
```ruby
require_relative 'lib/flow_regex'

# クリーネ閉包
regex = FlowRegex.new("a*b")
puts regex.match("aaab")    # => [4]
puts regex.match("b")       # => [1]
puts regex.match("aaaa")    # => []

# 選択
regex = FlowRegex.new("cat|dog")
puts regex.match("I have a cat")  # => [12]
```

### 手動テスト3: 攻撃パターン
```ruby
require_relative 'lib/flow_regex'
require 'benchmark'

# ReDoS攻撃パターン
attack_string = "a" * 30
pattern = "(a*)*b"

# FlowRegex
time1 = Benchmark.realtime do
  regex = FlowRegex.new(pattern)
  result = regex.match(attack_string)
end

# Ruby標準正規表現
time2 = Benchmark.realtime do
  result = attack_string.match(/(a*)*b/)
end

puts "FlowRegex: #{time1}秒"
puts "Ruby正規表現: #{time2}秒"
```

## 比較ポイント

### FlowRegexの良い点
1. **予測可能性**: 実行時間が常に線形
2. **安全性**: ReDoS攻撃が効かない
3. **デバッグ性**: ビットマスクの変化が見える
4. **理論的美しさ**: 関数合成による実装

### FlowRegexの悪い点（POC版）
1. **速度**: 単純なケースでRuby正規表現より遅い
2. **機能制限**: 基本的なパターンのみサポート
3. **文字列長制限**: 1000文字まで
4. **最適化不足**: 概念実証レベルの実装

### Ruby正規表現の良い点
1. **速度**: 高度に最適化されている
2. **機能豊富**: 後方参照、先読み等をサポート
3. **実績**: 長年の使用実績
4. **エコシステム**: 豊富なライブラリとツール

### Ruby正規表現の悪い点
1. **予測困難**: 入力により性能が大きく変動する可能性
2. **対症療法**: ReDoS対策は根本解決ではない
3. **複雑性**: 内部動作が複雑で理解困難

## 実験のアイデア

### 実験1: スケーリング特性
```bash
# 文字列長を変えて実行時間を測定
for size in 100 200 400 800; do
  echo "Testing with size: $size"
  # 適当なテストスクリプトを作成して実行
done
```

### 実験2: パターン複雑度
```ruby
# パターンの複雑さを変えて比較
patterns = [
  "a",
  "a*",
  "a*b*",
  "(a|b)*",
  "(a*b*)*"
]

patterns.each do |pattern|
  # 各パターンでの性能を測定
end
```

### 実験3: 攻撃耐性
```ruby
# 様々な攻撃パターンを試す
attacks = [
  "a" * 10,
  "a" * 20,
  "a" * 50,
  "a" * 100
]

attacks.each do |attack|
  # FlowRegexとRuby正規表現で比較
end
```

## 結果の見方

### 良い結果の例
- FlowRegexの実行時間が文字列長に比例
- 攻撃パターンでもFlowRegexが安定
- デバッグ出力でビットマスクの変化が理解できる

### 悪い結果の例
- FlowRegexがRuby正規表現より大幅に遅い（POC版では当然）
- エラーが発生する
- 期待した結果が得られない

## トラブルシューティング

### よくある問題
1. **文字列長制限エラー**: 1000文字以下にする
2. **パース エラー**: サポートされていない構文を使用
3. **予期しない結果**: デバッグモードで内部動作を確認

### デバッグ方法
```ruby
# デバッグモードを使用
regex = FlowRegex.new("a*b")
result = regex.match("aaab", debug: true)

# ビットマスクの変化を詳細に観察
```

実際に試してみて、疑問や発見があれば教えてください！
