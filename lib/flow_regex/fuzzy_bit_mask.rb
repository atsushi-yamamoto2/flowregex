class FlowRegex
  # ファジーマッチング用の3次元ビットマスク
  # [text_position][pattern_position][distance] の組み合わせを表す
  # 編集距離（置換・挿入・削除）の完全サポートを想定した設計
  class FuzzyBitMask
    attr_reader :text_length, :pattern_length, :max_distance
    
    def initialize(text_length, pattern_length, max_distance)
      @text_length = text_length
      @pattern_length = pattern_length
      @max_distance = max_distance
      
      # GPU移植を考慮した1次元配列での実装
      # インデックス計算: text_pos * (pattern_length + 1) * (max_distance + 1) + 
      #                  pattern_pos * (max_distance + 1) + distance
      @text_stride = (pattern_length + 1) * (max_distance + 1)
      @pattern_stride = max_distance + 1
      @bits = Array.new((text_length + 1) * @text_stride, false)
    end
    
    # 指定位置・距離のビットを設定
    def set(text_pos, pattern_pos, distance)
      return unless valid_indices?(text_pos, pattern_pos, distance)
      idx = calculate_index(text_pos, pattern_pos, distance)
      @bits[idx] = true
    end
    
    # 指定位置・距離のビットを取得
    def get(text_pos, pattern_pos, distance)
      return false unless valid_indices?(text_pos, pattern_pos, distance)
      idx = calculate_index(text_pos, pattern_pos, distance)
      @bits[idx]
    end
    
    # 全てのビットをクリア
    def clear!
      @bits.fill(false)
    end
    
    # 他のファジービットマスクとのOR演算
    def or!(other)
      return self unless compatible?(other)
      
      @bits.size.times do |i|
        @bits[i] = @bits[i] || other.bits[i]
      end
      self
    end
    
    # 他のファジービットマスクとのOR演算（新しいインスタンスを返す）
    def or(other)
      result = FuzzyBitMask.new(@text_length, @pattern_length, @max_distance)
      return result unless compatible?(other)
      
      @bits.size.times do |i|
        result.bits[i] = @bits[i] || other.bits[i]
      end
      result
    end
    
    # ファジービットマスクのコピー
    def copy
      result = FuzzyBitMask.new(@text_length, @pattern_length, @max_distance)
      @bits.size.times do |i|
        result.bits[i] = @bits[i]
      end
      result
    end
    
    # 設定されているビットの位置・距離の組み合わせを配列で取得
    def set_positions
      positions = []
      (0..@text_length).each do |text_pos|
        (0..@pattern_length).each do |pattern_pos|
          (0..@max_distance).each do |distance|
            if get(text_pos, pattern_pos, distance)
              positions << [text_pos, pattern_pos, distance]
            end
          end
        end
      end
      positions
    end
    
    # パターン完全マッチの終了位置を取得（距離別）
    def match_end_positions
      results = {}
      (0..@max_distance).each do |distance|
        positions = []
        (0..@text_length).each do |text_pos|
          if get(text_pos, @pattern_length, distance)
            positions << text_pos
          end
        end
        results[distance] = positions unless positions.empty?
      end
      results
    end
    
    # 2つのファジービットマスクが等しいかチェック
    def ==(other)
      return false unless compatible?(other)
      @bits == other.bits
    end
    
    # デバッグ用の文字列表現（簡略版）
    def to_s
      match_positions = match_end_positions
      "FuzzyBitMask[#{@text_length}x#{@pattern_length}x#{@max_distance}] matches: #{match_positions}"
    end
    
    # より詳細なデバッグ情報
    def inspect
      positions = set_positions
      "FuzzyBitMask[#{@text_length}x#{@pattern_length}x#{@max_distance}] (active: #{positions.size})"
    end
    
    # 空のビットマスクかチェック
    def empty?
      @bits.none?
    end
    
    # 後方互換性：通常のBitMaskのような結果を返す（距離0のマッチのみ）
    def compatible_positions
      match_end_positions[0] || []
    end
    
    protected
    
    attr_reader :bits
    
    private
    
    # インデックスの有効性チェック
    def valid_indices?(text_pos, pattern_pos, distance)
      text_pos >= 0 && text_pos <= @text_length &&
      pattern_pos >= 0 && pattern_pos <= @pattern_length &&
      distance >= 0 && distance <= @max_distance
    end
    
    # 3次元座標から1次元インデックスを計算
    def calculate_index(text_pos, pattern_pos, distance)
      text_pos * @text_stride + pattern_pos * @pattern_stride + distance
    end
    
    # 他のビットマスクとの互換性チェック
    def compatible?(other)
      other.is_a?(FuzzyBitMask) &&
      @text_length == other.text_length &&
      @pattern_length == other.pattern_length &&
      @max_distance == other.max_distance
    end
  end
end
