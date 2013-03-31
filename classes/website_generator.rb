class WebsiteGenerator
  attr_accessor :active_folder

  def generate
    create_index_page
    move_public_items
  end
  
  def upload
    vputs "Uploading docsets folder"
  
    upload_folder "docsets", ""
    upload_folder "html/*", ""
  end

  def create_index_page
    vputs "Creating index page"
    
    specs = create_docsets_array
    create_specs_json specs

    template = Tilt.new('views/index.slim')
    html = template.render
    index_path = "#{@active_folder}/html/index.html"

    vputs "Writing index"
    seve_file html, index_path
  end

  def create_specs_json specs
    array_string = specs.to_json.to_s
  
    function_wrapped = "var specs = #{array_string}; searchTermChanged()"
    json_filepath = @active_folder + "/html/documents.jsonp"

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
    resources_dir = "#{@active_folder}/html/assets/"

    command "rm -rf #{resources_dir}"
    command "mkdir #{resources_dir}"
    command "cp -R public/* #{resources_dir}"
  end

  def create_docsets_array
    specs = []
    docsets_dir = "#{@active_folder}/docsets/"
  
    Dir.foreach docsets_dir do |podspec_folder|
      next if podspec_folder[0] == '.'
   
      spec = { :versions => []}
    
      Dir.foreach "#{docsets_dir}/#{podspec_folder}" do |version|
        next if version[0] == '.' 
        next if version == "metadata.json"
        spec[:main_version] = version
        spec[:versions] << version
      end
    
      podspec_path = "/Specs/#{podspec_folder}/#{spec[:versions].last}/#{podspec_folder}.podspec"
      podspec = eval File.open(@active_folder + podspec_path).read 

      spec[:doc_url] = "/docsets/#{podspec.name}/#{spec[:main_version]}/"
      spec[:user] = podspec.or_user
      spec[:homepage] = podspec.homepage
      spec[:homepage_host] = podspec.or_extensionless_homepage
      spec[:name] = podspec.name
      spec[:summary] = podspec.summary
      
      specs << spec
    end
    specs
  end

  # Upload the docsets folder to s3
  def upload_folder from, to
    vputs "Uploading #{from} to #{to} on s3"
    
    upload_command = [
      "s3cmd sync",
      "--recursive  --acl-public",
      "--no-check-md5",
      "--verbose --human-readable-sizes",
      "#{@active_folder}/#{from} s3://cocoadocs.org/#{to}"
    ]

    command upload_command.join(' ')
  end

end