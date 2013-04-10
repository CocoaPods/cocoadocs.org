class DocsetGenerator
  include HashInit
  
  attr_accessor :spec, :from, :to, :readme_location
  
  def create_docset
    vputs "Creating docset"
  
    FileUtils.rmdir(to) if Dir.exists?(to)
  
    version = @spec.version.to_s.downcase
    id = @spec.name.downcase
    cocoadocs_id = "cocoadocs.#{spec.name.downcase}"
  
    headers = headers_for_spec_at_location @spec
    headers.map! { |header| Shellwords.escape header }
    vputs "Found #{headers.count} header files"
  
    if headers.count == 0
      headers = [from] 
    end
  
    docset_command = [
      "appledoc",
      "--project-name #{@spec.name}",                         # name in top left
      "--project-company '#{@spec.or_contributors_to_spec}'",   # name in top right
      "--project-version #{version}",                        # project version
      "--no-install-docset",                                 # don't make a duplicate

      "--company-id #{cocoadocs_id}",                        # the id for the 
      "--templates ./appledoc_templates",                    # use the custom template
      "--verbose 3",                                         # give some useful logs

      "--keep-intermediate-files",                           # space for now is OK
      "--create-html",                                       # eh, nice to have
   #   "--publish-docset",                                    # this should create atom
    
  #    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/%DOCSETATOMFILENAME",
   #   "--docset-package-url http://cocoadocs.org/docsets/#{spec.name}/%DOCSETPACKAGEFILENAME",
    
  #    "--docset-atom-filename '#{to}../#{spec.name}.atom' ",
  #    "--docset-feed-url http://cocoadocs.org/docsets/#{spec.name}/#{spec.name}.xml",
  #   "--docset-feed-name #{spec.name}",                    

      "--keep-undocumented-objects",                         # not everyone will be documenting
      "--keep-undocumented-members",                         # so we should at least show something
      "--search-undocumented-doc",                           # uh? ( no idea what this does... )
    
      "--output #{@to}",                                      # where should we throw stuff
      *headers
    ]

    if File.exists? readme_location
      docset_command.insert(3, "--index-desc resources/overwritten_index.html")
    end

    command docset_command.join ' '
  end
  
  # Use cocoapods to get the header files for a specific spec

  def headers_for_spec_at_location spec
    download_location = $active_folder + "/download/#{@spec.name}/#{@spec.version}/"
    
    sandbox = Pod::Sandbox.new( download_location )
    pathlist = Pod::Sandbox::PathList.new( Pathname.new(download_location) )  
    headers = []
  
#    headers = Pod::Generator::Documentation.new( sandbox, spec, pathlist).public_headers

    @spec.available_platforms.each do |platform|
      installer = Pod::Installer::PodSourceInstaller.new(sandbox, {platform => [@spec]} )
      sources = installer.send(:used_files).delete_if do |path|
          !path.include? ".h"
      end
      headers += sources
    end
  
    headers.uniq
  end
  
end