#!/usr/bin/env ruby

require_relative '../lib/flow_regex'

puts "=== FlowRegex 先読み演算子使用例 ==="
puts

# 1. 基本的な肯定先読み
puts "【1. 肯定先読み (?=B)A】"
regex = FlowRegex.new("(?=ab)ab*c")
puts "Pattern: '(?=ab)ab*c'"

test_cases = [
  { text: "abbbcd", desc: "abで始まる場合" },
  { text: "xbbbcd", desc: "abで始まらない場合" },
  { text: "ac", desc: "短いパターン" }
]

test_cases.each do |test_case|
  result = regex.match(test_case[:text])
  status = result.empty? ? "マッチなし" : "位置#{result.join(', ')}でマッチ"
  puts "  '#{test_case[:text]}' (#{test_case[:desc]}) => #{status}"
end
puts

# 2. 基本的な否定先読み
puts "【2. 否定先読み (?!B)A】"
regex = FlowRegex.new("(?!abc)ab*c")
puts "Pattern: '(?!abc)ab*c'"

test_cases = [
  { text: "abbbcd", desc: "abcで始まらない場合" },
  { text: "abcd", desc: "abcで始まる場合" },
  { text: "ac", desc: "短いパターン" }
]

test_cases.each do |test_case|
  result = regex.match(test_case[:text])
  status = result.empty? ? "マッチなし" : "位置#{result.join(', ')}でマッチ"
  puts "  '#{test_case[:text]}' (#{test_case[:desc]}) => #{status}"
end
puts

# 3. 実用的な例：パスワード検証
puts "【3. パスワード検証】"
puts "条件: 英数字を含み、'password'で始まらない8文字以上"

# (?!password).{8,} のような複雑なパターンは現在未対応のため、
# 簡単な例で代用
regex = FlowRegex.new("(?!pass)p.*")
puts "Pattern: '(?!pass)p.*' (passで始まらないp始まりの文字列)"

passwords = ["program123", "password123", "python", "pass123"]
passwords.each do |pwd|
  result = regex.match(pwd)
  status = result.empty? ? "NG" : "OK"
  puts "  '#{pwd}' => #{status}"
end
puts

# 4. 文字列の先頭条件
puts "【4. 文字列の先頭条件】"
regex = FlowRegex.new("(?=cat)c.*")
puts "Pattern: '(?=cat)c.*' (catで始まるc始まりの文字列)"

texts = ["caterpillar", "car", "cat", "dog"]
texts.each do |text|
  result = regex.match(text)
  if result.empty?
    puts "  '#{text}' => マッチなし"
  else
    puts "  '#{text}' => 位置#{result.join(', ')}でマッチ"
  end
end
puts

# 5. 選択との組み合わせ
puts "【5. 選択との組み合わせ】"
regex = FlowRegex.new("(?=a)a|(?=b)b")
puts "Pattern: '(?=a)a|(?=b)b' (aまたはbで始まる単一文字)"

texts = ["apple", "banana", "cherry"]
texts.each do |text|
  result = regex.match(text)
  if result.empty?
    puts "  '#{text}' => マッチなし"
  else
    puts "  '#{text}' => 位置#{result.join(', ')}でマッチ"
  end
end
puts

# 6. デバッグモードでの詳細確認
puts "【6. デバッグモード】"
puts "Pattern: '(?=ab)ab*c' vs Text: 'abbbcd'"
regex = FlowRegex.new("(?=ab)ab*c")
result = regex.match("abbbcd", debug: true)
puts "最終結果: #{result}"
puts

# 7. 集合演算の理論的説明
puts "【7. 集合演算の理論】"
puts "肯定先読み (?=B)A は A ∩ B の集合演算"
puts "- 同じ開始位置でBとAの両方がマッチする場合のみ成功"
puts "- Aの終了位置が結果として返される"
puts
puts "否定先読み (?!B)A は A - B の集合演算"
puts "- 同じ開始位置でBがマッチしない場合のみAを採用"
puts "- 開始位置ベースの差集合演算"

puts
puts "=== 先読み演算子使用例完了 ==="
