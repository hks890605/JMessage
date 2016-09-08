//
//  JSUserInfoViewController.h
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JSUserInfoViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView*   tableView;

@property (strong, nonatomic) IBOutlet UILabel *nickNameField;
@property (strong, nonatomic) IBOutlet UILabel *userIDField;
@property (nonatomic,retain) id currentUser;
@property (weak, nonatomic) IBOutlet UILabel *mobileNumberField;
@property (weak, nonatomic) IBOutlet UIImageView *avatarImageView;

- (IBAction)backTo:(id)sender;

@end
