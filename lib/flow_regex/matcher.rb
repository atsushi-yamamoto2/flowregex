class FlowRegex
  # マッチングエンジン
  # データフローを統合し、実際のマッチング処理を実行
  class Matcher
    def initialize(text, debug: false)
      @text = text
      @debug = debug
    end
    
    def match(regex_element, optimized_text: nil)
      # 初期ビットマスクを作成（文字列長+1のサイズ）
      # 全ての位置から開始可能とする
      initial_mask = BitMask.new(@text.length + 1)
      
      # 文字列の各位置から開始可能
      (0..@text.length).each do |pos|
        initial_mask.set(pos)
      end
      
      if @debug
        puts "=== FlowRegex Matching Debug ==="
        puts "Text: '#{@text}'"
        puts "Pattern: #{regex_element}"
        puts "Initial mask: #{initial_mask.inspect}"
        puts "Optimized: #{optimized_text ? 'Yes' : 'No'}"
        puts
      end
      
      # 正規表現要素を適用（最適化テキストがあれば渡す）
      if optimized_text
        result_mask = regex_element.apply(initial_mask, @text, debug: @debug, optimized_text: optimized_text)
      else
        result_mask = regex_element.apply(initial_mask, @text, debug: @debug)
      end
      
      if @debug
        puts "Final result: #{result_mask.inspect}"
        puts "=== End Debug ==="
        puts
      end
      
      # 結果として、全てのマッチ位置を返す
      positions = result_mask.set_positions.sort
      positions
    end
    
    private
    
    def estimate_pattern_length(regex_element)
      # 簡単なパターン長推定（実際の実装では正確に計算する必要がある）
      case regex_element
      when FlowRegex::Literal
        regex_element.char.length
      when FlowRegex::Concat
        regex_element.elements.sum { |e| estimate_pattern_length(e) }
      else
        1 # デフォルト
      end
    end
  end
end
