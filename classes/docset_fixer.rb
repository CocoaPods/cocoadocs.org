class DocsetFixer
  include HashInit
  attr_accessor :docset_path, :readme_path, :pod_root, :spec
  
  def fix
    remove_html_folder
    move_gfm_readme_in
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
  
  def add_redirect_to_latest_to_pod
    versions = []
    Dir.foreach @pod_root do |version|
      next if version[0] == '.'
      next if version == "metadata.json"
      next if version == "index.html"
      
      versions << version
    end

    #semantically order them as they're in unix's order ATM
    # we convert them to Versions, then get the last  string
    version = versions.map { |s| Pod::Version.new(s) }.sort.map { |semver| semver.version }.last

    from = @pod_root + "/index.html"
    from_server = "docsets/#{spec.name}/index.html"
    to = "docsets/#{spec.name}/#{version}"
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