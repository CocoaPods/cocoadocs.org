### Are you making an issue for CocoaDocs the service? 

Then delete this template

### Are you here to write a "my pod CHANGELOG/README" isn't updating on https://cocoapods.org/pod/[MyPod]?

Try trigger a redeploy of your pod's cocoapods metadata by running:

```sh
curl http://199.19.84.242:4567/redeploy/[My Pod]/latest
```

If it doesn't say `{"parsing":true}` - raise an issue, if it does - give it 5-10 minutes to download your pod and generate the docs, then double check. If that doesn't do work, raise an issue.

### Are you here to write a "my pod XXX" isn't showing on CocoaDocs?

Here's some first steps:

* First up, load up the expected URL in CocoaDocs. The URL will look like [http://cocoadocs.org/docsets/[pod]/](http://cocoadocs.org/docsets/SCConfiguration/) if you get a 404 then that means CocoaDocs could not parse your library. 
  As a rule of thumb, CocoaDocs is stable and works. 
  
* The most common problem with generating documentation is that your library crashes either [appledoc](http://appledoc.gentlebytes.com/appledoc/) or [jazzy](https://github.com/realm/jazzy). This tends to happen when you use bleeding edge features in betas of Xcode. However, sometimes it can "just happen" generating all this documentation is a complex process, as most swift libs need to be compiled and Xcode it a tough dependency to have.

* The 404 page on CocoaDocs.org offers a button to request that CocoaDocs takes a second look at running your library, the URL for this is [http://api.cocoadocs.org:4567/redeploy/[pod]/latest](nope://hah)
  
* CocoaDocs also offer a way to see errors from CocoaDocs related to a pod. The URL for this [http://api.cocoadocs.org:4567/error/[Podname]/[Version]](http://api.cocoadocs.org:4567/error/SCConfiguration/1.0.0). You'll get a 404 if there's no logged errors.
  
* You can find out a bit more about CocoaDocs in the [Pod Authors README](http://cocoadocs.org/readme/).

If all of this fails, check for existing issues: https://github.com/CocoaPods/cocoadocs.org/issues?utf8=✓&q=is%3Aissue%20docs%20
Finally, if there's nothing specific to your problem, delete this template and start your issue. :+1:
