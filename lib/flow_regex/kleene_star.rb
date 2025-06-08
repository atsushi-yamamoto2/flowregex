class FlowRegex
  # クリーネ閉包の変換関数
  # 内部要素を収束するまで反復適用（固定点を求める）
  class KleeneStar < RegexElement
    def initialize(element)
      @element = element
    end
    
    def apply(input_mask, text, debug: false)
      # 初期状態：入力マスクをそのまま出力に含める（0回マッチの場合）
      current_mask = input_mask.copy
      iteration = 0
      
      if debug
        puts "KleeneStar (#{@element})*:"
        puts "  Initial: #{current_mask.inspect}"
      end
      
      loop do
        iteration += 1
        
        # 内部要素を適用
        new_bits = @element.apply(current_mask, text, debug: false)
        
        # 新しいビットを現在のマスクに追加
        old_mask = current_mask.copy
        current_mask.or!(new_bits)
        
        if debug
          puts "  Iteration #{iteration}: #{current_mask.inspect}"
        end
        
        # 収束チェック：新しいビットが追加されなかった場合
        if current_mask == old_mask
          if debug
            puts "  Converged after #{iteration} iterations!"
            puts
          end
          break
        end
        
        # 無限ループ防止（安全装置）
        if iteration > text.length + 10
          if debug
            puts "  Warning: Maximum iterations reached, forcing convergence"
            puts
          end
          break
        end
      end
      
      current_mask
    end
    
    def to_s
      "KleeneStar(#{@element})"
    end
  end
end
