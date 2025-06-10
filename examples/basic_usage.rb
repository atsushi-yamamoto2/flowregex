#!/usr/bin/env ruby

require_relative '../lib/flow_regex'

puts "=== FlowRegex 基本使用例 ==="
puts

# 1. 基本的なリテラルマッチ
puts "【1. リテラルマッチ】"
regex = FlowRegex.new("a")
result = regex.match("banana")
puts "Pattern: 'a', Text: 'banana' => #{result}"
puts "マッチ終了位置: #{result.join(', ')}"
puts

# 2. 連接パターン
puts "【2. 連接パターン】"
regex = FlowRegex.new("an")
result = regex.match("banana")
puts "Pattern: 'an', Text: 'banana' => #{result}"
puts

# 3. 選択パターン
puts "【3. 選択パターン】"
regex = FlowRegex.new("cat|dog")
result = regex.match("I have a cat and a dog")
puts "Pattern: 'cat|dog', Text: 'I have a cat and a dog' => #{result}"
puts

# 4. クリーネ閉包
puts "【4. クリーネ閉包】"
regex = FlowRegex.new("a*b")
result = regex.match("aaabxbbbby")
puts "Pattern: 'a*b', Text: 'aaabxbbbby' => #{result}"
puts

# 5. 複合パターン
puts "【5. 複合パターン】"
regex = FlowRegex.new("(ab)*c")
result = regex.match("ababcxyzc")
puts "Pattern: '(ab)*c', Text: 'ababcxyzc' => #{result}"
puts

# 6. デバッグモード
puts "【6. デバッグモード】"
regex = FlowRegex.new("a*|b")
puts "Pattern: 'a*|b', Text: 'aabaa'"
result = regex.match("aabaa", debug: true)
puts "Result: #{result}"
puts

# 7. ファジーマッチング（基本）
puts "【7. ファジーマッチング - 基本】"
regex = FlowRegex.new("hello")
puts "Pattern: 'hello'"

# 完全マッチ
result = regex.fuzzy_match("hello", max_distance: 1)
puts "Text: 'hello' (完全マッチ) => #{result}"

# 1文字置換
result = regex.fuzzy_match("hallo", max_distance: 1)
puts "Text: 'hallo' (1文字置換) => #{result}"

# 1文字削除
result = regex.fuzzy_match("helo", max_distance: 1)
puts "Text: 'helo' (1文字削除) => #{result}"

# 1文字挿入
result = regex.fuzzy_match("helllo", max_distance: 1)
puts "Text: 'helllo' (1文字挿入) => #{result}"
puts

# 8. ファジーマッチング（実用例）
puts "【8. ファジーマッチング - 実用例】"

# タイポ修正
puts "■ タイポ修正"
regex = FlowRegex.new("programming")
typos = ["programing", "progamming", "programmin"]
typos.each do |typo|
  result = regex.fuzzy_match(typo, max_distance: 1)
  status = result.empty? ? "マッチなし" : "距離#{result.keys.first}でマッチ"
  puts "  '#{typo}' => #{status}"
end
puts

# 名前の曖昧検索
puts "■ 名前の曖昧検索"
names = ["Smith", "Smyth", "Schmidt"]
search_name = "Smith"
regex = FlowRegex.new(search_name)

names.each do |name|
  result = regex.fuzzy_match(name, max_distance: 2)
  if result.empty?
    puts "  '#{name}' => マッチなし"
  else
    distances = result.keys.sort
    puts "  '#{name}' => 距離#{distances.first}でマッチ"
  end
end
puts

# 9. ファジーマッチング（距離制限）
puts "【9. ファジーマッチング - 距離制限】"
regex = FlowRegex.new("test")
text = "txst"  # 2文字置換が必要

puts "Pattern: 'test', Text: '#{text}'"
(0..3).each do |max_dist|
  result = regex.fuzzy_match(text, max_distance: max_dist)
  status = result.empty? ? "マッチなし" : "マッチあり"
  puts "  距離#{max_dist}: #{status}"
end
puts

# 10. 結果の解釈
puts "【10. ファジーマッチング結果の解釈】"
regex = FlowRegex.new("cat")
result = regex.fuzzy_match("cats", max_distance: 1)
puts "Pattern: 'cat', Text: 'cats' => #{result}"
puts "解釈:"
result.each do |distance, positions|
  puts "  距離#{distance}: 位置#{positions.join(', ')}でパターン終了"
end
puts "  位置3は'cat'が完了した位置（'s'の直前）"
puts "  位置4は'cats'全体の終了位置"
