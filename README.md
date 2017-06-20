## CocoaDocs.org

[![Build Status](http://img.shields.io/travis/CocoaPods/cocoadocs.org/master.svg?style=flat)](https://travis-ci.org/CocoaPods/cocoadocs.org)

CocoaDocs is essentially 2 tools, one is a script for generating complex appledoc templates and the other is a server aspect for reacting to webhook notifications.

### Installation instructions

1. git clone git@github.com:CocoaPods/cocoadocs.org.git
2. cd cocoadocs.org
3. bundle install
4. bundle exec rake install_tools

The `install_tools` tasks will install the additional tools required for cocoadocs to work:

    * [cloc](https://github.com/AlDanial/cloc)
    * [appledoc](https://github.com/tomaz/appledoc)
    * [carthage](https://github.com/Carthage/Carthage)
    * [AWS' official CLI tool](https://aws.amazon.com/cli/)

### How it works for the 99% use cases:

CocoaDocs receives webhook notifications from the [CocoaPods/Specs](https://github.com/CocoaPods/Specs) repo on GitHub whenever a CocoaPod is updated.

A Swift Pod will create documentation [using Jazzy](https://github.com/realm/jazzy/). If this fails, perhaps due to new Swift version support, than it will fall back to Objective-C. An *Objective-C* Pod will use Appledoc to parse your library.  

If you have a Swift library and it's only showing Objective-C classes (or no classes) then Jazzy has crashed on your library, we'd recommend testing that out locally.


##### What control do I have over CocoaDocs as a library author?

 - For Objective-C projects, you have the ability to edit the styling of CocoaDocs for your own libraries to give some personal branding. This is done by adding a `.cocoadocs.yml` file to the root of your library, which overwrite these properties:   
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

 - You can find an example of styling at [ARAnalytics's .cocoadocs.yml](https://github.com/orta/ARAnalytics/blob/master/.cocoadocs.yml)
 - You can change the location of your readme with `readme: path/to/README.md` in your `.cocoadocs.yml`.
 - You can add your own documentation guides, either from remote markdown files or from files locally inside the library. CocoaDocs will automatically convert github wiki pages to the markdown behind it. These only work on Objective-C codebases.

   ```yaml
   additional_guides:
     - https://github.com/magicalpanda/MagicalRecord/wiki/Installation
     - https://github.com/CocoaPods/CocoaPods/wiki/A-pod-specification
     - docs/Getting_started.md
   ```

 -  If you host your own documentation, and/or just prefer to not use CocoaDocs you can use the [documentation_url](https://guides.cocoapods.org/syntax/podspec.html#documentation_url) reference in your Podspec.


##### Previewing my library in CocoaDocs

First, clone this repo: `git clone https://github.com/CocoaPods/cocoadocs.org` then run `bundle install` and then run `bundle exec rake install_tools` to get all pre-requisite apps set up.

To preview your library run:

```
bundle exec ./cocoadocs.rb preview ARAnalytics
```

This will get the _master_ version of your library and run it through CocoaDocs, then open the resulting folder, you can open the `index.html` in a web browser to preview locally.

##### CocoaDocs Admin

The CocoaPods' CocoaDocs server is hosted on [macminicolo.net](http://www.macminicolo.net/) provided by [Button](http://www.usebutton.com/). We use RSA public keys to log in. You'll have to get your `id_rsa.pub` to an existing admin ( currently [orta](/orta) /[segiddins](/segiddins) ) to get access.

SSH access is automated via the `Rakefile`:

* `bundle exec rake deploy` - will log in via SSH, stop the API server, update it and then bring the server back up.

* `bundle exec rake doc["pod_name"]` - will log in via SSH, and run a re-doc for a pod. Similar to the redeploy API, but you can see the logs.

##### Thanks!

The creation of CocoaDocs v2 has been made possible with help from the following:

* [Orta Therox](https://twitter.com/orta) - Design & Code
* [Sam Giddins](https://twitter.com/segiddins) -Admin & Code
* [Kyle Fuller](https://twitter.com/kylefuller) - Admin & Code
* [Delisa Mason](https://twitter.com/kattrali) - Docstat gem
* Clay Allsopp - README Complexity gem
* [Ash Furrow](https://twitter.com/AshFurrow) - Javascript & Ruby assistance
* [Boris Bugling](https://twitter.com/NeoNacho) - Boring legwork on templates
