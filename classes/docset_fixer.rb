class DocsetFixer
  include HashInit
  attr_accessor :docset_path, :readme_path, :pod_root, :spec, :css_path
  
  def fix
    get_latest_version_in_folder
    remove_html_folder
    delete_extra_docset_folder
    fix_relative_links_in_gfm
    move_gfm_readme_in
    move_css_in
    move_docset_icon_in
    create_dash_data
  end

  def get_latest_version_in_folder
    versions = []
    Dir.foreach @pod_root do |version|
      next if version[0] == '.'
      next unless File.directory? "#{@pod_root}/#{version}"
      
      versions << version
    end

    #semantically order them as they're in unix's order ATM
    # we convert them to Versions, then get the last  string
    @version = versions.map { |s| Pod::Version.new(s) }.sort.map { |semver| semver.version }.last    
  end
  
  
  def remove_html_folder
    # the structure is normally /POD/version/html/index.html
    # make it /POD/version/index.html
    
    return unless Dir.exists? @docset_path + "html/"
    
    vputs "Moving /POD/version/html/index.html to /POD/version/index.html"
    command "cp -Rf #{@docset_path}html/* #{@docset_path}/"
    command "rm -Rf #{@docset_path}/html"
  end
  
  def delete_extra_docset_folder
    vputs "Removing redundant docset extracts"
    command "rm -Rf #{@docset_path}/docset"
  end
  
  def fix_relative_links_in_gfm
    vputs "Fixing relative URLs in github flavoured markdown"
    
    return unless @spec.or_is_github?
    return unless File.exists? @readme_path
    
    doc = Nokogiri::HTML(File.read @readme_path)
    doc.css("a").each do |link|
      if link.attributes["href"]
        link_string = link.attributes["href"].value
        next if link_string.start_with? "#"
        next if link_string.start_with? "http"
        next if link_string.include? "@"
      
        link.attributes["href"].value = "http://github.com/#{@spec.or_user}/#{@spec.or_repo}/#{CGI.escape link.attributes["href"].value}"
      end
    end

    `rm #{@readme_path}`
    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end
  
  def move_docset_icon_in
    vputs "Adding Docset Icon For Dash"
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    command "cp resources/docset_icon.png #{@docset_path}/#{docset}/icon.png"
  end
  
  def move_gfm_readme_in
    return unless File.exists? @readme_path

    vputs "Moving Github Markdown into index"
    readme_text = File.open(@readme_path).read
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    
    ['index.html', "#{docset}/Contents/Resources/Documents/index.html"].each do |path|
      next unless File.exists? @docset_path + path
      
      html = File.open(@docset_path + path).read
      html.sub!("</THISISTOBEREMOVED>", readme_text)
      File.open(@docset_path + path, 'w') { |f| f.write(html) }
    end 
  end
  
  def move_css_in
    # dash only supports local css
    vputs "Generating and moving local CSS files into the DocSet"
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    command "sass views/appledoc_stylesheet.scss:#{@docset_path}/#{docset}/Contents/Resources/Documents/appledoc_stylesheet.css"
    command "cp public/appledoc_gfm.css #{@docset_path}/#{docset}/Contents/Resources/Documents/"
  end
  
  def create_dash_data
    vputs "Creating XML for Dash"
    # Dash requires a different format for the docset and the xml data
    
    # create the tgz file for the xcode docset using our GFM index
    version_folder = "#{@pod_root}/#{@spec.version}"
    publish_folder = "#{version_folder}/publish"
    
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    
    Dir.chdir(version_folder) do
      command "xar -cf 'publish/docset.xar' '#{docset}'"
    end
    
    # the Dash XML
    xml_path = "#{publish_folder}/#{@spec.name}.xml"
    
    File.open(xml_path, "wb") do |file|
       file.write("
       <entry>
          <version>#{@version}</version>
          <url>#{$website_home}docsets/#{@spec.name}/#{@spec.name}.tgz</url>
        </entry>")
    end

    # the dash docset tgz
    to = "publish/#{@spec.name}.tgz"
    from = docset
    
    Dir.chdir(version_folder) do
      command "tar --exclude='.DS_Store' -czf #{to} #{from}"
    end
    
  end
  
  def add_index_redirect_to_latest_to_pod
    vputs "Creating a redirect to move to the latest pod"
    
    from = @pod_root + "/index.html"
    from_server = "docsets/#{@spec.name}/index.html"
    to = "docsets/#{@spec.name}/#{@version}"
    redirect_command from, from_server, to
  end
  
  def add_docset_redirects
    vputs "Adding redirects for the DocSets for Xcode & Dash"
    
    # this is a xar'd (???) version of the docset
    from = @pod_root + "/docset.xar"
    from_server = "docsets/#{@spec.name}/docset.xar"
    to = "docsets/#{@spec.name}/#{@version}/publish/docset.xar"
    redirect_command from, from_server, to
    
    # this atom feed contains all the metadata for xcode
    from = @pod_root + "/xcode-docset.atom"
    from_server = "docsets/#{spec.name}/xcode-docset.atom"
    to = "docsets/#{@spec.name}/#{@version}/publish/xcode-docset.atom"
    redirect_command from, from_server, to
    
    # this xml feed contains all the metadata for dash
    from = "#{@pod_root}/#{@version}/publish/#{@spec.name}.xml"
    from_server = "docsets/#{@spec.name}/#{@spec.name}.xml"
    to = "docsets/#{@spec.name}/#{@version}/publish/#{@spec.name}.xml"
    redirect_command from, from_server, to

    # this is the tgz for dash
    from = "#{@pod_root}/#{@version}/publish/#{@spec.name}.tgz"
    from_server = "docsets/#{@spec.name}/#{@spec.name}.tgz"
    to = "docsets/#{@spec.name}/#{@version}/publish/#{@spec.name}.tgz"
    redirect_command from, from_server, to
  end
  
  def redirect_command from, from_server, to
    command "touch #{from}"
    
    redirect_command = [
      "s3cmd put",
      "--acl-public",
      "--no-check-md5",
      "--verbose --human-readable-sizes --reduced-redundancy",
      "--add-header='x-amz-website-redirect-location:/#{to}'",
      "#{from} s3://cocoadocs.org/#{from_server}"
    ]

    command redirect_command.join(' ')
    
  end
end