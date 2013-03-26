class DocsetFixer
  attr_accessor :docset_path
  
  def fix
    fix_images
  end
  
  def fix_images
    # !<a href="https://raw.github.com/zhigang1992/ZGParallelView/master/ScreenShotA.png">img</a>
    # to <img src="https://raw.github.com/zhigang1992/ZGParallelView/master/ScreenShotA.png">
    
    # thanks @benoitcorda !
    ['html/index.html', 'docset/Contents/Resources/Documents/index.html'].each do |path|
#      puts 'sed 's/.*!<a href="\([^"]*\)".*$/<img src="\1">/g' -i ' + @docset_path + path 
      sed_command = 's/.*!<a href="\([^"]*\)".*$/<img src="\1">/g'

      command `sed -i '' '#{sed_command}' '#{ @docset_path + path }'`
    end
  end
  
end