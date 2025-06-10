#!/usr/bin/env ruby

require_relative '../lib/flow_regex'

puts "=== FlowRegex 量指定子テスト ==="
puts "新しく実装された量指定子の動作確認"
puts

class QuantifierTest
  def initialize
    @passed = 0
    @failed = 0
  end
  
  def test(description, pattern, text, expected)
    print "#{description}: "
    
    begin
      regex = FlowRegex.new(pattern)
      result = regex.match(text)
      
      if result == expected
        puts "✅ PASS"
        @passed += 1
      else
        puts "❌ FAIL - Expected: #{expected}, Got: #{result}"
        @failed += 1
      end
    rescue => e
      puts "❌ ERROR - #{e.message}"
      @failed += 1
    end
  end
  
  def test_error(description, pattern, expected_error_class = nil)
    print "#{description}: "
    
    begin
      regex = FlowRegex.new(pattern)
      puts "❌ FAIL - Expected error but succeeded"
      @failed += 1
    rescue => e
      if expected_error_class.nil? || e.is_a?(expected_error_class)
        puts "✅ PASS - #{e.message}"
        @passed += 1
      else
        puts "❌ FAIL - Expected #{expected_error_class}, got #{e.class}: #{e.message}"
        @failed += 1
      end
    end
  end
  
  def summary
    puts
    puts "=== テスト結果 ==="
    puts "成功: #{@passed}"
    puts "失敗: #{@failed}"
    puts "合計: #{@passed + @failed}"
    puts
    
    if @failed == 0
      puts "🎉 全てのテストが成功しました！"
    else
      puts "⚠️  #{@failed}個のテストが失敗しました。"
    end
  end
end

# テスト実行
test = QuantifierTest.new

puts "【基本的な量指定子】"
test.test("+ 量指定子（1回以上）", "a+", "aaab", [1, 2, 3])
test.test("? 量指定子（0回または1回）", "a?", "ab", [0, 1, 2])
test.test("{n} 量指定子（n回ちょうど）", "a{3}", "aaaab", [3, 4])
test.test("{n,m} 量指定子（n-m回）", "a{2,4}", "aaaaab", [2, 3, 4, 5])
test.test("{n,} 量指定子（n回以上）", "a{2,}", "aaaaab", [2, 3, 4, 5])
puts

puts "【グループ化との組み合わせ】"
test.test("グループ + Plus", "(ab)+", "ababab", [2, 4, 6])
test.test("グループ + Question", "(ab)?c", "abc", [3])
test.test("グループ + ExactCount", "(ab){2}", "ababab", [4, 6])  # 2回ちょうど: 位置4と6で終了
test.test("グループ + RangeCount", "(ab){1,2}", "ababab", [2, 4, 6])  # 1-2回: 位置2,4,6で終了
puts

puts "【複雑な組み合わせ】"
test.test("複数の量指定子", "a+b?c*", "aaabccc", [1, 2, 3, 4, 5, 6, 7])
test.test("選択 + 量指定子", "(a|b){2,3}", "abab", [2, 3, 4])
test.test("ネストした量指定子", "((a+b?)+c){1,2}", "aabcaabc", [4, 8])
puts

puts "【エラーケース】"
test.test_error("無効な範囲", "a{5,2}", FlowRegex::ParseError)
test.test_error("不完全な量指定子", "a{", FlowRegex::ParseError)
test.test_error("数値以外", "a{abc}", FlowRegex::ParseError)
test.test_error("量指定子のみ", "+", FlowRegex::ParseError)
puts

puts "【従来機能との互換性】"
test.test("KleeneStar", "a*", "aaa", [0, 1, 2, 3])
test.test("選択", "a|b", "abc", [1, 2])
test.test("連接", "ab", "ababab", [2, 4, 6])
test.test("グループ化", "(ab)*", "ababab", [0, 1, 2, 3, 4, 5, 6])
puts

puts "【実用的なパターン】"
test.test("メールアドレス風", "a+@b+", "aaa@bbb", [5, 6, 7])  # a+@b+: 様々な長さのb+でマッチ
test.test("HTMLタグ風", "<a+>", "<aaa>", [5])
test.test("数字パターン", "1{2,3}2?", "11122", [2, 3, 4])  # 1{2,3}2?: 11, 111, 1112でマッチ
puts

test.summary
