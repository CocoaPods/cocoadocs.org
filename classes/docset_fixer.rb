require 'htmlcompressor'
require 'docstat'
require 'travis'

class DocsetFixer
  include HashInit
  attr_accessor :docset_path, :readme_path, :changelog_path, :pod_root, :spec, :css_path, :doc_percent, :versions

  def manipulator
    ReadmeManipulator.new({ :readme_path => @readme_path, :spec => @spec })
  end

  def fix
    @version = spec.version
    remove_html_folder
    delete_extra_docset_folder
    manipulator.run_for_cocoadocs
    move_gfm_readme_in
    move_css_in
    move_docset_icon_in
    post_process
    create_dash_data
    minify_html
    create_separate_readme
    move_changelog_in
  end

  def fix_for_jazzy
    @version = spec.version
    manipulator.run_for_jazzy
    create_dash_data
    minify_html
    create_separate_readme('article.main-content .section')
    move_changelog_in
  end

  def move_changelog_in
    destination = File.join(docset_path, "CHANGELOG.html")
    FileUtils.copy(changelog_path, destination) if File.exist? changelog_path
  end

  def create_separate_readme(parent_selector = nil)
    destination = File.join(docset_path, "README.html")
    if parent_selector
      doc = Nokogiri::HTML(File.read readme_path)
      doc = doc.css(parent_selector)

      File.open(destination, 'w') { |f| f.write(doc) }
    else
      FileUtils.copy(readme_path, destination)
    end
  end

  def post_process
    percent = get_doc_percent
    programming_guides = get_programming_guides

    Dir.glob(@docset_path + "**/*.html").each do |name|
      text = File.read(name)

      replace = text.gsub("$$$DOC_PERCENT$$$", percent)
      replace = replace.gsub("$$$PROGRAMMING_GUIDES$$$", programming_guides)

      File.open(name, "w") { |file| file.puts replace }
    end
  end

  def get_programming_guides
    list = ""
    guides_path = File.join(@docset_path, "docs", "guides")
    return "" unless File.exist? guides_path

    Dir.foreach guides_path do |guide|
      next if guide.start_with? "."

      list << "<li><a href='#{ guide }'>#{ guide.gsub(".html", "") }</a></li>"
    end
    list
  end

  def get_doc_percent
    return @doc_percent if @doc_percent
    vputs "Generating documentation stats for moving into docset"

    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    stats = DocStat.process(@docset_path + docset)
    percent = (stats["ratio"] * 100).round(0).to_s

    # How nice am I?!
    percent = "100" if stats["ratio"] > 0.95
    @doc_percent = percent
    percent
  end

  def remove_html_folder
    # the structure is normally /POD/version/html/index.html
    # make it /POD/version/index.html

    return unless Dir.exist? @docset_path + "html/"

    vputs "Moving /POD/version/html/index.html to /POD/version/index.html"
    command "cp -Rf \"#{@docset_path}\"html/* \"#{@docset_path}/\""
    command "rm -Rf \"#{@docset_path}\"/html"
  end

  def delete_extra_docset_folder
    vputs "Removing redundant docset extracts"
    command "rm -Rf \"#{@docset_path}\"/docset"
  end

  def move_docset_icon_in
    vputs "Adding Docset Icon For Dash"
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"
    command "cp resources/docset_icon.png \"#{@docset_path}\"/#{docset}/icon.png"
  end

  def move_gfm_readme_in
    return unless File.exist? @readme_path

    vputs "Moving Github Markdown into index"
    readme_text = File.read(@readme_path)
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"

    ['index.html', "#{docset}/Contents/Resources/Documents/index.html"].each do |path|
      homepage_path = File.join(@docset_path, path)
      return unless File.exist?(homepage_path)

      html = File.read(homepage_path)
      html.sub!("</THISISTOBEREMOVED>", readme_text)
      File.open(homepage_path, 'w') { |f| f.write(html) }
    end
  end

  def move_css_in
    vputs "Generating and moving local CSS files into the DocSet"
    docset = "com.cocoadocs.#{@spec.name.downcase}.#{@spec.name}.docset"

    # embed css in docset
    command "sass views/appledoc_stylesheet.scss:\"#{@docset_path}\"/#{docset}/Contents/Resources/Documents/appledoc_stylesheet.css"
    command "sass views/appledoc_gfm.scss:\"#{@docset_path}\"/#{docset}/Contents/Resources/Documents/appledoc_gfm.css"

    # copy to website too
    command "cp \"#{@docset_path}\"/#{docset}/Contents/Resources/Documents/appledoc_stylesheet.css \"#{@docset_path}/\""
    command "cp \"#{@docset_path}\"/#{docset}/Contents/Resources/Documents/appledoc_gfm.css \"#{@docset_path}/\""

  end

  def create_dash_data
    vputs "Creating XML for Dash"
    # Dash requires a different format for the docset and the xml data

    # create the tgz file for the xcode docset using our GFM index
    version_folder = "#{@pod_root}/#{@spec.version}"
    publish_folder = "#{version_folder}/publish"

    command "mkdir -p '#{publish_folder}'"

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

  def add_index_redirect_to_latest_to_pod(latest_version)
    vputs "Creating a redirect to move to the latest pod"

    from = @pod_root + "/index.html"
    server_location = "docsets/#{@spec.name}/index.html"
    to = "docsets/#{@spec.name}/#{latest_version}"
    vputs "Will be redirecting to #{@spec.name}/#{latest_version}"


    File.open(from, 'w') do |f|
      f.write "<meta http-equiv='refresh' content='0; url=/#{to}'>"
    end

    upload_file from, server_location
  end

  def add_docset_redirects(latest_version)
    vputs "Adding redirects for the DocSets for Xcode & Dash"

    # this is a xar'd (???) version of the docset
    from = @pod_root + "/docset.xar"
    from_server = "docsets/#{@spec.escaped_name}/docset.xar"
    to = "docsets/#{@spec.name}/#{latest_version}/publish/docset.xar"
    redirect_command from, from_server, to

    # this atom feed contains all the metadata for xcode
    from = @pod_root + "/xcode-docset.atom"
    from_server = "docsets/#{spec.escaped_name}/xcode-docset.atom"
    to = "docsets/#{@spec.name}/#{latest_version}/publish/xcode-docset.atom"
    redirect_command from, from_server, to

    # this xml feed contains all the metadata for dash
    from = "#{@pod_root}/#{@version}/publish/#{@spec.name}.xml"
    from_server = "docsets/#{@spec.escaped_name}/#{@spec.escaped_name}.xml"
    to = "docsets/#{@spec.name}/#{@version}/publish/#{@spec.name}.xml"
    redirect_command from, from_server, to

    # this is the tgz for dash
    from = "#{@pod_root}/#{latest_version}/publish/#{@spec.name}.tgz"
    from_server = "docsets/#{@spec.escaped_name}/#{@spec.escaped_name}.tgz"
    to = "docsets/#{@spec.name}/#{latest_version}/publish/#{@spec.name}.tgz"
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

  def redirect_command(from, from_server, to)
    return unless $upload_redirects_for_docsets
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

  def upload_file(file, to)
    return unless $upload_site_to_s3

    upload_command = [
      "s3cmd put",
      "--acl-public",
      "--no-check-md5",
      " --human-readable-sizes --reduced-redundancy",
      "#{file} s3://#{ $s3_bucket }/#{to}"
    ]

    command upload_command.join(' ')
  end
end
