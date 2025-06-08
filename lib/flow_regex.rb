# FlowRegex - 関数合成による正規表現マッチングライブラリ
# 山本法の実装

require_relative 'flow_regex/bit_mask'
require_relative 'flow_regex/regex_element'
require_relative 'flow_regex/literal'
require_relative 'flow_regex/concat'
require_relative 'flow_regex/alternation'
require_relative 'flow_regex/kleene_star'
require_relative 'flow_regex/parser'
require_relative 'flow_regex/matcher'

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
    
    matcher = FlowRegex::Matcher.new(text, debug: debug)
    matcher.match(@parsed_regex)
  end
  
  def to_s
    "FlowRegex(#{@pattern})"
  end
end
