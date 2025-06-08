class FlowRegex
  # マッチングエンジン
  # データフローを統合し、実際のマッチング処理を実行
  class Matcher
    def initialize(text, debug: false)
      @text = text
      @debug = debug
    end
    
    def match(regex_element)
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
        puts
      end
      
      # 正規表現要素を適用
      result_mask = regex_element.apply(initial_mask, @text, debug: @debug)
      
      if @debug
        puts "Final result: #{result_mask.inspect}"
        puts "=== End Debug ==="
        puts
      end
      
      # 結果として、マッチ終了位置の配列を返す
      positions = result_mask.set_positions.sort
      positions
    end
  end
end
