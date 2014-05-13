require 'erb'

class WebsiteGenerator
  include HashInit
  attr_accessor :generate_json, :spec

  def generate
    create_index_page
    move_public_items
    create_stylesheet
  end  
  
  def create_index_page
    vputs "Creating index page"

    save_slim "views/index.slim", "#{$active_folder}/html/index.html"
    save_slim "views/404.slim", "#{$active_folder}/html/404.html"
  end


  def save_slim slim_filepath, to_filepath
    template = Tilt.new slim_filepath
    html = template.render

    vputs "Writing slim_filepath"
    seve_file html, to_filepath
  end

  def create_stylesheet
    vputs "Creating sass stylesheets"
    command "sass views/homepage_stylesheet.scss:#{$active_folder}/html/assets/homepage_stylesheet.css"
    command "sass views/appledoc_stylesheet.scss:#{$active_folder}/html/assets/appledoc_stylesheet.css"
    command "sass views/appledoc_gfm.scss:#{$active_folder}/html/assets/appledoc_gfm.css"
  end

  def create_specs_json specs
    array_string = specs.to_json.to_s

    function_wrapped = "var specs = #{array_string}; searchTermChanged()"
    json_filepath = $active_folder + "/html/documents.jsonp"

    vputs "Writing JSON for docsets"
    seve_file function_wrapped, json_filepath
  end

  def seve_file file, path
    FileUtils.mkdir_p(File.dirname(path))
    if File.exists? path
       File.unlink path
    end

    File.open(path, "wb") { |f| f.write file }
  end

  def move_public_items
    resources_dir = "#{$active_folder}/html/assets/"

    command "rm -rf #{resources_dir}"
    command "mkdir #{resources_dir}"
    command "cp -R public/* #{resources_dir}"
  end

  def upload_docset
    vputs "Uploading docsets folder"
    upload_folder "docsets/#{@spec.name}/#{@spec.version}/", "/docsets/#{@spec.name}/#{@spec.version}/", "put"
    upload_folder "docsets/#{@spec.name}/metadata.json", "/docsets/#{@spec.name}/", "put"
  end

  def upload_site
    vputs "Uploading site folder"
    upload_folder "html/*", "/", "put"
  end


  # Upload the docsets folder to s3
  def upload_folder from, to, command
    vputs "Uploading #{from} with #{command} on s3"

    upload_command = [
      "s3cmd #{command}",
      "--recursive  --acl-public",
      "--no-check-md5",
      "--verbose --human-readable-sizes --reduced-redundancy",
      "#{$active_folder}/#{from} s3://cocoadocs.org#{to}"
    ]

    command upload_command.join(' ')
  end
end