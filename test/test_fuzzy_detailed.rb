require_relative '../lib/flow_regex'

puts "=== 詳細ファジーマッチングテスト ==="

# 単一文字 'a' のファジーマッチングを詳細にテスト
def test_single_char_fuzzy(text, target_char, max_distance)
  puts "\n--- テスト: '#{text}' で '#{target_char}' を検索 (距離#{max_distance}) ---"
  
  fuzzy_literal = FlowRegex::FuzzyLiteral.new(target_char)
  
  # 初期マスク：全ての位置から開始可能
  initial_mask = FlowRegex::BitMask.new(text.length + 1)
  (0..text.length).each { |i| initial_mask.set(i) }
  
  puts "初期マスク: #{initial_mask.set_positions}"
  
  result = fuzzy_literal.apply(initial_mask, text, max_distance: max_distance, debug: true)
  
  if result.is_a?(FlowRegex::FuzzyBitMask)
    match_positions = result.match_end_positions
    puts "マッチ結果:"
    match_positions.each do |distance, positions|
      puts "  距離#{distance}: 位置#{positions}"
    end
  else
    puts "マッチ結果: #{result.set_positions}"
  end
  
  puts "期待される結果の解釈:"
  text.chars.each_with_index do |char, i|
    if char == target_char
      puts "  位置#{i}: '#{char}' = 完全マッチ → 終了位置#{i+1} (距離0)"
    else
      puts "  位置#{i}: '#{char}' ≠ '#{target_char}' → 置換で終了位置#{i+1} (距離1)" if max_distance > 0
    end
  end
  
  if max_distance > 0
    puts "  挿入: パターンをスキップ → 各位置で距離1"
    puts "  削除: テキストをスキップ → 次の位置で距離1"
  end
end

# テストケース実行
test_single_char_fuzzy("abc", 'a', 0)
test_single_char_fuzzy("abc", 'a', 1)
test_single_char_fuzzy("xbc", 'a', 1)
test_single_char_fuzzy("bc", 'a', 1)

puts "\n=== 複数文字パターンのテスト準備 ==="

# Concatを使った複数文字のテスト
puts "\n--- 'ab' パターンのテスト ---"

# 手動でConcatを作成
literal_a = FlowRegex::FuzzyLiteral.new('a')
literal_b = FlowRegex::FuzzyLiteral.new('b')

text = "abc"
puts "Text: '#{text}'"

# 'a' を適用
initial_mask = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial_mask.set(i) }

puts "\n1. 'a' を適用:"
result_a = literal_a.apply(initial_mask, text, max_distance: 1, debug: true)

puts "\n2. 'b' を適用:"
if result_a.is_a?(FlowRegex::FuzzyBitMask)
  result_b = literal_b.apply(result_a, text, max_distance: 1, debug: true)
  puts "最終結果: #{result_b.match_end_positions}"
else
  puts "結果がFuzzyBitMaskではありません"
end

puts "\n=== テスト完了 ==="
