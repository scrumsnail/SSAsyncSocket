//
//  ViewController.m
//  SSAsyncSocket
//
//  Created by allthings_LuYD on 16/9/26.
//  Copyright © 2016年 scrum_snail. All rights reserved.
//

#import "ViewController.h"
#import "SSAsyncSocket.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[SSAsyncSocket sharedSocket] startConnectSocket];
}


@end
