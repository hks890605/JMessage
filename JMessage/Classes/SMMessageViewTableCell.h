//
//  SMMessageViewTableCell.h
//  JabberClient
//
//  Created by cesarerocchi on 9/8/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppInfo.h"

@class SMMessageViewTableCell;
@class SMChatViewController;

@protocol SMMessageTableCellDelegate <NSObject>
@optional
- (void)selectPhotoButton:(SMMessageViewTableCell*)cell;
- (void)selectPlayAudio:(SMMessageViewTableCell*)cell state:(BOOL)isPlay;
- (void)selectShare:(SMMessageViewTableCell*)cell;
@end

@interface SMMessageViewTableCell : UITableViewCell
@property (nonatomic,strong) SMChatViewController<SMMessageTableCellDelegate>* delegateForCell;
@property (nonatomic,strong) NSIndexPath *indexPath;
@property (nonatomic,strong) NSString *photoImagePath;
@property (nonatomic,strong) UILabel *senderAndTimeLabel;
@property (nonatomic,strong) UITextView *messageContentView;
@property (nonatomic,strong) UIImageView *bgImageView;
@property (nonatomic,readwrite, getter = isOutgoingCell) BOOL outgoingCell;
@property (nonatomic,readwrite) MessageType messageType;

+ (UIFont*)messageFont;
+ (CGSize)cellSizeForMessage:(NSString *)message type:(MessageType)nType width:(CGFloat)width;
+ (UIImage*)resizableImageForIncoming;
+ (UIImage*)resizableImageForOutgoing;

- (void)setCellWith:(NSString*)message type:(MessageType)nType style:(BOOL)isOutgoing width:(CGFloat)width playing:(BOOL)nowPlaying;

- (UIImage*)photoImage;
- (IBAction)playAudio:(id)sender;
- (void)pauseAudio;

@end
