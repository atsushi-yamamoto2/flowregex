require_relative '../lib/flow_regex'

puts "=== 先読み演算子 高度なテスト ==="

def test_advanced_lookahead(pattern, text, expected_description)
  puts "\n--- テスト: '#{pattern}' vs '#{text}' ---"
  puts "期待: #{expected_description}"
  
  begin
    regex = FlowRegex.new(pattern)
    result = regex.match(text, debug: false)
    puts "結果: #{result}"
    
    if result.empty?
      puts "マッチなし"
    else
      puts "マッチ終了位置: #{result.join(', ')}"
    end
  rescue => e
    puts "エラー: #{e.message}"
  end
end

puts "\n=== 複数開始位置での先読みテスト ==="

# 1. 文字列の途中から始まる先読み
test_advanced_lookahead("a(?=bc)b", "abcabc", "aの後にbcが続く場合のab")
test_advanced_lookahead("a(?=bc)b", "abxabc", "最初のaは条件を満たさず、2番目のaが条件を満たす")

# 2. 複数のマッチ候補がある場合
test_advanced_lookahead("a(?=b)a", "ababab", "aの後にbが続く場合のaa（連続するa）")
test_advanced_lookahead("a(?!b)a", "ababaa", "aの後にbが続かない場合のaa")

# 3. より複雑なパターン
test_advanced_lookahead("x(?=ab)a.*", "xabcxabc", "xの後にabが続く場合のxa.*")
test_advanced_lookahead("x(?!ab)a.*", "xacxabc", "xの後にabが続かない場合のxa.*")

puts "\n=== 選択と先読みの組み合わせ ==="

# 4. 選択演算子を含む複雑なパターン
test_advanced_lookahead("(a|b)(?=c)c", "acbc", "aまたはbの後にcが続く場合")
test_advanced_lookahead("(a|b)(?!c).", "adbe", "aまたはbの後にcが続かない場合")

puts "\n=== 量詞と先読みの組み合わせ ==="

# 5. 量詞を含むパターン
test_advanced_lookahead("a*(?=b)a", "aaabaaab", "a*の後にbが続く場合のa")
test_advanced_lookahead("a*(?!b)a", "aaaxaaab", "a*の後にbが続かない場合のa")

puts "\n=== デバッグモードでの詳細確認 ==="

puts "\n--- デバッグ: 'a(?=bc)b' vs 'abcabc' ---"
begin
  regex = FlowRegex.new("a(?=bc)b")
  result = regex.match("abcabc", debug: true)
  puts "最終結果: #{result}"
rescue => e
  puts "エラー: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n--- デバッグ: 'a(?!bc)b' vs 'abxabc' ---"
begin
  regex = FlowRegex.new("a(?!bc)b")
  result = regex.match("abxabc", debug: true)
  puts "最終結果: #{result}"
rescue => e
  puts "エラー: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n=== 集合の複数要素テスト ==="

# 6. 複数の開始位置を持つ入力での動作確認
puts "\n--- 複数開始位置での集合演算確認 ---"
puts "パターン: 'a(?=b)b' (aの後にbが続く場合のab)"
puts "テキスト: 'ababxab' (位置0,2,5でaが存在)"

regex = FlowRegex.new("a(?=b)b")
result = regex.match("ababxab", debug: true)
puts "期待: 位置0と位置2のaは条件を満たすが、位置5のaは満たさない"
puts "実際の結果: #{result}"

puts "\n=== エッジケースのテスト ==="

# 7. エッジケース
test_advanced_lookahead("(?=a)a", "aaa", "先頭での肯定先読み")
test_advanced_lookahead("(?!b)a", "aaa", "先頭での否定先読み")
test_advanced_lookahead("a(?=)a", "aa", "空の先読み条件")

puts "\n=== テスト完了 ==="
