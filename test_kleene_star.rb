require_relative 'lib/flow_regex'

# Test "a*b" on "aaab"
text = "aaab"
pattern = "a*b"

puts "Testing pattern '#{pattern}' on text '#{text}'"
puts "Text positions: #{text.chars.map.with_index { |c, i| "#{i}:#{c}" }.join(' ')}"

regex = FlowRegex.new(pattern)
result = regex.match(text, debug: true)

puts "Result: #{result.inspect}"
puts "Expected positions where 'a*b' matches:"
puts "- Position 0: '' + 'aaab' (0 a's + b at position 3)"
puts "- Position 1: 'a' + 'aab' (1 a + b at position 3)" 
puts "- Position 2: 'aa' + 'ab' (2 a's + b at position 3)"
puts "- Position 3: 'aaa' + 'b' (3 a's + b at position 3)"
puts "So result should be [4] (position after the match)"
