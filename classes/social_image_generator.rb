class SocialImageGenerator
  include HashInit
  attr_accessor :spec, :output_folder, :stats_generator
  
  def generate
    image_command = [
      spec.name,
      quote_wrap(spec.summary),
      quote_wrap(spec.or_podfile_string),
      quote_wrap("Tested"),
      quote_wrap("Doc'd"),
      quote_wrap(spec.or_license_name_and_url[:license]),
      quote_wrap(@stats_generator.cloc_top[:language]),
      @output_folder + "preview.png"
    ]
    
    command "vendor/Headliner.app/Contents/MacOS/Headliner " + image_command.join(' ')
  end
  
  def quote_wrap thing
    '"' + thing.gsub('"', "££").gsub("'", "@@") + '"'
  end

end