//
//  FlatTextField.m
//  Jesus
//
//  Created by Starlet on 11/5/13.
//  Copyright (c) 2013 Starlet. All rights reserved.
//

#import "FlatTextField.h"
#import "UIColor+Starlet.h"

@implementation FlatTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self setupBackground];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setupBackground];
}

- (void)setupBackground {
    self.borderStyle = UITextBorderStyleNone;
    self.layer.cornerRadius = 6.f;
    self.layer.backgroundColor = [UIColor whiteLightGrayColor].CGColor;
    self.layer.masksToBounds = YES;
}

- (CGRect)textRectForBounds:(CGRect)bounds {
    CGRect textRect = [super textRectForBounds:bounds];
    textRect = CGRectInset(textRect, 6, 0);
    return textRect;
}

- (CGRect)editingRectForBounds:(CGRect)bounds {
    CGRect textRect = [super editingRectForBounds:bounds];
    textRect = CGRectInset(textRect, 6, 0);
    return textRect;
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
