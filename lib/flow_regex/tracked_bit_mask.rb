require 'set'

class FlowRegex
  # 開始位置を追跡するビットマスク
  # 先読み演算子での同じ開始位置での集合演算を可能にする
  class TrackedBitMask < BitMask
    def initialize(size)
      super(size)
      # 終了位置 => 開始位置の集合のマッピング
      @start_map = {}
    end
    
    # 開始位置と終了位置のペアを設定
    def set_with_start(start_pos, end_pos)
      return if start_pos < 0 || start_pos >= @size
      return if end_pos < 0 || end_pos >= @size
      
      set(end_pos)  # 通常のBitMaskとしても設定
      @start_map[end_pos] ||= Set.new
      @start_map[end_pos].add(start_pos)
    end
    
    # 指定終了位置の開始位置集合を取得
    def get_starts(end_pos)
      @start_map[end_pos] || Set.new
    end
    
    # 全ての開始-終了位置ペアを取得
    def get_pairs
      pairs = []
      @start_map.each do |end_pos, start_set|
        start_set.each do |start_pos|
          pairs << [start_pos, end_pos]
        end
      end
      pairs
    end
    
    # 先読み用積集合：同じ開始位置を持つもののみ
    def lookahead_intersect(other)
      result = TrackedBitMask.new(@size)
      
      get_pairs.each do |start_a, end_a|
        # 同じ開始位置でotherにもマッチがあるかチェック
        if other.get_pairs.any? { |start_b, end_b| start_a == start_b }
          result.set_with_start(start_a, end_a)
        end
      end
      
      result
    end
    
    # 先読み用差集合：同じ開始位置でotherがマッチしない場合のみ
    def lookahead_subtract(other)
      result = TrackedBitMask.new(@size)
      
      get_pairs.each do |start_a, end_a|
        # 同じ開始位置でotherにマッチがないかチェック
        unless other.get_pairs.any? { |start_b, end_b| start_a == start_b }
          result.set_with_start(start_a, end_a)
        end
      end
      
      result
    end
    
    # TrackedBitMaskのコピー
    def copy
      result = TrackedBitMask.new(@size)
      get_pairs.each do |start_pos, end_pos|
        result.set_with_start(start_pos, end_pos)
      end
      result
    end
    
    # 他のTrackedBitMaskとのOR演算
    def or!(other)
      super(other)  # 通常のBitMaskとしてのOR演算
      
      # 開始位置情報もマージ
      other.get_pairs.each do |start_pos, end_pos|
        set_with_start(start_pos, end_pos)
      end
      
      self
    end
    
    # 通常のBitMaskに変換
    def to_bit_mask
      result = BitMask.new(@size)
      set_positions.each { |pos| result.set(pos) }
      result
    end
    
    # 通常のBitMaskからTrackedBitMaskに変換（開始位置=終了位置として初期化）
    def self.from_bit_mask(bit_mask)
      result = TrackedBitMask.new(bit_mask.size)
      bit_mask.set_positions.each do |pos|
        result.set_with_start(pos, pos)
      end
      result
    end
    
    # デバッグ用の詳細表示
    def inspect_tracked
      pairs = get_pairs.sort
      "TrackedBitMask[#{to_s}] (pairs: #{pairs})"
    end
    
    # 空のTrackedBitMaskかチェック
    def empty?
      @start_map.empty?
    end
  end
end
