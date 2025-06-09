## FlowRegex: 関数合成とビットマスクによる高速かつReDoS耐性のある正規表現マッチング

### アブストラクト

本稿では、正規表現マッチングにおける従来のバックトラックに起因する**ReDoS（Regular expression Denial of Service）脆弱性**と**計算量爆発問題**に対し、根本的な解決策を提案する新たな手法「**FlowRegex（フロー正規表現法）**」を記述する。FlowRegex法は、正規表現を「文字列中の可能なマッチ位置の集合を、ビットマスクを用いて変換する**関数合成のパイプライン**」として再解釈する。各正規表現要素（リテラル、連接、選択、クリーネ閉包、文字クラス、アンカーなど）は、入力されたビットマスク（可能な開始位置の集合）を受け取り、対応する出力ビットマスク（可能な終了位置の集合）を生成する純粋関数として振る舞う。このデータフロー指向のアプローチにより、バックトラックを完全に排除し、入力文字列長に対して**線形時間計算量（O(N)）**でのマッチングを保証する。

また、FlowRegex法は計算の並列化に極めて適しており、GPUなどの並列処理アーキテクチャ上での高速化の可能性を秘める。従来の正規表現エンジンが苦手とする**POSIX互換の厳密な最長マッチ**も、ビットマスクから直接的に取得可能である。部分文字列の抽出については、FlowRegexで高速に特定された終了位置に対し、既存の正規表現エンジンまたはFlowRegex自体の逆方向マッチ機能を組み合わせた**二段階マッチング戦略**を導入することで、実用性を確保する。

本稿ではFlowRegex法の理論的基礎、アーキテクチャ、主要コンポーネントの実装について詳述し、プロトタイプ実装による実験を通じてその性能特性とReDoS耐性を実証する。本研究は、正規表現マッチング技術におけるパラダイムシフトを提示し、より安全で高性能なテキスト処理の基盤を築くことを目指す。**特に、その高い並列性から、ゲノム配列解析のような大規模なバイオインフォマティクスデータ処理におけるGPU演算への応用が期待される。**

---

### 全体構成案

#### 第1章 緒論 (Introduction)
* **1.1 はじめに (Overview)**
    * 正規表現の普及と重要性。
    * 既存の正規表現エンジンが抱える問題点（バックトラック、ReDoS脆弱性、計算量爆発）。
    * 本研究の目的：これらの課題を根本的に解決するFlowRegex法の提案。
* **1.2 関連研究 (Related Work)**
    * 有限オートマトン (DFA, NFA) と正規表現マッチングの基礎。
    * Thompsonの構成法、Glushkovの構成法、Position Automataなど。
    * ハイブリッドエンジン（DFA/バックトラック）の概要。
    * ReDoS対策の既存アプローチと限界。
* **1.3 本稿の構成 (Organization)**

---

#### 第2章 FlowRegex法の理論的基礎 (Theoretical Foundations of FlowRegex)
* **2.1 位置の集合としてのビットマスク (Bitmask as a Set of Positions)**
    * 文字列中の各文字位置をビットで表現する概念。
    * ビットマスクによる集合演算（OR, AND, COPY）の定義。
* **2.2 正規表現要素の関数合成 (Functional Composition of Regular Expression Elements)**
    * 各正規表現要素が「入力ビットマスクから出力ビットマスクへの変換関数」として機能する概念。
    * パイプライン処理としての正規表現マッチング。
    * バックトラックが不要となる理由。
* **2.3 線形時間計算量の保証 (Guarantee of Linear Time Complexity)**
    * 各ステップが入力文字列長に線形な時間で完了することの証明。
    * 状態数の有限性。
* **2.4 POSIX最長マッチの特性 (Characteristics of POSIX Longest Match)**
    * FlowRegexが全ての可能な終了位置を網羅的に取得できるため、最長マッチが容易に特定できること。

---

#### 第3章 FlowRegexのアーキテクチャと実装 (FlowRegex Architecture and Implementation)
* **3.1 全体アーキテクチャ (Overall Architecture)**
    * Parser、RegexElement、Matcher、BitMaskの役割と連携。
    * メインとなる `FlowRegex` クラスと `Matcher` クラスの動作フロー。
* **3.2 正規表現パーサー (Regular Expression Parser)**
    * 再帰下降パーサーによる正規表現文字列から抽象構文木（AST）への変換。
    * 対応する基本要素（リテラル、連接、選択、クリーネ閉包）。
    * **新規追加予定の記法**：
        * `+` (One or more) の実装（例: `X X*` への変換）。
        * `?` (Zero or one) の実装（例: `X | Epsilon` への変換）。
        * `{n,m}` (Quantifiers) の実装（例: `X{n}X?{m-n}` への変換）。
* **3.3 RegexElementとその変換関数 (RegexElement and its Transformation Functions)**
    * `RegexElement` 基底クラスの役割。
    * **各要素の実装詳細**:
        * `Literal` (文字リテラル)
        * `Concat` (連接)
        * `Alternation` (選択)
        * `KleeneStar` (クリーネ閉包) と固定点収束。
        * `CharClass` (文字クラス `[a-z]`, `\d` など) の実装。
        * `Anchor` (位置へのマッチ `^`, `$`, `\b`) の実装。
        * **`Intersect` (積集合)** の導入と、`(?=...)` 肯定先読みへの応用。
        * （もし可能であれば）`Complement` (補集合) の導入と、`(?！...)` 否定先読みへの応用。
* **3.4 ビットマスク管理ユーティリティ (Bitmask Management Utility)**
    * `BitMask` クラスのデータ構造と効率的な集合操作（`set`, `or!`, `copy` など）。
    * 大規模文字列へのスケーラビリティの考察（CPUワード長への最適化の可能性など）。

---

#### 第4章 部分文字列抽出と二段階マッチング (Substring Extraction and Two-Stage Matching)
* **4.1 FlowRegexの情報の粒度 (Granularity of Information in FlowRegex)**
    * FlowRegexが終了位置の集合を返すことの再確認。
    * 開始位置やキャプチャグループ情報を直接提供しない理由とトレードオフ。
* **4.2 二段階マッチング戦略 (Two-Stage Matching Strategy)**
    * `TwoStageMatcher` クラスの動作原理。
    * 第一段階: FlowRegexによる高速な終了位置候補の特定。
    * 第二段階: 各終了位置からの逆方向検証による開始位置の特定と部分文字列抽出。
    * 既存の正規表現エンジンを用いた逆方向検証の実装（`Onigmo` などへのインターフェース）。
    * （発展として）FlowRegex自体の逆方向マッチング実装の可能性と課題。

---

#### 第5章 実験と評価 (Experiment and Evaluation)
* **5.1 実験環境とセットアップ (Experimental Environment and Setup)**
    * ハードウェア、ソフトウェア、プログラミング言語（Ruby）。
* **5.2 パフォーマンス評価 (Performance Evaluation)**
    * 様々な正規表現パターンと文字列長に対するマッチング速度の測定。
    * 既存の正規表現エンジン（Ruby `Regexp`、Onigmoなど）との比較ベンチマーク。
    * 特にReDoS脆弱性を持つパターンに対するFlowRegexの安定性と高速性。
* **5.3 スケーラビリティ分析 (Scalability Analysis)**
    * 文字列長に対する計算量の検証（線形時間特性の確認）。
    * 複雑な正規表現パターンに対する性能特性。
* **5.4 実装の限界と今後の課題 (Limitations and Future Work)**
    * Ruby実装のプロトタイプとしての限界（パフォーマンスボトルネックなど）。
    * より低レベルな言語（C/Rust）やGPU実装による真のパフォーマンスの追求。
    * `\G` のような高度な機能の検討。
    * キャプチャグループのサポート。

---

#### 第6章 結論 (Conclusion)
* **6.1 本研究のまとめ (Summary of Contributions)**
    * FlowRegex法の革新性と主な利点。
    * ReDoS問題への根本的解決。
    * 並列計算への高い適性。
* **6.2 今後の展望 (Future Prospects)**
    * FlowRegex法がもたらすテキスト処理技術の新たな可能性。
    * **大規模なデータ処理、特にゲノム配列解析などのバイオインフォマティクス分野におけるGPU演算への応用による、飛躍的な高速化の可能性。**
    * 汎用的な正規表現ライブラリとしての発展性。
    * 新たなアルゴリズム研究への貢献。
