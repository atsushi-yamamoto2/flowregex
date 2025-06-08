class FlowRegex
  # 文字リテラルの変換関数
  # 入力位置集合の各位置について、次の文字が指定文字と一致するかチェック
  class Literal < RegexElement
    def initialize(char)
      @char = char
    end
    
    def apply(input_mask, text, debug: false)
      output_mask = BitMask.new(input_mask.size)
      
      # 入力位置集合の各位置について処理
      input_mask.set_positions.each do |pos|
        # 現在位置の文字をチェック
        if pos < text.length && text[pos] == @char
          # マッチした場合、次の位置（終了位置）を設定
          output_mask.set(pos + 1)
        end
      end
      
      debug_info("Literal '#{@char}'", input_mask, output_mask) if debug
      output_mask
    end
    
    def to_s
      "Literal('#{@char}')"
    end
  end
end
