require 'htmlcompressor'
require 'docstat'

class DocsetFixer
  include HashInit
  attr_accessor :docset_path, :readme_path, :pod_root, :spec, :css_path

  def fix
    get_latest_version_in_folder
    remove_html_folder
    delete_extra_docset_folder
    fix_relative_links_in_gfm
    fix_travis_links_in_gfm
    move_gfm_readme_in
    move_css_in
    move_docset_icon_in
    add_documentation_stats
    create_dash_data
    minify_html
  end

  def add_documentation_stats
    vputs "Generating documentation stats for moving into docset"

    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    stats = DocStat.process(@docset_path + docset)
    percent = (stats["ratio"] * 100).round(0).to_s

    # How nice am I?!
    percent = "100" if (stats["ratio"] > 0.97);

    Dir.glob(@docset_path + "**/*.html").each do |name|
      text = File.read(name)
      replace = text.gsub("$$$DOC_PERCENT$$$", percent)
      File.open(name, "w") { |file| file.puts replace }
    end
  end

  def get_latest_version_in_folder
    versions = []
    Dir.foreach @pod_root do |version|
      next if version[0] == '.'
      next unless File.directory? "#{@pod_root}/#{version}"

      versions << version
    end

    #semantically order them as they're in unix's order ATM
    # we convert them to Versions, then get the last string
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

  def fix_relative_link link_string
    if link_string.start_with? "#"
      return link_string
    end
    if link_string.start_with? "http"
      return link_string
    end
    if link_string.start_with? "https"
      return link_string
    end
    if link_string.include? "@"
      return link_string
    end

    return "https://raw.github.com/#{@spec.or_user}/#{@spec.or_repo}/#{@spec.or_git_ref}/#{CGI.escape link_string}"
  end

  def fix_relative_links_in_gfm
    vputs "Fixing relative URLs in github flavoured markdown"

    return unless @spec.or_is_github?
    return unless File.exists? @readme_path

    doc = Nokogiri::HTML(File.read @readme_path)
    doc.css("a").each do |link|
      if link.attributes["href"]
        link.attributes["href"].value = fix_relative_link link.attributes["href"].value
      end
    end

    doc.css("img").each do |img|
      if img.attributes["src"]
        img.attributes["src"].value = fix_relative_link img.attributes["src"].value
      end
    end

    `rm #{@readme_path}`
    File.open(@readme_path, 'w') { |f| f.write(doc) }
  end


  def fix_travis_links_in_gfm
    vputs "Fixing Travis links in markdown"

    return unless @spec.or_is_github?
    return unless File.exists? @readme_path

    doc = Nokogiri::HTML(File.read @readme_path)
    doc.css('a[href^="https://travis-ci"]').each do |link|

      link.attributes["href"].value = "https://travis-ci.org/#{@spec.or_user}/#{@spec.or_repo}/branches"
      link.inner_html = "<img src='https://travis-ci.org/#{@spec.or_user}/#{@spec.or_repo}.svg?branch=#{ @spec.version }'>"

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
    readme_text = File.read(@readme_path)
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"

    ['index.html', "#{docset}/Contents/Resources/Documents/index.html"].each do |path|
      homepage_path = File.join(@docset_path, path)
      return unless File.exists?(homepage_path)

      html = File.read(homepage_path)
      html.sub!("</THISISTOBEREMOVED>", readme_text)
      File.open(homepage_path, 'w') { |f| f.write(html) }
    end
  end

  def move_css_in
    vputs "Generating and moving local CSS files into the DocSet"
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"

    # embed css in docset
    command "sass views/appledoc_stylesheet.scss:#{@docset_path}/#{docset}/Contents/Resources/Documents/appledoc_stylesheet.css"
    command "sass views/appledoc_gfm.scss:#{@docset_path}/#{docset}/Contents/Resources/Documents/appledoc_gfm.css"

    # copy to website too
    command "cp #{@docset_path}/#{docset}/Contents/Resources/Documents/appledoc_stylesheet.css #{@docset_path}/"
    command "cp #{@docset_path}/#{docset}/Contents/Resources/Documents/appledoc_gfm.css #{@docset_path}/"

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

  # Minify all of the HTML files in the docset
  #
  # This is done to save space, with some testing, it
  # saved 0.2MB on 1.6MB documentation
  def minify_html
    compressor = HtmlCompressor::Compressor.new

    Dir.chdir(@pod_root) do
      Dir.glob('**/*.html') do |filename|
        html = File.read(filename)
        compressed_html = compressor.compress(html)
        File.open(filename, 'w') { |f| f.write(compressed_html) }
      end
    end
  end

  def redirect_command from, from_server, to
    command "touch #{from}"

    redirect_command = [
      "s3cmd put",
      "--acl-public",
      "--no-check-md5",
      "--verbose --human-readable-sizes --reduced-redundancy",
      "--add-header='x-amz-website-redirect-location:/#{to}'",
      "#{from} s3://#{$s3_bucket}/#{from_server}"
    ]

    command redirect_command.join(' ')
  end
end
