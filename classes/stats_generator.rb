require 'cgi'
require 'readme-score'
require 'rest'

class StatsGenerator
  include HashInit
  attr_accessor :spec, :api_json_path, :cloc_results, :readme_location, :doc_percent, :download_location, :docset_location, :testing_estimate, :cloc_top

  def upload
    vputs "Generating the CocoaDocs stats for CP Metrics"

    cloc_sum = get_summary_cloc
    @cloc_top = get_top_cloc
    
    data = {
      :total_files => cloc_sum[:files],
      :total_comments => cloc_sum[:comments],
      :total_lines_of_code => cloc_sum[:lines_of_code],
      :doc_percent => @doc_percent,
      :total_test_expectations => testing_estimate,
      :readme_complexity => readme_metadata[:complexity],
      :rendered_readme_url => spec.or_cocoadocs_url + "/README.html",
      :initial_commit_date => get_first_commit_date,
      :download_size => generated_download_size,
      :license_short_name => spec.or_license_name_and_url[:license],
      :license_canonical_url => spec.or_license_name_and_url[:url],
      :dominant_language => @cloc_top[:language]
    }

    # send it to the db
    handle_request REST.post("http://cocoadocs-api.cocoapods.org/pods/#{spec.name}", data.to_json)
    handle_request REST.post("https://cocoadocs-api-cocoapods-org.herokuapp.com/pods/#{spec.name}/cloc", @cloc_results.to_json)
  end

  def get_summary_cloc 
    cloc_sum = @cloc_results.select do |cloc|
      cloc[:language] == "SUM"
    end.first

    unless cloc_sum
      cloc_sum = { :language => "SUM", :files => 0, :comments => 0, :lines_of_code => 0 }
    end
    cloc_sum
  end
  
  def get_top_cloc
    cloc_top = @cloc_results.reject do |cloc|
      cloc[:language] == "C/C++ Header" ||  cloc[:language] == "SUM"
    end.sort_by { |cloc| cloc[:files] }.first
        
    unless cloc_top
      cloc_top = { :language => "Objective C", :files => 1, :comments => 1, :lines_of_code => 1 }
    end
    cloc_top
  end

  def handle_request response    
    if response.ok?
      vputs "Sent".green
    elsif response.unauthorized?
      vputs "Denied sending to CocoaDocs API: #{response.body}".red
    else
      vputs "Likely could not find pod in Trunk DB: #{response.body}".red
    end
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
