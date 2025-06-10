require_relative '../lib/flow_regex'

puts "=== 先読み演算子テスト ==="

def test_lookahead(pattern, text, expected_description)
  puts "\n--- テスト: '#{pattern}' vs '#{text}' ---"
  puts "期待: #{expected_description}"
  
  begin
    regex = FlowRegex.new(pattern)
    result = regex.match(text)
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

puts "\n=== 肯定先読みテスト (?=B)A ==="

# 基本的な肯定先読み
test_lookahead("(?=ab)ab*c", "abbbcd", "abで始まる場合のab*c")
test_lookahead("(?=ab)ab*c", "xbbbcd", "abで始まらない場合（マッチなし）")

# より複雑なパターン
test_lookahead("(?=cat)c.*", "caterpillar", "catで始まる任意の文字列")
test_lookahead("(?=cat)c.*", "dog", "catで始まらない場合（マッチなし）")

puts "\n=== 否定先読みテスト (?!B)A ==="

# 基本的な否定先読み
test_lookahead("(?!abc)ab*c", "abbbcd", "abcで始まらないab*c")
test_lookahead("(?!abc)ab*c", "abcd", "abcで始まる場合（マッチなし）")

# より複雑なパターン
test_lookahead("(?!dog)...", "cat", "dogで始まらない3文字")
test_lookahead("(?!dog)...", "dog", "dogで始まる場合（マッチなし）")

puts "\n=== 複合パターンテスト ==="

# 選択との組み合わせ
test_lookahead("(?=a)a|(?=b)b", "apple", "aまたはbで始まる文字")
test_lookahead("(?=a)a|(?=b)b", "banana", "aまたはbで始まる文字")

puts "\n=== デバッグモードテスト ==="

puts "\n--- デバッグ: (?=ab)ab*c vs 'abbbcd' ---"
begin
  regex = FlowRegex.new("(?=ab)ab*c")
  result = regex.match("abbbcd", debug: true)
  puts "最終結果: #{result}"
rescue => e
  puts "エラー: #{e.message}"
  puts e.backtrace.first(5)
end

puts "\n=== テスト完了 ==="
