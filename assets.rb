require 'tilt'
require 'erb'
require 'pathname'

# I tend to use
# ruby assets.rb; ruby app.rb doc AFNetworking --skip-fetch --skip-source-download --dont-delete-source

$active_folder = "activity"

`sass views/homepage_stylesheet.scss:#{$active_folder}/html/assets/homepage_stylesheet.css`
`sass views/appledoc_stylesheet.scss:#{$active_folder}/html/assets/appledoc_stylesheet.css`
`sass views/appledoc_gfm.scss:#{$active_folder}/html/assets/appledoc_gfm.css`

output_folder = Dir.pwd + "/appledoc_templates/html/"
Dir[Dir.pwd + "/views/appledoc_template/*.html.erb"].each { |file| 
  filename = File.basename(file, ".html.erb")
  
  erb = ERB.new(File.read(file))
  erb.filename = filename
  output = erb.result
  
  output_path = output_folder + filename + ".html"
  File.open(output_path, 'w') { |f| f.write output }
}

puts "Updated templates"
