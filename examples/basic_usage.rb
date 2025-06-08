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
