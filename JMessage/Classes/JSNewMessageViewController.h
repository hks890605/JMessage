//
//  JSNewMessageViewController.h
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PopupTableController.h"
#import "JSChatInputView.h"
#import "TITokenField.h"

@interface JSNewMessageViewController : UIViewController<PopupTableDelegate, UIPopoverControllerDelegate, TITokenFieldDelegate>
@property (nonatomic, retain) PopupTableController  *tablePopupController;
@property (nonatomic, retain) UIPopoverController   *currentPopoverController;
@property (strong, nonatomic) IBOutlet JSChatInputView *messageInputView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *cancelButtonItem;
@property (strong, nonatomic) NSArray *userArray;
@property (weak, nonatomic) IBOutlet TITokenFieldView *tokenFieldView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint*  chatInputBottomConstraint;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *rightCancelButton;

- (IBAction)backTo:(id)sender;
- (IBAction)clickToField:(id)sender;
- (IBAction)sendText:(id)sender;
- (IBAction)cancelSearch:(id)sender;

- (IBAction)sendImage:(id)sender;

-(IBAction)startRecording:(id)sender;
-(IBAction)stopRecording:(id)sender;

- (IBAction)doCancelEditing:(id)sender;
@end
