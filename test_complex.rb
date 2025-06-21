require_relative 'lib/flow_regex'

# Test "a(b|c)*d" on "abcbcd"
text = "abcbcd"
pattern = "a(b|c)*d"

puts "Testing pattern '#{pattern}' on text '#{text}'"
puts "Text positions: #{text.chars.map.with_index { |c, i| "#{i}:#{c}" }.join(' ')}"

regex = FlowRegex.new(pattern)
result = regex.match(text, debug: true)

puts "Result: #{result.inspect}"
puts "Expected positions where 'a(b|c)*d' matches:"
puts "- Position 0: 'a' + '(b|c)*' + 'd' at position 5"
puts "So result should be [6] (position after the match)"
