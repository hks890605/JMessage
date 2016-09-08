//
//  SMMessageViewTableCell.m
//  JabberClient
//
//  Created by cesarerocchi on 9/8/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import "SMMessageViewTableCell.h"
#import "SMChatViewController.h"

#define kTimeLabelHeight    20

@interface SMMessageViewTableCell ()
@property (strong, nonatomic) UIButton*  photoButton;
@property (strong, nonatomic) UIButton*  playAudioButton;

@end


@implementation SMMessageViewTableCell

@synthesize senderAndTimeLabel, messageContentView, bgImageView, photoButton;

- (void)dealloc {
	
	senderAndTimeLabel = nil;//[senderAndTimeLabel release];
	messageContentView = nil;//[messageContentView release];
	bgImageView = nil;//[bgImageView release];
//    [super dealloc];
	
}

+ (UIFont*)messageFont {
    return [UIFont systemFontOfSize:16];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
		senderAndTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.contentView.frame.size.width, kTimeLabelHeight)];
		senderAndTimeLabel.textAlignment = NSTextAlignmentCenter; //UITextAlignmentCenter;
		senderAndTimeLabel.font = [UIFont systemFontOfSize:11.0];
		senderAndTimeLabel.textColor = [UIColor lightGrayColor];
		senderAndTimeLabel.backgroundColor = [UIColor clearColor];
		[self.contentView addSubview:senderAndTimeLabel];
        senderAndTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;
		
		bgImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
		[self.contentView addSubview:bgImageView];
        
		messageContentView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
		messageContentView.backgroundColor = [UIColor clearColor];
		messageContentView.editable = NO;
		messageContentView.scrollEnabled = NO;
        messageContentView.userInteractionEnabled = YES;
        messageContentView.font = [SMMessageViewTableCell messageFont];
        messageContentView.contentInset = UIEdgeInsetsMake(0, -4, 0, 0);
		[self.contentView addSubview:messageContentView];
        
        UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [recognizer setMinimumPressDuration:0.4];
        [self addGestureRecognizer:recognizer];
    }
	
    return self;
}

+ (CGSize)textSizeForMessage:(NSString*)message width:(CGFloat)width {
    CGSize  textSize = { width, 10000.0 };
	CGSize size = [[message stringByAppendingString:@" "] sizeWithFont:[SMMessageViewTableCell messageFont] constrainedToSize:textSize lineBreakMode:NSLineBreakByWordWrapping];// NSLineBreakModeWordWrap];
    return size;
}


#define kBackImageCapTop    14
#define kBackImageCapLeft   22
#define kBackImageCapBottom 14
#define kBackImageCapRight  16
#define kBackImageWidth     40 //kBackImageCapLeft + kBackImageCapRight + 1
#define kBackImageHeight    30 //kBackImageCapTop + kBackImageCapBottom + 1

#define kTextMarginTop      6
#define kTextMarginLeft     12
#define kTextMarginBottom   6
#define kTextMarginRight    8

#define kTextViewInsetTop   8
#define kTextViewInsetLeft  4
#define kTextViewInsetBottom    2
#define kTextViewInsetRight     4

+ (UIImage*)resizableImageForIncoming {
    return [[UIImage imageNamed:@"incoming.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(kBackImageCapTop, kBackImageCapRight, kBackImageCapBottom, kBackImageCapLeft)];
}

+ (UIImage*)resizableImageForOutgoing {
    return [[UIImage imageNamed:@"outgoing.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(kBackImageCapTop, kBackImageCapLeft, kBackImageCapBottom, kBackImageCapRight)];
}

+ (CGSize)cellSizeForMessage:(NSString *)message type:(MessageType)nType width:(CGFloat)width {
    CGSize cellSize = CGSizeZero;
    if (nType == MessageType_String) {
        cellSize = [self textSizeForMessage:message width:(width * 0.75)/*width - kBackImageWidth*/];
    } else if (nType == MessageType_Photo) {
        cellSize = CGSizeMake(140, 100);
    } else {
        cellSize = CGSizeMake(48, 28);
    }
    cellSize.width = MAX(kBackImageWidth, cellSize.width + kTextMarginLeft + kTextMarginRight);
    cellSize.height = MAX(kBackImageHeight, cellSize.height + kTextMarginTop + kTextMarginBottom) + kTimeLabelHeight;
    return cellSize;
}

- (void) setClippingPath:(UIBezierPath *)clippingPath : (UIButton *)imgView;
{
    if (![[imgView layer] mask])
        [[imgView layer] setMask:[CAShapeLayer layer]];
    
    [(CAShapeLayer*) [[imgView layer] mask] setPath:[clippingPath CGPath]];
}

#define kRoundUnit    4
- (UIBezierPath*)bubblePathForImageView:(CGSize)size {
    UIBezierPath *aPath = [UIBezierPath bezierPath];
    CGFloat borderRadius = 12;
    
    borderRadius = kRoundUnit * 3;
    if (self.outgoingCell) {//incoming
        // Set the starting point of the shape.
        [aPath moveToPoint:CGPointMake(0,  borderRadius)];
        // Draw the lines.
        [aPath addLineToPoint:CGPointMake(0, size.height - borderRadius)];
        [aPath addQuadCurveToPoint:CGPointMake(borderRadius, size.height) controlPoint:CGPointMake(0, size.height)];
        [aPath addLineToPoint:CGPointMake(size.width - kRoundUnit * 3, size.height)];
        
        [aPath addQuadCurveToPoint:CGPointMake(size.width - kRoundUnit, size.height - kRoundUnit) controlPoint:CGPointMake(size.width - kRoundUnit, size.height)];
        [aPath addQuadCurveToPoint:CGPointMake(size.width, size.height) controlPoint:CGPointMake(size.width - kRoundUnit * 2, size.height)];
        [aPath addQuadCurveToPoint:CGPointMake(size.width - kRoundUnit, size.height - borderRadius) controlPoint:CGPointMake(size.width - kRoundUnit, size.height - kRoundUnit)];

        [aPath addLineToPoint:CGPointMake(size.width - kRoundUnit, borderRadius)];
        [aPath addQuadCurveToPoint:CGPointMake(size.width - kRoundUnit * 3, 0) controlPoint:CGPointMake(size.width - kRoundUnit, 0)];
        [aPath addLineToPoint:CGPointMake(borderRadius, 0)];
        [aPath addQuadCurveToPoint:CGPointMake(0, borderRadius) controlPoint:CGPointMake(0, 0)];
        //[aPath addLineToPoint:CGPointMake(0, 0)];
    } else {
        // Set the starting point of the shape.
        [aPath moveToPoint:CGPointMake(kRoundUnit,  borderRadius)];
        // Draw the lines.
        [aPath addLineToPoint:CGPointMake(kRoundUnit, size.height - borderRadius)];
        //Draw bull
        [aPath addQuadCurveToPoint:CGPointMake(0, size.height) controlPoint:CGPointMake(kRoundUnit, size.height - kRoundUnit)];
        [aPath addQuadCurveToPoint:CGPointMake(kRoundUnit, size.height - kRoundUnit) controlPoint:CGPointMake(kRoundUnit*2, size.height)];
        [aPath addQuadCurveToPoint:CGPointMake(kRoundUnit * 3, size.height) controlPoint:CGPointMake(kRoundUnit, size.height)];
       
        [aPath addLineToPoint:CGPointMake(size.width - borderRadius, size.height)];
        [aPath addQuadCurveToPoint:CGPointMake(size.width, size.height - borderRadius) controlPoint:CGPointMake(size.width, size.height)];
        [aPath addLineToPoint:CGPointMake(size.width, borderRadius)];
        [aPath addQuadCurveToPoint:CGPointMake(size.width - borderRadius, 0) controlPoint:CGPointMake(size.width, 0)];
        //[aPath addLineToPoint:CGPointMake(0, 0)];
        [aPath addLineToPoint:CGPointMake(borderRadius, 0)];
        [aPath addQuadCurveToPoint:CGPointMake(kRoundUnit, borderRadius) controlPoint:CGPointMake(kRoundUnit, 0)];
    }
    [aPath closePath];
    
    return aPath;
}

- (void)setCellWith:(NSString*)message type:(MessageType)nType style:(BOOL)isOutgoing width:(CGFloat)width playing:(BOOL)nowPlaying {
    self.outgoingCell = isOutgoing;
    self.messageType = nType;
    
    bgImageView.image = (isOutgoing ? [SMMessageViewTableCell resizableImageForOutgoing] : [SMMessageViewTableCell resizableImageForIncoming]);

    switch (nType) {
        case MessageType_String:
            messageContentView.textColor = (isOutgoing ? [UIColor whiteColor] : [UIColor blackColor]);
            messageContentView.text = message;

            messageContentView.hidden = NO;
            photoButton.hidden = YES;
            self.playAudioButton.hidden = YES;
            break;
        case MessageType_Photo:
            if (photoButton == nil) {
                photoButton = [UIButton buttonWithType:UIButtonTypeCustom];
                photoButton.backgroundColor = [UIColor redColor];
                photoButton.contentMode = UIViewContentModeScaleAspectFit;
                [photoButton addTarget:self action:@selector(clickPhotoButton:) forControlEvents:UIControlEventTouchUpInside];
                [self.contentView addSubview:photoButton];
            }
            [self.photoButton setBackgroundImage:[[UIImage alloc] initWithContentsOfFile:message] forState:UIControlStateNormal];
            self.photoImagePath = message;

            self.photoButton.hidden = NO;
            messageContentView.hidden = YES;
            self.playAudioButton.hidden = YES;
            bgImageView.image = nil;

            break;
        case MessageType_Audio:
            if (self.playAudioButton == nil) {
                self.playAudioButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
                self.playAudioButton.backgroundColor = [UIColor clearColor];
                self.playAudioButton.contentMode = UIViewContentModeScaleAspectFit;
                [self.playAudioButton setImage:[UIImage imageNamed:@"playbtn"] forState:UIControlStateNormal];
                [self.playAudioButton setImage:[UIImage imageNamed:@"pausebtn"] forState:UIControlStateSelected];
                [self.playAudioButton addTarget:self action:@selector(playAudio:) forControlEvents:UIControlEventTouchUpInside];
                [self.contentView addSubview:self.playAudioButton];
            }
            self.playAudioButton.selected = nowPlaying;
            self.playAudioButton.hidden = NO;
            photoButton.hidden = YES;
            messageContentView.hidden = YES;
            break;
        default:
            break;
    }
}

- (UIImage*)photoImage {
    return (self.photoButton.hidden ? nil : [self.photoButton backgroundImageForState:UIControlStateNormal]);
}

- (IBAction)clickPhotoButton:(id)sender {
    if (self.delegateForCell && [self.delegateForCell respondsToSelector:@selector(selectPhotoButton:)]) {
        [self.delegateForCell selectPhotoButton:self];
    }
}

- (IBAction)playAudio:(id)sender {
    self.playAudioButton.selected = !self.playAudioButton.selected;
    if (self.delegateForCell && [self.delegateForCell respondsToSelector:@selector(selectPlayAudio:state:)])
        [self.delegateForCell selectPlayAudio:self state:self.playAudioButton.isSelected];
}

- (void)pauseAudio {
    self.playAudioButton.selected = NO;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    NSString* message = messageContentView.text;
    BOOL isOutgoing = self.isOutgoingCell;
    CGFloat width = self.frame.size.width;

    CGSize cellSize = [SMMessageViewTableCell cellSizeForMessage:message type:self.messageType width:width];
    CGRect frame;
    frame.origin.y = kTimeLabelHeight;
    frame.origin.x = (isOutgoing ? width - cellSize.width : 0);
    frame.size.width = cellSize.width;
    frame.size.height = cellSize.height - kTimeLabelHeight;
    bgImageView.frame = frame;
    
    if (messageContentView.hidden == NO) {
        frame.origin.x += (isOutgoing ? kTextMarginRight : kTextMarginLeft);
        frame.origin.y += kTextMarginTop - kTextViewInsetTop;
        frame.size.width -= (kTextMarginLeft + kTextMarginRight) - (kTextViewInsetLeft + kTextViewInsetRight);//(isOutgoing ? kTextMarginLeft : kTextMarginRight) -  (kTextViewInsetLeft + kTextViewInsetRight);
        frame.size.height -= kTextMarginBottom - (kTextViewInsetTop + kTextViewInsetBottom);

        frame.size.width += 4;//UITextView left edge inset implicitly
        
        messageContentView.frame = frame;
    }
    if (photoButton.hidden == NO) {
        CGRect iframe = frame;//CGRect iframe = CGRectInset(frame, 4, 6);
        CGSize imageSize = [photoButton backgroundImageForState:UIControlStateNormal].size;
        if (imageSize.width > 0 && imageSize.height > 0) {
            CGFloat scale = fminf(frame.size.width / imageSize.width , frame.size.height / imageSize.height);
            imageSize.width = floor(imageSize.width * scale);
            imageSize.height = floor(imageSize.height * scale);
            iframe.origin.x = (isOutgoing ? frame.origin.x + frame.size.width - imageSize.width : 0);
            iframe.origin.y += roundf((iframe.size.height - imageSize.height) / 2);
            iframe.size = imageSize;
        }
        photoButton.frame = iframe;
        [self setClippingPath:[self bubblePathForImageView:iframe.size] :photoButton];
    }
    if (self.playAudioButton.hidden == NO) {
        frame = CGRectInset(frame, 8, 12);
        self.playAudioButton.frame = frame;
        self.playAudioButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [super becomeFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if(action == @selector(copy:))
        return YES;
    if(action == @selector(delete:))
        return YES;
    
    if (action == @selector(share:))
        return YES;
    
    return [super canPerformAction:action withSender:sender];
}

- (void)copy:(id)sender {
    [[UIPasteboard generalPasteboard] setString:self.messageContentView.text];
    [self resignFirstResponder];
}

- (void)delete:(id)sender {
    if (self.delegateForCell && [self.delegateForCell respondsToSelector:@selector(delete:)]) {
        [self.delegateForCell delete:self];
    }
}

- (IBAction)share:(id)sender {
    if (self.delegateForCell && [self.delegateForCell respondsToSelector:@selector(selectShare:)]) {
        [self.delegateForCell selectShare:self];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if(longPress.state != UIGestureRecognizerStateBegan
       || ![self becomeFirstResponder])
        return;
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    
    if (self.messageType == MessageType_Photo || self.messageType == MessageType_Audio) {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"title like %@", @"Share"];
        NSArray* shareItems = [menu.menuItems filteredArrayUsingPredicate:predicate];
        if (shareItems.count < 1) {
            UIMenuItem* shareItem = [[UIMenuItem alloc] initWithTitle:@"Share" action:@selector(share:)];
            NSMutableArray* items = [NSMutableArray arrayWithArray:menu.menuItems];
            [items addObject:shareItem];
            menu.menuItems = items;
        }
    }
    
    CGRect targetRect = [self convertRect:[self.bgImageView bounds]
                                 fromView:self.bgImageView];
    [menu setTargetRect:CGRectInset(targetRect, 0.0f, 4.0f) inView:self];
    [menu setMenuVisible:YES animated:YES];
}

@end
