require_relative '../lib/flow_regex'

# BitMask演算の詳細テスト
class TestBitMaskOperations
  def self.run_test
    puts "=== BitMask演算詳細テスト ==="
    
    # テスト用のテキストとパターン
    text = "ATGCATGCATGC"
    pattern = "ATG"
    
    puts "テキスト: #{text}"
    puts "パターン: #{pattern}"
    puts
    
    # 最適化テキストを作成
    optimized = FlowRegex.optimize_for_dna(text)
    
    # MatchMaskの内容を確認
    puts "--- MatchMask内容確認 ---"
    ['A', 'T', 'G', 'C'].each do |char|
      mask = optimized.get_match_mask(char)
      puts "文字 '#{char}': #{mask.to_s} (positions: #{mask.set_positions})"
    end
    puts
    
    # 実際のマッチング処理をステップバイステップで確認
    puts "--- マッチング処理詳細 ---"
    regex = FlowRegex.new(pattern)
    
    # デバッグモードでマッチング実行
    puts "通常処理:"
    normal_result = regex.match(text, debug: true)
    puts
    
    puts "最適化処理:"
    optimized_result = regex.match_optimized(optimized, debug: true)
    puts
    
    # 結果比較
    puts "--- 結果比較 ---"
    puts "通常処理結果: #{normal_result}"
    puts "最適化処理結果: #{optimized_result}"
    
    if normal_result == optimized_result
      puts "✓ 結果一致"
    else
      puts "✗ 結果不一致"
    end
    
    puts
    puts "=== テスト完了 ==="
  end
end

# テスト実行
if __FILE__ == $0
  TestBitMaskOperations.run_test
end
