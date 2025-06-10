#!/usr/bin/env ruby

require_relative '../lib/flow_regex'

puts "=== FlowRegex ピリオド（任意の文字）テスト ==="
puts "ピリオド（.）とエスケープピリオド（\\.）の動作確認"
puts

class AnyCharTest
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
test = AnyCharTest.new

puts "【基本的なピリオド】"
test.test(". (任意の文字)", ".", "abc", [1, 2, 3])
test.test("a.c (a+任意+c)", "a.c", "abc", [3])
test.test("a.c (a+x+c)", "a.c", "axc", [3])
test.test("a.c (a+数字+c)", "a.c", "a1c", [3])
test.test("a.c (a+空白+c)", "a.c", "a c", [3])
test.test("a.c (a+記号+c)", "a.c", "a@c", [3])
puts

puts "【改行文字の扱い】"
test.test("a.c (改行はマッチしない)", "a.c", "a\nc", [])
test.test(". (改行以外)", ".", "a\nb", [1, 3])
test.test(".. (改行をまたがない)", "..", "a\nb", [])
puts

puts "【エスケープピリオド】"
test.test("\\. (リテラルピリオド)", "\\.", "a.b", [2])
test.test("a\\.b (リテラルピリオド)", "a\\.b", "a.b", [3])
test.test("a\\.b (xではマッチしない)", "a\\.b", "axb", [])
test.test("file\\.txt", "file\\.txt", "file.txt", [8])
test.test("www\\.example\\.com", "www\\.example\\.com", "www.example.com", [15])
puts

puts "【量指定子との組み合わせ】"
test.test(".+ (任意文字1回以上)", ".+", "hello", [1, 2, 3, 4, 5])
test.test(".* (任意文字0回以上)", ".*", "hello", [0, 1, 2, 3, 4, 5])
test.test(".? (任意文字0-1回)", ".?", "ab", [0, 1, 2])
test.test(".{3} (任意文字3回)", ".{3}", "abcde", [3, 4, 5])
test.test(".{2,4} (任意文字2-4回)", ".{2,4}", "abcdef", [2, 3, 4, 5, 6])
puts

puts "【実用的なパターン】"
test.test(".+@.+ (メールアドレス風)", ".+@.+", "user@domain.com", [6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
test.test(".*\\.txt (txtファイル)", ".*\\.txt", "document.txt", [12])
test.test(".*\\.rb (rubyファイル)", ".*\\.rb", "script.rb", [9])
test.test("a.{2,3}b (a+2-3文字+b)", "a.{2,3}b", "a123b", [5])
test.test("..-..-.. (日付風)", "..-..-..", "12-34-56", [8])
puts

puts "【複雑な組み合わせ】"
test.test("選択+ピリオド", "a.|b.", "ax by", [2, 5])
test.test("グループ+ピリオド", "(..)+", "abcdef", [2, 3, 4, 5, 6])  # 全ての可能な終了位置
test.test("ネスト+ピリオド", "(.{2,3})+", "abcdefgh", [2, 3, 4, 5, 6, 7, 8])
test.test("文字クラス+ピリオド", "[a-z].\\d", "a1b2c3", [])  # マッチしない（\\dは数字クラス）
puts

puts "【Unicode文字との組み合わせ】"
test.test(". (日本語)", ".", "あいう", [1, 2, 3])
test.test("あ.う", "あ.う", "あいう", [3])
test.test("あ.う", "あ.う", "あxう", [3])
test.test(".+ (日本語)", ".+", "こんにちは", [1, 2, 3, 4, 5])
puts

puts "【文字クラス内の特殊文字】"
test.test("[.] (ピリオドリテラル)", "[.]", "a.b", [2])
test.test("[a.] (a or ピリオド)", "[a.]", "a.b", [1, 2])
test.test("[-az] (- or a or z)", "[-az]", "a-z", [1, 2, 3])
test.test("[az-] (a or z or -)", "[az-]", "a-z", [1, 2, 3])
test.test("[.-/] (ピリオドから/の範囲)", "[.-/]", "./", [1, 2])
puts

puts "【エラーケースなし】"
puts "ピリオドは基本的にエラーを起こさない安全な機能です"
puts

test.summary
