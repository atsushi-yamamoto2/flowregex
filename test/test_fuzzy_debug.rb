require_relative '../lib/flow_regex'

puts "=== FuzzyBitMask デバッグテスト ==="

# 簡単なケースから始める
puts "\n1. 単一文字 'a' のテスト"

text = "abc"
fuzzy_a = FlowRegex::FuzzyLiteral.new('a')

# 初期マスク
initial_mask = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial_mask.set(i) }

puts "初期マスク: #{initial_mask.set_positions}"

result = fuzzy_a.apply(initial_mask, text, max_distance: 1, debug: false)
puts "結果の型: #{result.class}"
puts "結果の詳細: #{result.inspect}"
puts "設定されている位置: #{result.set_positions}"
puts "マッチ終了位置: #{result.match_end_positions}"

puts "\n2. 手動でFuzzyBitMaskを作成してテスト"

# 手動でFuzzyBitMaskを作成
manual_mask = FlowRegex::FuzzyBitMask.new(3, 2, 1)

# パターン完了状態を手動設定
manual_mask.set(2, 2, 0)  # テキスト位置2, パターン位置2(完了), 距離0
manual_mask.set(3, 2, 1)  # テキスト位置3, パターン位置2(完了), 距離1

puts "手動設定後:"
puts "  設定位置: #{manual_mask.set_positions}"
puts "  マッチ終了位置: #{manual_mask.match_end_positions}"

puts "\n3. Concat処理の詳細追跡"

literal_a = FlowRegex::Literal.new('a')
literal_b = FlowRegex::Literal.new('b')

text = "ab"
puts "Text: '#{text}'"

# 初期マスク
initial = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial.set(i) }

puts "\n初期状態: #{initial.set_positions}"

# 'a' を適用
puts "\n'a' を適用:"
result_a = literal_a.apply(initial, text, max_distance: 1, debug: false)
puts "結果の型: #{result_a.class}"
if result_a.is_a?(FlowRegex::FuzzyBitMask)
  puts "設定位置: #{result_a.set_positions}"
  puts "パターン長: #{result_a.pattern_length}"
  puts "マッチ終了位置: #{result_a.match_end_positions}"
end

# 'b' を適用
puts "\n'b' を適用:"
result_b = literal_b.apply(result_a, text, max_distance: 1, debug: false)
puts "結果の型: #{result_b.class}"
if result_b.is_a?(FlowRegex::FuzzyBitMask)
  puts "設定位置: #{result_b.set_positions}"
  puts "パターン長: #{result_b.pattern_length}"
  puts "マッチ終了位置: #{result_b.match_end_positions}"
  
  # 手動で期待される終了状態をチェック
  puts "\n期待される終了状態のチェック:"
  (0..result_b.max_distance).each do |dist|
    (0..text.length).each do |pos|
      if result_b.get(pos, result_b.pattern_length, dist)
        puts "  位置#{pos}, 距離#{dist}: マッチ終了"
      end
    end
  end
end

puts "\n=== デバッグ完了 ==="
