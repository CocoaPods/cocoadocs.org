class ReadmeGenerator
  POSSIBLE_CHANGELOG_NAMES = ['CHANGELOG', 'RELEASE_NOTES']

  include HashInit
  attr_accessor :spec, :readme_location, :changelog_location, :active_folder, :settings

  def create_changelog
    return if $skip_downloading_readme

    spec_changelog_path = POSSIBLE_CHANGELOG_NAMES.map { |name| file_local_path(name, @spec) }.first { |path| !path.nil? }
    return unless spec_changelog_path

    markdown = github_render spec_changelog_path, @changelog_location
    File.open(@changelog_location, 'w') { |f| f.write(markdown) }
  end

  def create_readme
    return if $skip_downloading_readme

    spec_readme_path = find_spec_readme_path(@settings, "README", @spec)
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
    contents = File.open(spec_readme_path, "r:UTF-8", &:read)
    Octokit.markdown(contents, mode: "markdown", context: context)
  end

  def find_spec_readme_path(settings, name, spec)
    path = nil
    if settings.key? "readme"
      path = settings["readme"]
    elsif spec.attributes_hash["readme"]
      path = spec.attributes_hash["readme"]
    end

    return $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}/#{path}" if path
    return file_local_path("README", @spec)
  end

  def file_local_path(name, spec)
    download_location = $active_folder + "/download/#{spec.name}/#{spec.version}/#{spec.name}/"
    Dir.glob("#{download_location}/{#{name},*/#{name},*/**/#{name}}{.md,.markdown,.mdown,}", File::FNM_CASEFOLD).first
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
