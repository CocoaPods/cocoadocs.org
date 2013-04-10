class WebsiteGenerator
  include HashInit
  
  attr_accessor :generate_json

  def generate
    create_index_page
    move_public_items
    create_stylesheet
  end
  
  def create_index_page
    vputs "Creating index page"
    
    if @generate_json
      specs = create_docsets_array
      create_specs_json specs
    end
    

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
    `sass views/homepage_stylesheet.scss:#{$active_folder}/html/assets/homepage_stylesheet.css`
    `sass views/appledoc_stylesheet.scss:#{$active_folder}/html/assets/appledoc_stylesheet.css`
  end

  def create_specs_json specs
    array_string = specs.to_json.to_s
  
    function_wrapped = "var specs = #{array_string}; searchTermChanged()"
    json_filepath = $active_folder + "/html/documents.jsonp"

    vputs "Writing JSON"
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

  def create_docsets_array
    specs = []
    docsets_dir = "#{$active_folder}/docsets/"
  
    Dir.foreach docsets_dir do |podspec_folder|
      next if podspec_folder[0] == '.'
      index_exists = false
      spec = { :versions => []}
    
      Dir.foreach "#{docsets_dir}/#{podspec_folder}" do |version|
        next if version[0] == '.' 
        next if version == "metadata.json"

        index_exists = File.exists?("#{docsets_dir}/#{podspec_folder}/#{version}/index.html")
        spec[:main_version] = version
        spec[:versions] << version
      end
      next unless index_exists
      
      podspec_path = "#{$active_folder}/Specs/#{podspec_folder}/#{spec[:versions].last}/#{podspec_folder}.podspec"
      next unless File.exists? podspec_path
      
      podspec = eval File.open(podspec_path).read 

      spec[:doc_url] = "/docsets/#{podspec.name}/#{spec[:main_version]}/"
      spec[:user] = podspec.or_contributors_to_spec
      spec[:homepage] = podspec.homepage
      spec[:homepage_host] = podspec.or_extensionless_homepage
      spec[:name] = podspec.name
      spec[:summary] = podspec.summary
      
      specs << spec
    end
    specs
  end
  
  # do the *long* check for changes?
  def upload_docset
    vputs "Uploading docsets folder"
    upload_folder "docsets", "sync"
  end
  
  # just dumbly send the html assets over
  def upload_site
    vputs "Uploading site folder"
    upload_folder "html/*", "put"
  end
  

  # Upload the docsets folder to s3
  def upload_folder from, command
    vputs "Uploading #{from} with #{command} on s3"
    
    upload_command = [
      "s3cmd #{command}",
      "--recursive  --acl-public",
      "--no-check-md5",
      "--verbose --human-readable-sizes",
      "#{$active_folder}/#{from} s3://cocoadocs.org/"
    ]

    command upload_command.join(' ')
  end
end