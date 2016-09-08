//
//  JSRoundImageView.m
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSRoundImageView.h"

@implementation JSRoundImageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupRound];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupRound];
}

- (void)setupRound {
    self.layer.cornerRadius = 3;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.borderWidth = 1;
    self.layer.masksToBounds = YES;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
