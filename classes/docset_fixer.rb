class DocsetGenerator
  attr_accessor :docset_path
  
  def fix
    fix_images
  end
  
  def fix_images
    # !<a href="https://raw.github.com/zhigang1992/ZGParallelView/master/ScreenShotA.png">img</a>
    # to <img src="https://raw.github.com/zhigang1992/ZGParallelView/master/ScreenShotA.png">
    
    
    
  end
  
end