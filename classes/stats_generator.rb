require 'cgi'
require 'readme-score'

class StatsGenerator
  include HashInit
  attr_accessor :spec, :api_json_path, :cloc_results, :readme_location, :doc_percent, :download_location

  def generate
    vputs "Generating the entire api stats"
    data = {
      :readme => CGI::escapeHTML(File.read(@readme_location)),
      :readme_metadata => readme_metadata,
      :cloc => @cloc_results,
      :doc_percent => @doc_percent,
      :download_size => generated_download_size,
    }

    File.open(@api_json_path, "wb") { |f| f.write data.to_json.to_s}

  end

  def generated_download_size
    `du -sk #{ @download_location}`.split("\t")[0]
  end
  
  def readme_metadata
    score = ReadmeScore::Document.new(File.read(@readme_location)).score
    {
      :has_gifs => score.metrics.has_gifs?,
      :has_images => score.metrics.has_images?,
      :complexity => score.total_score,
      :breakdown => score.breakdown
    }
  end

end
