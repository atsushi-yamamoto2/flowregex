require_relative '../lib/flow_regex'

puts "=== 簡単なファジーマッチングテスト ==="

# 最も基本的なケース：単一文字の完全マッチ
puts "\n1. 単一文字完全マッチ"

text = "a"
fuzzy_a = FlowRegex::FuzzyLiteral.new('a')

# 初期マスク
initial_mask = FlowRegex::BitMask.new(text.length + 1)
(0..text.length).each { |i| initial_mask.set(i) }

puts "Text: '#{text}'"
puts "初期マスク: #{initial_mask.set_positions}"

result = fuzzy_a.apply(initial_mask, text, max_distance: 0, debug: true)
puts "距離0結果: #{result.set_positions}"

result_fuzzy = fuzzy_a.apply(initial_mask, text, max_distance: 1, debug: false)
puts "距離1結果: #{result_fuzzy.inspect}"
puts "設定位置: #{result_fuzzy.set_positions}"

# 手動で終了状態をチェック
puts "\n手動終了状態チェック:"
(0..result_fuzzy.max_distance).each do |dist|
  (0..text.length).each do |pos|
    # パターン長1なので、pattern_pos=1が終了状態
    if result_fuzzy.get(pos, 1, dist)
      puts "  位置#{pos}, 距離#{dist}: 終了状態あり"
    end
  end
end

puts "\n2. 手動でパターン長1のFuzzyBitMaskテスト"

# パターン長1で手動作成
manual_mask = FlowRegex::FuzzyBitMask.new(1, 1, 1)
manual_mask.set(1, 1, 0)  # 位置1, パターン完了, 距離0

puts "手動設定:"
puts "  設定位置: #{manual_mask.set_positions}"
puts "  マッチ終了位置: #{manual_mask.match_end_positions}"

puts "\n=== テスト完了 ==="
