class ReadmeGenerator
  include HashInit
  attr_accessor :spec, :readme_location, :changelog_location, :active_folder

  def create_changelog
    return if $skip_downloading_readme

    spec_changelog_path = file_local_path("CHANGELOG", @spec)
    return unless spec_changelog_path

    markdown = github_render spec_changelog_path, @changelog_location
    File.open(@changelog_location, 'w') { |f| f.write(markdown) }
  end

  def create_readme
    return if $skip_downloading_readme

    spec_readme_path = file_local_path("README", @spec)
    spec_readme_path = generated_readme_path unless spec_readme_path

    markdown = github_render spec_readme_path, @readme_location
    File.open(@readme_location, 'w') { |f| f.write(markdown) }
  end

  def github_render(spec_readme_path, rendered_path)
    readme_folder = rendered_path.split("/")[0...-1].join("/")
    `mkdir -p '#{readme_folder}'`

    context = nil
    context = "#{@spec.or_user}/#{@spec.or_repo}" if @spec.or_is_github?

    # this is just an empty github app that does nothing
    Octokit.client_id = '52019dadd0bc010084c4'
    Octokit.client_secret = 'c529632d7aa3ceffe3d93b589d8d2599ca7733e8'
    Octokit.markdown(File.read(spec_readme_path), mode: "markdown", context: context)
  end

  def file_local_path(name, spec)
    download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}/"
    local_files = Dir.glob(download_location + "*")
    first_folders = Dir.glob(download_location + "*/*")
    files = local_files + first_folders
    files.select do |f|
      f.end_with?("#{name}.md") || f.end_with?("#{name}.markdown") || f.end_with?("#{name}.mdown") || f.end_with?(name)
    end.first
  end

  def generated_readme_path
    vputs "Generating a README from the Podspec"
    download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}/README.md"

    license = @spec.or_license_name_and_url

    text = %(
# #{ @spec.name }

### #{@spec.summary }

#{ @spec.description }

### Installation

```ruby
pod '#{ @spec.name }'
```

### Authors

#{ @spec.or_contributors_to_spec }

### License

<a href="#{license[:url]}">#{license[:license]}</a>
    )

    `touch #{download_location}`
    File.open(download_location, 'w') { |f| f.write(text) }
    download_location
  end
end
