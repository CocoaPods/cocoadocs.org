class AppledocTemplateGenerator
  include HashInit
  attr_accessor :spec, :versions, :appledoc_templates_path, :source_download_location, :rendering

  def generate
    generate_doc_vars
    generate_versions
    generate_templates
  end

  def generate_doc_vars
    vputs "Generating SCSS variables for templates"
    
    cocoadocs_settings = @source_download_location + "/.cocoadocs.yml"
    settings = YAML::load(File.open(Dir.pwd + "/views/cocoadocs.defaults.yml").read)

    if File.exists? cocoadocs_settings
      vputs "- found custom CocoaDocs colours"
      doc_settings = YAML::load(File.open(cocoadocs_settings).read)
      settings = settings.merge doc_settings
    end

    vars_string = ""
    for key, value in settings
      if value
        vars_string << "$" + key + ": "  + value + "; \n"
      end
    end
    
    vars = Dir.pwd + "/views/_vars.scss"
    File.unlink vars
    File.open(vars, 'w') { |f| f.write vars_string }
  end

  def generate_templates
    vputs "Creating appledoc template at for #{@spec.name}"

    Dir.mkdir(@appledoc_templates_path) unless File.exist?(@appledoc_templates_path)
    Dir.mkdir(@appledoc_templates_path + "/html") unless File.exist?(@appledoc_templates_path + "/html")

    Dir[Dir.pwd + "/views/appledoc_template/*.html.erb"].each do |file|
      filename = File.basename(file, ".html.erb")
      output = render_erb file
      output_path = @appledoc_templates_path + "/html/" + filename + ".html"
      File.open(output_path, 'w') { |f| f.write output }
    end

    `cp -r #{Dir.pwd}/views/docset #{@appledoc_templates_path}`
  end

  def generate_versions
    vputs "Grabbing different version of the library"

    filepath = $active_folder + "/" + $cocoadocs_specs_name + "/Specs/" + @spec.name

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

  def render_erb filepath, context=nil
    if context
      @rendering_context = context
    end
  
    filename = File.basename(filepath, ".html.erb")

    erb = ERB.new(File.read(filepath))
    erb.filename = filename
    result = erb.result(self.get_binding)
  end

  def get_binding
    binding()
  end

end
