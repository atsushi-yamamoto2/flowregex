class FlowRegex
  # 汎用量指定子クラス
  # 指定された回数範囲で内部要素を反復適用
  class Quantifier < RegexElement
    def initialize(element, min_count, max_count = nil)
      @element = element
      @min_count = min_count
      @max_count = max_count || min_count
      
      # 無限大の場合（KleeneStar相当）
      @max_count = Float::INFINITY if @max_count == -1
    end
    
    def apply(input_mask, text, debug: false)
      if debug
        puts "Quantifier (#{@element}){#{@min_count},#{@max_count == Float::INFINITY ? '∞' : @max_count}}:"
        puts "  Initial: #{input_mask.inspect}"
      end
      
      # 結果マスクを初期化
      result_mask = BitMask.new(input_mask.size)
      
      # 0回マッチ（min_count が 0 の場合のみ）
      if @min_count == 0
        result_mask.or!(input_mask)
      end
      
      # 各回数でのマッチを計算
      current_mask = input_mask.copy
      
      (1..[@max_count, 100].min).each do |count|
        # 内部要素を適用
        current_mask = @element.apply(current_mask, text, debug: false)
        
        # 指定回数範囲内なら結果に追加
        if count >= @min_count
          result_mask.or!(current_mask)
        end
        
        if debug
          puts "  Count #{count}: #{current_mask.inspect}"
        end
        
        # マスクが空になったら終了
        break if current_mask.empty?
      end
      
      if debug
        puts "  Final: #{result_mask.inspect}"
        puts
      end
      
      result_mask
    end
    
    def to_s
      if @max_count == Float::INFINITY
        "Quantifier(#{@element}){#{@min_count},∞}"
      elsif @min_count == @max_count
        "Quantifier(#{@element}){#{@min_count}}"
      else
        "Quantifier(#{@element}){#{@min_count},#{@max_count}}"
      end
    end
  end
  
  # 便利メソッド用のクラス
  
  # + 量指定子（1回以上）
  class Plus < Quantifier
    def initialize(element)
      super(element, 1, -1)  # -1 は無限大を表す
    end
    
    def to_s
      "Plus(#{@element})"
    end
  end
  
  # ? 量指定子（0回または1回）
  class Question < Quantifier
    def initialize(element)
      super(element, 0, 1)
    end
    
    def to_s
      "Question(#{@element})"
    end
  end
  
  # {n} 量指定子（n回ちょうど）
  class ExactCount < Quantifier
    def initialize(element, count)
      super(element, count, count)
    end
    
    def to_s
      "ExactCount(#{@element}){#{@min_count}}"
    end
  end
  
  # {n,m} 量指定子（n回からm回）
  class RangeCount < Quantifier
    def initialize(element, min_count, max_count)
      super(element, min_count, max_count)
    end
    
    def to_s
      "RangeCount(#{@element}){#{@min_count},#{@max_count}}"
    end
  end
end
