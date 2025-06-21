# FlowRegex - 関数合成による正規表現マッチングライブラリ

require_relative 'flow_regex/bit_mask'
require_relative 'flow_regex/regex_element'
require_relative 'flow_regex/literal'
require_relative 'flow_regex/concat'
require_relative 'flow_regex/alternation'
require_relative 'flow_regex/kleene_star'
require_relative 'flow_regex/quantifier'
require_relative 'flow_regex/character_class'
require_relative 'flow_regex/any_char'
require_relative 'flow_regex/parser'
require_relative 'flow_regex/matcher'
require_relative 'flow_regex/fuzzy_bit_mask'
require_relative 'flow_regex/fuzzy_literal'
require_relative 'flow_regex/fuzzy_matcher'
require_relative 'flow_regex/tracked_bit_mask'
require_relative 'flow_regex/lookahead'
require_relative 'flow_regex/optimized_text'

class FlowRegex
  class ParseError < StandardError; end
  class TextTooLongError < StandardError; end
  
  MAX_TEXT_LENGTH = 10000
  
  def initialize(pattern)
    @pattern = pattern
    @parsed_regex = FlowRegex::Parser.new(pattern).parse
  end
  
  def match(text, debug: false)
    raise TextTooLongError, "Text length #{text.length} exceeds maximum #{MAX_TEXT_LENGTH}" if text.length > MAX_TEXT_LENGTH
    
    # 全てのマッチ位置を取得
    matcher = FlowRegex::Matcher.new(text, debug: debug)
    positions = matcher.match(@parsed_regex)
    
    # 位置の配列をそのまま返す
    positions
  end
  
  def fuzzy_match(text, max_distance: 1, debug: false)
    raise TextTooLongError, "Text length #{text.length} exceeds maximum #{MAX_TEXT_LENGTH}" if text.length > MAX_TEXT_LENGTH
    raise ArgumentError, "max_distance must be >= 0" if max_distance < 0
    
    # ファジーマッチャーで処理
    matcher = FlowRegex::FuzzyMatcher.new(text, max_distance: max_distance, debug: debug)
    matcher.match(@parsed_regex)
  end
  
  def match_optimized(optimized_text, debug: false)
    # OptimizedTextを使った最適化マッチング
    matcher = FlowRegex::Matcher.new(optimized_text.text, debug: debug)
    positions = matcher.match(@parsed_regex, optimized_text: optimized_text)
    
    # 位置の配列をそのまま返す
    positions
  end
  
  def to_s
    "FlowRegex(#{@pattern})"
  end
  
  # MatchMask最適化のためのテキスト事前処理
  def self.optimize_text(text, alphabets:)
    raise TextTooLongError, "Text length #{text.length} exceeds maximum #{MAX_TEXT_LENGTH}" if text.length > MAX_TEXT_LENGTH
    
    # 文字列を配列に正規化
    char_array = case alphabets
    when String
      alphabets.chars.uniq
    when Array
      alphabets.map(&:to_s).uniq
    else
      raise ArgumentError, "alphabets must be String or Array"
    end
    
    OptimizedText.new(text, precompute_chars: char_array)
  end
  
  # よく使われる文字セットのプリセット
  DNA_ALPHABETS = "ATGC"
  RNA_ALPHABETS = "AUGC"
  AMINO_ACIDS = "ACDEFGHIKLMNPQRSTVWY"
  DIGITS = "0123456789"
  LOWERCASE = "abcdefghijklmnopqrstuvwxyz"
  UPPERCASE = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  
  def self.optimize_for_dna(text)
    optimize_text(text, alphabets: DNA_ALPHABETS)
  end
  
  def self.optimize_for_rna(text)
    optimize_text(text, alphabets: RNA_ALPHABETS)
  end
  
  def self.optimize_for_amino_acids(text)
    optimize_text(text, alphabets: AMINO_ACIDS)
  end
  
  def self.optimize_for_digits(text)
    optimize_text(text, alphabets: DIGITS)
  end
  
  def self.optimize_for_lowercase(text)
    optimize_text(text, alphabets: LOWERCASE)
  end
  
  def self.optimize_for_uppercase(text)
    optimize_text(text, alphabets: UPPERCASE)
  end
end
