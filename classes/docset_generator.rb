class DocsetGenerator
  include HashInit
  attr_accessor :spec, :from, :to, :readme_location, :appledoc_templates_path, :library_settings, :source_download_location
  
  def create_docset
    vputs "Creating docset"

    FileUtils.rmdir(to) if Dir.exists?(to)

    version = @spec.version.to_s.downcase
    id = @spec.name.downcase
    cocoadocs_id = "com.cocoadocs.#{spec.name.downcase}"

    headers = headers_for_spec_at_location @spec
    headers.map! { |header| Shellwords.escape header }
    headers = [from] if headers.count == 0
    
    guides = GuidesGenerator.new(:spec = @spec, :source_download_location => @source_download_location) 

    verbosity = $verbose ? "5" : "1"

    template_directory = File.join($current_dir, 'appledoc_templates')

    docset_command = [
      "appledoc",
      "--project-name #{@spec.name}",                           # name in top left
      "--project-company '#{@spec.or_contributors_to_spec}'",   # name in top right
      "--company-id #{cocoadocs_id}",                           # the id for the

      "--project-version #{version}",                           # project version
      "--no-install-docset",                                    # don't make a duplicate

      "--templates #{@appledoc_templates_path}",                # use the custom template
      "--verbose #{verbosity}",                                 # give some useful logs

      "--keep-intermediate-files",                              # space for now is OK
      "--create-html",                                          # eh, nice to have
      "--publish-docset",                                       # this should create atom

      "--docset-feed-url #{$website_home}docsets/#{spec.name}/xcode-docset.atom",
      "--docset-atom-filename xcode-docset.atom",

      "--docset-package-url #{$website_home}docsets/#{spec.name}/docset.xar",
      "--docset-package-filename docset",

      "--docset-fallback-url #{$website_home}docsets/#{spec.name}",
      "--docset-feed-name #{spec.name}",

      # http://gentlebytes.com/appledoc-docs-examples-advanced/
      "--keep-undocumented-objects",                         # not everyone will be documenting
      "--keep-undocumented-members",                         # so we should at least show something
      "--search-undocumented-doc",                           # uh? ( no idea what this does... )
      
      guides.generate_string_for_appledoc

      "--output #{@to}",                                      # where should we throw stuff
      *headers
    ]

    if File.exists? readme_location
      docset_command.insert(3, "--index-desc resources/overwritten_index.html")
    end

    
    command docset_command.join(' ')

    raise "Appledoc crashed in creating the DocSet for this project." unless Dir.exists? to
    raise "Appledoc did not generate HTML for this project. Perhaps it has no objc classes." unless File.exists? to + "/html/index.html"
    
  end

  def report_appledoc_error
    raise 'Appledoc has crashed'
  end

  # Use cocoapods to get the header files for a specific spec

  def headers_for_spec_at_location spec
    pathlist = Pod::Sandbox::PathList.new( Pathname.new(@source_download_location) )
    headers = []

    # https://github.com/CocoaPods/cocoadocs.org/issues/35
    [@spec, *@spec.recursive_subspecs].each do |internal_spec|
      internal_spec.available_platforms.each do |platform|
        consumer = Pod::Specification::Consumer.new(internal_spec, platform)
        accessor = Pod::Sandbox::FileAccessor.new(pathlist, consumer)

        if accessor.public_headers
          headers += accessor.public_headers.map{ |filepath| filepath.to_s }
        else
          puts "Skipping headers for #{internal_spec} on platform #{platform} (no headers found).".blue
        end
      end
    end

    headers.uniq
  end
end
