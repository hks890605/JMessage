//
//  JSUserListCell.m
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSUserListCell.h"

@implementation JSUserListCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        [self setupCircleImage];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)awakeFromNib {
    [super awakeFromNib];

    [self setupCircleImage];
}

- (void)setupCircleImage {
    CGRect ibounds = self.photoView.bounds;
    self.photoView.layer.cornerRadius = ibounds.size.height / 2;
    self.photoView.layer.masksToBounds = YES;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect frame = self.detailLabel.frame;
    frame.size.height = 99999;
    CGSize size = [self.detailLabel sizeThatFits:frame.size];
    frame.size.height = fminf(size.height, 34);
    self.detailLabel.frame = frame;
}

@end
