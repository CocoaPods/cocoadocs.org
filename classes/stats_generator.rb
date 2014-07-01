require 'cgi'

class StatsGenerator
  include HashInit
  attr_accessor :spec, :api_json_path, :cloc_results, :readme_location, :doc_percent, :download_location


  def generate
    vputs "Generating the entire api stats"
    data = {
      :readme => CGI::escapeHTML(File.read(@readme_location)),
      :cloc => @cloc_results,
      :doc_percent => @doc_percent,
      :download_size => generated_download_size,
    }

    File.open(@api_json_path, "wb") { |f| f.write data.to_json.to_s}

  end

  def generated_download_size
    `du -s #{ @download_location}`.split("\t")[0]
  end

end