class FlowRegex
  # 正規表現パーサー
  # 基本的な再帰下降パーサーで連接、選択、クリーネ閉包をサポート
  class Parser
    def initialize(pattern)
      @pattern = pattern
      @pos = 0
    end
    
    def parse
      result = parse_expression
      raise ParseError, "Unexpected character at position #{@pos}: '#{current_char}'" unless at_end?
      result
    end
    
    private
    
    # Expression := Term ('|' Term)*
    def parse_expression
      left = parse_term
      
      while current_char == '|'
        consume('|')
        right = parse_term
        left = Alternation.new(left, right)
      end
      
      left
    end
    
    # Term := Factor*
    def parse_term
      factors = []
      
      while !at_end? && current_char != '|' && current_char != ')'
        factors << parse_factor
      end
      
      case factors.length
      when 0
        raise ParseError, "Empty term at position #{@pos}"
      when 1
        factors.first
      else
        # 複数の要素を左結合で連接
        factors.reduce { |acc, factor| Concat.new(acc, factor) }
      end
    end
    
    # Factor := Atom ('*' | '+' | '?' | '{' NUMBER (',' NUMBER?)? '}')?
    def parse_factor
      atom = parse_atom
      
      case current_char
      when '*'
        consume('*')
        KleeneStar.new(atom)
      when '+'
        consume('+')
        Plus.new(atom)
      when '?'
        consume('?')
        Question.new(atom)
      when '{'
        parse_quantifier(atom)
      else
        atom
      end
    end
    
    # 量指定子 {n} または {n,m} をパース
    def parse_quantifier(atom)
      consume('{')
      
      # 最初の数値を読む
      min_count = parse_number
      
      if current_char == ','
        consume(',')
        if current_char == '}'
          # {n,} の形式（n回以上）
          consume('}')
          RangeCount.new(atom, min_count, -1)  # -1 は無限大
        else
          # {n,m} の形式
          max_count = parse_number
          consume('}')
          if min_count > max_count
            raise ParseError, "Invalid quantifier range: {#{min_count},#{max_count}} at position #{@pos}"
          end
          RangeCount.new(atom, min_count, max_count)
        end
      else
        # {n} の形式（n回ちょうど）
        consume('}')
        ExactCount.new(atom, min_count)
      end
    end
    
    # 数値をパース
    def parse_number
      start_pos = @pos
      
      unless current_char && current_char.match(/\d/)
        raise ParseError, "Expected number at position #{@pos}"
      end
      
      while current_char && current_char.match(/\d/)
        advance
      end
      
      @pattern[start_pos...@pos].to_i
    end
    
    # Atom := CHAR | '(' Expression ')' | '[' CharClass ']' | '\' EscapeChar | '.'
    def parse_atom
      case current_char
      when '('
        consume('(')
        expr = parse_expression
        consume(')')
        expr
      when '['
        parse_character_class
      when '\\'
        parse_escape_sequence
      when '.'
        advance
        AnyChar.new
      when nil
        raise ParseError, "Unexpected end of pattern"
      when '|', ')', '*', '+', '?', '{', ']'
        raise ParseError, "Unexpected character '#{current_char}' at position #{@pos}"
      else
        char = current_char
        advance
        Literal.new(char)
      end
    end
    
    # 文字クラス [a-z] をパース
    def parse_character_class
      consume('[')
      
      start_pos = @pos
      class_content = ""
      
      # ] までの内容を読む
      while current_char && current_char != ']'
        class_content += current_char
        advance
      end
      
      if current_char != ']'
        raise ParseError, "Unclosed character class at position #{start_pos}"
      end
      
      consume(']')
      
      if class_content.empty?
        raise ParseError, "Empty character class at position #{start_pos}"
      end
      
      CharacterClass.new(class_content)
    end
    
    # エスケープシーケンス \d, \n などをパース
    def parse_escape_sequence
      consume('\\')
      
      if current_char.nil?
        raise ParseError, "Incomplete escape sequence at end of pattern"
      end
      
      escape_char = current_char
      advance
      
      case escape_char
      when 'd', 'D', 's', 'S', 'w', 'W'
        # 文字クラス略記
        CharacterClass.new(escape_char)
      else
        # 通常のエスケープシーケンス
        EscapeSequence.new(escape_char)
      end
    end
    
    def current_char
      return nil if @pos >= @pattern.length
      @pattern[@pos]
    end
    
    def advance
      @pos += 1
    end
    
    def consume(expected)
      if current_char == expected
        advance
      else
        raise ParseError, "Expected '#{expected}' at position #{@pos}, got '#{current_char}'"
      end
    end
    
    def at_end?
      @pos >= @pattern.length
    end
  end
end
