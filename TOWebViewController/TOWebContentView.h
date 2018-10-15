//
//  TOWebContentView.h
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 16/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TOWebContentView : WKWebView
@property (nonatomic, assign, readonly) CGPoint lastTappedPoint;
@end

NS_ASSUME_NONNULL_END
