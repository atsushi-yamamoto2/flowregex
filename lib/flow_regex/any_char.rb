class FlowRegex
  # 任意の文字にマッチする変換関数（ピリオド . の実装）
  class AnyChar < RegexElement
    def apply(input_mask, text, debug: false)
      if debug
        puts "AnyChar (.):"
        puts "  Input:  #{input_mask.inspect}"
      end
      
      output_mask = BitMask.new(input_mask.size)
      
      # 各位置をチェック（改行以外の任意の文字にマッチ）
      input_mask.set_positions.each do |pos|
        next if pos >= text.length
        
        char = text[pos]
        # 改行文字以外の任意の文字にマッチ
        unless char == "\n"
          output_mask.set(pos + 1)
        end
      end
      
      if debug
        puts "  Output: #{output_mask.inspect}"
        puts
      end
      
      output_mask
    end
    
    def to_s
      "AnyChar(.)"
    end
  end
end
