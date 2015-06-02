class AppledocTemplateGenerator
  include HashInit
  attr_accessor :spec, :versions, :appledoc_templates_path, :source_download_location, :rendering, :library_settings

  def generate
    generate_doc_vars
    generate_templates
  end

  def generate_doc_vars
    vputs "Generating SCSS variables for templates"

    vars_string = ""
    for key, value in @library_settings
      if value && value.is_a?(String)
        vars_string << "$" + key + ": "  + value + "; \n"
      end
    end

    vars = Dir.pwd + "/views/_vars.scss"
    File.unlink vars if File.exist? vars
    File.open(vars, 'w') { |f| f.write vars_string }
  end

  def generate_templates
    vputs "Creating appledoc template at for #{@spec.name}"

    `mkdir -p #{@appledoc_templates_path}/html` unless File.exist?(@appledoc_templates_path + "/html")

    Dir[Dir.pwd + "/views/appledoc_template/*.html.erb"].each do |file|
      filename = File.basename(file, ".html.erb")
      output = render_erb file
      output_path = File.join(@appledoc_templates_path, "html")
      FileUtils.mkpath(output_path) if !File.directory?(output_path)
      output_file = File.join(output_path, filename + ".html")
      File.open(output_file, 'w') { |f| f.write output }
    end

    `cp -r \"#{Dir.pwd}\"/views/docset \"#{@appledoc_templates_path}\"`
  end

  # ERB helpers

  def render_erb(filepath, context = nil)
    if context
      @rendering_context = context
    end

    filename = File.basename(filepath, ".html.erb")

    erb = ERB.new(File.read(filepath))
    erb.filename = filename
    result = erb.result(get_binding)
  end

  def get_binding
    binding
  end
end
