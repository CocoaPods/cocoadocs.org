start = Time.now

files = Dir.glob('activity/cocoadocs_specs/Specs/**/**/*.podspec.json')
puts "Found #{files.length} Podspecs"

files.each do |file|
  puts "#{files.index file} / #{files.length} - #{ file}"
  `bundle exec ./cocoadocs.rb cocoadocs doc #{file} --dont-delete-source --skip-fetch-specs`
end


puts "started at #{start}" 
puts "finished at #{Time.now}"