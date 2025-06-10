#!/usr/bin/env ruby

require_relative '../lib/flow_regex'

puts "=== FlowRegex 文字クラステスト ==="
puts "文字クラス、エスケープシーケンス、Unicode対応の確認"
puts

class CharacterClassTest
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
test = CharacterClassTest.new

puts "【文字クラス略記】"
test.test("\\d (数字)", "\\d", "a1b2c", [2, 4])
test.test("\\D (数字以外)", "\\D", "1a2b3", [2, 4])
test.test("\\s (空白)", "\\s", "a b c", [2, 4])
test.test("\\S (空白以外)", "\\S", " a b ", [2, 4])
test.test("\\w (単語文字)", "\\w", "a@b_c", [1, 3, 4, 5])
test.test("\\W (単語文字以外)", "\\W", "a@b_c", [2])
puts

puts "【文字クラス範囲指定】"
test.test("[a-z] (小文字)", "[a-z]", "A1b2C", [3])
test.test("[A-Z] (大文字)", "[A-Z]", "a1B2c", [3])
test.test("[0-9] (数字)", "[0-9]", "a1b2c", [2, 4])
test.test("[a-zA-Z] (英字)", "[a-zA-Z]", "1a2B3", [2, 4])
test.test("[1-5] (数字範囲)", "[1-5]", "0123456", [2, 3, 4, 5, 6])
puts

puts "【文字クラス個別指定】"
test.test("[abc] (個別指定)", "[abc]", "xaybzc", [2, 4, 6])
test.test("[123] (数字個別)", "[123]", "a1b2c3", [2, 4, 6])
test.test("[xyz] (存在しない)", "[xyz]", "abcdef", [])
puts

puts "【文字クラス否定】"
test.test("[^abc] (否定)", "[^abc]", "abcdef", [4, 5, 6])
test.test("[^0-9] (数字以外)", "[^0-9]", "a1b2c", [1, 3, 5])
test.test("[^a-z] (小文字以外)", "[^a-z]", "aB1c", [2, 3])
puts

puts "【エスケープシーケンス】"
test.test("\\n (改行)", "\\n", "a\nb", [2])
test.test("\\t (タブ)", "\\t", "a\tb", [2])
test.test("\\r (キャリッジリターン)", "\\r", "a\rb", [2])
test.test("\\\\ (バックスラッシュ)", "\\\\", "a\\b", [2])
puts

puts "【量指定子との組み合わせ】"
test.test("\\d+ (数字1回以上)", "\\d+", "abc123def", [4, 5, 6])
test.test("\\w* (単語文字0回以上)", "\\w*", "hello@world", [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
test.test("[a-z]{2,4} (小文字2-4回)", "[a-z]{2,4}", "abcdefg", [2, 3, 4, 5, 6, 7])
test.test("[0-9]? (数字0-1回)", "[0-9]?", "a1b2c", [0, 1, 2, 3, 4, 5])
test.test("\\s+ (空白1回以上)", "\\s+", "a   b", [2, 3, 4])
puts

puts "【実用的なパターン】"
test.test("電話番号風", "\\d{3}-\\d{4}", "123-4567", [8])
test.test("メールアドレス風", "[a-zA-Z]+@[a-zA-Z]+", "user@domain", [6, 7, 8, 9, 10, 11])
test.test("ファイル名風", "\\w+\\.\\w+", "file.txt", [6, 7, 8])
test.test("大文字+小文字", "[A-Z][a-z]+", "Hello World", [2, 3, 4, 5, 8, 9, 10, 11])
test.test("HTMLタグ風", "<[a-zA-Z]+>", "<div>", [5])
puts

puts "【Unicode文字対応】"
test.test("ひらがな範囲", "[あ-ん]+", "こんにちは世界", [1, 2, 3, 4, 5])
test.test("カタカナ範囲", "[ア-ン]+", "コンニチハ世界", [1, 2, 3, 4, 5])
test.test("漢字個別", "[世界]", "こんにちは世界", [6, 7])
test.test("\\w + Unicode", "\\w+", "hello世界", [1, 2, 3, 4, 5])
puts

puts "【文字クラス内エスケープシーケンス】"
test.test("[\\d\\s] (数字+空白)", "[\\d\\s]", "a1 b2 c", [2, 3, 5, 6])
test.test("[\\w@] (単語文字+@)", "[\\w@]", "a@b1c", [1, 2, 3, 4, 5])
test.test("[a-z\\d] (小文字+数字)", "[a-z\\d]", "A1b2C", [2, 3, 4])
test.test("[\\D\\S] (数字以外+空白以外)", "[\\D\\S]", "1 a 2", [1, 2, 3, 4, 5])
test.test("[\\n\\t] (改行+タブ)", "[\\n\\t]", "a\nb\tc", [2, 4])
test.test("[^\\d\\s] (数字・空白以外)", "[^\\d\\s]", "1 a 2", [3])
puts

puts "【複雑な組み合わせ】"
test.test("複数文字クラス", "\\d+[a-z]+\\d+", "123abc456", [7, 8, 9])  # 全ての可能な終了位置
test.test("ネスト量指定子", "(\\d{2,3})+", "12345678", [2, 3, 4, 5, 6, 7, 8])  # 全ての可能な終了位置
test.test("選択+文字クラス", "\\d|[a-z]", "1a2b3", [1, 2, 3, 4, 5])
test.test("文字クラス内エスケープ+量指定子", "[\\d\\w]+", "abc123@def", [1, 2, 3, 4, 5, 6, 8, 9, 10])
test.test("複合文字クラス+量指定子", "[a-z\\d\\s]+", "abc 123 def", [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
puts

puts "【エラーケース】"
test.test_error("空の文字クラス", "[]", FlowRegex::ParseError)
test.test_error("閉じられていない文字クラス", "[abc", FlowRegex::ParseError)
test.test_error("不完全なエスケープ", "\\", FlowRegex::ParseError)
puts

test.summary
