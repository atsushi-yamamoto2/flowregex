require_relative '../lib/flow_regex'

# DNA塩基配列でのパフォーマンステスト
class TestDNAPerformance
  def self.run_test
    puts "=== DNA塩基配列パフォーマンステスト ==="
    
    # DNA塩基配列を生成（ATGC）
    dna_sequence = generate_dna_sequence(800)  # 800文字のDNA配列
    puts "DNA配列長: #{dna_sequence.length}文字"
    puts "配列サンプル: #{dna_sequence[0..50]}..."
    puts
    
    # テストパターン
    test_patterns = [
      "ATG",    # 開始コドン
      "TAA",    # 終止コドン
      "GC",     # GC配列
      "ATGC",   # 4塩基
      "AAAA",   # 同一塩基の繰り返し
      "CGCG"    # 交互配列
    ]
    
    test_patterns.each do |pattern|
      puts "--- パターン: #{pattern} ---"
      test_pattern_performance(dna_sequence, pattern)
      puts
    end
    
    puts "=== テスト完了 ==="
  end
  
  private
  
  def self.generate_dna_sequence(length)
    bases = ['A', 'T', 'G', 'C']
    sequence = ""
    
    length.times do
      sequence += bases.sample
    end
    
    sequence
  end
  
  def self.test_pattern_performance(dna_sequence, pattern)
    # 通常のFlowRegex
    regex = FlowRegex.new(pattern)
    
    # DNA用最適化テキスト
    optimized_dna = FlowRegex.optimize_for_dna(dna_sequence)
    
    # 通常処理の時間測定
    start_time = Time.now
    iterations = 200
    normal_results = []
    iterations.times do
      result = regex.match(dna_sequence)
      normal_results << result
    end
    normal_time = Time.now - start_time
    
    # 最適化処理の時間測定
    start_time = Time.now
    optimized_results = []
    iterations.times do
      result = regex.match_optimized(optimized_dna)
      optimized_results << result
    end
    optimized_time = Time.now - start_time
    
    # 結果の一致確認
    normal_match = normal_results.first
    optimized_match = optimized_results.first
    
    results_match = (normal_match.nil? && optimized_match.nil?) ||
                   (normal_match && optimized_match && 
                    normal_match[:start] == optimized_match[:start] &&
                    normal_match[:match] == optimized_match[:match])
    
    # 結果表示
    puts "通常処理時間: #{(normal_time * 1000).round(2)}ms (#{iterations}回)"
    puts "最適化処理時間: #{(optimized_time * 1000).round(2)}ms (#{iterations}回)"
    
    if optimized_time < normal_time
      improvement = ((normal_time - optimized_time) / normal_time * 100).round(1)
      puts "✓ パフォーマンス改善: #{improvement}%高速化"
    else
      degradation = ((optimized_time - normal_time) / normal_time * 100).round(1)
      puts "✗ パフォーマンス低下: #{degradation}%遅延"
    end
    
    if results_match
      puts "✓ 結果一致確認"
    else
      puts "✗ 結果不一致"
      puts "  通常: #{normal_match}"
      puts "  最適化: #{optimized_match}"
    end
    
    # マッチ情報
    if normal_match
      puts "マッチ位置: #{normal_match[:start]} (#{normal_match[:match]})"
    else
      puts "マッチなし"
    end
  end
end

# テスト実行
if __FILE__ == $0
  TestDNAPerformance.run_test
end
