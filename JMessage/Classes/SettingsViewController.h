//
//  SettingsViewController.h
//  iPhoneXMPP
//
//  Created by Eric Chamberlain on 3/18/11.
//  Copyright 2011 RF.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface SettingsViewController : UITableViewController <UIPopoverControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, UINavigationControllerDelegate, UITextFieldDelegate>

- (void)setStatusWithInfo:(NSDictionary*)item;

- (IBAction)hideKeyboard:(id)sender;

- (IBAction)selectDone:(id)sender;
- (IBAction)selectLogin:(id)sender;
- (IBAction)selectState:(id)sender;
- (IBAction)selectAvatar:(id)sender;
@end
