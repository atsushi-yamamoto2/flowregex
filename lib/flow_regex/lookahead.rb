class FlowRegex
  # 肯定先読み演算子 (?=B)A
  # A ∩ B の集合演算を同じ開始位置で実行
  class PositiveLookahead < RegexElement
    def initialize(lookahead_pattern, main_pattern)
      @lookahead = lookahead_pattern
      @main = main_pattern
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0)
      # 入力マスクをTrackedBitMaskに変換
      tracked_input = convert_to_tracked(input_mask)
      
      if debug
        puts "PositiveLookahead (?=#{@lookahead})#{@main}:"
        puts "  Input: #{tracked_input.inspect_tracked}"
      end
      
      # 各パターンを適用（開始位置情報を保持）
      lookahead_result = apply_with_tracking(@lookahead, tracked_input, text, debug, max_distance)
      main_result = apply_with_tracking(@main, tracked_input, text, debug, max_distance)
      
      if debug
        puts "  Lookahead result: #{lookahead_result.inspect_tracked}"
        puts "  Main result: #{main_result.inspect_tracked}"
      end
      
      # 同じ開始位置での積集合
      result = main_result.lookahead_intersect(lookahead_result)
      
      if debug
        puts "  Final result: #{result.inspect_tracked}"
        puts
      end
      
      # 通常のBitMaskに変換して返す
      result.to_bit_mask
    end
    
    def to_s
      "PositiveLookahead((?=#{@lookahead})#{@main})"
    end
    
    private
    
    def convert_to_tracked(input_mask)
      if input_mask.is_a?(TrackedBitMask)
        input_mask
      else
        TrackedBitMask.from_bit_mask(input_mask)
      end
    end
    
    def apply_with_tracking(pattern, tracked_input, text, debug, max_distance)
      # パターンを適用して結果をTrackedBitMaskで取得
      if pattern.respond_to?(:apply_tracked)
        pattern.apply_tracked(tracked_input, text, debug: debug, max_distance: max_distance)
      else
        # 通常のapplyメソッドを使用してTrackedBitMaskに変換
        normal_result = pattern.apply(tracked_input.to_bit_mask, text, debug: debug, max_distance: max_distance)
        convert_result_to_tracked(normal_result, tracked_input, text, pattern)
      end
    end
    
    def convert_result_to_tracked(result, original_tracked_input, text, pattern)
      tracked_result = TrackedBitMask.new(result.size)
      
      # 元の開始位置情報を使って結果を構築
      original_tracked_input.get_pairs.each do |start_pos, _|
        # この開始位置から単独でパターンを適用
        single_start = BitMask.new(result.size)
        single_start.set(start_pos)
        
        single_result = pattern.apply(single_start, text, debug: false)
        single_result.set_positions.each do |end_pos|
          if result.get(end_pos)  # 全体の結果にも含まれている場合のみ
            tracked_result.set_with_start(start_pos, end_pos)
          end
        end
      end
      
      tracked_result
    end
  end
  
  # 否定先読み演算子 (?!B)A
  # A - B の集合演算を同じ開始位置で実行
  class NegativeLookahead < RegexElement
    def initialize(lookahead_pattern, main_pattern)
      @lookahead = lookahead_pattern
      @main = main_pattern
    end
    
    def apply(input_mask, text, debug: false, max_distance: 0)
      # 入力マスクをTrackedBitMaskに変換
      tracked_input = convert_to_tracked(input_mask)
      
      if debug
        puts "NegativeLookahead (?!#{@lookahead})#{@main}:"
        puts "  Input: #{tracked_input.inspect_tracked}"
      end
      
      # 各パターンを適用（開始位置情報を保持）
      lookahead_result = apply_with_tracking(@lookahead, tracked_input, text, debug, max_distance)
      main_result = apply_with_tracking(@main, tracked_input, text, debug, max_distance)
      
      if debug
        puts "  Lookahead result: #{lookahead_result.inspect_tracked}"
        puts "  Main result: #{main_result.inspect_tracked}"
      end
      
      # 同じ開始位置での差集合
      result = main_result.lookahead_subtract(lookahead_result)
      
      if debug
        puts "  Final result: #{result.inspect_tracked}"
        puts
      end
      
      # 通常のBitMaskに変換して返す
      result.to_bit_mask
    end
    
    def to_s
      "NegativeLookahead((?!#{@lookahead})#{@main})"
    end
    
    private
    
    def convert_to_tracked(input_mask)
      if input_mask.is_a?(TrackedBitMask)
        input_mask
      else
        TrackedBitMask.from_bit_mask(input_mask)
      end
    end
    
    def apply_with_tracking(pattern, tracked_input, text, debug, max_distance)
      # パターンを適用して結果をTrackedBitMaskで取得
      if pattern.respond_to?(:apply_tracked)
        pattern.apply_tracked(tracked_input, text, debug: debug, max_distance: max_distance)
      else
        # 通常のapplyメソッドを使用してTrackedBitMaskに変換
        normal_result = pattern.apply(tracked_input.to_bit_mask, text, debug: debug, max_distance: max_distance)
        convert_result_to_tracked(normal_result, tracked_input, text, pattern)
      end
    end
    
    def convert_result_to_tracked(result, original_tracked_input, text, pattern)
      tracked_result = TrackedBitMask.new(result.size)
      
      # 元の開始位置情報を使って結果を構築
      original_tracked_input.get_pairs.each do |start_pos, _|
        # この開始位置から単独でパターンを適用
        single_start = BitMask.new(result.size)
        single_start.set(start_pos)
        
        single_result = pattern.apply(single_start, text, debug: false)
        single_result.set_positions.each do |end_pos|
          if result.get(end_pos)  # 全体の結果にも含まれている場合のみ
            tracked_result.set_with_start(start_pos, end_pos)
          end
        end
      end
      
      tracked_result
    end
  end
end
