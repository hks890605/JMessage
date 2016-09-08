//
//  JSUserInfoViewController.m
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSUserInfoViewController.h"
#import "XMPPFramework.h"
#import "JSAppDelegate.h"

@interface JSUserInfoViewController ()

@end

@implementation JSUserInfoViewController

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

- (XMPPUserCoreDataStorageObject*)currentUserInfo {
    return (XMPPUserCoreDataStorageObject*)self.currentUser;
}

- (void)viewDidUnload {
    [self setNickNameField:nil];
    [self setUserIDField:nil];
    [super viewDidUnload];
}

- (JSAppDelegate*)appDelegate {
    return (JSAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (IBAction)backTo:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return 4;
            break;
        case 1:
            return 2;
            break;
        case 2:
            return 3;
        default:
            break;
    }
    return 0;
}

#define kTableHeaderSize    32

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kTableHeaderSize;
}

//- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    if (section == 0)
//        return @"Personal Information";
//    else if (section == 1)
//        return @"Account";
//    return @"Security";
//}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UITableViewHeaderFooterView* headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"HeaderView"];
    if (headerView == nil) {
        headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:@"HeaderView"];
        CGRect frame = [tableView rectForHeaderInSection:section];
        frame.origin = CGPointZero;
        
//        headerView.backgroundView = [[UIView alloc] initWithFrame:frame];
//        headerView.backgroundView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.7f];
//
//        frame = CGRectInset(frame, 8, 0);
//        frame.origin.y = kTableHeaderSize - 20;
//        frame.size.height = 20;
//        UILabel* label = [[UILabel alloc] initWithFrame:frame];
//        label.backgroundColor = [UIColor clearColor];
//        label.textColor = [UIColor darkGrayColor];
//        label.font = [UIFont systemFontOfSize:14];
//        [headerView addSubview:label];
//        label.tag = 1124;
    }
    
    UILabel* label = headerView.textLabel;// (UILabel*)[headerView viewWithTag:1124];
    if (section == 0)
        label.text = @"Personal Information";
    else if (section == 1)
        label.text = @"Account";
    else
        label.text = @"Security";
    
    return headerView;
}

////테이블뷰의 아래부분의 빈 쎌들에 대하여 separator들이 보이지 않게 한다.
//- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
//    return 0.6;
//}
//
//- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
//    UIView* view = [UIView new];
//    view.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
//    return view;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 3)
        return 104;
    return 44;
}

- (NSDictionary*)currentUserStatusInfo {
    XMPPUserCoreDataStorageObject* user = self.currentUserInfo;
    NSDictionary* statusInfo = nil;
    if (user.primaryResource == nil) {
        statusInfo = [AppInfo statusArray][4];
    } else {
        switch (user.section) {
            case 0://chat
                statusInfo = [AppInfo statusArray][0];
                break;
            case 1://dnd - do not disturb
                statusInfo = [AppInfo statusArray][2];
                break;
            case 2://away
                statusInfo = [AppInfo statusArray][1];
                break;
            case 3://xa (extended away
                statusInfo = [AppInfo statusArray][3];
                break;
            case 4://unavailable
            default:
                statusInfo = [AppInfo statusArray][4];
                break;
        }
    }
    return statusInfo;
}

- (UIImage*)currentUserAvatar {
    XMPPUserCoreDataStorageObject* user = self.currentUserInfo;

    UIImage* image = nil;
	if (user.photo != nil) {
		image = user.photo;
	} else {
		NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];
        
		if (photoData != nil)
			image = [UIImage imageWithData:photoData];
		else
			image = [UIImage imageNamed:@"defaultPerson"];
	}
    return image;
}

- (NSLayoutConstraint*)widthConstraint:(UIView*)theView {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"firstAttribute=%d", NSLayoutAttributeWidth];
    NSArray* layouts = [theView.constraints filteredArrayUsingPredicate:predicate];
    if (layouts.count > 0)
        return layouts[0];
    return nil;
}

- (void)configurCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    XMPPUserCoreDataStorageObject* user = self.currentUserInfo;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Name";
                cell.detailTextLabel.text = user.nickname;
                break;
            case 1:
            {
                cell.textLabel.text = @"Status";
                UIButton* button = (UIButton*)[cell viewWithTag:1125];
                if (button) {
                    NSDictionary* statusInfo = [self currentUserStatusInfo];
                    [button setImage:[UIImage imageNamed:statusInfo[kImageNameKey]] forState:UIControlStateNormal];
                    [button setTitle:statusInfo[kTitleKey] forState:UIControlStateNormal];
                    
                    CGSize size = [button sizeThatFits:CGSizeMake(999, 999)];
                    NSLayoutConstraint* widths = [self widthConstraint:button];
                    if (widths)
                        widths.constant = size.width + [button imageRectForContentRect:button.bounds].size.width - 4;
                }
            }
                break;
            case 2:
                cell.textLabel.text = @"Mobile";
                cell.detailTextLabel.text = user.jid.user;
                break;
            case 3:
            {
                cell.textLabel.text = @"Photo";
                UIImageView* avatarView = (UIImageView*)[cell viewWithTag:1124];
                if (avatarView) {
                    avatarView.layer.cornerRadius = 6.f;
                    avatarView.layer.masksToBounds = YES;
                    avatarView.image = [self currentUserAvatar];
                }
            }
                break;
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            cell.textLabel.text = @"Username";
            cell.detailTextLabel.text = user.jidStr;
        } else {
            cell.textLabel.text = @"Password";
            cell.detailTextLabel.text = @"";
        }
    } else if (indexPath.section == 2) {
        cell.detailTextLabel.text = @"";
        if (indexPath.row == 0) {
            cell.textLabel.text = @"One Time Password";
        } else if (indexPath.row == 1) {
            cell.textLabel.text = @"Public Key";
        } else {
            cell.textLabel.text = @"Private Key";
        }
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString* cellID = @"UserInfoCellID1";
    if (indexPath.section == 0) {
        if (indexPath.row == 1)
            cellID = @"UserInfoCellID3";
        else if (indexPath.row == 3)
            cellID = @"UserInfoCellID2";
    }
    
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    }
    
    [self configurCell:cell atIndexPath:indexPath];
    
    return cell;
}

@end
