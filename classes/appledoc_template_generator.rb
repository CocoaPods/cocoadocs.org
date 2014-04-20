class AppledocTemplateGenerator
  include HashInit
  attr_accessor :spec, :versions
  
  def generate
    generate_versions
    generate_templates
  end
  
  def generate_templates
    vputs "Creating appledoc template at for #{@spec.name}"
    
    output_folder = Dir.pwd + "/appledoc_templates/html/"

    Dir[Dir.pwd + "/views/appledoc_template/*.html.erb"].each do |file| 
      filename = File.basename(file, ".html.erb")
      output = render_erb file
      output_path = output_folder + filename + ".html"
      File.open(output_path, 'w') { |f| f.write output }
    end
  end
  
  def generate_versions
    vputs "Grabbing different version of the library"
    
    filepath = $active_folder + "/" + $cocoadocs_specs_name +"/" + @spec.name

    versions = []
    Dir.foreach filepath do |version|
      next if version[0] == '.'
      next unless File.directory? "#{filepath}/#{version}/"
    
      versions << version
    end

    # Semantically order them as they're in unix's order ATM
    # we convert them to Versions, then back to strings
    @versions = versions.map { |s| Pod::Version.new(s) }.sort.map { |semver| semver.version }
  end
  
  # ERB helpers
  
  def render_erb filepath
    filename = File.basename(filepath, ".html.erb")

    erb = ERB.new(File.read(filepath))
    erb.filename = filename
    erb.result(self.get_binding)
  end
  
  def get_binding
    binding()
  end
  
end