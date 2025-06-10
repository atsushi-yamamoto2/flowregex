#!/usr/bin/env ruby

require_relative '../lib/flow_regex'

puts "=== FlowRegex ファジーマッチング使用例 ==="
puts

# 1. 基本的なファジーマッチング
puts "【1. 基本的なファジーマッチング】"
regex = FlowRegex.new("cat")

test_cases = [
  { text: "cat", desc: "完全マッチ" },
  { text: "bat", desc: "1文字置換" },
  { text: "ca", desc: "1文字削除" },
  { text: "cart", desc: "1文字挿入" },
  { text: "dog", desc: "全文字置換（距離3）" }
]

test_cases.each do |test_case|
  result = regex.fuzzy_match(test_case[:text], max_distance: 1)
  status = result.empty? ? "マッチなし" : "距離#{result.keys.min}でマッチ"
  puts "  '#{test_case[:text]}' (#{test_case[:desc]}) => #{status}"
end
puts

# 2. 実用的な例：スペルチェッカー
puts "【2. スペルチェッカー】"
dictionary = ["apple", "application", "apply", "appreciate"]
user_input = "aple"  # タイポ

puts "辞書: #{dictionary}"
puts "入力: '#{user_input}'"
puts "候補:"

dictionary.each do |word|
  regex = FlowRegex.new(word)
  result = regex.fuzzy_match(user_input, max_distance: 2)
  
  unless result.empty?
    distance = result.keys.min
    puts "  '#{word}' (編集距離: #{distance})"
  end
end
puts

# 3. 遺伝子配列の類似検索（簡単な例）
puts "【3. 遺伝子配列の類似検索】"
target_sequence = "ATCG"
sequences = ["ATCG", "ATCC", "TTCG", "ATCGA", "ACCG"]

puts "目標配列: #{target_sequence}"
puts "検索対象:"

regex = FlowRegex.new(target_sequence)
sequences.each do |seq|
  result = regex.fuzzy_match(seq, max_distance: 1)
  
  if result.empty?
    puts "  #{seq} => マッチなし"
  else
    distance = result.keys.min
    puts "  #{seq} => 距離#{distance}でマッチ"
  end
end
puts

# 4. 距離による段階的検索
puts "【4. 距離による段階的検索】"
pattern = "hello"
text = "hxllx"  # 2文字置換

regex = FlowRegex.new(pattern)
puts "Pattern: '#{pattern}', Text: '#{text}'"

(0..3).each do |max_dist|
  result = regex.fuzzy_match(text, max_distance: max_dist)
  
  if result.empty?
    puts "  距離#{max_dist}: マッチなし"
  else
    distances = result.keys.sort
    puts "  距離#{max_dist}: #{distances.map{|d| "距離#{d}"}.join(', ')}でマッチ"
  end
end
puts

# 5. 複数の候補から最適なマッチを選択
puts "【5. 最適マッチ選択】"
search_term = "program"
candidates = ["programming", "program", "programmer", "programs", "progress"]

puts "検索語: '#{search_term}'"
puts "候補から最適なマッチを選択:"

regex = FlowRegex.new(search_term)
matches = []

candidates.each do |candidate|
  result = regex.fuzzy_match(candidate, max_distance: 3)
  
  unless result.empty?
    min_distance = result.keys.min
    matches << { word: candidate, distance: min_distance }
  end
end

# 距離でソート
matches.sort_by! { |m| m[:distance] }

matches.each_with_index do |match, index|
  rank = index + 1
  puts "  #{rank}. '#{match[:word]}' (距離: #{match[:distance]})"
end
puts

# 6. パフォーマンス比較
puts "【6. 通常マッチ vs ファジーマッチ】"
pattern = "test"
texts = ["test", "tset", "best", "testing"]

regex = FlowRegex.new(pattern)
puts "Pattern: '#{pattern}'"

texts.each do |text|
  normal_result = regex.match(text)
  fuzzy_result = regex.fuzzy_match(text, max_distance: 1)
  
  normal_status = normal_result.empty? ? "なし" : "あり"
  fuzzy_status = fuzzy_result.empty? ? "なし" : "距離#{fuzzy_result.keys.min}"
  
  puts "  '#{text}': 通常=#{normal_status}, ファジー=#{fuzzy_status}"
end
puts

# 7. 実際の使用パターン
puts "【7. 実際の使用パターン】"

def fuzzy_search(pattern, texts, max_distance = 1)
  regex = FlowRegex.new(pattern)
  results = []
  
  texts.each_with_index do |text, index|
    result = regex.fuzzy_match(text, max_distance: max_distance)
    
    unless result.empty?
      min_distance = result.keys.min
      results << {
        index: index,
        text: text,
        distance: min_distance,
        positions: result[min_distance]
      }
    end
  end
  
  results.sort_by { |r| r[:distance] }
end

# 使用例
documents = [
  "Ruby programming tutorial",
  "Python programing guide", 
  "Java programming basics",
  "C++ program examples",
  "JavaScript programming tips"
]

search_results = fuzzy_search("programming", documents, 2)

puts "検索: 'programming'"
puts "結果:"
search_results.each_with_index do |result, index|
  puts "  #{index + 1}. \"#{result[:text]}\" (距離: #{result[:distance]})"
end

puts
puts "=== ファジーマッチング使用例完了 ==="
