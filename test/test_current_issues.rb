require_relative '../lib/flow_regex'

puts "=== 現在の実装の問題点と使い方 ==="

puts "\n1. 【動作する】単一文字のファジーマッチング"
puts "---"

# 単一文字は正しく動作
text = "abc"
fuzzy_a = FlowRegex::FuzzyLiteral.new('a')

initial_mask = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial_mask.set(i) }

result = fuzzy_a.apply(initial_mask, text, max_distance: 1, debug: false)
puts "Text: '#{text}', Pattern: 'a', 距離1"
puts "結果: #{result.set_positions}"
puts "期待: 'a'が位置0で完全マッチ、他の位置で置換・挿入・削除マッチ"

puts "\n2. 【問題あり】複数文字パターン（Concat使用）"
puts "---"

# 複数文字で問題発生
literal_a = FlowRegex::Literal.new('a')
literal_b = FlowRegex::Literal.new('b')
concat_ab = FlowRegex::Concat.new(literal_a, literal_b)

test_cases = [
  { text: "ab", expected: "完全マッチ（距離0）" },
  { text: "xb", expected: "1文字目置換（距離1）" },
  { text: "ax", expected: "2文字目置換（距離1）" },
  { text: "abc", expected: "完全マッチ + 余分文字" }
]

test_cases.each do |test_case|
  text = test_case[:text]
  initial = FlowRegex::BitMask.new(text.length + 1)
  (0..text.length).each { |i| initial.set(i) }
  
  puts "\nText: '#{text}' vs Pattern: 'ab'"
  puts "期待: #{test_case[:expected]}"
  
  # 距離0
  result_0 = concat_ab.apply(initial, text, max_distance: 0, debug: false)
  puts "距離0結果: #{result_0.set_positions}"
  
  # 距離1
  result_1 = concat_ab.apply(initial, text, max_distance: 1, debug: false)
  if result_1.is_a?(FlowRegex::FuzzyBitMask)
    match_positions = result_1.match_end_positions
    puts "距離1結果: #{match_positions}"
    puts "問題: #{match_positions.empty? ? 'マッチが検出されない' : 'OK'}"
  else
    puts "距離1結果: #{result_1.set_positions}"
  end
end

puts "\n3. 【問題あり】FlowRegex.fuzzy_match の使用"
puts "---"

begin
  regex = FlowRegex.new("ab")
  
  ["ab", "xb", "ax", "abc"].each do |text|
    puts "\nText: '#{text}' vs Pattern: 'ab'"
    
    # 通常マッチ
    normal_result = regex.match(text)
    puts "通常マッチ: #{normal_result}"
    
    # ファジーマッチ
    fuzzy_result = regex.fuzzy_match(text, max_distance: 1)
    puts "ファジーマッチ: #{fuzzy_result}"
    puts "問題: #{fuzzy_result.empty? ? 'マッチが検出されない' : 'OK'}"
  end
rescue => e
  puts "エラー: #{e.message}"
  puts "スタックトレース: #{e.backtrace.first(3)}"
end

puts "\n4. 【根本問題】パターン長管理の問題"
puts "---"

puts "問題の詳細:"
puts "- 各FuzzyLiteralが独立してパターン長を管理"
puts "- Concatで'a'+'b'を処理すると："
puts "  1. 'a'処理後: パターン長2"
puts "  2. 'b'処理後: パターン長3"
puts "  3. しかし実際のパターン'ab'の長さは2"
puts "- match_end_positionsは pattern_pos == pattern_length を探すため空になる"

puts "\n5. 【期待される動作】"
puts "---"

puts "期待される結果:"
puts "FlowRegex.new('ab').fuzzy_match('xb', max_distance: 1)"
puts "=> {1 => [2]}  # 距離1で位置2に終了"
puts ""
puts "FlowRegex.new('ab').fuzzy_match('ax', max_distance: 1)" 
puts "=> {1 => [2]}  # 距離1で位置2に終了"
puts ""
puts "FlowRegex.new('ab').fuzzy_match('ab', max_distance: 1)"
puts "=> {0 => [2]}  # 距離0で位置2に終了"

puts "\n=== 問題整理完了 ==="
