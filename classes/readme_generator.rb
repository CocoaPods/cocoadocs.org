class ReadmeGenerator
  include HashInit
  attr_accessor :spec, :readme_location, :active_folder
  
  def create_readme
      spec_readme = readme_path @spec
      return unless spec_readme
    
      readme_folder = @readme_location.split("/")[0...-1].join("/")
      `mkdir -p '#{readme_folder}'`

      context = nil
      context = "#{@spec.or_user}/#{@spec.or_repo}" if @spec.or_is_github?
    
      # this is just an empty github app that does nothing
      Octokit.client_id = '52019dadd0bc010084c4'
      Octokit.client_secret = 'c529632d7aa3ceffe3d93b589d8d2599ca7733e8'
      markdown = Octokit.markdown(File.read(spec_readme), :mode => "markdown", :context => context)
    
      File.open(readme_location, 'w') { |f| f.write(markdown) }
  end

  def readme_path spec
    download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}"
    ["README.md", "README.markdown", "README.mdown"].each do |potential_name|
      potential_path = download_location + "/" + potential_name
      if File.exists? potential_path
        return potential_path
      end
    end
    nil
  end
  
end