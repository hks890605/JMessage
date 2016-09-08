//
//  SMChatViewController.m
//  jabberClient
//
//  Created by cesarerocchi on 7/16/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import "SMChatViewController.h"
#import "JSAppDelegate.h"

#import "XMPP.h"

#import "NSString+Utils.h"
#import "AppInfo.h"
#import "JSNavigationBar.h"
#import "JSUserInfoViewController.h"
#import "JSPhotoViewController.h"
#import "RootViewController.h"
#import "UIImage+Starlet.h"
#import "Base64.h"

@interface SMChatViewController()
@property (nonatomic, readwrite) BOOL keyboardIsShowing;
@property (nonatomic, readwrite) CGFloat keyboardShowHeight;
@property (nonatomic, readwrite, getter = isExpaned) BOOL expanded;

@property (nonatomic, strong) SMMessageViewTableCell* selectedCell;

@end

@implementation SMChatViewController

@synthesize chatUser, messages;

- (JSAppDelegate *)appDelegate {
	return (JSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream {
	return [[self appDelegate] xmppStream];
}

- (XMPPUserCoreDataStorageObject*)chatUserObj {
    return (XMPPUserCoreDataStorageObject*)self.chatUser;
}

- (id) initWithUser:(id) user {
	if (self = [super init]) {
		chatUser = user;
	}
	
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (messages == nil)
        messages = [[NSMutableArray alloc ] init];
	
    if (![AppInfo isBeforeIOS70])
        self.tableView.tableHeaderView = nil;
    
//	[self.messageField becomeFirstResponder];
    
}

- (void)setMessageList:(NSArray*)messageList {
    if (messages == nil)
        messages = [[NSMutableArray alloc ] init];
    [messages setArray:messageList];
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
    
    [self appDelegate].chatDelegate = self;

    ((UILabel*)self.navigationItem.titleView).text = self.chatUserObj.displayName;
        //self.title = self.chatUserObj.displayName;
    
    if ([AppInfo isBeforeIOS70])
        self.navigationController.navigationBar.translucent = YES;

    [self addChatNotification];
    
    [self.chatInputView clearContents];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.chatInputView clearContents];

    [self appDelegate].chatDelegate = nil;

    [self expandNavBar:NO with:self.contactNavView animation:NO];
    
    if ([AppInfo isBeforeIOS70])
        self.navigationController.navigationBar.translucent = NO;

    [self.view endEditing:YES];

    [self removeChatNotification];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.phoneNumberField.text = self.chatUserObj.jid.user;

    if (messages.count > 0) {
        NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
        
        [self.tableView scrollToRowAtIndexPath:topIndexPath
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
}

- (NSString*)chatUserName {
    return self.chatUserObj.jidStr;
}

#pragma mark -
#pragma mark Actions

- (IBAction) closeChat {
    [self.view endEditing:YES];

    UIViewController* messagesController = nil;
    for (int i = self.navigationController.viewControllers.count - 1; i >= 0; i--) {
        UIViewController* controller  = self.navigationController.viewControllers[i] ;
        if ([controller isKindOfClass:RootViewController.class]) {
            messagesController = controller;
            break;
        }
    }
    
	[self.navigationController popToViewController:messagesController animated:YES];
}

- (IBAction)showContact:(id)sender {
    [self expandNavBar:!self.isExpaned with:self.contactNavView animation:YES];
}

- (IBAction)sendMessage {
//    [self.view endEditing:YES];
	
    NSString *messageStr = self.chatInputView.inputValue;
	
    if([messageStr length] > 0) {
		
        messageStr = [messageStr substituteEmotiKeys];
        
        NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
        [body setStringValue:messageStr];
		
        NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
        [message addAttributeWithName:@"type" stringValue:@"chat"];
        [message addAttributeWithName:@"to" stringValue:self.chatUserObj.jidStr];
        [message addChild:body];
		
        [self.xmppStream sendElement:message];
		
		[self.chatInputView setInputValue:@""];
		
//        NSString* myID = [[self appDelegate] xmppStream].myJID.bare;
//		NSMutableDictionary *m = [[NSMutableDictionary alloc] init];
//		[m setObject:[messageStr substituteEmoticons] forKey:kMessageKey];
//		[m setObject:myID forKey:kSenderKey];
//		[m setObject:[NSString getCurrentTime] forKey:kDateKey];
//		
//		[messages addObject:m];
//		[self.tableView reloadData];
    }
	
//    if (messages.count > 0) {
//        NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
//        
//        [self.tableView scrollToRowAtIndexPath:topIndexPath
//                          atScrollPosition:UITableViewScrollPositionBottom 
//                                  animated:YES];
//    }
}

- (IBAction)sendImage:(id)sender {
    [self.view endEditing:YES];
    [self stopRecording:nil];
    [self stopAudioPlaying];

    [self.chatInputView sendImage];
}

- (void)sendImageToCurrentUser:(UIImage*)image {
    NSData *imageData = UIImagePNGRepresentation(image);
    NSString* filePath = [AppInfo writeFileData:imageData withType:MessageType_Photo user:self.chatUserObj.jidStr filename:nil];
    
    if (!filePath.isNotEmpty)
        return;
    
    NSString *fullJidStr = self.chatUserObj.primaryResource.jidStr;
    if (fullJidStr.length < 1)
        fullJidStr = self.chatUserObj.jidStr;
    
    [[self appDelegate] sendToOtherDevice:imageData receiverJid:fullJidStr type:MessageType_Photo filePath:filePath];
//    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
//    [body setStringValue:@"image sending"];
//    
//    NSString *imageStr = [imageData base64EncodedString];
//    NSXMLElement *ImgAttachement = [NSXMLElement elementWithName:@"attachement"];
//    //[ImgAttachement setStringValue:imageStr];
//
//    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
//    [message addAttributeWithName:@"type" stringValue:@"chat"];
//    [message addAttributeWithName:@"to" stringValue:self.chatUserObj.jidStr];
//    [message addChild:body];
//    //[message addChild:ImgAttachement];
//    
//    [self.xmppStream sendElement:message];
}

-(IBAction)startRecording:(id)sender {
    [self.chatInputView clearContents];
    
    [self.chatInputView startRecording];
}


-(IBAction)stopRecording:(id)sender
{
    [self.chatInputView stopRecording:@[self.chatUserObj]];
}

- (IBAction)phoneCall:(id)sender {
    NSURL* phoneCall = [NSURL URLWithString:[@"tel:" stringByAppendingString:self.phoneNumberField.text]];
    [[UIApplication sharedApplication] openURL:phoneCall];
}

#pragma mark Table view delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [messages count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	NSDictionary *dict = (NSDictionary *)[messages objectAtIndex:indexPath.row];
	NSString *msg = [dict objectForKey:kMessageKey];
    MessageType msgType = MessageType_String;
    id msgTypeObj = dict[kMessageTypeKey];
    if ([msgTypeObj respondsToSelector:@selector(intValue)])
        msgType = [msgTypeObj intValue];

    if (msgType == MessageType_String)
        msg = [msg substituteEmoticons];

	CGSize cellSize = [SMMessageViewTableCell cellSizeForMessage:msg type:msgType width:tableView.frame.size.width];
    return cellSize.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"MessageCellIdentifier";
	
	SMMessageViewTableCell *cell = (SMMessageViewTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	
	if (cell == nil) {
		cell = [[SMMessageViewTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
	}

	NSDictionary *msginfo = (NSDictionary *) [messages objectAtIndex:indexPath.row];
	NSString *sender = [msginfo objectForKey:kSenderKey];
	NSString *message = [msginfo objectForKey:kMessageKey];
	NSString *time = [msginfo objectForKey:kDateKey];
    
	cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    NSString* myID = [[self appDelegate] xmppStream].myJID.bare;
    
    CGRect frame = tableView.frame;
    BOOL isOutgoing = [sender isEqualToString:myID];
	cell.senderAndTimeLabel.text = [NSString stringWithFormat:@"%@", /*sender, */time];
	
    MessageType msgType = MessageType_String;
    id msgTypeObj = msginfo[kMessageTypeKey];
    if ([msgTypeObj respondsToSelector:@selector(intValue)])
        msgType = [msgTypeObj intValue];
    
    BOOL nowIsPlaying = NO;
    if (msgType == MessageType_String)
        message = [message substituteEmoticons];
    else if (msgType == MessageType_Audio)
        nowIsPlaying = [self.chatInputView isPlayingAtPath:message];

    [cell setCellWith:message type:msgType style:isOutgoing width:frame.size.width playing:nowIsPlaying];
    
    cell.delegateForCell = self;
    cell.indexPath = indexPath;
    
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.view endEditing:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark -

- (void)delete:(id)sender {
    if ([sender isKindOfClass:SMMessageViewTableCell.class]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        if (indexPath) {
            NSDictionary* messageInfo = self.messages[indexPath.row];
            if ([[AppInfo sharedInfo] deleteMessage:messageInfo]) {
                //Delete file
                MessageType msgType = MessageType_String;
                id msgTypeObj = messageInfo[kMessageTypeKey];
                if ([msgTypeObj respondsToSelector:@selector(intValue)])
                    msgType = [msgTypeObj intValue];

                if (msgType != MessageType_String) {
                    NSString *filePath = [messageInfo objectForKey:kMessageKey];
                    if (filePath.isNotEmpty && [[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
                        NSError *error = nil;
                        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
                        if (error)
                            NSLog(@"Delete file error(%@)", error);
                    }
                }

                [self.messages removeObjectAtIndex:indexPath.row];
                [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }
}

- (void)selectPhotoButton:(SMMessageViewTableCell *)cell {
    self.selectedCell = cell;
    [self performSegueWithIdentifier:@"SegueID_ToPhoto" sender:self];
}

- (void)selectPlayAudio:(SMMessageViewTableCell *)cell state:(BOOL)isPlay {
    if (cell.indexPath.row >= messages.count)
        return;
    
    if (isPlay == NO) {
        [self.chatInputView stopPlaying];
        return;
    }

    if (self.selectedCell != cell) {
        [self.selectedCell pauseAudio];
        self.selectedCell = nil;
    }
    
    NSDictionary *msginfo = (NSDictionary *) [messages objectAtIndex:cell.indexPath.row];
	NSString *audioPath = [msginfo objectForKey:kMessageKey];

    [self.chatInputView startPlaying:audioPath];
    self.selectedCell = cell;
}

- (void)stopAudioPlaying {
    [self.chatInputView stopPlaying];
    [self.selectedCell pauseAudio];
    self.selectedCell = nil;
}

#pragma mark -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueID_ToUserInfo"]) {
        JSUserInfoViewController* controller = (JSUserInfoViewController*)segue.destinationViewController;
        controller.currentUser = self.chatUser;
    } else if ([segue.identifier isEqualToString:@"SegueID_ToPhoto"]) {
        JSPhotoViewController* controller = (JSPhotoViewController*)segue.destinationViewController;
        [controller setCurrentPhoto:[self.selectedCell photoImage] path:self.selectedCell.photoImagePath];
    }
}

#pragma mark Chat delegates

- (void)newMessageReceived:(NSMutableDictionary *)messageContent {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *m = [messageContent objectForKey:kMessageKey];
        if (m.length > 0) {
            [messageContent setObject:m forKey:kMessageKey];
            [messageContent setObject:[NSString getCurrentTime] forKey:kDateKey];
            [messages addObject:messageContent];
            [self.tableView reloadData];

            NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count-1 
                                                           inSection:0];
            
            [self.tableView scrollToRowAtIndexPath:topIndexPath
                              atScrollPosition:UITableViewScrollPositionMiddle 
                                      animated:YES];
        }
    });
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewDidUnload {
    [self setContactNavView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	self.chatUser = nil;//[chatWithUser dealloc];
	self.tableView = nil;//[tView dealloc];
//    [super dealloc];
}

#pragma mark - Share

- (void)selectShare:(SMMessageViewTableCell*)cell {
    if (cell.indexPath.row >= messages.count)
        return;
    
    if (!IS_OveriOS6)
        return;
    
    NSDictionary *msginfo = (NSDictionary *) [messages objectAtIndex:cell.indexPath.row];
	NSString *filePath = [msginfo objectForKey:kMessageKey];
    
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

#pragma mark - 

- (void)willChangeChatInputView:(JSChatInputView *)inputView frame:(CGRect)newFrame {
    CGRect inputframe = inputView.frame;
    CGRect frame = self.tableView.frame;
    frame.size.height -= newFrame.size.height - inputframe.size.height;
    self.tableView.frame = frame;
    
    if (messages.count > 0) {
        NSIndexPath *topIndexPath = [NSIndexPath indexPathForRow:messages.count-1 inSection:0];
        
        [self.tableView scrollToRowAtIndexPath:topIndexPath
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
    }
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
        self.keyboardIsShowing = YES;
        self.keyboardShowHeight = keyboardShowHeight;

        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
        [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
        
        if (self.chatInputBottomConstraint) {
            self.chatInputBottomConstraint.constant += keyboardHeight;
            [self.view layoutIfNeeded];
        } else {
            CGRect frame = self.tableView.frame;
            frame.size.height -= keyboardHeight;
            CGRect frame1 = self.chatInputView.frame;
            frame1.origin.y -= keyboardHeight;
            self.chatInputView.frame = frame1;
            self.tableView.frame = frame;
        }
        
        [UIView commitAnimations];
        
        NSInteger sections = [self.tableView numberOfSections];
        if (sections > 0) {
            NSInteger rows = [self.tableView numberOfRowsInSection:sections - 1];
            if (rows > 0) {
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:rows - 1 inSection:sections - 1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
        }
    }
}

- (void)keyboardWillHide:(NSNotification*)notification {
    if (!self.keyboardIsShowing) {
        return;
    }
    
    self.keyboardIsShowing = NO;
    
    CGFloat keyboardHeight = self.keyboardShowHeight;//[[notification.userInfo valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size.height;
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:[[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue]];
    [UIView setAnimationCurve:[[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]];
    
    if (self.chatInputBottomConstraint) {
        self.chatInputBottomConstraint.constant -= keyboardHeight;
        [self.view layoutIfNeeded];
    } else {
        CGRect frame = self.tableView.frame;
        frame.size.height += keyboardHeight;
        CGRect frame1 = self.chatInputView.frame;
        frame1.origin.y += keyboardHeight;
        
        self.tableView.frame = frame;
        self.chatInputView.frame = frame1;
    }
    
    [UIView commitAnimations];
    
    self.keyboardShowHeight = 0;
}

- (void)expandNavBar:(BOOL)isExpand with:(UIView*)barView animation:(BOOL)animate {
    self.expanded = isExpand;
    if (barView) {
        if (isExpand) {
            CGFloat originy = 0;//self.view.frame.origin.y;
            if (self.navigationController.navigationBar.translucent)
                originy += self.navigationController.navigationBar.frame.size.height;
            self.contactNavView.hidden = NO;
            
            if (animate) {
                [UIView animateWithDuration:0.35 animations:^{
                    self.contactDropTopConstraint.constant = originy;
                    [self.view layoutSubviews];
                } completion:^(BOOL finished) {
                    if (finished) {
                    }
                }];
            } else {
                self.contactDropTopConstraint.constant = originy;
            }
        } else {
            CGFloat originy = -barView.frame.size.height;
            if (animate) {
                [UIView animateWithDuration:0.35 animations:^{
                    self.contactDropTopConstraint.constant = originy;
                    [self.view layoutSubviews];
                } completion:^(BOOL finished) {
                    if (finished) {
                        self.contactNavView.hidden = YES;
                    }
                }];
            } else {
                self.contactDropTopConstraint.constant = originy;
                self.contactNavView.hidden = YES;
            }
        }
    }
}

@end
