require_relative '../lib/flow_regex'

# 大規模DNA塩基配列でのパフォーマンステスト
class TestLargeDNAPerformance
  def self.run_test
    puts "=== 大規模DNA塩基配列パフォーマンステスト ==="
    
    # より大きなDNA塩基配列を生成（ATGC）
    dna_sequence = generate_dna_sequence(8000)  # 8000文字のDNA配列
    puts "DNA配列長: #{dna_sequence.length}文字"
    puts "配列サンプル: #{dna_sequence[0..50]}..."
    puts
    
    # テストパターン（生物学的に意味のあるパターン）
    test_patterns = [
      "ATG",        # 開始コドン
      "TAA",        # 終止コドン（アンバー）
      "TAG",        # 終止コドン（オーカー）
      "TGA",        # 終止コドン（オパール）
      "TATA",       # TATAボックス
      "CAAT",       # CAATボックス
      "GAATTC",     # EcoRI制限酵素認識配列
      "AAGCTT",     # HindIII制限酵素認識配列
      "GGATCC",     # BamHI制限酵素認識配列
      "CCGCGG"      # SacII制限酵素認識配列
    ]
    
    puts "テストパターン数: #{test_patterns.length}"
    puts "各パターン100回実行でのパフォーマンス測定"
    puts
    
    total_normal_time = 0
    total_optimized_time = 0
    improvement_count = 0
    
    test_patterns.each_with_index do |pattern, index|
      puts "--- #{index + 1}/#{test_patterns.length}: パターン '#{pattern}' ---"
      normal_time, optimized_time, improved = test_pattern_performance(dna_sequence, pattern)
      
      total_normal_time += normal_time
      total_optimized_time += optimized_time
      improvement_count += 1 if improved
      
      puts
    end
    
    # 全体統計
    puts "=== 全体統計 ==="
    puts "総通常処理時間: #{(total_normal_time * 1000).round(2)}ms"
    puts "総最適化処理時間: #{(total_optimized_time * 1000).round(2)}ms"
    
    if total_optimized_time < total_normal_time
      overall_improvement = ((total_normal_time - total_optimized_time) / total_normal_time * 100).round(1)
      puts "✓ 全体パフォーマンス改善: #{overall_improvement}%高速化"
    else
      overall_degradation = ((total_optimized_time - total_normal_time) / total_normal_time * 100).round(1)
      puts "✗ 全体パフォーマンス低下: #{overall_degradation}%遅延"
    end
    
    puts "改善したパターン: #{improvement_count}/#{test_patterns.length} (#{(improvement_count.to_f / test_patterns.length * 100).round(1)}%)"
    puts
    puts "=== テスト完了 ==="
  end
  
  private
  
  def self.generate_dna_sequence(length)
    bases = ['A', 'T', 'G', 'C']
    sequence = ""
    
    # より現実的なDNA配列を生成（GC含量を考慮）
    length.times do |i|
      # 周期的にGC含量を変化させる
      if (i / 100) % 2 == 0
        # GC rich region
        sequence += ['G', 'C', 'A', 'T'].sample
      else
        # AT rich region  
        sequence += ['A', 'T', 'G', 'C'].sample
      end
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
    iterations = 100
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
    puts "通常処理時間: #{(normal_time * 1000).round(2)}ms"
    puts "最適化処理時間: #{(optimized_time * 1000).round(2)}ms"
    
    improved = false
    if optimized_time < normal_time
      improvement = ((normal_time - optimized_time) / normal_time * 100).round(1)
      puts "✓ パフォーマンス改善: #{improvement}%高速化"
      improved = true
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
    
    [normal_time, optimized_time, improved]
  end
end

# テスト実行
if __FILE__ == $0
  TestLargeDNAPerformance.run_test
end
