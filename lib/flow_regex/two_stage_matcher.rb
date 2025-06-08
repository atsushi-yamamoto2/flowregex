class FlowRegex
  # 2段階マッチング：フロー正規表現法 + 逆方向従来手法
  # 1. 高速で終了位置を特定
  # 2. 各終了位置から逆方向にマッチして部分文字列を抽出
  class TwoStageMatcher
    def initialize(pattern)
      @pattern = pattern
      @flow_regex = FlowRegex.new(pattern)
    end
    
    def match_with_substrings(text)
      # Step 1: フロー正規表現法で終了位置を高速取得
      end_positions = @flow_regex.match(text)
      
      return [] if end_positions.empty?
      
      # Step 2: 各終了位置から逆方向マッチで部分文字列を抽出
      matches = []
      
      end_positions.each do |end_pos|
        next if end_pos == 0  # 空マッチはスキップ
        
        # 逆方向マッチで開始位置を特定
        start_pos = find_start_position(text, end_pos)
        
        if start_pos
          substring = text[start_pos...end_pos]
          matches << {
            start: start_pos,
            end: end_pos,
            substring: substring
          }
        end
      end
      
      matches.uniq { |m| [m[:start], m[:end]] }
    end
    
    private
    
    def find_start_position(text, end_pos)
      # 簡単な実装：終了位置から逆方向に従来の正規表現でマッチ
      # より効率的な実装では、パターンを反転して逆方向マッチ
      
      # 最大探索範囲を制限（メモリ効率のため）
      max_search_length = [end_pos, 1000].min
      start_search = [0, end_pos - max_search_length].max
      
      # 各可能な開始位置を試行
      (start_search...end_pos).reverse_each do |start_pos|
        substring = text[start_pos...end_pos]
        
        # Ruby の正規表現で検証（POC用の簡易実装）
        if substring.match(/^#{convert_to_ruby_regex(@pattern)}$/)
          return start_pos
        end
      end
      
      nil
    end
    
    def convert_to_ruby_regex(flow_pattern)
      # FlowRegex パターンを Ruby 正規表現に変換（簡易版）
      # 実際の実装では、より複雑な変換が必要
      
      # 基本的な変換
      ruby_pattern = flow_pattern
      ruby_pattern = ruby_pattern.gsub('*', '.*')  # 簡易的な変換
      
      ruby_pattern
    end
  end
end
