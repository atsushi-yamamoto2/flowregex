require_relative '../lib/flow_regex'

puts "=== Concat + ファジーマッチングテスト ==="

# 通常のLiteralとConcatを使用
literal_a = FlowRegex::Literal.new('a')
literal_b = FlowRegex::Literal.new('b')
concat_ab = FlowRegex::Concat.new(literal_a, literal_b)

text = "abc"
puts "Text: '#{text}'"
puts "Pattern: 'ab' (Concat)"

# 初期マスク
initial_mask = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial_mask.set(i) }

puts "\n1. 距離0でのマッチング:"
result_exact = concat_ab.apply(initial_mask, text, debug: true, max_distance: 0)
puts "結果: #{result_exact.set_positions}"

puts "\n2. 距離1でのマッチング:"
result_fuzzy = concat_ab.apply(initial_mask, text, debug: true, max_distance: 1)

if result_fuzzy.is_a?(FlowRegex::FuzzyBitMask)
  puts "結果: #{result_fuzzy.match_end_positions}"
else
  puts "結果: #{result_fuzzy.set_positions}"
end

puts "\n=== 異なるテキストでのテスト ==="

test_cases = [
  "ab",   # 完全マッチ
  "xb",   # 1文字目置換
  "ax",   # 2文字目置換
  "xx",   # 両方置換
  "abc",  # 完全マッチ + 余分な文字
  "xbc"   # 1文字目置換 + 余分な文字
]

test_cases.each do |test_text|
  puts "\n--- Text: '#{test_text}' ---"
  
  initial = FlowRegex::BitMask.new(test_text.length + 1)
  (0..test_text.length).each { |i| initial.set(i) }
  
  result = concat_ab.apply(initial, test_text, debug: false, max_distance: 1)
  
  if result.is_a?(FlowRegex::FuzzyBitMask)
    match_positions = result.match_end_positions
    if match_positions.empty?
      puts "マッチなし"
    else
      match_positions.each do |distance, positions|
        puts "距離#{distance}: 終了位置#{positions}"
      end
    end
  else
    positions = result.set_positions
    if positions.empty?
      puts "マッチなし"
    else
      puts "終了位置: #{positions}"
    end
  end
end

puts "\n=== テスト完了 ==="
