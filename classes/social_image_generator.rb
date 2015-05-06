class SocialImageGenerator
  include HashInit
  attr_accessor :spec, :output_folder, :stats_generator
  
  def generate    
    image_command = [
      spec.name,
      quote_wrap(spec.summary),
      quote_wrap(spec.or_podfile_string),
      quote_wrap(testing_quote),
      quote_wrap(doc_quote),
      quote_wrap(spec.or_license_name_and_url[:license]),
      quote_wrap(@stats_generator.get_top_cloc[:language]),
      @output_folder + "preview.png"
    ]
    
    command "vendor/Headliner.app/Contents/MacOS/Headliner " + image_command.join(' ')
  end
  
  def testing_quote 
    case @stats_generator.testing_estimate
    when -1..1 then "No Tests"
    when 2..10 then "Some Tests"
    when 11..30 then "Has Tests"
    when 31..80 then "Amply Tested"
    when 81..150 then "Well Tested"
    else "Great Tests"
    end
  end
  
  def doc_quote 
    case @stats_generator.doc_percent
    when -1..5 then "No Docs"
    when 6..20 then "Partial Docs"
    when 21..50 then "Documented"
    when 51..80 then "Good Docs"
    else "Great Docs"
    end
  end
  
  def quote_wrap thing
    '"' + thing.gsub('"', "££").gsub("'", "@@") + '"'
  end

end