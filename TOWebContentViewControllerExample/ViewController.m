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
    webContentController.setsTitleFromContent = YES;

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webContentController];
    navigationController.navigationBar.barStyle = UIBarStyleBlack;
    navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    navigationController.view.tintColor = [UIColor colorWithRed:91.0f/255.0f green:158.0f/255.0f blue:1.0f alpha:1.0f];
    [self presentViewController:navigationController animated:YES completion:nil];

    webContentController.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(webContentViewControllerDone:)];
}

- (IBAction)webContentViewControllerDone:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
