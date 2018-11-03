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

It is not meant to be an  web browser, but more to display specific information inside the app, where spending the resources to implement an equivalent native UI wouldn't be worth it.

This makes the library perfect for things like displaying privacy policies, open source acknowledgements, or even just an 'About' page.

The view controller also features several extra niceties, such as being able to dynamically pre-set the background color, and using the [[mustache]](https://mustache.github.io/) templating system to dynamically inject information.

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

## Examples

For on disk content, it is recommended you put all of your HTML/CSS in one folder and import it into Xcode as a 'Group Reference' (ie, so it uses a blue icon in the Xcode navigator) ([Screenshot](https://raw.githubusercontent.com/TimOliver/TOWebContentViewController/master/xcode-import.jpg))

