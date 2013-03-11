class WebsiteGenerator
  attr_accessor :active_folder

  def create_index_page
     specs = create_docsets_array
   
     template = Tilt.new('views/index.slim')
     html = template.render( :specs => specs )
     index_path = "#{@active_folder}/html/index.html"
   
     FileUtils.mkdir_p(File.dirname(index_path))
     if File.exists? index_path
       File.unlink index_path
     end

     File.open(index_path, "wb") { |f| f.write html }
  end

  def move_public_items
    resources_dir = "#{@active_folder}/html/resources/"
    `rm #{resources_dir}/*`
    `cp public/* #{resources_dir}`
  end

  def create_docsets_array
    specs = []
    docsets_dir = "#{@active_folder}/docsets/"
  
    Dir.foreach docsets_dir do |podspec_folder|
      next if podspec_folder == '.' or podspec_folder == '..'    
   
      spec = { :versions => []}
    
      Dir.foreach "#{docsets_dir}/#{podspec_folder}" do |version|
        next if version == '.' or version == '..'

        spec[:main_version] = version
        spec[:versions] << version
      end
    
      podspec_path = "/Specs/#{podspec_folder}/#{spec[:versions].first}/#{podspec_folder}.podspec"
      podspec = eval File.open(@active_folder + podspec_path).read 
      spec[:spec] = podspec
    
      specs << spec
    end
    specs
  end

end