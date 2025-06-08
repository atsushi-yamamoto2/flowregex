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
    
    # Factor := Atom ('*')?
    def parse_factor
      atom = parse_atom
      
      if current_char == '*'
        consume('*')
        KleeneStar.new(atom)
      else
        atom
      end
    end
    
    # Atom := CHAR | '(' Expression ')'
    def parse_atom
      case current_char
      when '('
        consume('(')
        expr = parse_expression
        consume(')')
        expr
      when nil
        raise ParseError, "Unexpected end of pattern"
      when '|', ')', '*'
        raise ParseError, "Unexpected character '#{current_char}' at position #{@pos}"
      else
        char = current_char
        advance
        Literal.new(char)
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
