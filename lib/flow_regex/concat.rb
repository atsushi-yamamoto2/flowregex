class FlowRegex
  # 連接の変換関数
  # 第一要素の出力を第二要素の入力として渡す関数合成
  class Concat < RegexElement
    attr_reader :elements
    
    def initialize(first, second)
      @first = first
      @second = second
      @elements = [first, second]
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0, optimized_text: nil)
      # 第一要素を適用
      if optimized_text
        intermediate_mask = @first.apply(input_mask, text, debug: debug, max_distance: max_distance, optimized_text: optimized_text)
      else
        intermediate_mask = @first.apply(input_mask, text, debug: debug, max_distance: max_distance)
      end
      
      # 第二要素を適用（第一要素の出力を入力として使用）
      if optimized_text
        output_mask = @second.apply(intermediate_mask, text, debug: debug, max_distance: max_distance, optimized_text: optimized_text)
      else
        output_mask = @second.apply(intermediate_mask, text, debug: debug, max_distance: max_distance)
      end
      
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
