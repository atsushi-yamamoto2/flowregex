# FlowRegex - フロー正規表現法による正規表現ライブラリ（POC版）

FlowRegexは、従来のオートマトンベースのアプローチとは根本的に異なる、新しい正規表現マッチングアルゴリズム「フロー正規表現法」を実装したRubyライブラリです。

## Abstract (概要)

本研究では、従来のオートマトン理論に依存しない革新的な正規表現マッチングアルゴリズム「フロー正規表現法」を提案する。本手法は、正規表現の各要素を「文字列終端位置の集合を変換する関数」として定義し、関数合成により全体のマッチング処理を実現する。ビットマスクによる位置集合管理と固定点収束理論により、ReDoS（Regular Expression Denial of Service）攻撃に対する理論的免疫を獲得し、いかなる入力に対しても線形時間での処理を保証する。

実験評価において、特定の攻撃パターン `(a|a|b)*$` に対して、Ruby正規表現エンジン（Onigmo）が3秒でタイムアウトする場面で、本手法は0.0001秒で処理を完了し、**29,000倍以上の性能向上**を達成した。また、文字列長に対する完全な線形スケーリングを実証し、大規模データ処理における予測可能な性能を提供する。

本手法は、セキュリティクリティカルなシステム、リアルタイム処理、ゲノム解析等の分野において、従来手法では困難な安全性と性能の両立を実現する。GPU並列処理との高い親和性により、将来的には1000倍を超える性能向上の可能性を秘めている。

---

We propose a novel regular expression matching algorithm called "Flow Regex Method" that fundamentally departs from traditional automaton-based approaches. Our method defines each regex component as a function that transforms sets of string end positions, achieving overall matching through function composition. By employing bitmask-based position set management and fixed-point convergence theory, we achieve theoretical immunity against ReDoS (Regular Expression Denial of Service) attacks and guarantee linear-time processing for any input.

In experimental evaluation, our method completed processing in 0.0001 seconds for the attack pattern `(a|a|b)*$` where Ruby's regex engine (Onigmo) timed out after 3 seconds, achieving **over 29,000× performance improvement**. We also demonstrated perfect linear scaling with respect to string length, providing predictable performance for large-scale data processing.

Our approach enables the coexistence of safety and performance that is difficult to achieve with conventional methods, particularly in security-critical systems, real-time processing, and genomic analysis. The high affinity with GPU parallel processing suggests potential for performance improvements exceeding 1000× in the future.

**⚠️ 重要: これはPOC（Proof of Concept）版です**
- 理論の実証が目的であり、パフォーマンスは最適化されていません
- 実用性よりも概念の理解と動作確認を重視した実装です
- 高速化やメモリ効率化は将来の課題として残されています

## フロー正規表現法の特徴

### 核心概念
- **関数合成による処理**: 各正規表現要素を「位置集合を変換する関数」として定義
- **ビットマスクによる位置管理**: 文字列の各位置でのマッチ可能性をビットマスクで効率的に管理
- **バックトラックなし**: 複数のマッチパスを並列処理し、ReDoS脆弱性を根本的に回避

### 従来手法との違い
| 手法 | 管理対象 | 特徴 |
|------|----------|------|
| Thompson NFA | 現在位置での状態集合 | 線形時間、バックトラックなし |
| DFA | 現在位置での単一状態 | 高速だが状態爆発の可能性 |
| バックトラック | 探索パスの履歴 | 表現力が高いがReDoS脆弱性 |
| **フロー正規表現法** | **マッチ終了位置の集合** | **関数合成、並列処理、ReDoS耐性** |

## インストール

```ruby
require_relative 'lib/flow_regex'
```

## 基本的な使用方法

```ruby
# 基本的なマッチング
regex = FlowRegex.new("abc")
result = regex.match("xabcyz")
# => [4] (位置4でマッチ終了)

# 複数マッチ
regex = FlowRegex.new("a")
result = regex.match("banana")
# => [2, 4, 6] (各'a'のマッチ終了位置)

# 選択パターン
regex = FlowRegex.new("cat|dog")
result = regex.match("I have a cat and a dog")
# => [12, 22]

# クリーネ閉包
regex = FlowRegex.new("a*b")
result = regex.match("aaab")
# => [4]

# デバッグモード
regex = FlowRegex.new("a*|b")
result = regex.match("aab", debug: true)
# ビットマスクの変化過程を表示
```

## サポートする正規表現構文

現在のPOC版では以下の構文をサポート：

### 基本構文
- **リテラル**: `a`, `b`, `c` など
- **任意の文字**: `.` (改行以外の任意の文字)
- **連接**: `ab` (aの後にb)
- **選択**: `a|b` (aまたはb)
- **グループ化**: `(ab)` (グループ化)

### 量指定子
- **クリーネ閉包**: `a*` (aの0回以上の繰り返し)
- **プラス**: `a+` (aの1回以上の繰り返し)
- **クエスチョン**: `a?` (aの0回または1回)
- **固定回数**: `a{3}` (aの3回ちょうど)
- **範囲指定**: `a{2,4}` (aの2回から4回)
- **下限指定**: `a{2,}` (aの2回以上)

### 文字クラス
- **数字**: `\d` (0-9), `\D` (数字以外)
- **空白**: `\s` (空白文字), `\S` (空白以外)
- **単語文字**: `\w` (英数字_), `\W` (単語文字以外)
- **範囲指定**: `[a-z]`, `[A-Z]`, `[0-9]`
- **個別指定**: `[abc]`, `[123]`
- **複合指定**: `[a-z0-9]`, `[A-Za-z]`
- **文字クラス内エスケープ**: `[\d\s]`, `[\w@]`, `[a-z\d]`
- **否定**: `[^abc]`, `[^\d\s]` (指定文字以外)

### 先読み演算子（積集合・補集合）
- **肯定先読み**: `(?=B)A` (Aの積集合B、同じ開始位置でBとAの両方がマッチ)
- **否定先読み**: `(?!B)A` (AからBの差集合、同じ開始位置でBがマッチしない場合のみA)
- **任意位置対応**: 文字列の先頭以外でも動作
- **複数開始位置**: 複数の開始位置での正確な集合演算

### ファジーマッチング（編集距離対応）
- **基本ファジーマッチ**: `fuzzy_match(text, max_distance: n)`
- **編集操作**: 置換・挿入・削除をサポート
- **距離制限**: 指定した編集距離以内のマッチを検出
- **完全性保証**: ヒューリスティックではない厳密解

### エスケープシーケンス
- **改行**: `\n`, **タブ**: `\t`
- **キャリッジリターン**: `\r`
- **バックスラッシュ**: `\\`

### 複合パターン例
```ruby
# 複数の量指定子の組み合わせ
FlowRegex.new("a+b?c*").match("aaabccc")
# => [1, 2, 3, 4, 5, 6, 7]

# グループ化と量指定子
FlowRegex.new("(ab){2,3}").match("ababab")
# => [4, 6]

# 先読み演算子（積集合・補集合）
FlowRegex.new("(?=ab)ab*c").match("abbbcd")
# => [5] (abで始まる場合のab*c)

FlowRegex.new("(?!abc)ab*c").match("abbbcd")
# => [5] (abcで始まらない場合のab*c)

# ファジーマッチング（編集距離対応）
FlowRegex.new("hello").fuzzy_match("helo", max_distance: 1)
# => {1=>[4]} (1文字削除でマッチ)

FlowRegex.new("cat").fuzzy_match("bat", max_distance: 1)
# => {1=>[3]} (1文字置換でマッチ)
```

## 実装アーキテクチャ

```
FlowRegex
├── BitMask            # ビットマスク操作
├── TrackedBitMask     # 開始位置追跡ビットマスク（先読み用）
├── RegexElement       # 変換関数の基底クラス
├── Literal            # 文字リテラル変換関数
├── Concat             # 連接変換関数（関数合成）
├── Alternation        # 選択変換関数（並列処理）
├── KleeneStar         # クリーネ閉包変換関数（収束処理）
├── Quantifier         # 汎用量指定子変換関数
├── CharacterClass     # 文字クラス変換関数
├── AnyChar            # 任意文字変換関数
├── PositiveLookahead  # 肯定先読み変換関数（積集合）
├── NegativeLookahead  # 否定先読み変換関数（差集合）
├── FuzzyBitMask       # ファジーマッチング用3次元ビットマスク
├── FuzzyLiteral       # ファジーマッチング対応文字リテラル
├── FuzzyMatcher       # ファジーマッチングエンジン
├── Parser             # 正規表現パーサー（先読み対応）
├── Matcher            # データフローエンジン
└── TwoStageMatcher    # 2段階マッチング（部分文字列抽出）
```

## 制限事項（POC版）

- 文字列長上限: 1000文字
- **Unicode対応**: 日本語（ひらがな・カタカナ・漢字）は動作確認済み
- 後方参照（`\1`, `\2`）未対応
- **先読み計算量**: 先読み演算子使用時のみ最悪ケースでO(N²)に増加（複数開始位置での集合演算のため）
- 後読み未対応
- 非貪欲マッチ未対応
- 位置マッチ（`^`, `$`, `\b`）未対応

## 性能特性と優位性

### フロー正規表現法が真価を発揮する場面

1. **ReDoS攻撃パターン**: 従来手法が指数時間になる場合でも線形時間を保証
2. **複雑なネストパターン**: バックトラック爆発を回避
3. **大規模データ処理**: GPU並列処理との高い親和性
4. **複数文字列同時処理**: 個別処理ではなく同時処理が可能

### 計算量比較

| シナリオ | 従来手法 | フロー正規表現法 | 優位性 |
|----------|----------|------------------|--------|
| 単純パターン | O(N) | O(N×M) | 劣る（POC段階） |
| ReDoS攻撃 | O(2^N) | O(N×M) | **指数的改善** |
| 複数文字列 | O(K×N×M) | O(N×M) | **K倍高速** |
| GPU並列処理 | 困難 | 高適性 | **1000倍期待** |

**注意**: POC版は概念実証が目的であり、単純なケースでは最適化されたRuby正規表現エンジンに劣ります。真の価値は理論的優位性と将来の拡張可能性にあります。

## ファジーマッチングへの革新的適用

フロー正規表現法の最も革新的な応用可能性は、**ファジーマッチング（曖昧検索）**分野にあります。

### ゲノム解析での革命的価値

**現在の課題:**
- **BLAST**: ヒューリスティック手法、完全性に限界
- **BWA/Bowtie**: 大量インデックス必要、メモリ消費大
- **従来ファジーマッチ**: 指数時間の危険性、ReDoS脆弱性

**フロー正規表現法の優位性:**
- **線形時間保証**: ミスマッチ数に関係なく安定した性能
- **インデックス不要**: リアルタイム処理が可能
- **GPU完全対応**: 1000倍超の並列化効果が期待
- **理論的完全性**: ヒューリスティックではない厳密解

### 多次元ビットマスク拡張

```
従来: BitMask[position] = 0/1
拡張: BitMask[position][mismatch_count] = 0/1
```

この拡張により、各位置でのミスマッチ数を同時追跡し、編集距離を考慮したマッチングを線形時間で実現します。

### 応用分野

1. **個人ゲノム医療**: リアルタイム変異検出・薬剤感受性予測
2. **感染症対策**: ウイルス変異株の即座特定・薬剤耐性菌検出  
3. **進化生物学**: 大規模比較ゲノム解析・古代DNA研究
4. **バイオインフォマティクス**: 次世代シーケンサーデータ解析

### 技術的実現性

**段階的アプローチ:**
- **Phase 1**: 置換ミスマッチのみ（最も実装容易）
- **Phase 2**: 挿入・削除の追加（編集距離対応）
- **Phase 3**: GPU並列実装（大規模データ対応）
- **Phase 4**: 実ゲノムデータでの検証・最適化

この革新により、計算生物学に新しいパラダイムをもたらす可能性があります。

## 将来の拡張予定

### 高優先度: ファジーマッチング対応
- **ゲノム解析革命**: SNP検出、変異株特定、個人ゲノム解析
- **多次元ビットマスク**: 位置×ミスマッチ数の2次元管理
- **編集距離対応**: 置換・挿入・削除を統合したファジーマッチング
- **リアルタイム変異検出**: インデックス不要の高速ファジー検索

### 技術的拡張
- **GPU並列処理**: ビットマスク操作のGPU最適化
- **スパースビットマップ**: 大規模ファジーマッチング用メモリ最適化
- **曖昧検索エンジン**: 自然言語処理・情報検索への応用
- **メモリ最適化**: 圧縮技術による効率化

## テスト実行

```bash
ruby test/test_flow_regex.rb
```

## 使用例実行

```bash
ruby examples/basic_usage.rb
```

## 理論的背景

フロー正規表現法は以下の数学的概念に基づいています：

1. **関数合成**: `f ∘ g` による正規表現要素の結合
2. **固定点理論**: クリーネ閉包の収束処理
3. **集合演算**: ビット単位OR/ANDによる位置集合操作
4. **並列処理**: 複数マッチパスの同時実行

この手法により、従来のオートマトン理論に依存しない、新しい正規表現処理パラダイムを実現しています。

## 先行研究

### 正規表現関数による拡張（2003年）
本研究の理論的基盤は、山本篤による2003年の研究に基づいています：

**山本篤 (2003)**. "正規表現関数による正規表現の拡張とそのパターンマッチングへの応用". 情報処理学会論文誌 44(7), 1756-1765.

この研究では、正規表現を「文字列終端位置の集合を変換する関数」として定義する理論的枠組みが提案され、関数合成による正規表現処理の基礎が確立されました。本実装は、この20年前の理論を現代的なビットマスク演算と組み合わせて実用化したものです。

### 微分ベース正規表現マッチング（2025年）
最近の関連研究として、微分ベースの正規表現マッチングにおける積集合・補集合・先読み演算子の実装があります：

**Ian Erik Varatalu, Margus Veanes, and Juhan Ernits (2025)**. "RE#: High Performance Derivative-Based Regex Matching with Intersection, Complement, and Restricted Lookarounds". Proc. ACM Program. Lang. 9, POPL, Article 1. https://doi.org/10.1145/3704837

この研究では、Brzozowski微分を用いた記号的アプローチで積集合・補集合・制限付き先読みを実装し、入力線形時間での処理を実現しています。理論的基盤は異なりますが、本研究と同様の機能（積集合・補集合演算）を提供する並行研究として注目されます。

### 理論的関連性

両研究は**本質的に同じ理論的基盤**を持つ可能性があります：

**共通する核心概念:**
- 位置ベースの処理（文字列の位置を基準とした演算）
- 関数的アプローチ（正規表現要素を関数として扱う）
- 合成による構築（小さな要素から大きなパターンを構築）
- 集合演算の直接的サポート（積集合・補集合）

**表現の違い:**
- **FlowRegex法（2003年基盤）**: 「文字列終端位置の集合を変換する関数」
- **Brzozowski微分**: 「正規表現の微分による状態遷移」

これらは同一の数学的概念を異なる用語で表現している可能性があります。両手法とも従来のオートマトン理論を超越し、積集合・補集合演算を効率的に実現する新しいパラダイムを示しています。

## ライセンス

TBD (To Be Determined)

## 作者

Atsushi Yamamoto
