//
//  JSUserListCell.h
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <UIKit/UIKit.h>

#define JSUserListCellID    @"JSUserListCellID"

@interface JSUserListCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UIImageView  *photoView;
@property (strong, nonatomic) IBOutlet UIImageView  *markImageView;
@property (strong, nonatomic) IBOutlet UILabel  *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel  *detailLabel;
@property (strong, nonatomic) IBOutlet UILabel  *dateLabel;

@end

#define JSSearchUserListCellID    @"JSSearchUserListCellID"

@interface JSSearchUserListCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel  *nicknameLabel;
@property (strong, nonatomic) IBOutlet UILabel  *jidLabel;

@end
