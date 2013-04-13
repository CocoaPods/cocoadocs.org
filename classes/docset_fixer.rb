class DocsetFixer
  include HashInit
  attr_accessor :docset_path, :readme_path, :pod_root, :spec
  
  def fix
    get_latest_version_in_folder
    remove_html_folder
    move_gfm_readme_in
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
    
    `cp -Rf #{@docset_path}html/* #{@docset_path}/`
    `rm -Rf #{@docset_path}/html`
  end
  
  def move_gfm_readme_in
    return unless File.exists? @readme_path
    
    readme = File.read @readme_path

    ['index.html', 'docset/Contents/Resources/Documents/index.html'].each do |path|      
      html = File.open(@docset_path + path).read
      html.sub!("</THISISTOBEREMOVED>", readme)
      File.open(@docset_path + path, 'w') { |f| f.write(html) }
    end 
  end
  
  def create_dash_data
    # the Dash XML
    xml_path = "#{@pod_root}/#{version}/publish/#{spec.name}.xml"
    File.open(xml_path, "wb") do |file|
       file.write("
       <entry>
          <version>#{@version}</version>
          <url>http://cocoadocs.org/docsets/#{spec.name}/#{spec.name}.tgz</url>
        </entry>")
    end

    # the dash docset tgz
    to = "docsets/#{spec.name}/#{@version}/publish/#{spec.name}.tgz"
    from = "docsets/#{spec.name}com.cocoadocs.*"
    command "tar --exclude='.DS_Store' -cvzf #{to} #{from}"
  end
  
  def add_index_redirect_to_latest_to_pod
    from = @pod_root + "/index.html"
    from_server = "docsets/#{spec.name}/index.html"
    to = "docsets/#{spec.name}/#{@version}"
    redirect_command from, from_server, to
  end
  
  def add_docset_redirects
    # this is a xar'd (???) version of the docset
    from = @pod_root + "/docset.xar"
    from_server = "docsets/#{spec.name}/docset.xar"
    to = "docsets/#{spec.name}/#{@version}/publish/docset.xar"
    redirect_command from, from_server, to
    
    # this atom feed contains all the metadata for xcode
    from = @pod_root + "/xcode-docset.atom"
    from_server = "docsets/#{spec.name}/xcode-docset.atom"
    to = "docsets/#{spec.name}/#{@version}/publish/xcode-docset.atom"
    redirect_command from, from_server, to
    
    # this xml feed contains all the metadata for dash
    from = "#{@pod_root}/#{@version}/publish/#{spec.name}.xml"
    from_server = "docsets/#{spec.name}/#{spec.name}.xml"
    to = "docsets/#{spec.name}/#{@version}/publish/#{spec.name}.xml"
    redirect_command from, from_server, to

    # this is the tgz for dash
    from = "#{@pod_root}/#{@version}/publish/#{spec.name}.tgz"
    from_server = "docsets/#{spec.name}/#{spec.name}.tgz"
    to = "docsets/#{spec.name}/#{@version}/publish/#{spec.name}.tgz"
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