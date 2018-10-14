//
//  ViewController.m
//  TOWebContentViewControllerExample
//
//  Created by Tim Oliver on 14/10/18.
//  Copyright © 2018 Tim Oliver. All rights reserved.
//

#import "ViewController.h"
#import "TOWebContentViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (IBAction)didTapButton:(id)sender
{
    // Get resources folder URL
    NSURL *resources = [[NSBundle mainBundle] resourceURL];
    NSURL *baseURL = [resources URLByAppendingPathComponent:@"HTML"];
    NSURL *fileURL = [baseURL URLByAppendingPathComponent:@"about.html"];

    TOWebContentViewController *webContentController = [[TOWebContentViewController alloc] initWithFileURL:fileURL baseURL:baseURL];
    [self.navigationController pushViewController:webContentController animated:YES];
}

@end
