//
//  JSChatInputView.h
//  JMessage
//
//  Created by Starlet on 11/10/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HPGrowingTextView.h"
#import <AVFoundation/AVFoundation.h>

@class JSChatInputView;

@protocol JSChatInputDelegate <NSObject>
- (void)willChangeChatInputView:(JSChatInputView*)inputView frame:(CGRect)newFrame;

@end

@interface JSChatInputView : UIView<HPGrowingTextViewDelegate, AVAudioPlayerDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate, UIPopoverControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) HPGrowingTextView *textView;
@property (strong, nonatomic) IBOutlet UIViewController*    controller;
@property (strong, nonatomic) IBOutlet UIImageView*         backImageView;
@property (strong, nonatomic) IBOutlet UIButton*            sendMessageButton;
@property (strong, nonatomic) IBOutlet UILabel*             recordTimeLabel;
@property (strong, nonatomic) IBOutlet UIButton*            recordButton;
@property (readwrite, nonatomic) NSInteger audioDuration;

-(void)resignTextView;

- (NSString*)inputValue;
- (void)setInputValue:(NSString*)value;

- (void)clearContents;

- (void)sendImage;
- (void)startRecording;
- (void)stopRecording:(NSArray*)chatUserList;
- (BOOL)isPlayingAtPath:(NSString*)audioPath;
- (void)startPlaying:(NSString*)audioPath;
- (void)stopPlaying;

@end
