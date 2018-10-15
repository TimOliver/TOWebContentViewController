//
//  TOWebContentView.m
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 16/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import "TOWebContentView.h"

@interface TOWebContentView ()

@property (nonatomic, assign, readwrite) CGPoint lastTappedPoint;

@end

@implementation TOWebContentView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    self.lastTappedPoint = [touches.anyObject locationInView:self];
}

@end
