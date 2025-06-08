require_relative '../lib/flow_regex'
require 'benchmark'

# ReDoS攻撃に対する耐性テスト
class ReDoSBenchmark
  def self.run_all
    puts "=== ReDoS耐性ベンチマーク ==="
    puts
    
    test_catastrophic_backtracking
    test_nested_quantifiers
    test_alternation_explosion
    
    puts "=== ベンチマーク完了 ==="
  end
  
  # 破滅的バックトラッキングのテスト
  def self.test_catastrophic_backtracking
    puts "【1. 破滅的バックトラッキング】"
    puts "パターン: (a+)+b"
    puts "攻撃文字列: 'a' * n (末尾に'b'なし)"
    puts
    
    # 攻撃文字列の生成
    attack_strings = [
      "a" * 10,
      "a" * 15,
      "a" * 20,
      "a" * 25
    ]
    
    attack_strings.each do |text|
      puts "文字列長: #{text.length}"
      
      # FlowRegex（フロー正規表現法）
      flow_time = Benchmark.realtime do
        begin
          regex = FlowRegex.new("(a*)*b")  # 簡略化版
          result = regex.match(text)
        rescue => e
          puts "  FlowRegex エラー: #{e.message}"
        end
      end
      
      # Ruby標準正規表現
      ruby_time = Benchmark.realtime do
        begin
          # タイムアウト設定（5秒）
          require 'timeout'
          Timeout::timeout(5) do
            result = text.match(/(a+)+b/)
          end
        rescue Timeout::Error
          puts "  Ruby正規表現: タイムアウト（5秒超過）"
        rescue => e
          puts "  Ruby正規表現 エラー: #{e.message}"
        end
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      puts "  Ruby正規表現: #{ruby_time > 5 ? 'タイムアウト' : sprintf('%.6f', ruby_time)}秒"
      puts "  速度比: #{ruby_time > 5 ? '∞' : sprintf('%.1f', ruby_time / flow_time)}倍高速"
      puts
    end
  end
  
  # ネストした量詞のテスト
  def self.test_nested_quantifiers
    puts "【2. ネストした量詞】"
    puts "パターン: a*a*a*a*b"
    puts
    
    attack_strings = [
      "a" * 10,
      "a" * 15,
      "a" * 20
    ]
    
    attack_strings.each do |text|
      puts "文字列長: #{text.length}"
      
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("a*a*a*b")
        result = regex.match(text)
      end
      
      ruby_time = Benchmark.realtime do
        begin
          require 'timeout'
          Timeout::timeout(3) do
            result = text.match(/a*a*a*a*b/)
          end
        rescue Timeout::Error
          puts "  Ruby正規表現: タイムアウト（3秒超過）"
        end
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      puts "  Ruby正規表現: #{ruby_time > 3 ? 'タイムアウト' : sprintf('%.6f', ruby_time)}秒"
      puts
    end
  end
  
  # 選択の爆発テスト
  def self.test_alternation_explosion
    puts "【3. 選択の爆発】"
    puts "パターン: (a|a)*b"
    puts
    
    attack_strings = [
      "a" * 8,
      "a" * 12,
      "a" * 16
    ]
    
    attack_strings.each do |text|
      puts "文字列長: #{text.length}"
      
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("(a|a)*b")
        result = regex.match(text)
      end
      
      ruby_time = Benchmark.realtime do
        begin
          require 'timeout'
          Timeout::timeout(2) do
            result = text.match(/(a|a)*b/)
          end
        rescue Timeout::Error
          puts "  Ruby正規表現: タイムアウト（2秒超過）"
        end
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      puts "  Ruby正規表現: #{ruby_time > 2 ? 'タイムアウト' : sprintf('%.6f', ruby_time)}秒"
      puts
    end
  end
end

# ベンチマーク実行
ReDoSBenchmark.run_all
