Cocoadocs.org
-------

Hello there! Cocoadocs is a Cocoapods sister-project that exists to document every cocoapod. This includes all the different versions so its easy to get older information too. On top of that it provides self updating docsets for Dash & Xcode.

Cocoadocs receives notifications from the [CocoaPods/Specs](https://github.com/CocoaPods/Specs) repo on GitHub whenever a CocoaPod is updated. This triggers a process that will generate documentation for _objective-c_ projects via [appledoc](http://gentlebytes.com/appledoc/) and host them for the community. This process can take around 15 minutes after your Podspec is merged. If you host your own documentation, you can use the [documentation_url](http://guides.cocoapods.org/syntax/podspec.html#documentation_url).


## Notes

CocoaDocs requires a ruby of 1.9+
Compile changes to the appledoc_templates with `ruby assets.rb ; ruby app.rb doc AFNetworking --create-website --dont-delete-source --skip-fetch --skip-source-download --verbose`
