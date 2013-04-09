class DocsetFixer
  include HashInit
  attr_accessor :docset_path, :readme_path
  
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
end