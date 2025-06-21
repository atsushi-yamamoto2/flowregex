class FlowRegex
  # 文字リテラルの変換関数
  # 入力位置集合の各位置について、次の文字が指定文字と一致するかチェック
  class Literal < RegexElement
    attr_reader :char
    
    def initialize(char)
      @char = char
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0, optimized_text: nil)
      if max_distance == 0
        # 距離0の場合の処理
        if optimized_text
          apply_with_match_mask(input_mask, text, debug, optimized_text)
        elsif text.respond_to?(:optimized?) && text.optimized?
          apply_with_match_mask(input_mask, text, debug)
        else
          apply_traditional(input_mask, text, debug)
        end
      else
        # ファジーマッチングの場合はFuzzyLiteralに委譲
        fuzzy_literal = FuzzyLiteral.new(@char)
        fuzzy_literal.apply(input_mask, text, debug: debug, max_distance: max_distance)
      end
    end
    
    private
    
    # MatchMaskを使った最適化処理
    def apply_with_match_mask(input_mask, text, debug, optimized_text = nil)
      if optimized_text
        match_mask = optimized_text.get_match_mask(@char)
      else
        match_mask = text.get_match_mask(@char)
      end
      
      output_mask = BitMask.new(input_mask.size)
      
      # MatchMaskを使った高速処理
      input_mask.set_positions.each do |pos|
        if match_mask.get(pos)
          output_mask.set(pos + 1)
        end
      end
      
      debug_info("Literal '#{@char}' (MatchMask optimized)", input_mask, output_mask) if debug
      output_mask
    end
    
    # 従来の文字比較処理
    def apply_traditional(input_mask, text, debug)
      output_mask = BitMask.new(input_mask.size)
      
      # 入力位置集合の各位置について処理
      input_mask.set_positions.each do |pos|
        # 現在位置の文字をチェック
        if pos < text.length && text[pos] == @char
          # マッチした場合、次の位置（終了位置）を設定
          output_mask.set(pos + 1)
        end
      end
      
      debug_info("Literal '#{@char}' (traditional)", input_mask, output_mask) if debug
      output_mask
    end
    
    def to_s
      @char
    end
  end
end
