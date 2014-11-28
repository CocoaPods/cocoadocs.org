require 'cgi'
require 'readme-score'

class StatsGenerator
  include HashInit
  attr_accessor :spec, :api_json_path, :cloc_results, :readme_location, :doc_percent, :download_location, :docset_location

  def generate
    vputs "Generating the entire api stats"
    data = {
      readme: "README.html",
      readme_metadata: readme_metadata,
      cloc: @cloc_results,
      doc_percent: @doc_percent,
      download_size: generated_download_size,
      first_commit_date: get_first_commit_date
    }

    puts @readme_location
    puts @docset_location

    FileUtils.copy(@readme_location, File.join(@docset_location, "README.html"))
    File.open(@api_json_path, "wb") { |f| f.write data.to_json.to_s }
  end

  def generated_download_size
    `du -sk #{ @download_location }`.split("\t")[0]
  end

  def get_first_commit_date
    Dir.chdir(File.join(@download_location)) do
      return `git log --pretty=format:%ad --date=iso| tail -1`
    end
  end


  def readme_metadata
    score = ReadmeScore::Document.new(File.read(@readme_location)).score
    {
      has_gifs: score.metrics.has_gifs?,
      has_images: score.metrics.has_images?,
      complexity: score.total_score,
      breakdown: score.breakdown
    }
  end
end
