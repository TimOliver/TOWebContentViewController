//
//  TOWebContentViewController.h
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 14/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOWebContentViewController : UIViewController

/** The WKWebView used to display the HTML content*/
@property (nonatomic, strong, readonly) WKWebView *webView;

/** The URL of the content currently being displayed. Can be a file URL, or an online one. */
@property (nonatomic, strong, readonly) NSURL *URL;

/** For local URLs, this is the folder that is used for relative file path references in the HTML code. */
@property (nonatomic, strong, readonly) NSURL *baseURL;

- (instancetype)initWithURL:(NSURL *)URL;
- (instancetype)initWithFileURL:(NSURL *)fileURL baseURL:(NSURL *)baseURL;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
