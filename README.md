# TOWebContentViewController

<p align="center">
<img src="https://raw.githubusercontent.com/TimOliver/TOWebContentViewController/master/screenshot.jpg" width="500" style="margin:0 auto" />
</p>

[![CocoaPods](https://img.shields.io/cocoapods/dt/TOWebContentViewController.svg?maxAge=3600)](https://cocoapods.org/pods/TOWebContentViewController)
[![Version](https://img.shields.io/cocoapods/v/TOWebContentViewController.svg?style=flat)](http://cocoadocs.org/docsets/TOCropViewController)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/TimOliver/TOWebContentViewController/master/LICENSE)
[![Platform](https://img.shields.io/cocoapods/p/TONavigationBar.svg?style=flat)](http://cocoadocs.org/docsets/TOWebContentViewController)
[![Beerpay](https://beerpay.io/TimOliver/TOWebContentViewController/badge.svg?style=flat)](https://beerpay.io/TimOliver/TOWebContentViewController)
[![PayPal](https://img.shields.io/badge/paypal-donate-blue.svg)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M4RKULAVKV7K8)


`TOWebContentViewController` is a class built to allow fast presentation of HTML, either from a local file or online. 

It is not meant to be a web browser, but more to display specific information inside the app, where spending the resources to implement an equivalent native UI wouldn't be worth it. For example, displaying a privacy policy, or a list of open-source acknowledgements.

The view controller also features several extra niceties, such as being able to dynamically pre-set the background color, and using the [mustache](https://mustache.github.io/) templating system to dynamically inject information.

## Features

* Uses `WKWebView` to display HTML content and images, either from disk, or from a website.
* Intentionally disallows 'back' or 'forward' navigation in favour of treating the content like a component of the app.
* Tapping links is captured, and can be handled dynamically, or automatically by the view controller.
* For local HTML content, allows the injection of dynamic information from the app (eg, app version, current year etc)
* If present in the HTML, can extract the background color of the HTML content, and set the view controller view background to match while loading.

## System Requirements
iOS 9.0 and above.

## Installation

**As a CocoaPods Dependency**

Add the following to your Podfile:
```
pod 'TOWebContentViewController
```

**Manual Installation**

Copy the folder `TOWebContentViewController` to your Xcode project.

`TOWebContentViewController` is an Objective-C project, but it has been written to work properly in Swift as well. If you are using it in a Swift project, don't forget to include it in your Objective-C bridging header.

## Examples

For on disk content, it is recommended you put all of your HTML/CSS in one folder and import it into Xcode as a 'Group Reference' (ie, so it uses a blue icon in the Xcode navigator) ([Screenshot](https://raw.githubusercontent.com/TimOliver/TOWebContentViewController/master/xcode-import.jpg))

### Hello World Example

```swift
// Get resources folder URL
let resourcesURL = Bundle.main.resourceURL!
let baseURL = resourcesURL.appendingPathComponent("HTML")
let fileURL = baseURL.appendingPathComponent("about.html")

// Create the web content view controller
let webContentController = WebContentViewController(fileURL: fileURL, baseURL: baseURL)

// Present the view controller however way you need.
navigationController.push(webContentViewController, animated: true)
```


### Using the Templating System

If loading a local HTML file, a bare-bones mustache-based templating system has been implemented to allow the injection of dynamic content from your app into the HTML. This is useful for things like showing the current app version or build number, or even more clever things like swapping out CSS files.

To use the templating system, all you need to do is insert template tags into your HTML and then specify what they need to be replaced with.

```swift
let myHTMLString = "<html><body>{{Greeting}}</body></html>"

let vc = WebContentViewController(htmlString: myHTMLString, baseURL: nil)
vc.templateTags = ["Greeting": "Hello World!"]
```

When displayed, `{{Greeting}}` will be replaced with "Hello World!".

You can set your own custom values in `templateTags`, but the view controller also creates several by default:

* `{{AppName}}` - The short name of the app from the main bundle (e.g. 'iComics')
* `{{AppVersion}}` - The version number of this build of the app (e.g. '1.4')
* `{{AppBuildNumber}}` - The build number of this version of the app (e.g. '1432')
* `{{AppCurrentYear}}` - The current year according to the device (e.g. '2018')

### Setting the Background Color
Before the web view has had a chance to load, you can dynamically set the background of the view controller to be the same color as the web content, so the appearance will look more native with the rest of the app.

To automatically set the color, place a tag named `data-bgcolor=""` anywhere in your HTML file:

```html
<html>
	<body data-bgcolor="#eeeeee"></body>
</html>
```

Please note that you must use a 6 character hex code in order for this to work.

## Credits
`TOWebContentViewController` was originally created by [Tim Oliver](http://twitter.com/TimOliverAU) as a component for [iComics](http://icomics.co), a comic reader app for iOS.

iOS Device mockups used in the screenshot created by [Pixeden](http://www.pixeden.com).

## License
TOWebContentViewController is licensed under the MIT License, please see the [LICENSE](LICENSE) file. ![analytics](https://ga-beacon.appspot.com/UA-5643664-16/TOWebContentViewController/README.md?pixel)
