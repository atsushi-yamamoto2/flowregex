class FlowRegex
  # 文字クラスの変換関数
  # [a-z], [0-9], \d, \s, \w などの文字クラスをサポート
  class CharacterClass < RegexElement
    def initialize(pattern)
      @pattern = pattern
      @matcher = build_matcher(pattern)
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0)
      if max_distance == 0
        # 通常のマッチング
        if debug
          puts "CharacterClass [#{@pattern}]:"
          puts "  Input:  #{input_mask.inspect}"
        end
        
        output_mask = BitMask.new(input_mask.size)
        
        # 各位置をチェック
        input_mask.set_positions.each do |pos|
          next if pos >= text.length
          
          char = text[pos]
          if @matcher.call(char)
            output_mask.set(pos + 1)
          end
        end
        
        if debug
          puts "  Output: #{output_mask.inspect}"
          puts
        end
        
        output_mask
      else
        # ファジーマッチング - FuzzyLiteralと同様の処理
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
          
          # 1. 完全マッチ（文字クラスにマッチ）
          if text_pos < text.length && @matcher.call(text[text_pos])
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
          puts "CharacterClass [#{@pattern}] - Fuzzy:"
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
      "CharacterClass[#{@pattern}]"
    end
    
    private
    
    def build_matcher(pattern)
      case pattern
      # 基本的な文字クラス略記
      when 'd'  # \d - 数字
        ->(char) { char.match?(/[0-9]/) }
      when 'D'  # \D - 数字以外
        ->(char) { !char.match?(/[0-9]/) }
      when 's'  # \s - 空白文字
        ->(char) { char.match?(/\s/) }
      when 'S'  # \S - 空白文字以外
        ->(char) { !char.match?(/\s/) }
      when 'w'  # \w - 単語文字
        ->(char) { char.match?(/[a-zA-Z0-9_]/) }
      when 'W'  # \W - 単語文字以外
        ->(char) { !char.match?(/[a-zA-Z0-9_]/) }
      else
        # [a-z] や [abc] などの文字クラス
        build_bracket_matcher(pattern)
      end
    end
    
    def build_bracket_matcher(pattern)
      # 文字クラスの解析
      chars = []
      ranges = []
      char_class_matchers = []
      negated = false
      
      i = 0
      if pattern[0] == '^'
        negated = true
        i = 1
      end
      
      while i < pattern.length
        char = pattern[i]
        
        # エスケープシーケンス (\d, \s, \w など)
        if char == '\\' && i + 1 < pattern.length
          escape_char = pattern[i + 1]
          case escape_char
          when 'd'  # \d - 数字
            char_class_matchers << ->(c) { c.match?(/[0-9]/) }
          when 'D'  # \D - 数字以外
            char_class_matchers << ->(c) { !c.match?(/[0-9]/) }
          when 's'  # \s - 空白文字
            char_class_matchers << ->(c) { c.match?(/\s/) }
          when 'S'  # \S - 空白文字以外
            char_class_matchers << ->(c) { !c.match?(/\s/) }
          when 'w'  # \w - 単語文字
            char_class_matchers << ->(c) { c.match?(/[a-zA-Z0-9_]/) }
          when 'W'  # \W - 単語文字以外
            char_class_matchers << ->(c) { !c.match?(/[a-zA-Z0-9_]/) }
          when 'n'  # \n - 改行
            chars << "\n"
          when 't'  # \t - タブ
            chars << "\t"
          when 'r'  # \r - キャリッジリターン
            chars << "\r"
          when '\\'  # \\ - バックスラッシュ
            chars << "\\"
          else
            # その他のエスケープは文字として扱う
            chars << escape_char
          end
          i += 2
        # 範囲指定 (a-z)
        elsif i + 2 < pattern.length && pattern[i + 1] == '-' && pattern[i + 2] != ']'
          start_char = char
          end_char = pattern[i + 2]
          ranges << (start_char..end_char)
          i += 3
        else
          # 単一文字
          chars << char
          i += 1
        end
      end
      
      # マッチャー関数を作成
      ->(char) {
        # 個別文字と範囲のマッチ
        basic_matched = chars.include?(char) || ranges.any? { |range| range.cover?(char) }
        
        # 文字クラスマッチャーのマッチ
        class_matched = char_class_matchers.any? { |matcher| matcher.call(char) }
        
        matched = basic_matched || class_matched
        negated ? !matched : matched
      }
    end
  end
  
  # エスケープシーケンスの変換関数
  class EscapeSequence < RegexElement
    ESCAPE_MAP = {
      'n' => "\n",    # 改行
      't' => "\t",    # タブ
      'r' => "\r",    # キャリッジリターン
      'f' => "\f",    # フォームフィード
      'v' => "\v",    # 垂直タブ
      '0' => "\0",    # NULL文字
      '\\' => "\\",   # バックスラッシュ
      '/' => "/",     # スラッシュ
      '"' => '"',     # ダブルクォート
      "'" => "'",     # シングルクォート
      '.' => ".",     # ピリオド（リテラル）
    }.freeze
    
    def initialize(char)
      @char = char
      @literal_char = ESCAPE_MAP[char] || char
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0)
      if max_distance == 0
        # 通常のマッチング
        if debug
          puts "EscapeSequence \\#{@char} (#{@literal_char.inspect}):"
          puts "  Input:  #{input_mask.inspect}"
        end
        
        output_mask = BitMask.new(input_mask.size)
        
        # 各位置をチェック
        input_mask.set_positions.each do |pos|
          next if pos >= text.length
          
          if text[pos] == @literal_char
            output_mask.set(pos + 1)
          end
        end
        
        if debug
          puts "  Output: #{output_mask.inspect}"
          puts
        end
        
        output_mask
      else
        # ファジーマッチングの場合はFuzzyLiteralに委譲
        fuzzy_literal = FuzzyLiteral.new(@literal_char)
        fuzzy_literal.apply(input_mask, text, debug: debug, max_distance: max_distance)
      end
    end
    
    def to_s
      "EscapeSequence(\\#{@char})"
    end
  end
end
