//
//  JSSearchBar.m
//  JMessage
//
//  Created by Starlet on 11/11/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSSearchBar.h"
#import <objc/runtime.h>

@implementation JSSearchBar

- (UIButton*)getCancelButton {
#if 1
    return [self valueForKey:@"_cancelButton"];
#else
    Ivar ivar = class_getInstanceVariable([self class], "_cancelButton");
    void* buttonptr = ((__bridge void*)self) + ivar_getOffset(ivar);
    UIButton* button = (__bridge_transfer UIButton*)(*(void**)buttonptr);
    return button;
#endif
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupCancelButton];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)awakeFromNib {
    [super awakeFromNib];
    
//    [self setupCancelButton];
}

- (void)setupCancelButton {
    self.showsCancelButton = YES;
    UIButton* button = [self getCancelButton];
    [button setBackgroundImage:[UIImage imageNamed:@"Cancel.png"] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
}

- (void)setShowsCancelButton:(BOOL)showsCancelButton animated:(BOOL)animated {
    [super setShowsCancelButton:showsCancelButton animated:animated];
}
//
//- (UIButton*)_cancelButton {
//    static UIButton* sCancelButton = nil;
//    if (sCancelButton == nil) {
//        sCancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        [sCancelButton setTitle:@"Cancel" forState:UIControlStateNormal];
//        
//        [sCancelButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
//        [sCancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
//    }
//    return sCancelButton;
//}

@end
