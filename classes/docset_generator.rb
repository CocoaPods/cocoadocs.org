if RUBY_VERSION < "2.0.0"
  require 'shellescape'
end

class DocsetGenerator
  include HashInit
  attr_accessor :spec, :from, :to, :readme_location, :appledoc_templates_path, :library_settings, :source_download_location

  def docset_command

      FileUtils.rmdir(to) if Dir.exist?(to)

      version = @spec.version.to_s.downcase
      cocoadocs_id = "com.cocoadocs.#{@spec.name.downcase}"

      headers = headers_for_spec_at_location @spec
      headers = [from] if headers.count == 0

      guides = GuidesGenerator.new(spec: @spec, source_download_location: @source_download_location)

      verbosity = $verbose ? "5" : "1"
      FileUtils.mkpath(to) if !File.directory?(to)

      docset_command = [
        "vendor/appledoc",
        "--project-name", wrap(@spec.name),                       # name in top left
        "--project-company", wrap(@spec.or_contributors_to_spec), # name in top right
        "--company-id", "#{cocoadocs_id}",                        # the id for the

        "--project-version", "#{version}",                      # project version
        "--no-install-docset",                                  # don't make a duplicate

        "--templates", wrap(@appledoc_templates_path),          # use the custom template
        "--verbose", "#{verbosity}",                            # give some useful logs

        "--keep-intermediate-files",                            # space for now is OK
        "--create-html",                                        # eh, nice to have
        "--publish-docset",                                     # this should create atom

        "--docset-feed-url", wrap("#{$website_home}docsets/#{@spec.name}/xcode-docset.atom"),
        "--docset-atom-filename", "xcode-docset.atom",

        "--docset-package-url", wrap("#{$website_home}docsets/#{@spec.name}/docset.xar"),
        "--docset-package-filename", "docset",

        "--docset-fallback-url", wrap("#{$website_home}docsets/#{@spec.name}"),
        "--docset-feed-name", "#{@spec.name}",

        # http://gentlebytes.com/appledoc-docs-examples-advanced/
        "--keep-undocumented-objects",                         # not everyone will be documenting
        "--keep-undocumented-members",                         # so we should at least show something
        "--search-undocumented-doc",                           # uh? ( no idea what this does... )

        *guides.generate_array_for_appledoc,

        "--output", to.shellescape,                            # where should we throw stuff
        *headers.map { |header| header.shellescape }
      ]

      if File.exist? readme_location
        docset_command.insert(3, "--index-desc", "resources/overwritten_index.html")
      end

      if @library_settings["explicit-references"]
        docset_command.insert(3, "--explicit-crossref")
      end

      docset_command.join " "
  end

  def create_docset
    vputs "Creating docset"

    command docset_command

    fail "Appledoc crashed in creating the DocSet for this project." unless Dir.exist? to

    # Appledoc did not generate HTML for this project. Perhaps it has no objc classes?
    index = File.join(to, "html", "index.html")
    unless File.exists? index

      show_error_page index, "Could not find Objective-C Classes."
    end
  end

  def wrap(string)
    '"' + string + '"'
  end

  def show_error_page(path, error)
    vputs "Got an error from Appledoc"

    index_template_path = File.join(@appledoc_templates_path, "html", "index-template.html")
    metadata = {
      page: {
        title: @spec.name
      },

      indexDescription: {
      },
      hasDocs: {
        strings: { indexPage: { docsTitle: "Error Parsing Pod" } },
        docs: [{ href: "#", title: error }]
      }
    }
    tempalate_contents = File.read(index_template_path)
    index_content = Mustache.render(tempalate_contents, metadata)

    fake_index_content = File.read("resources/overwritten_index.html")

    index_content = index_content.gsub('index-overview">', 'index-overview">' + fake_index_content)
    output_path = File.dirname(path)
    FileUtils.mkpath(output_path) if !File.directory?(output_path)
    File.open(path, 'w') { |f| f.write(index_content) }
  end

  def report_appledoc_error
    puts "Appledoc has crashed."
    fail 'Appledoc has crashed'
  end

  # Use cocoapods to get the header files for a specific spec

  def headers_for_spec_at_location(_spec)
    pathlist = Pod::Sandbox::PathList.new(Pathname.new(@source_download_location))
    headers = []

    # https://github.com/CocoaPods/cocoadocs.org/issues/35
    [@spec, *@spec.recursive_subspecs].each do |internal_spec|
      internal_spec.available_platforms.each do |platform|
        consumer = Pod::Specification::Consumer.new(internal_spec, platform)
        accessor = Pod::Sandbox::FileAccessor.new(pathlist, consumer)

        if accessor.public_headers
          headers += accessor.public_headers.map(&:to_s)
        else
          puts "Skipping headers for #{internal_spec} on platform #{platform} (no headers found).".blue
        end
      end
    end

    headers.uniq
  end
end
