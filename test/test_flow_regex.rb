require_relative '../lib/flow_regex'

# FlowRegexの基本テスト
class TestFlowRegex
  def self.run_all
    puts "=== FlowRegex テスト開始 ==="
    puts
    
    test_literal
    test_concat
    test_alternation
    test_kleene_star
    test_complex_patterns
    
    puts "=== テスト完了 ==="
  end
  
  def self.test_literal
    puts "【リテラルテスト】"
    
    # 基本的な文字マッチ
    regex = FlowRegex.new("a")
    result = regex.match("xax")
    puts "Pattern: 'a', Text: 'xax' => #{result}"
    assert_equal([2], result, "単一文字マッチ")
    
    # 複数マッチのテスト
    result = regex.match("aaa")
    puts "Pattern: 'a', Text: 'aaa' => #{result}"
    assert_equal([1, 2, 3], result, "複数文字マッチ")
    
    # マッチしない場合
    result = regex.match("xyz")
    puts "Pattern: 'a', Text: 'xyz' => #{result}"
    assert_equal([], result, "マッチなし")
    
    puts
  end
  
  def self.test_concat
    puts "【連接テスト】"
    
    regex = FlowRegex.new("ab")
    result = regex.match("xabyz")
    puts "Pattern: 'ab', Text: 'xabyz' => #{result}"
    assert_equal([3], result, "連接マッチ")
    
    # 複数マッチ
    result = regex.match("ababab")
    puts "Pattern: 'ab', Text: 'ababab' => #{result}"
    assert_equal([2, 4, 6], result, "複数連接マッチ")
    
    puts
  end
  
  def self.test_alternation
    puts "【選択テスト】"
    
    regex = FlowRegex.new("a|b")
    result = regex.match("xaybz")
    puts "Pattern: 'a|b', Text: 'xaybz' => #{result}"
    assert_equal([2, 4], result, "選択マッチ")
    
    puts
  end
  
  def self.test_kleene_star
    puts "【クリーネ閉包テスト】"
    
    regex = FlowRegex.new("a*")
    result = regex.match("aaab")
    puts "Pattern: 'a*', Text: 'aaab' => #{result}"
    # a*は0回以上なので、位置0,1,2,3でマッチ可能
    puts
    
    regex = FlowRegex.new("a*b")
    result = regex.match("aaab")
    puts "Pattern: 'a*b', Text: 'aaab' => #{result}"
    assert_equal([4], result, "a*bマッチ")
    
    puts
  end
  
  def self.test_complex_patterns
    puts "【複合パターンテスト】"
    
    # デバッグ付きで実行
    regex = FlowRegex.new("a*b|c")
    result = regex.match("aaabcd", debug: true)
    puts "Result: #{result}"
    
    puts
  end
  
  def self.assert_equal(expected, actual, message)
    if expected == actual
      puts "  ✓ #{message}"
    else
      puts "  ✗ #{message}: expected #{expected}, got #{actual}"
    end
  end
end

# テスト実行
TestFlowRegex.run_all
