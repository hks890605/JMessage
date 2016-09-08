//
//  JSPhotoViewController.m
//  JMessage
//
//  Created by Starlet on 12/6/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSPhotoViewController.h"

@interface JSPhotoViewController ()
@property (nonatomic, strong) NSString* imagePath;
@end

@implementation JSPhotoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        [self view];
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

- (void)setCurrentPhoto:(UIImage*)image path:(NSString*)imagePath {
    if (self.imageView == nil)
        [self view];
    self.imageView.image = image;
    
    self.imagePath = imagePath;
}

- (IBAction)gotoBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doShareAction:(id)sender {
    if (!IS_OveriOS6)
        return;
    
    if (self.imagePath.length < 1)
        return;
    
	NSString *filePath = self.imagePath;
    
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSArray* objectToShare = @[url];
    UIActivityViewController* controller = [[UIActivityViewController alloc] initWithActivityItems:objectToShare applicationActivities:nil];
    
    // Exclude all activities except AirDrop.
    NSArray *excludedActivities = nil;
    if (IS_iOS7) {
        //excludedActivities = @[UIActivityTypePostToTwitter, UIActivityTypePostToFacebook,                                    UIActivityTypePostToWeibo, UIActivityTypeMessage, UIActivityTypeMail, UIActivityTypePrint, UIActivityTypeCopyToPasteboard, UIActivityTypeAssignToContact, UIActivityTypeSaveToCameraRoll, UIActivityTypeAddToReadingList, UIActivityTypePostToFlickr,                                    UIActivityTypePostToVimeo, UIActivityTypePostToTencentWeibo];
    }
    
    controller.excludedActivityTypes = excludedActivities;
    
    [self presentViewController:controller animated:YES completion:nil];
}

@end
