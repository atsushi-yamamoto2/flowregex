class FlowRegex
  # ビットマスクによる位置集合の管理
  # 各ビットは文字列の位置を表し、1ならその位置でマッチ可能
  class BitMask
    attr_reader :bits, :size
    
    def initialize(size)
      @size = size
      @bits = Array.new(size, false)
    end
    
    # 指定位置のビットを設定
    def set(position)
      return if position < 0 || position >= @size
      @bits[position] = true
    end
    
    # 指定位置のビットを取得
    def get(position)
      return false if position < 0 || position >= @size
      @bits[position]
    end
    
    # 全てのビットをクリア
    def clear!
      @bits.fill(false)
    end
    
    # 他のビットマスクとのOR演算
    def or!(other)
      @size.times do |i|
        @bits[i] = @bits[i] || other.get(i)
      end
      self
    end
    
    # 他のビットマスクとのOR演算（新しいインスタンスを返す）
    def or(other)
      result = BitMask.new(@size)
      @size.times do |i|
        result.set(i) if @bits[i] || other.get(i)
      end
      result
    end
    
    # ビットマスクのコピー
    def copy
      result = BitMask.new(@size)
      @size.times do |i|
        result.set(i) if @bits[i]
      end
      result
    end
    
    # 設定されているビットの位置を配列で取得
    def set_positions
      positions = []
      @size.times do |i|
        positions << i if @bits[i]
      end
      positions
    end
    
    # 2つのビットマスクが等しいかチェック
    def ==(other)
      return false unless other.is_a?(BitMask)
      return false unless @size == other.size
      
      @size.times do |i|
        return false if @bits[i] != other.get(i)
      end
      true
    end
    
    # デバッグ用の文字列表現
    def to_s
      @bits.map { |b| b ? '1' : '0' }.join
    end
    
    # より詳細なデバッグ情報
    def inspect
      positions = set_positions
      "BitMask[#{to_s}] (positions: #{positions})"
    end
    
    # 空のビットマスクかチェック
    def empty?
      @bits.none?
    end
  end
end
