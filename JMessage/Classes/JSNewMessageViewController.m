//
//  JSNewMessageViewController.m
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSNewMessageViewController.h"
#import "JSAppDelegate.h"
#import "NSString+Utils.h"
#import "JSSearchBar.h"
#import "UIColor+Starlet.h"
#import "SMChatViewController.h"
#import "AppInfo.h"
#import "JSContactsViewController.h"

#import "XMPPFramework.h"

#define kMaxSelectCount 10

@interface JSNewMessageViewController ()
@property (strong, nonatomic) XMPPUserCoreDataStorageObject* currentUser;
@property (strong, nonatomic) NSMutableArray* searchContactList;
@property (nonatomic, readwrite) BOOL keyboardIsShowing;
@property (nonatomic, readwrite) CGFloat keyboardShowHeight;

@end

@implementation JSNewMessageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (JSAppDelegate *)appDelegate {
	return (JSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream {
	return [[self appDelegate] xmppStream];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.navigationItem.hidesBackButton = YES;
    
    self.tablePopupController = [[PopupTableController alloc] initWithStyle:UITableViewStylePlain];
    self.tablePopupController.popupDelegate = self;
    self.tablePopupController.selectedItem = @"";
    self.currentUser = nil;
    
    self.currentPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.tablePopupController];
    self.currentPopoverController.delegate = self;
    
    self.searchContactList = [NSMutableArray new];
//    [self.searchDisplayController.searchBar setBackgroundImage:[UIImage imageNamed:@"titlebar.png"]];
//    self.searchDisplayController.searchBar.tintColor = [UIColor whiteLightGrayColor];
    
//    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTitleTextAttributes:
//     [NSDictionary dictionaryWithObjectsAndKeys:
//      [UIFont systemFontOfSize:16], UITextAttributeFont,
//      [UIColor blueColor], UITextAttributeTextColor,
//      [UIColor clearColor], UITextAttributeTextShadowColor,
//      UIOffsetMake(0, 0), UITextAttributeTextShadowOffset,
//      nil]
//                                                                                        forState:UIControlStateNormal];

	[self.tokenFieldView.tokenField setDelegate:self];
	[self.tokenFieldView setShouldSearchInBackground:NO];
	[self.tokenFieldView setShouldSortResults:NO];
//	[self.tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldFrameDidChange:) forControlEvents:TITokenFieldControlEventFrameDidChange];
	[self.tokenFieldView.tokenField setTokenizingCharacters:[NSCharacterSet characterSetWithCharactersInString:@",;."]]; // Default is a comma
    [self.tokenFieldView.tokenField setPromptText:@"To:"];
	[self.tokenFieldView.tokenField setPlaceholder:@"Type a name"];
	
	UIButton * addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
	[addButton addTarget:self action:@selector(showContactsPicker:) forControlEvents:UIControlEventTouchUpInside];
	[self.tokenFieldView.tokenField setRightView:addButton];
	[self.tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidBegin];
	[self.tokenFieldView.tokenField addTarget:self action:@selector(tokenFieldChangedEditing:) forControlEvents:UIControlEventEditingDidEnd];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)addChatNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)removeChatNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addChatNotification];
    
//    self.navigationItem.rightBarButtonItem = nil;
    
    [self.messageInputView clearContents];

    // You can call this on either the view on the field.
	// They both do the same thing.
	[self.tokenFieldView becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self removeChatNotification];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // You can call this on either the view on the field.
	// They both do the same thing.
	[self.tokenFieldView becomeFirstResponder];
}

- (IBAction)backTo:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)clickToField:(id)sender {
    self.tablePopupController.selectedItem = self.currentUser;
    self.tablePopupController.itemsForDisplay = self.userArray;
//    self.currentPopoverController.popoverContentSize = [self.tablePopupController contentSize];
    CGRect frame = ((UIButton*)sender).bounds;
    [self.currentPopoverController presentPopoverFromRect:frame inView:sender permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)sendText:(id)sender {
    NSArray* selectedUsers = self.tokenFieldView.tokenField.tokenObjects;
    if (selectedUsers.count < 1) {
        [UIAlertView showMessage:@"Input user."];
        return;
    }
    
    if (!self.messageInputView.inputValue.isNotEmpty) {
        [UIAlertView showMessage:@"Input message."];
        return;
    }
    
    [self.view endEditing:YES];
	
    NSString *messageStr = self.messageInputView.inputValue;
    if([messageStr length] > 0) {
        XMPPUserCoreDataStorageObject* lastUser = nil;
        for (XMPPUserCoreDataStorageObject* chatUser in selectedUsers) {
            if (![chatUser isKindOfClass:XMPPUserCoreDataStorageObject.class])
                return;

            NSString *chatUserID = chatUser.jidStr;
            NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
            [body setStringValue:messageStr];
            
            NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
            [message addAttributeWithName:@"type" stringValue:@"chat"];
            [message addAttributeWithName:@"to" stringValue:chatUserID];
            [message addChild:body];
            
            [self.xmppStream sendElement:message];
            
            lastUser = chatUser;
        }
        [self.messageInputView setInputValue:@""];
        
        if (selectedUsers.count == 1 && lastUser) {
            self.currentUser = lastUser;
            [self performSegueWithIdentifier:@"SegueID_ToChat" sender:self];
        } else {
            [self backTo:nil];
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueID_ToChat"]) {
        SMChatViewController* controller = segue.destinationViewController;
        if (controller && self.currentUser) {
            controller.chatUser = self.currentUser;
            
            [controller setMessageList:[[AppInfo sharedInfo] messageArrayWith:self.currentUser.jidStr]];
        }
    } else if ([segue.identifier isEqualToString:@"SegueID_ToContacts"]) {
        UINavigationController* navController = segue.destinationViewController;
        JSContactsViewController* controller = navController.viewControllers.lastObject;
        if ([controller respondsToSelector:@selector(setContactList:)]) {
            controller.contactList = self.userArray;
            controller.select_contact_block = ^(id contact) {
                XMPPUserCoreDataStorageObject* selectedItem = contact;
                if (![self.tokenFieldView.tokenField.tokenObjects containsObject:selectedItem]) {
                    [self.tokenFieldView.tokenField addTokenWithTitle:[self tokenField:self.tokenFieldView.tokenField displayStringForRepresentedObject:selectedItem] representedObject:selectedItem];
                }
                
                [self dismissViewControllerAnimated:YES completion:^{
                    // You can call this on either the view on the field.
                    // They both do the same thing.
                    [self.tokenFieldView becomeFirstResponder];
                }];
            };
        }
    }
}

- (IBAction)cancelSearch:(id)sender {
}

- (void)viewDidUnload {
    [self setMessageInputView:nil];
    [self setCancelButtonItem:nil];
    [super viewDidUnload];
}

- (void)stopAudioPlaying {
    [self.messageInputView stopPlaying];
//    [self.selectedCell pauseAudio];
}

- (IBAction)sendImage:(id)sender {
    [self.view endEditing:YES];
    [self stopRecording:nil];
    [self stopAudioPlaying];
    
    NSArray* selectedUsers = self.tokenFieldView.tokenField.tokenObjects;
    if (selectedUsers.count < 1) {
        [UIAlertView showMessage:@"Input user."];
        return;
    }

    [self.messageInputView sendImage];
}

- (void)sendImageToCurrentUser:(UIImage*)image {
    NSArray* selectedUsers = self.tokenFieldView.tokenField.tokenObjects;
    if (selectedUsers.count < 1) {
        [UIAlertView showMessage:@"Input user."];
        return;
    }

    NSData *imageData = UIImagePNGRepresentation(image);

    XMPPUserCoreDataStorageObject* lastUser = nil;
    for (XMPPUserCoreDataStorageObject* chatUser in selectedUsers) {
        if (![chatUser isKindOfClass:XMPPUserCoreDataStorageObject.class])
            return;
        
        NSString* filePath = [AppInfo writeFileData:imageData withType:MessageType_Photo user:chatUser.jidStr filename:nil];
        if (!filePath.isNotEmpty)
            continue;
    
        NSString *fullJidStr = chatUser.primaryResource.jidStr;
        if (fullJidStr.length < 1)
            fullJidStr = self.currentUser.jidStr;
    
        [[self appDelegate] sendToOtherDevice:imageData receiverJid:fullJidStr type:MessageType_Photo filePath:filePath];
    //    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    //    [body setStringValue:@"image sending"];
    //
    //    NSString *imageStr = [imageData base64EncodedString];
    //    NSXMLElement *ImgAttachement = [NSXMLElement elementWithName:@"attachement"];
    //    [ImgAttachement setStringValue:imageStr];
    //
    //    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    //    [message addAttributeWithName:@"type" stringValue:@"chat"];
    //    [message addAttributeWithName:@"to" stringValue:self.chatUserObj.jidStr];
    //    [message addChild:body];
    //    [message addChild:ImgAttachement];
    //
    //    [self.xmppStream sendElement:message];
    }
    if (selectedUsers.count == 1 && lastUser) {
        self.currentUser = lastUser;
        [self performSegueWithIdentifier:@"SegueID_ToChat" sender:self];
    } else {
        [self backTo:nil];
    }
}

-(IBAction)startRecording:(id)sender {
    [self.messageInputView clearContents];
    
    NSArray* selectedUsers = self.tokenFieldView.tokenField.tokenObjects;
    if (selectedUsers.count < 1) {
        [UIAlertView showMessage:@"Input user."];
        return;
    }
    
    [self.messageInputView startRecording];
}

-(IBAction)stopRecording:(id)sender
{
    NSArray* selectedUsers = self.tokenFieldView.tokenField.tokenObjects;
    if (selectedUsers.count < 1)
        return;
    
    [self.messageInputView stopRecording:selectedUsers];
    
    if (sender) {
        XMPPUserCoreDataStorageObject* lastUser = nil;
        if (selectedUsers.count == 1 && (lastUser = selectedUsers.lastObject) && lastUser) {
            self.currentUser = lastUser;
            [self performSegueWithIdentifier:@"SegueID_ToChat" sender:self];
        } else {
            [self backTo:nil];
        }
    }
}

- (IBAction)doCancelEditing:(id)sender {
    [self.view endEditing:YES];
    
    [self backTo:sender];
}

#pragma mark -

- (void)popupTableController:(PopupTableController *)controller didSelectString:(id)selectedItem {
//    self.currentUser = selectedItem;
    [self.currentPopoverController dismissPopoverAnimated:YES];
    
    if ([self.tokenFieldView.tokenField.tokenObjects containsObject:selectedItem])
        return;
    
	/*TIToken * token = */[self.tokenFieldView.tokenField addTokenWithTitle:[self tokenField:self.tokenFieldView.tokenField displayStringForRepresentedObject:selectedItem] representedObject:selectedItem];
//	[token setAccessoryType:TITokenAccessoryTypeDisclosureIndicator];
	// If the size of the token might change, it's a good idea to layout again.
	[self.tokenFieldView.tokenField layoutTokensAnimated:YES];

//	NSUInteger tokenCount = _tokenFieldView.tokenField.tokens.count;
//	[token setTintColor:((tokenCount % 3) == 0 ? [TIToken redTintColor] : ((tokenCount % 2) == 0 ? [TIToken greenTintColor] : [TIToken blueTintColor]))];
}

#pragma mark - Search

- (void)tokenFieldChangedEditing:(TITokenField *)tokenField {
	// There's some kind of annoying bug where UITextFieldViewModeWhile/UnlessEditing doesn't do anything.
	[tokenField setRightViewMode:(tokenField.editing ? UITextFieldViewModeAlways : UITextFieldViewModeNever)];
}

- (void)showContactsPicker:(id)sender {
	// Show some kind of contacts picker in here.
	// For now, here's how to add and customize tokens.
    
    //Don't resign first responder.
    //[self.view endEditing:YES];
    
    if (self.tokenFieldView.tokenField.tokens.count >= kMaxSelectCount)
        return;

    [self performSegueWithIdentifier:@"SegueID_ToContacts" sender:nil];
}

- (BOOL)tokenField:(TITokenField *)field shouldUseCustomSearchForSearchString:(NSString *)searchString {
    if (self.userArray.count < 1 || self.tokenFieldView.tokenTitles.count >= kMaxSelectCount)
        return NO;

    NSPredicate* predicateJid = [NSPredicate predicateWithFormat:@"SELF.jidStr.uppercaseString contains %@", searchString.uppercaseString];
    NSPredicate* predicateNickname = [NSPredicate predicateWithFormat:@"SELF.nickname.uppercaseString contains %@", searchString.uppercaseString];
    NSPredicate* predicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicateJid, predicateNickname, nil]];
    [self.searchContactList setArray:[self.userArray filteredArrayUsingPredicate:predicate]];
    
    [self.searchContactList removeObjectsInArray:self.tokenFieldView.tokenField.tokenObjects];
    
    return (self.searchContactList.count > 0);
}

- (void)tokenField:(TITokenField *)field performCustomSearchForSearchString:(NSString *)searchString withCompletionHandler:(void (^)(NSArray *))completionHandler {
    
    completionHandler(self.searchContactList);
}
//for sort
- (NSString *)tokenField:(TITokenField *)tokenField searchResultStringForRepresentedObject:(id)object {
    XMPPUserCoreDataStorageObject *userObj = (XMPPUserCoreDataStorageObject*)object;
    return (userObj.nickname.isNotEmpty ? userObj.nickname : userObj.jidStr);
}

- (NSString *)tokenField:(TITokenField *)tokenField displayStringForRepresentedObject:(id)object {
    XMPPUserCoreDataStorageObject *userObj = (XMPPUserCoreDataStorageObject*)object;
    return (userObj.nickname.isNotEmpty ? userObj.nickname : userObj.jidStr);
}

- (UITableViewCell *)tokenField:(TITokenField *)tokenField resultsTableView:(UITableView *)tableView cellForRepresentedObject:(id)object {
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    XMPPUserCoreDataStorageObject *userObj = (XMPPUserCoreDataStorageObject *)object;
    cell.textLabel.text = userObj.nickname;
    cell.detailTextLabel.text = userObj.jid.user;
    
    return cell;
}

#pragma mark - keyboard

-(void) keyboardWillShow:(NSNotification *)notification {
    CGRect keyboardFrame = [[notification.userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat keyboardHeight = keyboardFrame.size.height;
    if (keyboardFrame.origin.y == 0) {//landscape
        keyboardHeight = keyboardFrame.size.width;
    }
    if (keyboardHeight != self.keyboardShowHeight)
        self.keyboardIsShowing = NO;
    
    CGFloat keyboardShowHeight = keyboardHeight;
    keyboardHeight = keyboardHeight -= self.keyboardShowHeight;
    
    if (self.keyboardIsShowing == NO) {
//        self.navigationItem.rightBarButtonItem = self.cancelButtonItem;
        
        self.keyboardIsShowing = YES;
        self.keyboardShowHeight = keyboardShowHeight;
        
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        
        if (self.chatInputBottomConstraint) {
            self.chatInputBottomConstraint.constant += keyboardHeight;
            [self.view layoutIfNeeded];
        } else {
            CGRect frame1 = self.messageInputView.frame;
            frame1.origin.y -= keyboardHeight;
            
            self.messageInputView.frame = frame1;
        }
        
        [UIView commitAnimations];
    }
}

- (void)keyboardWillHide:(NSNotification*)notification {
    if (!self.keyboardIsShowing) {
        return;
    }
    
//    self.navigationItem.rightBarButtonItem = nil;

    self.keyboardIsShowing = NO;
    
    CGFloat keyboardHeight = self.keyboardShowHeight;//[[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    if (self.chatInputBottomConstraint) {
        self.chatInputBottomConstraint.constant -= keyboardHeight;
        [self.view layoutIfNeeded];
    } else {
        CGRect frame1 = self.messageInputView.frame;
        frame1.origin.y += keyboardHeight;
        
        self.messageInputView.frame = frame1;
    }
    
    [UIView commitAnimations];
    
    self.keyboardShowHeight = 0;
}

@end
