require_relative '../lib/flow_regex'

puts "=== 'ax' vs 'ab' デバッグ ==="

text = "ax"
literal_a = FlowRegex::Literal.new('a')
literal_b = FlowRegex::Literal.new('b')
concat_ab = FlowRegex::Concat.new(literal_a, literal_b)

puts "Text: '#{text}'"
puts "Pattern: 'ab' (Concat)"

# 初期マスク
initial = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial.set(i) }

puts "\n初期マスク: #{initial.set_positions}"

# ステップバイステップでデバッグ
puts "\n=== ステップ1: 'a' を適用 ==="
result_a = literal_a.apply(initial, text, max_distance: 1, debug: true)

if result_a.is_a?(FlowRegex::FuzzyBitMask)
  puts "結果の型: FuzzyBitMask"
  puts "設定位置: #{result_a.set_positions}"
  puts "パターン長: #{result_a.pattern_length}"
  
  # 手動で期待される状態をチェック
  puts "\n期待される状態:"
  puts "- 位置0の'a'が完全マッチ → (1, 1, 0)"
  puts "- 位置1の'x'が置換マッチ → (2, 1, 1)"
  puts "- 挿入・削除操作も含む"
  
  puts "\n実際の状態:"
  result_a.set_positions.each do |text_pos, pattern_pos, distance|
    puts "  (#{text_pos}, #{pattern_pos}, #{distance})"
  end
else
  puts "結果の型: #{result_a.class}"
  puts "設定位置: #{result_a.set_positions}"
end

puts "\n=== ステップ2: 'b' を適用 ==="
result_b = literal_b.apply(result_a, text, max_distance: 1, debug: true)

if result_b.is_a?(FlowRegex::FuzzyBitMask)
  puts "結果の型: FuzzyBitMask"
  puts "設定位置: #{result_b.set_positions}"
  puts "パターン長: #{result_b.pattern_length}"
  puts "マッチ終了位置: #{result_b.match_end_positions}"
  
  puts "\n期待される終了状態:"
  puts "- パターン位置2（完了）で距離1のマッチがあるはず"
  
  puts "\n実際の終了状態チェック:"
  (0..result_b.max_distance).each do |dist|
    (0..text.length).each do |pos|
      if result_b.get(pos, result_b.pattern_length, dist)
        puts "  位置#{pos}, 距離#{dist}: 終了状態"
      end
    end
  end
else
  puts "結果の型: #{result_b.class}"
  puts "設定位置: #{result_b.set_positions}"
end

puts "\n=== FlowRegex.fuzzy_match での結果 ==="
regex = FlowRegex.new("ab")
fuzzy_result = regex.fuzzy_match(text, max_distance: 1, debug: false)
puts "FlowRegex結果: #{fuzzy_result}"

puts "\n=== デバッグ完了 ==="
