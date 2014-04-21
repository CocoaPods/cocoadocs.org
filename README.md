## CocoaDocs 2.0.0

CocoaDocs was originally a single ruby file that could either run a sinatra server or document something. CocoaDocs2 is a split of the server and the documentation tool. The tool itself will be a [CocoaPods plugin for AppleDoc](https://github.com/CocoaPods/cocoapods-appledoc). CocoaDocs2 is a Rails 4 app that acts as a conduit for webhook requests and a dashboard for providing an overview on the queuing situtation showing errors etc, and providing some feedback.

Everyone will get read access for logs etc, but if you want to deploy docsets etc you need to be a part of the CocoaPods team on Github.

## Getting Started

`git clone https://github.com/orta/CocoaDocs2`
`bundle install`
`foreman start`
