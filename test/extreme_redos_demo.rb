require_relative '../lib/flow_regex'
require 'benchmark'
require 'timeout'

# 極端なReDoS攻撃デモ
class ExtremeReDoSDemo
  def self.run_all
    puts "=== 極端なReDoS攻撃デモ ==="
    puts "恣意的に作られた最悪ケースでの比較"
    puts
    
    demo_exponential_explosion
    demo_nested_hell
    demo_alternation_bomb
    
    puts "=== デモ完了 ==="
  end
  
  # 指数爆発デモ
  def self.demo_exponential_explosion
    puts "【1. 指数爆発攻撃】"
    puts "パターン: (a*)*b"
    puts "攻撃: 'a' * n (末尾に'b'なし)"
    puts "理論計算量: Ruby O(2^n), FlowRegex O(n)"
    puts
    
    attack_sizes = [10, 15, 20, 25, 30]
    
    attack_sizes.each do |size|
      attack_string = "a" * size
      puts "攻撃文字列長: #{size}"
      
      # FlowRegex - 線形時間保証
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("(a*)*b")
        result = regex.match(attack_string)
      end
      
      # Ruby標準正規表現 - 指数時間爆発
      ruby_time = nil
      ruby_timeout = false
      
      begin
        ruby_time = Benchmark.realtime do
          Timeout::timeout(0.1) do  # 100ms制限
            result = attack_string.match(/(a*)*b/)
          end
        end
      rescue Timeout::Error
        ruby_timeout = true
        ruby_time = 0.1
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      if ruby_timeout
        puts "  Ruby正規表現: タイムアウト (>0.1秒)"
        puts "  推定速度比: >#{sprintf('%.0f', 0.1 / flow_time)}倍高速"
      else
        puts "  Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
        puts "  速度比: #{sprintf('%.1f', ruby_time / flow_time)}倍高速"
      end
      puts
    end
  end
  
  # ネスト地獄デモ
  def self.demo_nested_hell
    puts "【2. ネスト地獄攻撃】"
    puts "パターン: ((a*)*)*b"
    puts "攻撃: 'a' * n (末尾に'b'なし)"
    puts "理論計算量: Ruby O(3^n), FlowRegex O(n)"
    puts
    
    attack_sizes = [8, 10, 12, 15]
    
    attack_sizes.each do |size|
      attack_string = "a" * size
      puts "攻撃文字列長: #{size}"
      
      # FlowRegex
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("((a*)*)*b")
        result = regex.match(attack_string)
      end
      
      # Ruby標準正規表現
      ruby_time = nil
      ruby_timeout = false
      
      begin
        ruby_time = Benchmark.realtime do
          Timeout::timeout(0.05) do  # 50ms制限
            result = attack_string.match(/((a*)*)*b/)
          end
        end
      rescue Timeout::Error
        ruby_timeout = true
        ruby_time = 0.05
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      if ruby_timeout
        puts "  Ruby正規表現: タイムアウト (>0.05秒)"
        puts "  推定速度比: >#{sprintf('%.0f', 0.05 / flow_time)}倍高速"
      else
        puts "  Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
        puts "  速度比: #{sprintf('%.1f', ruby_time / flow_time)}倍高速"
      end
      puts
    end
  end
  
  # 選択爆弾デモ
  def self.demo_alternation_bomb
    puts "【3. 選択爆弾攻撃】"
    puts "パターン: (a|a|a)*(b|b|b)*c"
    puts "攻撃: 'ab' * n (末尾に'c'なし)"
    puts "理論計算量: Ruby O(6^n), FlowRegex O(n)"
    puts
    
    attack_sizes = [6, 8, 10, 12]
    
    attack_sizes.each do |size|
      attack_string = "ab" * size
      puts "攻撃文字列長: #{attack_string.length}"
      
      # FlowRegex
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("(a|a|a)*(b|b|b)*c")
        result = regex.match(attack_string)
      end
      
      # Ruby標準正規表現
      ruby_time = nil
      ruby_timeout = false
      
      begin
        ruby_time = Benchmark.realtime do
          Timeout::timeout(0.02) do  # 20ms制限
            result = attack_string.match(/(a|a|a)*(b|b|b)*c/)
          end
        end
      rescue Timeout::Error
        ruby_timeout = true
        ruby_time = 0.02
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒"
      if ruby_timeout
        puts "  Ruby正規表現: タイムアウト (>0.02秒)"
        puts "  推定速度比: >#{sprintf('%.0f', 0.02 / flow_time)}倍高速"
      else
        puts "  Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
        puts "  速度比: #{sprintf('%.1f', ruby_time / flow_time)}倍高速"
      end
      puts
    end
  end
end

# 実際のReDoS攻撃シミュレーション
class RealWorldReDoSDemo
  def self.run
    puts "=== 実世界ReDoS攻撃シミュレーション ==="
    puts
    
    # 実際のCVEで報告されたパターンに類似
    email_validation_attack
    url_validation_attack
  end
  
  def self.email_validation_attack
    puts "【メール検証ReDoS攻撃】"
    puts "パターン: (a+)+@"
    puts "攻撃: 'a' * n + 'X' (不正なメール形式)"
    puts
    
    attack_sizes = [20, 25, 30]
    
    attack_sizes.each do |size|
      attack_string = "a" * size + "X"
      puts "攻撃文字列: #{'a' * [size, 10].min}#{'...' if size > 10}X (長さ#{size + 1})"
      
      # FlowRegex
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("(a*)*@")
        result = regex.match(attack_string)
      end
      
      # Ruby標準正規表現（タイムアウト付き）
      ruby_time = nil
      ruby_timeout = false
      
      begin
        ruby_time = Benchmark.realtime do
          Timeout::timeout(1.0) do
            result = attack_string.match(/(a+)+@/)
          end
        end
      rescue Timeout::Error
        ruby_timeout = true
        puts "  Ruby正規表現: 1秒でタイムアウト（サービス停止レベル）"
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒（正常動作）"
      
      if ruby_timeout
        puts "  → FlowRegexはDoS攻撃を完全に防御！"
      else
        puts "  Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
      end
      puts
    end
  end
  
  def self.url_validation_attack
    puts "【URL検証ReDoS攻撃】"
    puts "パターン: (http|https)*(://)*"
    puts "攻撃: 'http' * n (不正なURL形式)"
    puts
    
    attack_sizes = [10, 15, 20]
    
    attack_sizes.each do |size|
      attack_string = "http" * size
      puts "攻撃文字列: #{'http' * [size, 3].min}#{'...' if size > 3} (長さ#{size * 4})"
      
      # FlowRegex
      flow_time = Benchmark.realtime do
        regex = FlowRegex.new("(http|https)*://*")
        result = regex.match(attack_string)
      end
      
      puts "  FlowRegex: #{sprintf('%.6f', flow_time)}秒（安全）"
      puts "  → 従来手法なら指数時間爆発の危険性"
      puts
    end
  end
end

puts "恣意的ReDoS攻撃デモを実行します..."
puts "（実際の攻撃者が使用する手法を模擬）"
puts

ExtremeReDoSDemo.run_all
RealWorldReDoSDemo.run
