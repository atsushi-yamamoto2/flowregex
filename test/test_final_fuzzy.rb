require_relative '../lib/flow_regex'

puts "=== ファジーマッチング最終テスト ==="

def test_fuzzy_match(pattern, text, max_distance, expected_description)
  puts "\n--- テスト: '#{pattern}' vs '#{text}' (距離#{max_distance}) ---"
  puts "期待: #{expected_description}"
  
  regex = FlowRegex.new(pattern)
  
  # 通常マッチ
  normal_result = regex.match(text)
  puts "通常マッチ: #{normal_result}"
  
  # ファジーマッチ
  fuzzy_result = regex.fuzzy_match(text, max_distance: max_distance)
  puts "ファジーマッチ: #{fuzzy_result}"
  
  # 結果の解釈
  if fuzzy_result.empty?
    puts "結果: マッチなし"
  else
    fuzzy_result.each do |distance, positions|
      puts "結果: 距離#{distance}で位置#{positions}に終了"
    end
  end
end

puts "\n=== 基本的なファジーマッチング ==="

# 完全マッチ
test_fuzzy_match("a", "a", 1, "完全マッチ")
test_fuzzy_match("ab", "ab", 1, "完全マッチ")

# 置換
test_fuzzy_match("a", "x", 1, "1文字置換")
test_fuzzy_match("ab", "xb", 1, "1文字目置換")
test_fuzzy_match("ab", "ax", 1, "2文字目置換")

# 挿入・削除
test_fuzzy_match("a", "ab", 1, "1文字挿入")
test_fuzzy_match("ab", "a", 1, "1文字削除")

puts "\n=== より複雑なケース ==="

# 複数の編集操作
test_fuzzy_match("abc", "axc", 1, "中間文字置換")
test_fuzzy_match("abc", "abx", 1, "末尾文字置換")
test_fuzzy_match("abc", "xbc", 1, "先頭文字置換")

# 距離2のテスト
test_fuzzy_match("ab", "xy", 2, "2文字置換")
test_fuzzy_match("abc", "xyz", 3, "全文字置換")

puts "\n=== エラーケース ==="

# 距離制限を超える場合
test_fuzzy_match("ab", "xy", 1, "距離制限超過（マッチなし）")
test_fuzzy_match("abc", "xyz", 2, "距離制限超過（マッチなし）")

puts "\n=== 実用例 ==="

# 実際の使用例
test_fuzzy_match("hello", "helo", 1, "タイポ修正")
test_fuzzy_match("world", "wrold", 1, "文字順序間違い（置換2回必要）")
test_fuzzy_match("test", "tset", 1, "文字順序間違い（置換2回必要）")

puts "\n=== 推奨使用方法 ==="
puts "✅ 推奨: FlowRegex.new(pattern).fuzzy_match(text, max_distance: n)"
puts "❌ 非推奨: 直接ConcatとLiteralを組み合わせる方法"
puts ""
puts "例:"
puts "  regex = FlowRegex.new('hello')"
puts "  result = regex.fuzzy_match('helo', max_distance: 1)"
puts "  # => {1 => [5]}  # 距離1で位置5に終了"

puts "\n=== テスト完了 ==="
