class DocsetFixer
  attr_accessor :docset_path
  
  def fix
    fix_images
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
end