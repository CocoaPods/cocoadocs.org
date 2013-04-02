class DocsetFixer
  attr_accessor :docset_path
  attr_accessor :readme_path
  
  def fix
#    fix_images
    move_gfm_readme_in
    remove_html_folder
  end
  
  
  
  def fix_images
    # !<a href="https://raw.github.com/zhigang1992/ZGParallelView/master/ScreenShotA.png">img</a>
    # to <img src="https://raw.github.com/zhigang1992/ZGParallelView/master/ScreenShotA.png">
    
    # thanks @benoitcorda !
    ['html/index.html', 'docset/Contents/Resources/Documents/index.html'].each do |path|
      sed_command = 's/.*!<a href="\([^"]*\)".*$/<img src="\1">/g'
      command `sed -i '' '#{sed_command}' '#{ @docset_path + path }'`
    end
  end
  
  def remove_html_folder
    # the structure is normally /POD/version/html/index.html
    # make it /POD/version/index.html
    
    `cp -Rf #{@docset_path}/html/* #{@docset_path}/`
    `rm -Rf #{@docset_path}/html`
    
  end
  
  def move_gfm_readme_in
    return unless File.exists? @readme_path
    
    readme = File.read @readme_path

    ['html/index.html', 'docset/Contents/Resources/Documents/index.html'].each do |path|      
      html = File.open(@docset_path + path).read
      html.sub!("</THISISTOBEREMOVED>", readme)
      File.open(@docset_path + path, 'w') { |f| f.write(html) }
    end 
  end
end