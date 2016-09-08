//
//  UIImage+Starlet.m
//  Starlet
//
//  Created by Lion User on 10/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "UIImage+Starlet.h"

@implementation UIImage (Starlet)

+ (UIImage*)imageContentFromURL:(NSString*)urlPath {
    NSURL* url = [NSURL URLWithString:urlPath];
    NSData* imgData = [NSData dataWithContentsOfURL:url];
    UIImage *image = [UIImage imageWithData:imgData];
    return image;
}

- (UIImage*)cropImageWithSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);
    [self drawAtPoint:CGPointZero];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage*)cropImageWithSquare {
    CGFloat cropSize = fmin(self.size.width, self.size.height);
    return [self cropImageWithSize:CGSizeMake(cropSize, cropSize)];
}

- (UIImage*)resizeImageWithSize:(CGSize)size {
    CGFloat scale = fmaxf(size.width / self.size.width, size.height / self.size.height);
    CGSize newSize = {ceil(self.size.width * scale), ceil(self.size.height * scale)};
    CGRect frame = CGRectZero;
    frame.origin.x = roundf((size.width - newSize.width) / 2);
    frame.origin.y = roundf((size.height - newSize.height) / 2);
    frame.size = newSize;
    
    UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    
    [self drawInRect:frame];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
