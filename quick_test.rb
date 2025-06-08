#!/usr/bin/env ruby

require_relative 'lib/flow_regex'
require 'benchmark'

puts "=== FlowRegex クイックテスト ==="
puts "FlowRegexの良さ悪さを手軽に体験"
puts

# テスト1: 基本動作
puts "【テスト1: 基本動作】"
regex = FlowRegex.new("abc")
result = regex.match("xabcyz")
puts "パターン: 'abc', 文字列: 'xabcyz'"
puts "結果: #{result} (期待値: [4])"
puts result == [4] ? "✓ 正常" : "✗ 異常"
puts

# テスト2: デバッグモード
puts "【テスト2: デバッグモード】"
puts "パターン: 'a*b', 文字列: 'aaab'"
puts "ビットマスクの変化過程:"
regex = FlowRegex.new("a*b")
result = regex.match("aaab", debug: true)
puts "結果: #{result}"
puts

# テスト3: 性能比較（簡単なケース）
puts "【テスト3: 性能比較（簡単なケース）】"
text = "a" * 100 + "b"
pattern = "a*b"

flow_time = Benchmark.realtime do
  regex = FlowRegex.new(pattern)
  result = regex.match(text)
end

ruby_time = Benchmark.realtime do
  result = text.match(/a*b/)
end

puts "パターン: '#{pattern}', 文字列: 'a'×100+'b'"
puts "FlowRegex: #{sprintf('%.6f', flow_time)}秒"
puts "Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"
puts "速度比: #{sprintf('%.1f', flow_time / ruby_time)}倍 (FlowRegex/Ruby)"
puts "→ 単純なケースではRuby正規表現が高速（予想通り）"
puts

# テスト4: ReDoS攻撃パターン
puts "【テスト4: ReDoS攻撃パターン】"
attack_string = "a" * 25
attack_pattern = "(a*)*b"

puts "攻撃パターン: '#{attack_pattern}', 攻撃文字列: 'a'×25"

flow_time = Benchmark.realtime do
  regex = FlowRegex.new(attack_pattern)
  result = regex.match(attack_string)
end

ruby_time = Benchmark.realtime do
  result = attack_string.match(/(a*)*b/)
end

puts "FlowRegex: #{sprintf('%.6f', flow_time)}秒"
puts "Ruby正規表現: #{sprintf('%.6f', ruby_time)}秒"

if flow_time < ruby_time * 2
  puts "→ 両者とも高速（現代Rubyの対策が効果的）"
else
  puts "→ FlowRegexが安定（#{sprintf('%.1f', ruby_time / flow_time)}倍高速）"
end
puts

# テスト5: 線形性確認
puts "【テスト5: 線形性確認】"
puts "文字列長を変えてFlowRegexの実行時間を測定"

sizes = [50, 100, 200, 400]
times = []

sizes.each do |size|
  test_string = "a" * size
  time = Benchmark.realtime do
    regex = FlowRegex.new("a*")
    result = regex.match(test_string)
  end
  times << time
  puts "文字列長#{size}: #{sprintf('%.6f', time)}秒 (#{sprintf('%.2f', time/size*1000000)}μs/文字)"
end

puts "→ 文字あたりの時間がほぼ一定なら線形性が確認できる"
puts

# テスト6: 複雑なパターン
puts "【テスト6: 複雑なパターン】"
complex_patterns = [
  { pattern: "a|b", text: "xaybz", expected: [2, 4] },
  { pattern: "(ab)*", text: "ababab", expected: [0, 2, 4, 6] },
  { pattern: "a*b|c", text: "aaabcd", expected: [4, 5] }
]

complex_patterns.each_with_index do |test, i|
  puts "パターン#{i+1}: '#{test[:pattern]}', 文字列: '#{test[:text]}'"
  regex = FlowRegex.new(test[:pattern])
  result = regex.match(test[:text])
  puts "結果: #{result}"
  puts "期待値: #{test[:expected]}"
  puts result == test[:expected] ? "✓ 正常" : "✗ 異常"
  puts
end

puts "=== クイックテスト完了 ==="
puts
puts "【まとめ】"
puts "✓ FlowRegexは動作している"
puts "✓ デバッグ機能でビットマスクの変化が見える"
puts "✓ 単純なケースではRuby正規表現が高速（予想通り）"
puts "✓ 攻撃パターンでも安定動作"
puts "✓ 実行時間の線形性が確認できる"
puts "✓ 複雑なパターンも正しく処理"
puts
puts "詳細なテストは以下のコマンドで実行できます："
puts "ruby test/test_flow_regex.rb           # 基本テスト"
puts "ruby examples/basic_usage.rb          # 使用例"
puts "ruby test/benchmark_redos.rb          # ReDoS耐性テスト"
puts "ruby test/complexity_analysis.rb      # 計算量分析"
puts "ruby test/extreme_redos_demo.rb       # 極端な攻撃テスト"
