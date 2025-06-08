class FlowRegex
  # 連接の変換関数
  # 第一要素の出力を第二要素の入力として渡す関数合成
  class Concat < RegexElement
    def initialize(first, second)
      @first = first
      @second = second
    end
    
    def apply(input_mask, text, debug: false)
      # 第一要素を適用
      intermediate_mask = @first.apply(input_mask, text, debug: debug)
      
      # 第二要素を適用（第一要素の出力を入力として使用）
      output_mask = @second.apply(intermediate_mask, text, debug: debug)
      
      if debug
        puts "Concat (#{@first} then #{@second}):"
        puts "  Final Output: #{output_mask.inspect}"
        puts
      end
      
      output_mask
    end
    
    def to_s
      "Concat(#{@first}, #{@second})"
    end
  end
end
