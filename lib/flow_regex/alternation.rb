class FlowRegex
  # 選択の変換関数
  # 複数の選択肢を並列に処理し、結果をOR結合
  class Alternation < RegexElement
    def initialize(*alternatives)
      @alternatives = alternatives
    end
    
    def apply(input_mask, text, debug: false)
      output_mask = BitMask.new(input_mask.size)
      
      # 各選択肢を並列に処理
      @alternatives.each do |alt|
        alt_output = alt.apply(input_mask, text, debug: debug)
        output_mask.or!(alt_output)
      end
      
      if debug
        alt_strs = @alternatives.map(&:to_s).join(' | ')
        puts "Alternation (#{alt_strs}):"
        puts "  Combined Output: #{output_mask.inspect}"
        puts
      end
      
      output_mask
    end
    
    def to_s
      alt_strs = @alternatives.map(&:to_s).join(' | ')
      "Alternation(#{alt_strs})"
    end
  end
end
