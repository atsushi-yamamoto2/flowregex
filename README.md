# FlowRegex - フロー正規表現法による正規表現ライブラリ（POC版）

FlowRegexは、従来のオートマトンベースのアプローチとは根本的に異なる、新しい正規表現マッチングアルゴリズム「フロー正規表現法」を実装したRubyライブラリです。

## Abstract (概要)

本研究では、Brzozowski (1964)の正規表現微分理論を現代的なビットマスク演算で実装した正規表現マッチングライブラリ「FlowRegex」を提案する。60年前に提唱された微分理論は、オートマトン構築を経由せずに直接的な正規表現マッチングを可能とし、積集合・補集合演算を自然にサポートする優れた理論的基盤を持つ。本実装では、この理論をビットマスクによる位置集合管理と関数合成により実用化し、現代的課題に対応する。

特に重要な成果として、ReDoS（Regular Expression Denial of Service）攻撃に対する理論的免疫を獲得し、いかなる入力に対しても線形時間での処理を保証する。実験評価において、特定の攻撃パターン `(a|a|b)*$` に対して、Ruby正規表現エンジン（Onigmo）が3秒でタイムアウトする場面で、本手法は0.0001秒で処理を完了し、**29,000倍以上の性能向上**を達成した。

また、従来のフロー正規表現法の制約であった部分文字列抽出の問題を、2段階マッチングアプローチにより解決した。第1段階で高速スクリーニング（O(n)）により終了位置を特定し、第2段階で逆方向解析により開始位置を求めることで、O(n + k×m)の計算量で完全な部分文字列抽出を実現する。

さらに、ファジーマッチング拡張により、ゲノム解析分野への革新的応用を実現する。従来のBLAST等のヒューリスティック手法とは異なり、理論的に完全な類似検索を線形時間で提供し、GPU並列処理との高い親和性により、将来的には1000倍を超える性能向上の可能性を秘めている。

---

We present FlowRegex, a regular expression matching library that implements Brzozowski's (1964) derivative theory of regular expressions using modern bitmask operations. The derivative theory, proposed 60 years ago, provides an excellent theoretical foundation that enables direct regex matching without automaton construction and naturally supports intersection and complement operations. Our implementation makes this theory practical through bitmask-based position set management and function composition, addressing contemporary challenges.

A key achievement is theoretical immunity against ReDoS (Regular Expression Denial of Service) attacks, guaranteeing linear-time processing for any input. In experimental evaluation, our method completed processing in 0.0001 seconds for the attack pattern `(a|a|b)*$` where Ruby's regex engine (Onigmo) timed out after 3 seconds, achieving **over 29,000× performance improvement**.

Furthermore, through fuzzy matching extensions, we enable revolutionary applications in genomic analysis. Unlike conventional heuristic methods such as BLAST, we provide theoretically complete similarity search in linear time, with high affinity for GPU parallel processing suggesting potential for performance improvements exceeding 1000× in the future.

**⚠️ 重要: これはPOC（Proof of Concept）版です**
- 理論の実証が目的であり、パフォーマンスは最適化されていません
- 実用性よりも概念の理解と動作確認を重視した実装です
- 高速化やメモリ効率化は将来の課題として残されています

## フロー正規表現法の特徴

### 核心概念

FlowRegex は、**ブルゾフスキーの正規表現の導関数理論**を基盤としつつ、その概念を現代的な**ビットマスク操作による「位置の集合の変換」** として実装することで、非常に効率的かつ安全な正規表現マッチングを実現しています。

#### 1. 関数合成による処理：位置集合の変換

* FlowRegex では、正規表現の各要素（リテラル、連結、選択、閉包など）が、特定の入力パターンを処理する**「変換関数」**として定義されます。
* この「変換関数」は、現在のマッチング状態、つまり正規表現内のどの部分が現在マッチングの候補になっているかを示す**「位置の集合（ビットマスクで表現）」** を入力として受け取ります。
* そして、入力文字列から読み込んだ**単一の文字**を処理すると、その文字の消費に基づいて、受け取ったビットマスク（開始点の集合）を新しいビットマスク（次の活性化点の集合）へと変換します。

#### 2. ビットマスクによる位置管理：効率的な並列処理

* 特に「選択（`|`）」や「閉包（`*`）」のような、複数の可能性が同時に存在しうる要素では、FlowRegex はこれらの可能性を個別に計算し、その結果である**複数のビットマスクを論理和（OR結合）**することで、すべてのマッチングパスを**並行して**追跡します。
* これにより、従来のバックトラッキングで問題となる計算量の爆発を防ぎ、入力文字列の長さに比例した線形時間でのマッチング完了を保証します。

#### 3. バックトラックなし：ReDoS耐性の実現

* この「集合の変換」によるアプローチは、正規表現の処理状態が常に有限個のビットマスクで表現されるため、無限ループや指数関数的な計算量に陥るバックトラッキングの問題が発生しません。
* これが、FlowRegex が ReDoS (Regular Expression Denial of Service) 攻撃に対して理論的に免疫を持つ主な理由です。

要するに、FlowRegex は、従来の正規表現が「文字列を認識する機械」であったのに対し、それを「**状態の集合を効率的に変換していく機械**」として再構築していると言えます。

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

## 2段階マッチング：部分文字列抽出への対応

### 背景と課題

フロー正規表現法の制約として「マッチ開始位置の欠如」がありました。従来の実装では終了位置のみを返すため、`text.match(/pattern/)[0]` のような部分文字列抽出ができませんでした。

### 2段階アプローチによる解決

この制約に対して「終了位置から逆算する」アプローチを採用しました：

#### Step 1: 高速スクリーニング
```ruby
end_positions = flow_regex_match(pattern, text)
# フロー正規表現法でO(n)時間で終了位置を特定
```

#### Step 2: 逆方向解析
```ruby
for each end_pos in end_positions:
    # パターンを反転して開始位置を特定
    start_pos = reverse_match(pattern, text, end_pos)
    extract_substring(text, start_pos, end_pos)
```

### 性能特性

**計算量**: O(n + k×m)
- **Step 1**: O(n) - 全文字列の線形スキャン
- **Step 2**: O(k×m) - k個のマッチ × 平均マッチ長m

**効果的な適用場面**:
- マッチ数が少ない大規模データ（k << n の場合）
- ゲノム解析での希少パターン検索
- 大規模ログでの異常パターン抽出

### 従来手法との比較

| 項目 | Thompson NFA | 2段階フロー正規表現法 |
|------|-------------|---------------------|
| 時間計算量 | O(nm) | O(n + k×m) |
| 部分文字列抽出 | ✓ | ✓ |
| 大量データ処理 | 標準的 | マッチ数が少ない場合に有利 |

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

| シナリオ | DFA | Thompson NFA | バックトラック | フロー正規表現法 | 2段階フロー |
|----------|-----|-------------|-------------|------------------|------------|
| **単純パターン** | O(N) | O(N×M) | O(N×M) | O(N×M) | O(N + k×m) |
| **ReDoS攻撃** | O(N) | O(N×M) | O(2^N) | O(N×M) | O(N + k×m) |
| **複数文字列** | O(K×N) | O(K×N×M) | O(K×N×M) | O(N×M) | O(N + K×k×m) |
| **メモリ使用量** | O(2^M) | O(M) | O(M) | O(N) | O(N) |
| **構築時間** | O(2^M) | O(M) | O(M) | O(M) | O(M) |

### 各手法の特徴と得意分野

| 手法 | 得意分野 | 制約・弱点 | 適用場面 |
|------|----------|-----------|----------|
| **DFA** | 高速マッチング | 状態爆発、メモリ消費大 | 単純パターン、高頻度処理 |
| **Thompson NFA** | 安定性、ReDoS耐性 | やや低速 | 汎用的な正規表現処理 |
| **バックトラック** | 高機能（後方参照等） | ReDoS脆弱性 | 複雑な正規表現、小規模データ |
| **フロー正規表現法** | 並列処理、複数文字列 | 単純ケースで劣る | 大規模並列処理、GPU活用 |
| **2段階フロー** | 希少マッチ、部分文字列抽出 | マッチ数が多いと劣化 | ゲノム解析、ログ監視 |

### FlowRegexが真価を発揮する場面

1. **大規模データでの希少パターン検索** (k << N)
   - ゲノム解析: 数億文字中の数個の変異パターン
   - ログ監視: 大量ログ中の少数の異常パターン

2. **複数文字列の同時処理**
   - 従来: O(K×N×M) → FlowRegex: O(N×M)
   - K個の文字列を個別処理せず、並列処理で効率化

3. **ReDoS攻撃への完全耐性**
   - バックトラック型が指数時間になるパターンでも線形時間保証
   - セキュリティクリティカルなシステムでの安全性

4. **GPU並列処理との親和性**
   - ビットマスク演算の自然な並列化
   - 将来的に1000倍超の性能向上が期待

**注意**: POC版は概念実証が目的であり、単純なケースでは最適化された既存エンジンに劣ります。真の価値は特定領域での圧倒的優位性にあります。

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

**実装済み機能:**
- **Phase 1**: 置換ミスマッチ（実装完了）
- **Phase 2**: 挿入・削除の追加（実装完了）
- **多次元ビットマスク**: 位置×ミスマッチ数の2次元管理（実装完了）

**今後の拡張:**
- **Phase 3**: GPU並列実装（大規模データ対応）
- **Phase 4**: 実ゲノムデータでの検証・最適化

この革新により、計算生物学に新しいパラダイムをもたらす可能性があります。

## 高性能並列化アーキテクチャ

### MatchMask方式

フロー正規表現法をさらに発展させた並列化手法を構想中です。この手法は、従来のシフト演算を完全に排除し、事前計算されたMatchMaskとビット列の効率的な再利用により、劇的な性能向上を実現します。

#### 核心技術：MatchMask事前計算
```
文字列 S (長さN): "abcabc"
文字 'a' のMatchMask: [1,0,0,1,0,0]
文字 'b' のMatchMask: [0,1,0,0,1,0]
文字 'c' のMatchMask: [0,0,1,0,0,1]

リテラル L('a') の処理:
Mout = (Min AND Ma) << 1  →  Mout = Min AND Ma_offset
```

#### シフト演算の完全排除

**従来の問題**:
```c
// コストの高いシフト演算
result = (input & match_mask) << 1;
```

**革新的解決策**:
```c
// オフセット管理による論理的シフト
result = input & match_mask_with_offset;
current_offset++;  // 論理的位置管理
```

#### ビット列の効率的再利用

**クリーネ閉包の段階的処理**:
```c
// "a*" の処理 - 2つのビット列で効率的に管理
offset_mask_t current = {input_mask, offset=0};
offset_mask_t result = {input_mask, offset=0};  // 0回マッチ

do {
    offset_mask_t next = process_literal(current, 'a');
    result.bits |= next.bits;  // 累積
    current = next;            // ビット列再利用
} while (has_new_matches(next));
```

**選択の効率的処理**:
```c
// "a|b" - 同一オフセットでの並列処理
offset_mask_t left = process_literal(input, 'a');
offset_mask_t right = process_literal(input, 'b');
result.bits = left.bits | right.bits;  // 単純なOR結合
```

### 適用条件と効果的な場面

#### ✅ 高い効果が期待できる場面

**ゲノム解析（最適）**:
- **文字種**: 4種類（A,T,G,C）のみ → 事前走査が極めて効率的
- **文字列長**: 数百万〜数億文字
- **処理頻度**: 同一データへの反復解析
- **効果**: 事前走査コスト << 処理高速化

**同一文字列への反復処理**:
- **ログ監視**: リアルタイム異常検出
- **定期解析**: バッチ処理での反復パターン検索
- **効果**: 事前計算コストを完全に償却

**大量文字列の並行処理**:
- **数千〜数万の文字列を同時処理**
- **GPU並列処理**: 1000倍超の性能向上が期待
- **メモリ効率**: 連続アクセスパターンによる最適化

#### ⚠️ 効果が限定的な場面

**一回限りの処理**:
- 事前計算コストが処理時間を上回る可能性
- 小規模データでは従来手法が有利

**文字種が多い場合**:
- ASCII全体（256種）では事前走査コストが増大
- 頻出文字のみの選択的適用が効果的

### 実装戦略

#### 段階的適用
```c
// Phase 1: 頻出文字のみ対象
char frequent_chars[] = {'a', 'e', 'i', 'o', 'u', ' ', '\n'};
for (char c : frequent_chars) {
    precompute_match_mask(text, c);
}

// Phase 2: 全文字対応（条件付き）
if (text_reuse_count > threshold) {
    precompute_all_match_masks(text);
}
```

#### 適用判定アルゴリズム
```c
typedef struct {
    size_t text_length;
    size_t unique_chars;
    size_t expected_matches;
    bool is_repeated_processing;
} optimization_context_t;

bool should_use_match_mask(optimization_context_t* ctx) {
    // ゲノムデータ: 常に適用
    if (ctx->unique_chars <= 4) return true;

    // 反復処理: 閾値判定
    if (ctx->is_repeated_processing &&
        ctx->expected_matches > REPEAT_THRESHOLD) return true;

    // 一回限り: 慎重に判定
    return (ctx->text_length > LARGE_TEXT_THRESHOLD &&
            ctx->expected_matches > SINGLE_USE_THRESHOLD);
}
```

### 性能特性

#### 理論的優位性
- **数学的等価性**: 従来手法と完全に同じ結果を保証
- **シフト演算削除**: CPU命令数の大幅削減
- **並列化親和性**: SIMD/GPU処理との完全な親和性
- **メモリ効率**: 連続アクセスパターンによる最適化

#### 実用的制約
- **事前計算コスト**: O(N×文字種数×MAX_OFFSET)
- **メモリ使用量**: 文字種数 × MAX_OFFSET × 文字列長のビットマスク
- **適用判定**: 処理頻度とデータ特性による動的選択

#### 応用分野別の特性

**ゲノム解析での理想的条件**:
```
メモリ使用量: 4文字 × 100オフセット × (1M文字/64) ≈ 6.25KB
処理速度: 従来比100-1000倍の向上が期待
適用価値: 極めて高い
```

**一般テキスト処理**:
```
メモリ使用量: 256文字 × MAX_OFFSET × (文字列長/64)
処理速度: 条件次第で大幅向上
適用価値: データ特性と処理頻度に依存
```

この並列化手法により、特にゲノム解析分野において革命的な性能向上が期待されます。4種類の塩基対という理想的な条件下では、従来手法を大幅に上回る効率性を実現できます。

## 将来の拡張予定

### 高優先度: 並列化アーキテクチャの実装
- **MatchMask方式の実装**: CPU SIMD対応版の開発
- **GPU並列処理**: CUDA/OpenCL実装による大規模並列化
- **ハイブリッド実装**: データ特性に応じた自動判定・切り替え
- **プロファイリング**: 最適化判定の自動化

### ファジーマッチング機能の拡張
- **ゲノム解析への本格適用**: SNP検出、変異株特定、個人ゲノム解析
- **性能最適化**: 現在のPOC実装から実用レベルへの高速化
- **メモリ効率化**: 大規模ゲノムデータ対応のためのメモリ最適化
- **リアルタイム変異検出**: インデックス不要の高速ファジー検索の実用化

### 技術的拡張
- **スパースビットマップ**: 大規模ファジーマッチング用メモリ最適化
- **曖昧検索エンジン**: 自然言語処理・情報検索への応用
- **分散処理対応**: クラスター環境での大規模並列処理
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

## 理論的基盤と先行研究

### Brzozowski微分理論（1964年）
本研究の理論的基盤は、Janusz A. Brzozowskiによる1964年の古典的研究に基づいています：

**Janusz A. Brzozowski (1964)**. "Derivatives of Regular Expressions". Journal of the ACM 11(4), 481-494.  
論文リンク: https://dl.acm.org/doi/10.1145/321239.321249

この研究では、正規表現の「微分」という概念が導入され、文字に対する正規表現の微分を再帰的に定義することで、オートマトン構築を経由せずに直接的な正規表現マッチングが可能であることが示されました。特に重要なのは、この理論が積集合・補集合演算を自然にサポートすることです。

### 現代的実装への発展

#### 正規表現関数による実装（2003年）
**山本篤 (2003)**. "正規表現関数による正規表現の拡張とそのパターンマッチングへの応用". 情報処理学会論文誌 44(7), 1756-1765.  
論文リンク: https://cir.nii.ac.jp/crid/1050564287837265792

Brzozowski理論を「文字列終端位置の集合を変換する関数」として実装し、関数合成による正規表現処理の実用化を図った研究です。

#### 高性能微分ベース実装（2025年）
**Ian Erik Varatalu, Margus Veanes, and Juhan Ernits (2025)**. "RE#: High Performance Derivative-Based Regex Matching with Intersection, Complement, and Restricted Lookarounds". Proc. ACM Program. Lang. 9, POPL, Article 1.  
論文リンク: https://www.microsoft.com/en-us/research/wp-content/uploads/2025/01/popl25-p2-final.pdf

Brzozowski微分を記号的に実装し、積集合・補集合・制限付き先読みを高性能で実現した最新の研究です。

### 本研究の位置づけ

**FlowRegex**は、Brzozowski (1964)の微分理論を現代的なビットマスク演算で実装し、以下の現代的課題に対応します：

1. **ReDoS攻撃の完全防止**: 微分理論の線形時間保証により、いかなる入力に対しても安全
2. **ゲノム解析への応用**: ファジーマッチング拡張により、DNA配列の高速類似検索を実現
3. **GPU並列処理対応**: ビットマスク演算の並列性により、大規模データ処理に適用可能

### 理論の現代的意義

60年前のBrzozowski理論が現代において重要な理由：

- **セキュリティ**: ReDoS攻撃が深刻化する現代において、理論的に安全な正規表現エンジンが必要
- **ビッグデータ**: 大規模データ処理において、予測可能な線形時間性能が重要
- **バイオインフォマティクス**: ゲノムデータの爆発的増加により、高速な類似検索技術が必要
- **並列処理**: GPU/多コア処理が一般化した現代において、並列化可能なアルゴリズムが重要

## ライセンス

TBD (To Be Determined)

## 作者

Atsushi Yamamoto
