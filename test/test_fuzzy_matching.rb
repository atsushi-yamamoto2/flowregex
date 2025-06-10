require_relative '../lib/flow_regex'

# ファジーマッチングの基本テスト
puts "=== ファジーマッチング基本テスト ==="

# 単一文字のファジーマッチングテスト
puts "\n1. 単一文字のファジーマッチング"

# FuzzyLiteralを直接使用してテスト
fuzzy_a = FlowRegex::FuzzyLiteral.new('a')
text = "abc"

# 通常のBitMaskから開始
initial_mask = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial_mask.set(i) }

puts "Text: '#{text}'"
puts "Pattern: 'a'"
puts "Initial mask: #{initial_mask.inspect}"

# 距離0でのマッチング
result_exact = fuzzy_a.apply(initial_mask, text, max_distance: 0, debug: true)
puts "距離0の結果: #{result_exact.inspect}"

# 距離1でのマッチング
result_fuzzy = fuzzy_a.apply(initial_mask, text, max_distance: 1, debug: true)
puts "距離1の結果: #{result_fuzzy.inspect}"

puts "\n2. FuzzyBitMaskの基本動作テスト"

# FuzzyBitMaskの基本動作確認
fuzzy_mask = FlowRegex::FuzzyBitMask.new(5, 2, 1)
fuzzy_mask.set(0, 0, 0)  # テキスト位置0, パターン位置0, 距離0
fuzzy_mask.set(1, 1, 0)  # テキスト位置1, パターン位置1, 距離0
fuzzy_mask.set(2, 1, 1)  # テキスト位置2, パターン位置1, 距離1

puts "FuzzyBitMask設定後:"
puts "  設定位置: #{fuzzy_mask.set_positions}"
puts "  マッチ終了位置: #{fuzzy_mask.match_end_positions}"
puts "  詳細: #{fuzzy_mask.inspect}"

puts "\n3. 実際の文字列でのテスト"

# より実際的なテスト
test_cases = [
  { text: "abc", pattern: 'a', distance: 0, expected: "完全マッチ" },
  { text: "abc", pattern: 'a', distance: 1, expected: "ファジーマッチ" },
  { text: "xbc", pattern: 'a', distance: 1, expected: "置換マッチ" },
  { text: "bc", pattern: 'a', distance: 1, expected: "削除マッチ" }
]

test_cases.each_with_index do |test_case, i|
  puts "\nテストケース #{i + 1}: #{test_case[:text]} vs #{test_case[:pattern]} (距離#{test_case[:distance]})"
  
  fuzzy_literal = FlowRegex::FuzzyLiteral.new(test_case[:pattern])
  initial = FlowRegex::BitMask.new(test_case[:text].length + 1)
  (0..test_case[:text].length).each { |pos| initial.set(pos) }
  
  result = fuzzy_literal.apply(initial, test_case[:text], max_distance: test_case[:distance], debug: false)
  
  if result.is_a?(FlowRegex::FuzzyBitMask)
    puts "  結果: #{result.match_end_positions}"
  else
    puts "  結果: #{result.set_positions}"
  end
end

puts "\n=== テスト完了 ==="
