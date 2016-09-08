//
//  SMChatViewController.h
//  jabberClient
//
//  Created by cesarerocchi on 7/16/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMMessageDelegate.h"
#import "SMMessageViewTableCell.h"
#import "JSChatInputView.h"
#import <AVFoundation/AVFoundation.h>

@interface SMChatViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, SMMessageDelegate, JSChatInputDelegate, SMMessageTableCellDelegate> {

	NSMutableArray	*messages;
	
}

@property (nonatomic,retain) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet JSChatInputView *chatInputView;

@property (nonatomic,retain) id chatUser;
@property (nonatomic,retain) NSMutableArray *messages;
@property (weak, nonatomic) IBOutlet UILabel *phoneNumberField;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint*  chatInputBottomConstraint;

@property (strong, nonatomic) IBOutlet UIView *contactNavView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint*  contactDropTopConstraint;

- (id) initWithUser:(id) user;
- (NSString*)chatUserName;
- (void)setMessageList:(NSArray*)messages;
- (IBAction) sendMessage;
- (IBAction) closeChat;
- (IBAction)showContact:(id)sender;
- (IBAction)sendImage:(id)sender;

-(IBAction)startRecording:(id)sender;
-(IBAction)stopRecording:(id)sender;

- (IBAction)phoneCall:(id)sender;
@end
