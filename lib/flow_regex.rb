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

class FlowRegex
  class ParseError < StandardError; end
  class TextTooLongError < StandardError; end
  
  MAX_TEXT_LENGTH = 1000
  
  def initialize(pattern)
    @pattern = pattern
    @parsed_regex = FlowRegex::Parser.new(pattern).parse
  end
  
  def match(text, debug: false)
    raise TextTooLongError, "Text length #{text.length} exceeds maximum #{MAX_TEXT_LENGTH}" if text.length > MAX_TEXT_LENGTH
    
    # 単一のマッチャーで全体を処理
    matcher = FlowRegex::Matcher.new(text, debug: debug)
    matcher.match(@parsed_regex)
  end
  
  def fuzzy_match(text, max_distance: 1, debug: false)
    raise TextTooLongError, "Text length #{text.length} exceeds maximum #{MAX_TEXT_LENGTH}" if text.length > MAX_TEXT_LENGTH
    raise ArgumentError, "max_distance must be >= 0" if max_distance < 0
    
    # ファジーマッチャーで処理
    matcher = FlowRegex::FuzzyMatcher.new(text, max_distance: max_distance, debug: debug)
    matcher.match(@parsed_regex)
  end
  
  def to_s
    "FlowRegex(#{@pattern})"
  end
end
