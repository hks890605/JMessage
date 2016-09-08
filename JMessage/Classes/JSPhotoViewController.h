//
//  JSPhotoViewController.h
//  JMessage
//
//  Created by Starlet on 12/6/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JSPhotoViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIImageView* imageView;

- (void)setCurrentPhoto:(UIImage*)image path:(NSString*)imagePath;
- (IBAction)gotoBack:(id)sender;

- (IBAction)doShareAction:(id)sender;
@end
