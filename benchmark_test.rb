require_relative 'lib/flow_regex'
require 'benchmark'

# 長い文字列でのテスト
def test_performance(pattern, text, iterations = 1000)
  puts "Pattern: #{pattern}"
  puts "Text length: #{text.length}"
  puts "Iterations: #{iterations}"
  puts

  # Ruby版のテスト
  ruby_time = Benchmark.realtime do
    regex = FlowRegex.new(pattern)
    iterations.times do
      regex.match(text)
    end
  end

  puts "Ruby implementation: #{(ruby_time * 1000).round(2)}ms total, #{(ruby_time * 1000 / iterations).round(4)}ms per match"
  
  # 結果確認用に1回実行
  regex = FlowRegex.new(pattern)
  result = regex.match(text)
  puts "Result: #{result.length} matches found"
  puts
end

# テストケース1: 長い文字列での単純なパターン
puts "=== Performance Test 1: Simple Pattern ==="
long_text = "a" * 500 + "b"
test_performance("a*b", long_text, 1000)

# テストケース2: 複雑なパターン
puts "=== Performance Test 2: Complex Pattern ==="
complex_text = ("abc" * 100) + "d"
test_performance("(a|b|c)*d", complex_text, 1000)

# テストケース3: ReDoS攻撃パターン（安全性テスト）
puts "=== Performance Test 3: ReDoS Pattern ==="
redos_text = "a" * 200 + "x"
test_performance("(a+)+b", redos_text, 100)
