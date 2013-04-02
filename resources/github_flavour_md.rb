#!/usr/bin/ruby
# Convert a Markdown README to HTML with Github Flavored Markdown
# Github and Pygments styles are included in the output
#
# Requirements: json gem (`gem install json`)
#
# Input: STDIN or filename
# Output: STDOUT 
# Arguments: "-c" to give context, or "> filename.html" to output to a file
# cat README.md | flavor > README.html

# Based on https://gist.github.com/ttscoff/3732963/


require 'rubygems'
require 'json'
require 'net/https'

clipboard_output = false
if ARGV[0] == "-c"
	context = ARGV[1]

	ARGV.shift
	ARGV.shift
end

input = ''
if ARGV.length > 0
	if File.exists?(File.expand_path(ARGV[0]))
		input = File.new(File.expand_path(ARGV[0])).read
	else
		puts "File not found: #{ARGV[0]}"
	end
else
	if STDIN.stat.size > 0
		input = STDIN.read
	else
		puts "No input specified"
	end
end

exit if input == ''

def e_sh(str)
	str.to_s.gsub(/(?=[^a-zA-Z0-9_.\/\-\x7F-\xFF\n])/, '\\').gsub(/\n/, "'\n'").sub(/^$/, "''")
end

output = {}
output['text'] = input
output['mode'] = 'gfm'
output['context'] = context if context

url = URI.parse("https://api.github.com/markdown")
request = Net::HTTP::Post.new("#{url.path}")
request.body = output.to_json
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true
response = http.start {|http| http.request(request) }

if response.code == "200"
	html=<<ENDOUTPUT
<div id="GFM">
#{response.body}
</div>
ENDOUTPUT
	if clipboard_output
		%x{echo #{html}|pbcopy}
		puts "Result in clipboard"
	else
		puts html
	end
else
	puts "Error #{response.code}"
end