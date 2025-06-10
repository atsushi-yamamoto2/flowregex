class FlowRegex
  # ファジーマッチング対応のマッチングエンジン
  # 編集距離を指定してファジーマッチングを実行
  class FuzzyMatcher < Matcher
    def initialize(text, max_distance: 0, debug: false)
      @max_distance = max_distance
      super(text, debug: debug)
    end
    
    def match(regex_element)
      if @max_distance == 0
        # 距離0の場合は通常のマッチング
        return super(regex_element)
      end
      
      # ファジーマッチング処理
      fuzzy_match(regex_element)
    end
    
    private
    
    def fuzzy_match(regex_element)
      # パターンの長さを推定（簡単な実装として）
      pattern_length = estimate_pattern_length(regex_element)
      
      # 初期ファジービットマスクを作成
      initial_mask = FuzzyBitMask.new(@text.length, pattern_length, @max_distance)
      
      # 文字列の各位置から開始可能（距離0、パターン位置0）
      (0..@text.length).each do |pos|
        initial_mask.set(pos, 0, 0)
      end
      
      if @debug
        puts "=== FuzzyRegex Matching Debug ==="
        puts "Text: '#{@text}'"
        puts "Pattern: #{regex_element}"
        puts "Max distance: #{@max_distance}"
        puts "Pattern length estimate: #{pattern_length}"
        puts "Initial mask: #{initial_mask.inspect}"
        puts
      end
      
      # 正規表現要素を適用
      result_mask = regex_element.apply(initial_mask, @text, max_distance: @max_distance, debug: @debug)
      
      if @debug
        puts "Final result: #{result_mask.inspect}"
        puts "Match end positions: #{result_mask.match_end_positions}"
        puts "=== End Debug ==="
        puts
      end
      
      # 結果として、マッチ終了位置と距離の組み合わせを返す
      result_mask.match_end_positions
    end
    
    # パターンの長さを推定（簡単な実装）
    def estimate_pattern_length(regex_element)
      case regex_element
      when FuzzyLiteral, Literal
        1
      when Concat
        # Concatの場合は2つの要素の長さを合計
        estimate_pattern_length(regex_element.instance_variable_get(:@first)) +
        estimate_pattern_length(regex_element.instance_variable_get(:@second))
      when Alternation
        # Alternationの場合は最大長を取る（実装されていれば）
        # 現在は簡単に1を返す
        1
      when KleeneStar, Quantifier
        # 量詞の場合は推定が困難なので大きめの値を設定
        [@text.length, 10].min
      else
        # その他の場合は1として扱う
        1
      end
    end
  end
end
