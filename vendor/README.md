## Vendored

#### Appledoc
We vendor Appledoc, this is so that we can ensure this tool is consistently the same between all versions. We should think about doing the same for `cloc` too.

#### Headliner
This is a Mac app I built to generate thumbnails for twitter / facebook on a pod. Code is dead simple, it runs like so:

```
Headliner.app/Contents/MacOS/Headliner "Pod Name" "Pod description of something" "podfile 'sdsd' , '~> 0.2'" "Tested" "Doc'd" "MIT" "Objective-C" /tmp/img.png
```

You will need to have GT Walsheim on the server to do this correctly.