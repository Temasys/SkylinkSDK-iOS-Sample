//
//  TEMPresenceNavigationController.m
//  TEM
//
//  Created by macbookpro on 02/09/2014.
//  Copyright (c) 2014 Temasys Communications. All rights reserved.
//

#import "TEMPresenceNavigationController.h"

#import "TEMAppDelegate.h"

@interface TEMPresenceNavigationController () {
    BOOL firstTime;
}

@end

@implementation TEMPresenceNavigationController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (id)initWithRootViewController:(UIViewController *)rootViewController
{
    self = [super initWithRootViewController:rootViewController];
    if (self) {
        // Custom initialization
        firstTime = TRUE;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (firstTime) {
        self.minimize = YES;
        firstTime = FALSE;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - properties

- (void)setMinimize:(BOOL)minimize
{
    if (self.minimize != minimize) {
        _minimize = minimize;
        if (self.minimize) {
            self.view.frame = CGRectMake(self.view.frame.origin.x, CGRectGetMaxY(self.view.frame) - CGRectGetMaxY(self.navigationBar.frame), self.view.frame.size.width, self.view.frame.size.height);
        } else {
            self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + CGRectGetMaxY(self.navigationBar.frame) - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
        }
    }
}

#pragma mark - public methods

- (CGFloat)getMinimizedY
{
    return CGRectGetMaxY(self.view.frame) - CGRectGetMaxY(self.navigationBar.frame);
}

- (void)refurbish:(BOOL)minimize
{
    if (minimize) {
        self.view.frame = CGRectMake(self.view.frame.origin.x, CGRectGetMaxY(self.view.frame) - CGRectGetMaxY(self.navigationBar.frame), self.view.frame.size.width, self.view.frame.size.height);
    } else {
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y + CGRectGetMaxY(self.navigationBar.frame) - self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height);
    }
    _minimize = minimize;
}

@end
