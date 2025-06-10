class FlowRegex
  # 任意の文字にマッチする変換関数（ピリオド . の実装）
  class AnyChar < RegexElement
    def apply(input_mask, text, debug: false, max_distance: 0)
      if max_distance == 0
        # 通常のマッチング
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
      else
        # ファジーマッチングの場合はFuzzyLiteralに類似した処理
        # AnyCharは任意の文字にマッチするので、ファジーマッチングでも基本的に同じ
        if input_mask.is_a?(FuzzyBitMask)
          fuzzy_input = input_mask
          pattern_length = fuzzy_input.pattern_length
        else
          pattern_length = 1
          fuzzy_input = convert_to_fuzzy_mask(input_mask, text.length, pattern_length, max_distance)
        end
        
        output_mask = FuzzyBitMask.new(text.length, pattern_length, max_distance)
        
        fuzzy_input.set_positions.each do |text_pos, pattern_pos, distance|
          next if pattern_pos < 0 || pattern_pos >= pattern_length
          
          next_pattern_pos = pattern_pos + 1
          next if next_pattern_pos > pattern_length
          
          # 1. 完全マッチ（任意の文字、改行以外）
          if text_pos < text.length && text[text_pos] != "\n"
            output_mask.set(text_pos + 1, next_pattern_pos, distance)
          end
          
          # 2. 置換（距離+1）
          if text_pos < text.length && distance < max_distance
            output_mask.set(text_pos + 1, next_pattern_pos, distance + 1)
          end
          
          # 3. 挿入（距離+1）
          if distance < max_distance
            output_mask.set(text_pos, next_pattern_pos, distance + 1)
          end
          
          # 4. 削除（距離+1）
          if text_pos < text.length && distance < max_distance
            output_mask.set(text_pos + 1, pattern_pos, distance + 1)
          end
        end
        
        if debug
          puts "AnyChar (.) - Fuzzy:"
          puts "  Input: #{fuzzy_input.inspect}"
          puts "  Output: #{output_mask.inspect}"
          puts
        end
        
        output_mask
      end
    end
    
    private
    
    def convert_to_fuzzy_mask(bit_mask, text_length, pattern_length, max_distance)
      fuzzy_mask = FuzzyBitMask.new(text_length, pattern_length, max_distance)
      
      if bit_mask.is_a?(FuzzyBitMask)
        return bit_mask
      end
      
      bit_mask.set_positions.each do |pos|
        fuzzy_mask.set(pos, 0, 0)
      end
      
      fuzzy_mask
    end
    
    def to_s
      "AnyChar(.)"
    end
  end
end
