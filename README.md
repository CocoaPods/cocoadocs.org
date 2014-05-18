## CocoaDocs.org

CocoaDocs is essentially 2 tools, one is a script for generating complex appledoc templates and the other is a server aspect for reacting to webhook notifications.

### How it works for the 99% use cases:

CocoaDocs receives webhook notifications from the [CocoaPods/Specs](https://github.com/CocoaPods/Specs) repo on GitHub whenever a CocoaPod is updated. 

This triggers a process that will generate documentation for _objective-c_ projects via [appledoc](http://gentlebytes.com/appledoc/) and host them for the community. This process can take around 15 minutes after your Podspec is published via trunk. 

At the minute 404 errors are likely to occur at our end due to work on trying to move to a queuing system. Presuming your library is made out of objc.

##### What control do I have over CocoaDocs as a library author?

 - You have the ability to edit the styling of CocoaDocs for your own libraries to give some personal branding. This is done by adding a `.cocoadocs.yml` file to the root of your library, which overwrite these properties:   
   ``` yaml
   highlight-font: '"GT Walsheim", "gt_walsheim_regular", "Avant Garde Gothic ITCW01Dm", "Avant Garde", "Helvetica Neue", "Arial"'

   body: '"Helvetica Neue", "Arial", san-serif'
   code: '"Monaco", "Menlo", "Consolas", "Courier New", monospace'

   highlight-color: '#ED0015'
   highlight-dark-color: '#A90010'

   darker-color: '#C6B7B2'
   darker-dark-color: '#A8A8A8'

   background-color: '#F2F2F2'
   alt-link-color: '#B7233F'
   warning-color: '#B80E3D'
   ```
   
   All defaults are stored in this config file for you to overwite.
   
 -  If you host your own documentation, and/or just prefer to not use CocoaDocs you can use the [documentation_url](http://guides.cocoapods.org/syntax/podspec.html#documentation_url) reference in your Podspec.

##### Common use cases:

First, clone this repo: `git clone https://github.com/CocoaPods/cocoadocs.org` then run `bundle install` you will need a working copy of [appledoc](http://gentlebytes.com/appledoc) ( which you can get a binary version from their github releases page as compiling doesn't work in Xcode 5.1+. )

I want to preview my WIP library: `./cocoadocs preview [path_to_repo]` - this will generate a preview in `cocoadocs.org/activity/docsets/lib_name/index.html`. For speed you can run this with `--skip-fetch --skip-readme-download --skip-source-download` after the first sucessful build.

##### CocoaDocs admin use cases:

You'll need to have a working copy of `s3cmd` installed, likely with `brew install`. 

- Starting the webhook server is as simple as running `./server.rb`
- Creating a doc and uploading to S3 for the most recent version of a pod: `./cocoadocs cocoadocs doc [pod_name or path_to_podspec]`
- Reparsing & uploading _x_ amount of days worth of CocoaPods: `./cocoadocs cocoadocs days [days]`