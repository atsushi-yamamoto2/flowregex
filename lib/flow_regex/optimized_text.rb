class FlowRegex
  # 事前計算されたMatchMaskを持つ最適化テキスト
  # 指定された文字のMatchMaskを事前計算し、高速なリテラルマッチングを実現
  class OptimizedText
    attr_reader :text, :precomputed_chars, :match_masks
    
    def initialize(text, precompute_chars: [])
      @text = text.to_s
      @precomputed_chars = precompute_chars.map(&:to_s).uniq
      @match_masks = {}
      @fallback_cache = {}
      
      # 指定された文字のMatchMaskを事前計算
      @precomputed_chars.each do |char|
        @match_masks[char] = compute_match_mask(char)
      end
    end
    
    # 指定文字のMatchMaskを取得
    def get_match_mask(char)
      char_str = char.to_s
      
      # 事前計算済みの場合
      return @match_masks[char_str] if @match_masks.key?(char_str)
      
      # フォールバックキャッシュにある場合
      return @fallback_cache[char_str] if @fallback_cache.key?(char_str)
      
      # 動的計算（警告付き）
      warn "Character '#{char_str}' not precomputed, falling back to dynamic calculation"
      @fallback_cache[char_str] = compute_match_mask(char_str)
    end
    
    # 最適化されたテキストかどうかの判定
    def optimized?
      true
    end
    
    # 事前計算された文字かどうかの判定
    def precomputed?(char)
      @precomputed_chars.include?(char.to_s)
    end
    
    # 統計情報
    def optimization_stats
      {
        text_length: @text.length,
        precomputed_chars: @precomputed_chars.size,
        precomputed_list: @precomputed_chars,
        fallback_chars: @fallback_cache.keys.size,
        fallback_list: @fallback_cache.keys
      }
    end
    
    # Stringのメソッドを委譲
    def length
      @text.length
    end
    
    def [](index)
      @text[index]
    end
    
    def chars
      @text.chars
    end
    
    def each_char
      @text.each_char
    end
    
    def to_s
      @text
    end
    
    def inspect
      "#<OptimizedText:#{object_id} text=#{@text.inspect} precomputed=#{@precomputed_chars}>"
    end
    
    # その他のStringメソッドを委譲
    def method_missing(method, *args, &block)
      if @text.respond_to?(method)
        @text.send(method, *args, &block)
      else
        super
      end
    end
    
    def respond_to_missing?(method, include_private = false)
      @text.respond_to?(method, include_private) || super
    end
    
    private
    
    # 指定文字のMatchMaskを計算
    def compute_match_mask(char)
      mask = BitMask.new(@text.length + 1)
      
      @text.each_char.with_index do |c, i|
        if c == char
          mask.set(i)
        end
      end
      
      mask
    end
  end
end
