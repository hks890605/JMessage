//
//  SettingsViewController.m
//  iPhoneXMPP
//
//  Created by Eric Chamberlain on 3/18/11.
//  Copyright 2011 RF.com. All rights reserved.
//

#import "SettingsViewController.h"
#import "AppInfo.h"
#import "JSAppDelegate.h"
#import "JSStausSelectViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import "UIImage+Starlet.h"
#import "XMPPvCardTemp.h"
#import "XMPPRoster.h"
#import "XMPPPresence+XEP_0172.h"

@interface SettingsViewController ()
@property (strong, nonatomic) NSDictionary* selectedStatus;
@property (strong, nonatomic) UIImage*      avatarImage;
@property (strong, nonatomic) NSString*     nickName;
@property (strong, nonatomic) NSString*     userName;
@property (strong, nonatomic) NSString*     userPassword;
@end

@implementation SettingsViewController

- (XMPPRosterCoreDataStorage*)xmppRosterStorage {
    return [self appDelegate].xmppRosterStorage;
}

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [[self xmppRosterStorage] mainThreadManagedObjectContext];
}

- (void)viewDidLoad {
    [super viewDidLoad];
 
    NSString* jidValue = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
    NSString* passwordValue = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    if (jidValue.length > 0)
        self.userName = jidValue;
    if (passwordValue.length > 0)
        self.userPassword = passwordValue;
    
    NSArray* statusItems = [AppInfo statusArray];
    
    XMPPPresence* myPresence = [self xmppStream].myPresence;
    if ([myPresence.type isEqualToString:@"unavailable"]) {
        [self setStatusWithInfo:statusItems[4]];
    } else {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"%K like %@", kStatusKey, myPresence.show];
        NSArray* array = [statusItems filteredArrayUsingPredicate:predicate];
        if (array.count > 0) {
            [self setStatusWithInfo:array[0]];
        } else {
            self.selectedStatus = [AppInfo statusArray][0];
        }
    }
    
    XMPPJID* myJID = [[self xmppStream] myJID];
    NSData* avatarData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:myJID];
    if (avatarData) {
        self.avatarImage = [UIImage imageWithData:avatarData];
    }
    
    self.nickName = [self xmppStream].myPresence.nick;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Init/dealloc methods
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)awakeFromNib {
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View lifecycle
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setField:(NSString *)username forKey:(NSString *)key
{
    if (username != nil)
    {
        [[NSUserDefaults standardUserDefaults] setObject:username forKey:key];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)hideKeyboard:(id)sender {
  [sender resignFirstResponder];
}

- (IBAction)selectDone:(id)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)selectLogin:(id)sender {
    [self.tableView endEditing:YES];
    
    if (self.userName.length < 1) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:@"Please input User ID." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
        [alert show];
        return;
    }
    [self setField:self.userName forKey:kXMPPmyJID];
    [self setField:self.userPassword forKey:kXMPPmyPassword];

    [[self appDelegate] disconnect];
	[[[self appDelegate] xmppvCardTempModule] removeDelegate:self];

    [[self appDelegate] connect];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
    
    __block SettingsViewController* dp = self;
    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [dp setAvatarPhoto:dp.avatarImage];
    });
}

- (JSAppDelegate *)appDelegate {
	return (JSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream {
	return [[self appDelegate] xmppStream];
}

- (IBAction)selectState:(id)sender {
//    self.tablePopupController.selectedItem = @"";
//    self.currentPopoverController.popoverContentSize = [self.tablePopupController contentSize];
//
//    CGRect frame = ((UIButton*)sender).bounds;
//    [self.currentPopoverController presentPopoverFromRect:frame inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)selectAvatar:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil  destructiveButtonTitle:@"Take from Album" otherButtonTitles:@"Take a Photo", @"Cancel", nil];
    CGRect frame = ((UIView*)sender).frame;
    frame.origin.x = CGRectGetMidX(frame);
    frame.origin.y = CGRectGetMidY(frame);
    
    [sheet showFromRect:frame inView:(UIView*)sender animated:YES];
}

- (void)setStatusWithInfo:(NSDictionary*)item {
    if (item) {
        self.selectedStatus = item;
//        [self.statusButton setImage:[UIImage imageNamed:item[kImageNameKey]] forState:UIControlStateNormal];
//        [self.statusButton setTitle:item[kTitleKey] forState:UIControlStateNormal];
        [self.tableView reloadData];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueID_ToStatus"]) {
        JSStausSelectViewController* controller = segue.destinationViewController;
        controller.selectedItem = self.selectedStatus;
    }
}

#pragma mark - image picker

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
            imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            imagePicker.delegate = self;
            imagePicker.allowsEditing = YES;
            
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                UIPopoverController* popoverController = [[UIPopoverController alloc] initWithContentViewController:imagePicker];
                popoverController.delegate = self;
                
                CGRect frame = self.tableView.bounds;
                [popoverController presentPopoverFromRect:frame inView:self.tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
            } else {
                [self presentViewController:imagePicker animated:YES completion:nil];
            }
        }
    } else if (buttonIndex == 1) {//camera
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            double delayInSeconds = .3f;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
                imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                imagePicker.delegate = self;
                imagePicker.allowsEditing = YES;
                
                imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
                [self presentViewController:imagePicker animated:YES completion:nil];
            });
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Camera Error" message:@"No Camera." delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
            [alert show];
        }
    } else if (buttonIndex == 2) {//cancel
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    if ([[info objectForKey:UIImagePickerControllerMediaType] isEqualToString:(NSString*)kUTTypeImage]) {
        NSURL *url = [info objectForKey:UIImagePickerControllerMediaURL];
        UIImage *image = nil;
        if (url.isFileURL)
            image = [[UIImage alloc] initWithContentsOfFile:url.path];
        if (image == nil) {
            image = [info objectForKey:UIImagePickerControllerEditedImage];
            if (image == nil)
                image = [info objectForKey:UIImagePickerControllerOriginalImage];
        }
        
        if (image != nil) {
            image = [image resizeImageWithSize:CGSizeMake(120, 120)];
            self.avatarImage = image;
            [self setAvatarPhoto:image];
            [self.tableView reloadData];
        }
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setAvatarPhoto:(UIImage*)image {// forUserWithJID:(XMPPJID *)jid xmppStream:(XMPPStream *)stream {
    if (image == nil || ![self xmppStream].isConnected)
        return;
    
    NSData* data = UIImagePNGRepresentation(image);

    NSXMLElement* vCardXML = [NSXMLElement elementWithName:@"vCard" xmlns:@"vcard-temp"];
    NSXMLElement* photoXML = [NSXMLElement elementWithName:@"PHOTO"];
    NSXMLElement* typeXML = [NSXMLElement elementWithName:@"TYPE" stringValue:@"image/png"];
    
    NSXMLElement* binvalXML = [NSXMLElement elementWithName:@"BINVAL" stringValue:[data base64Encoding]];
    [photoXML addChild:typeXML];
    [photoXML addChild:binvalXML];
    [vCardXML addChild:photoXML];
    
    XMPPvCardTemp* myvCardTemp = [[[self appDelegate] xmppvCardTempModule] myvCardTemp];
    if (myvCardTemp) {
        [myvCardTemp setPhoto:data];
        [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp:myvCardTemp];
    } else {
        XMPPvCardTemp* newvCardTemp = [XMPPvCardTemp vCardTempFromElement:vCardXML];
        [[[self appDelegate] xmppvCardTempModule] updateMyvCardTemp:newvCardTemp];
    }
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

- (NSLayoutConstraint*)widthConstraint:(UIView*)theView {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"firstAttribute=%d", NSLayoutAttributeWidth];
    NSArray* layouts = [theView.constraints filteredArrayUsingPredicate:predicate];
    if (layouts.count > 0)
        return layouts[0];
    return nil;
}

- (UITextField*)textFieldInCell:(UITableViewCell*)cell {
    UITextField* field = (UITextField*)[cell viewWithTag:1126];
    if (field) {
        field.userInteractionEnabled = YES;
        field.secureTextEntry = NO;
    }
    return field;
}

- (UILabel*)titleLabelInCell:(UITableViewCell*)cell {
    return (UILabel*)[cell viewWithTag:1127];
}

- (void)configurCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath {
    XMPPJID* myJID = [self xmppStream].myJID;
    
    if (indexPath.section == 0) {
        switch (indexPath.row) {
            case 0:
            {
                [self titleLabelInCell:cell].text = @"Name";
                UITextField* textField = [self textFieldInCell:cell];
                if (textField) {
                    textField.text = self.nickName;
                    textField.userInteractionEnabled = NO;
                }
            }
                break;
            case 1:
            {
                [self titleLabelInCell:cell].text = @"Status";
                UIButton* button = (UIButton*)[cell viewWithTag:1125];
                if (button) {
                    NSDictionary* statusInfo = self.selectedStatus;
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
            {
                [self titleLabelInCell:cell].text = @"Mobile";
                UITextField* textField = [self textFieldInCell:cell];
                if (textField) {
                    textField.userInteractionEnabled = NO;
                    textField.text = myJID.user;
                }
            }
                break;
            case 3:
            {
                [self titleLabelInCell:cell].text = @"Photo";
                UIImageView* avatarView = (UIImageView*)[cell viewWithTag:1124];
                if (avatarView) {
                    avatarView.layer.cornerRadius = 6.f;
                    avatarView.layer.masksToBounds = YES;
                    if (self.avatarImage)
                        avatarView.image = self.avatarImage;
                    else
                        avatarView.image = [UIImage imageNamed:@"defaultPerson"];
                }
            }
                break;
            default:
                break;
        }
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0) {
            [self titleLabelInCell:cell].text = @"Username";
            UITextField* textField = [self textFieldInCell:cell];
            if (textField) {
                if (self.userName.isNotEmpty) {
                    textField.text = self.userName;
                } else {
                    textField.text = @"61419223555@im.sopranodesign.com";
                    self.userName = @"61419223555@im.sopranodesign.com";
                }
            }
        } else {
            [self titleLabelInCell:cell].text = @"Password";
            UITextField* textField = [self textFieldInCell:cell];
            if (textField) {
                textField.secureTextEntry = YES;
                textField.text = self.userPassword;
            }
        }
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            UILabel* label = [self titleLabelInCell:cell];
            label.text = @"One Time Password";
            //[label sizeToFit];
        } else if (indexPath.row == 1) {
            [self titleLabelInCell:cell].text = @"Public Key";
        } else {
            [self titleLabelInCell:cell].text = @"Private Key";
        }
        UITextField* textField = [self textFieldInCell:cell];
        if (textField) {
            textField.userInteractionEnabled = NO;
            textField.text = @"";
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0) {
        if (indexPath.row == 1) { //status
            [self performSegueWithIdentifier:@"SegueID_ToStatus" sender:nil];
        } else if (indexPath.row == 3) {//image
            [self selectAvatar:cell];
        }
    }
}

#pragma mark -

- (UITableViewCell*)superTableCellInTextField:(UITextField*)textField {
    UITableViewCell* cell = nil;
    UIView* superView = textField.superview;
    while (superView != nil) {
        if ([superView isKindOfClass:UITableViewCell.class]) {
            cell = (UITableViewCell*)superView;
            break;
        }
        superView = superView.superview;
    }
    return cell;
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    UITableViewCell* cell = [self superTableCellInTextField:textField];
    NSIndexPath* indexPath = [self.tableView indexPathForCell:cell];
    
    if (indexPath.section == 0) {
        if (indexPath.row == 0)
            self.nickName = textField.text;
    } else if (indexPath.section == 1) {
        if (indexPath.row == 0)
            self.userName = textField.text;
        else
            self.userPassword = textField.text;
    }
    
    return YES;
}


@end
