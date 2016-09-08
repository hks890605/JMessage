//
//  JSSplashViewController.m
//  JMessage
//
//  Created by lion1 on 2/20/14.
//  Copyright (c) 2014 SM. All rights reserved.
//

#import "JSSplashViewController.h"

@interface JSSplashViewController ()

@end

@implementation JSSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self performSelector:@selector(startMain:) withObject:nil afterDelay:2.f];
}

- (void)startMain:(id)sender {
    [self performSegueWithIdentifier:@"SegueID_ToStart" sender:self];
}

@end
