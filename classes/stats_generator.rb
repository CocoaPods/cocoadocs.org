require 'cgi'
require 'readme-score'
require 'rest'

class StatsGenerator
  include HashInit
  attr_accessor :spec, :api_json_path, :cloc_results, :readme_location, :doc_percent, :download_location, :docset_location, :testing_estimate

  def upload
    vputs "Generating the CocoaDocs stats for CP Metrics"

    cloc_sum = @cloc_results.select do |cloc|
      cloc[:lang] == "SUM"
    end.first

    unless cloc_sum
      cloc_sum = { :lang => "SUM", :files => 0, :comment => 0, :lines_of_code => 0 }
    end
    
    puts cloc_sum

    data = {
      :total_files => cloc_sum[:files],
      :total_comments => cloc_sum[:comment],
      :total_lines_of_code => cloc_sum[:lines_of_code],
      :doc_percent => @doc_percent,
      :total_test_expectations => testing_estimate,
      :readme_complexity => readme_metadata[:complexity],
      :rendered_readme_url => spec.or_cocoadocs_url + "/README.html",
      :initial_commit_date => get_first_commit_date,
      :download_size => generated_download_size,
      :license_short_name => spec.or_license_name_and_url[:license],
      :license_canonical_url => spec.or_license_name_and_url[:url]
    }

    # send it to the db
    REST.post("http://cocoadocs-api.cocoapods.org/pod/#{spec.name}", data.to_json)
    REST.post("https://cocoadocs-api-cocoapods-org.herokuapp.com/pod/#{spec.name}/cloc", @cloc_results.to_json)
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
