//
//  ContentViewController.m
//  TouchIDLogin
//
//  Created by Pablo Caif on 20/04/2015.
//  Copyright (c) 2015 Pablo Caif. All rights reserved.
//

#import "ContentViewController.h"

@interface ContentViewController ()

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@end

@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSURL *url = [NSURL URLWithString:@"https://YourServer:8080/"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
   
}


@end
