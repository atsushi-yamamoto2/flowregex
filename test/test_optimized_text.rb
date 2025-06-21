require_relative '../lib/flow_regex'

# MatchMask最適化機能のテスト
class TestOptimizedText
  def self.run_all_tests
    puts "=== OptimizedText機能テスト開始 ==="
    
    test_basic_optimization
    test_match_accuracy
    test_preset_character_sets
    test_performance_comparison
    
    puts "=== 全テスト完了 ==="
  end
  
  # 基本的な最適化機能のテスト
  def self.test_basic_optimization
    puts "\n--- 基本最適化テスト ---"
    
    text = "hello world test"
    optimized = FlowRegex.optimize_text(text, alphabets: "abcdefghijklmnopqrstuvwxyz ")
    
    # OptimizedTextオブジェクトが正しく作成されているか
    if optimized.is_a?(FlowRegex::OptimizedText)
      puts "✓ OptimizedTextオブジェクト作成成功"
    else
      puts "✗ OptimizedTextオブジェクト作成失敗"
    end
    
    # 元のテキストが保持されているか
    if optimized.text == text
      puts "✓ 元テキスト保持確認"
    else
      puts "✗ 元テキスト保持失敗"
    end
    
    # MatchMaskが作成されているか
    if optimized.match_masks.is_a?(Hash) && !optimized.match_masks.empty?
      puts "✓ MatchMask作成確認"
    else
      puts "✗ MatchMask作成失敗"
    end
  end
  
  # マッチング精度のテスト
  def self.test_match_accuracy
    puts "\n--- マッチング精度テスト ---"
    
    text = "abcdefghijklmnopqrstuvwxyz"
    optimized = FlowRegex.optimize_text(text, alphabets: "abcdefghijklmnopqrstuvwxyz")
    
    test_cases = [
      { pattern: "abc", expected_positions: [0] },
      { pattern: "def", expected_positions: [3] },
      { pattern: "xyz", expected_positions: [23] },
      { pattern: "hello", expected_positions: [] },
      { pattern: "a", expected_positions: [0] },
      { pattern: "z", expected_positions: [25] }
    ]
    
    test_cases.each do |test_case|
      pattern = test_case[:pattern]
      expected = test_case[:expected_positions]
      
      # 通常のFlowRegexでマッチング
      regex = FlowRegex.new(pattern)
      normal_result = regex.match(text)
      normal_positions = normal_result
      
      # 最適化されたテキストでマッチング
      optimized_result = regex.match_optimized(optimized)
      optimized_positions = optimized_result
      
      if normal_positions == optimized_positions && normal_positions == expected
        puts "✓ パターン '#{pattern}': 正確なマッチング"
      else
        puts "✗ パターン '#{pattern}': マッチング不一致"
        puts "  期待値: #{expected}"
        puts "  通常処理: #{normal_positions}"
        puts "  最適化処理: #{optimized_positions}"
      end
    end
  end
  
  # プリセット文字セットのテスト
  def self.test_preset_character_sets
    puts "\n--- プリセット文字セットテスト ---"
    
    text = "Hello123 World!"
    optimized = FlowRegex.optimize_text(text, alphabets: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 !")
    
    # 数字のマッチング
    if optimized.match_masks.key?('0') && optimized.match_masks.key?('9')
      puts "✓ 数字文字セット作成確認"
    else
      puts "✗ 数字文字セット作成失敗"
    end
    
    # アルファベットのマッチング
    if optimized.match_masks.key?('H') && optimized.match_masks.key?('o')
      puts "✓ アルファベット文字セット作成確認"
    else
      puts "✗ アルファベット文字セット作成失敗"
    end
    
    # 特殊文字のマッチング
    if optimized.match_masks.key?(' ') && optimized.match_masks.key?('!')
      puts "✓ 特殊文字セット作成確認"
    else
      puts "✗ 特殊文字セット作成失敗"
    end
  end
  
  # パフォーマンス比較テスト
  def self.test_performance_comparison
    puts "\n--- パフォーマンス比較テスト ---"
    
    # 長いテキストを作成（制限内に収める）
    long_text = "abcdefghijklmnopqrstuvwxyz" * 30  # 780文字
    pattern = "xyz"
    
    # 最適化テキストを作成
    optimized = FlowRegex.optimize_text(long_text, alphabets: "abcdefghijklmnopqrstuvwxyz")
    regex = FlowRegex.new(pattern)
    
    # 通常処理の時間測定
    start_time = Time.now
    100.times { regex.match(long_text) }
    normal_time = Time.now - start_time
    
    # 最適化処理の時間測定
    start_time = Time.now
    100.times { regex.match_optimized(optimized) }
    optimized_time = Time.now - start_time
    
    puts "通常処理時間: #{(normal_time * 1000).round(2)}ms"
    puts "最適化処理時間: #{(optimized_time * 1000).round(2)}ms"
    
    if optimized_time < normal_time
      improvement = ((normal_time - optimized_time) / normal_time * 100).round(1)
      puts "✓ パフォーマンス改善: #{improvement}%高速化"
    else
      puts "✗ パフォーマンス改善なし"
    end
  end
end

# テスト実行
if __FILE__ == $0
  TestOptimizedText.run_all_tests
end
