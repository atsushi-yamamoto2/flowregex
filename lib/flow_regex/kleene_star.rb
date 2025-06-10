class FlowRegex
  # クリーネ閉包の変換関数
  # 内部要素を収束するまで反復適用（固定点を求める）
  class KleeneStar < RegexElement
    def initialize(element)
      @element = element
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0)
      # KleeneStar の正しい実装：
      # 1. 初期状態は入力マスク（0回マッチ）
      # 2. 段階的に内部要素を適用して拡張
      current_mask = input_mask.copy
      iteration = 0
      
      if debug
        puts "KleeneStar (#{@element})*:"
        puts "  Initial: #{current_mask.inspect}"
      end
      
      loop do
        iteration += 1
        
        # 無限ループ防止（早期チェック）
        if iteration > 100
          if debug
            puts "  Warning: Maximum iterations reached, forcing convergence"
            puts
          end
          break
        end
        
        # 現在のマスクのコピーを保存
        old_mask = current_mask.copy
        
        # 現在のマスクに内部要素を適用
        new_bits = @element.apply(current_mask, text, debug: false, max_distance: max_distance)
        
        # 新しいビットを追加
        current_mask.or!(new_bits)
        
        if debug
          puts "  Iteration #{iteration}: #{current_mask.inspect}"
        end
        
        # 収束チェック：マスクが変化しなかった場合
        if current_mask == old_mask
          if debug
            puts "  Converged after #{iteration} iterations!"
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
