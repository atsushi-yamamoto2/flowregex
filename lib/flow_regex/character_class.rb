class FlowRegex
  # 文字クラスの変換関数
  # [a-z], [0-9], \d, \s, \w などの文字クラスをサポート
  class CharacterClass < RegexElement
    def initialize(pattern)
      @pattern = pattern
      @matcher = build_matcher(pattern)
    end
    
    def apply(input_mask, text, debug: false)
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
    
    def apply(input_mask, text, debug: false)
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
    end
    
    def to_s
      "EscapeSequence(\\#{@char})"
    end
  end
end
