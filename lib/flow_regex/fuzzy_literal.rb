class FlowRegex
  # ファジーマッチング対応の文字リテラル
  # 編集距離（置換・挿入・削除）をサポート
  class FuzzyLiteral < RegexElement
    def initialize(char)
      @char = char
    end
    
    def apply(input_mask, text, max_distance: 0, debug: false)
      if max_distance == 0
        # 距離0の場合は通常のLiteralと同じ処理
        return apply_exact_match(input_mask, text, debug)
      end
      
      # ファジーマッチング処理
      apply_fuzzy_match(input_mask, text, max_distance, debug)
    end
    
    def to_s
      "FuzzyLiteral('#{@char}')"
    end
    
    private
    
    # 完全マッチ処理（距離0）
    def apply_exact_match(input_mask, text, debug)
      output_mask = BitMask.new(input_mask.size)
      
      input_mask.set_positions.each do |pos|
        if pos < text.length && text[pos] == @char
          output_mask.set(pos + 1)
        end
      end
      
      debug_info("FuzzyLiteral '#{@char}' (exact)", input_mask, output_mask) if debug
      output_mask
    end
    
    # ファジーマッチ処理
    def apply_fuzzy_match(input_mask, text, max_distance, debug)
      # 入力がFuzzyBitMaskでない場合は変換
      if input_mask.is_a?(FuzzyBitMask)
        fuzzy_input = input_mask
        # 既存のFuzzyBitMaskのパターン長を維持
        pattern_length = fuzzy_input.pattern_length
      else
        # 通常のBitMaskの場合、単一文字として扱う
        pattern_length = 1
        fuzzy_input = convert_to_fuzzy_mask(input_mask, text.length, pattern_length, max_distance)
      end
      
      # 出力用のファジービットマスク（パターン長は維持）
      output_mask = FuzzyBitMask.new(text.length, pattern_length, max_distance)
      
      # 各状態について処理
      fuzzy_input.set_positions.each do |text_pos, pattern_pos, distance|
        # 現在のパターン位置が有効な範囲内かチェック
        next if pattern_pos < 0 || pattern_pos >= pattern_length
        
        # パターン位置を1つ進めた位置が範囲内かチェック
        next_pattern_pos = pattern_pos + 1
        next if next_pattern_pos > pattern_length
        
        # 1. 完全マッチ（距離変化なし）
        if text_pos < text.length && text[text_pos] == @char
          output_mask.set(text_pos + 1, next_pattern_pos, distance)
        end
        
        # 2. 置換（距離+1）
        if text_pos < text.length && distance < max_distance
          output_mask.set(text_pos + 1, next_pattern_pos, distance + 1)
        end
        
        # 3. 挿入（テキスト位置そのまま、パターン進む、距離+1）
        if distance < max_distance
          output_mask.set(text_pos, next_pattern_pos, distance + 1)
        end
        
        # 4. 削除（テキストから文字を削除、テキスト位置進む、パターンそのまま、距離+1）
        if text_pos < text.length && distance < max_distance
          output_mask.set(text_pos + 1, pattern_pos, distance + 1)
        end
      end
      
      if debug
        puts "FuzzyLiteral '#{@char}' (fuzzy, max_distance=#{max_distance})"
        puts "  Input: #{fuzzy_input.inspect}"
        puts "  Output: #{output_mask.inspect}"
        puts "  Pattern length: #{pattern_length}"
      end
      
      output_mask
    end
    
    # 通常のBitMaskをFuzzyBitMaskに変換
    def convert_to_fuzzy_mask(bit_mask, text_length, pattern_length, max_distance)
      fuzzy_mask = FuzzyBitMask.new(text_length, pattern_length, max_distance)
      
      if bit_mask.is_a?(FuzzyBitMask)
        return bit_mask
      end
      
      # 通常のBitMaskの場合、距離0でパターン位置0として設定
      bit_mask.set_positions.each do |pos|
        fuzzy_mask.set(pos, 0, 0)
      end
      
      fuzzy_mask
    end
  end
end
