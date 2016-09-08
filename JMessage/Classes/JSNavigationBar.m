//
//  JSNavigationBar.m
//  JMessage
//
//  Created by Starlet on 11/9/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSNavigationBar.h"
#import "AppInfo.h"

@interface JSNavigationBar()
@property (nonatomic, readwrite, getter = isExpaned) BOOL expanded;

@end

@implementation JSNavigationBar

@synthesize expanded;

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

- (UIImage*)backgroundImage {
    return [UIImage imageNamed:@"titlebar.png"];
}

- (void)setupBackground {
    //ADD.MY.20140108
    if ([AppInfo isBeforeIOS70]) {
        if ([self respondsToSelector:@selector(setBackgroundImage:forBarMetrics:)]){
            [self setBackgroundImage:[self backgroundImage] forBarMetrics:UIBarMetricsDefault];
        }
        self.barStyle = UIBarStyleBlackOpaque;//for black status bar
    } else {
        self.translucent = NO;
    }
    
    //bold title
//    NSMutableDictionary* attrs = [NSMutableDictionary dictionaryWithDictionary:self.titleTextAttributes];
//    UIFont *titleFont = attrs[UITextAttributeFont];
//    titleFont = [UIFont boldSystemFontOfSize:titleFont.pointSize];
//    attrs[UITextAttributeFont] = titleFont;
//    self.titleTextAttributes = attrs;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

//- (CGSize)sizeThatFits:(CGSize)size {
//    size = [super sizeThatFits:size];
//    if (self.isExpaned)
//        return CGSizeMake(size.width, size.height * 2);
//    return size;
//}

#define NAV_HEIGHT  44

- (void)expandBar:(BOOL)isExpand with:(UIView*)barView animation:(BOOL)animate {
    self.expanded = isExpand;
    if (barView) {
        if (isExpand) {
            CGRect frame = self.bounds;
            barView.frame = frame;
            
            frame.origin.y += NAV_HEIGHT;
            frame.size.height = NAV_HEIGHT;

            if (animate) {
                [UIView animateWithDuration:0.35 animations:^{
                    barView.frame = frame;
                    [self addSubview:barView];
                    [self sendSubviewToBack:barView];
                } completion:^(BOOL finished) {
                    if (finished) {
                        [self bringSubviewToFront:barView];
                    }
                }];
            } else {
                barView.frame = frame;
                [self addSubview:barView];
                [self sendSubviewToBack:barView];
            }
        } else {
            CGRect frame = self.bounds;
            frame.origin.y -= NAV_HEIGHT;
            if (animate) {
                [UIView animateWithDuration:0.35 animations:^{
                    barView.frame = frame;
                } completion:^(BOOL finished) {
                    if (finished) {
                        [barView removeFromSuperview];
                    }
                }];
            } else {
                [barView removeFromSuperview];
            }
        }
    }
    
    [self layoutIfNeeded];
}

@end
