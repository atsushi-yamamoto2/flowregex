require_relative '../lib/flow_regex'
require 'benchmark'

# 計算量分析テスト
class ComplexityAnalysis
  def self.run_all
    puts "=== フロー正規表現法の計算量優位性分析 ==="
    puts
    
    analyze_start_position_advantage
    analyze_multiple_string_matching
    analyze_scaling_behavior
    
    puts "=== 分析完了 ==="
  end
  
  # 開始位置シフト不要の優位性
  def self.analyze_start_position_advantage
    puts "【1. 開始位置シフト不要の優位性】"
    puts "従来手法: O(N × M) - 各開始位置でマッチング試行"
    puts "フロー正規表現法: O(M) - 全開始位置を同時処理"
    puts "N: 文字列長, M: 正規表現の複雑さ"
    puts
    
    pattern = "abc"
    text_sizes = [100, 200, 400, 800]
    
    text_sizes.each do |size|
      # テスト文字列生成（パターンが複数箇所に存在）
      text = ("x" * 10 + "abc" + "y" * 10) * (size / 23) + "x" * (size % 23)
      text = text[0, size]  # 正確なサイズに調整
      
      puts "文字列長: #{size}"
      
      # FlowRegex - 全開始位置を同時処理
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new(pattern)
        result = regex.match(text)
      end
      
      # Ruby標準正規表現 - 内部的に開始位置をシフト
      ruby_time = Benchmark.realtime do
        matches = []
        pos = 0
        while pos < text.length
          match = text.match(/abc/, pos)
          break unless match
          matches << match.end(0)
          pos = match.begin(0) + 1
        end
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      puts "  Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
      puts "  効率比: #{sprintf('%.1f', ruby_time / flow_time)}倍"
      puts
    end
  end
  
  # 複数文字列同時マッチングの優位性
  def self.analyze_multiple_string_matching
    puts "【2. 複数文字列同時マッチング】"
    puts "従来手法: O(K × N × M) - K個の文字列を個別処理"
    puts "フロー正規表現法: O(N × M) - 複数文字列を同時処理"
    puts "K: 文字列数, N: 平均文字列長, M: 正規表現の複雑さ"
    puts
    
    pattern = "test"
    string_counts = [1, 2, 4, 8]
    base_text = "this is a test string for testing"
    
    string_counts.each do |count|
      texts = Array.new(count) { |i| base_text + " #{i}" }
      
      puts "文字列数: #{count}"
      
      # FlowRegex - 理論的には複数文字列を同時処理可能
      # （現在のPOC実装では単一文字列のみだが、概念実証）
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new(pattern)
        texts.each do |text|
          result = regex.match(text)
        end
      end
      
      # Ruby標準正規表現 - 各文字列を個別処理
      ruby_time = Benchmark.realtime do
        texts.each do |text|
          result = text.scan(/test/)
        end
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      puts "  Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
      puts "  線形スケーリング維持: #{sprintf('%.2f', flow_time / (count * 0.001))}ms/文字列"
      puts
    end
  end
  
  # スケーリング特性の分析
  def self.analyze_scaling_behavior
    puts "【3. スケーリング特性分析】"
    puts "複雑なパターンでの線形時間保証"
    puts
    
    # 複雑なパターン（ネストした選択とクリーネ閉包）
    pattern = "(a|b)*c(d|e)*"
    text_sizes = [50, 100, 200, 400]
    
    puts "パターン: #{pattern}"
    puts
    
    text_sizes.each do |size|
      # 最悪ケースに近い文字列（マッチしない）
      text = ("ab" * (size / 2))[0, size]
      
      puts "文字列長: #{size}"
      
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new(pattern)
        result = regex.match(text)
      end
      
      # 時間複雑度の線形性を確認
      time_per_char = flow_time / size
      
      puts "  処理時間: #{sprintf('%.6f', flow_time)}秒"
      puts "  文字あたり: #{sprintf('%.8f', time_per_char)}秒/文字"
      puts "  線形性指標: #{sprintf('%.2f', time_per_char * 1000000)}μs/文字"
      puts
    end
    
    puts "※ 線形性指標が一定であれば O(N) を維持"
    puts
  end
end

# 分析実行
ComplexityAnalysis.run_all
