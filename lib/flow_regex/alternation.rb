class FlowRegex
  # 選択の変換関数
  # 複数の選択肢を並列に処理し、結果をOR結合
  class Alternation < RegexElement
    def initialize(*alternatives)
      @alternatives = alternatives
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0)
      if max_distance == 0
        # 通常のマッチング
        output_mask = BitMask.new(input_mask.size)
        
        # 各選択肢を並列に処理
        @alternatives.each do |alt|
          alt_output = alt.apply(input_mask, text, debug: debug, max_distance: max_distance)
          output_mask.or!(alt_output)
        end
        
        if debug
          alt_strs = @alternatives.map(&:to_s).join(' | ')
          puts "Alternation (#{alt_strs}):"
          puts "  Combined Output: #{output_mask.inspect}"
          puts
        end
        
        output_mask
      else
        # ファジーマッチング - 最初の選択肢の結果を基準にFuzzyBitMaskを作成
        first_result = @alternatives.first.apply(input_mask, text, debug: debug, max_distance: max_distance)
        
        if first_result.is_a?(FuzzyBitMask)
          output_mask = first_result.copy
        else
          # 通常のBitMaskの場合は変換
          output_mask = convert_to_fuzzy_mask(first_result, input_mask, max_distance)
        end
        
        # 残りの選択肢を処理
        @alternatives[1..-1].each do |alt|
          alt_output = alt.apply(input_mask, text, debug: debug, max_distance: max_distance)
          
          if alt_output.is_a?(FuzzyBitMask) && output_mask.is_a?(FuzzyBitMask)
            output_mask.or!(alt_output)
          end
        end
        
        if debug
          alt_strs = @alternatives.map(&:to_s).join(' | ')
          puts "Alternation (#{alt_strs}) - Fuzzy:"
          puts "  Combined Output: #{output_mask.inspect}"
          puts
        end
        
        output_mask
      end
    end
    
    private
    
    def convert_to_fuzzy_mask(bit_mask, input_mask, max_distance)
      # 簡単な変換 - 実際の実装では改善が必要
      text_length = bit_mask.size - 1
      pattern_length = 1  # 仮の値
      fuzzy_mask = FuzzyBitMask.new(text_length, pattern_length, max_distance)
      
      bit_mask.set_positions.each do |pos|
        fuzzy_mask.set(pos, pattern_length, 0)
      end
      
      fuzzy_mask
    end
    
    def to_s
      alt_strs = @alternatives.map(&:to_s).join(' | ')
      "Alternation(#{alt_strs})"
    end
  end
end
