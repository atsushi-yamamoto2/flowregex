require_relative 'lib/flow_regex'

# Test "a?b" on "ab"
text = "ab"
pattern = "a?b"

puts "Testing pattern '#{pattern}' on text '#{text}'"
puts "Text positions: #{text.chars.map.with_index { |c, i| "#{i}:#{c}" }.join(' ')}"

regex = FlowRegex.new(pattern)
result = regex.match(text, debug: true)

puts "Result: #{result.inspect}"
puts "Expected positions where 'a?b' matches:"
puts "- Position 0: '' + 'ab' (0 a's + b at position 1)"
puts "- Position 1: 'a' + 'b' (1 a + b at position 1)"
puts "So result should be [2] (position after the match)"
