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

@property (nonatomic, readonly) WKWebView *webView;

@end

NS_ASSUME_NONNULL_END
