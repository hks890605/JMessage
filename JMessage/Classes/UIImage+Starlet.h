//
//  UIImage+Starlet.h
//  Starlet
//
//  Created by Lion User on 10/19/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Starlet)

+ (UIImage*)imageContentFromURL:(NSString*)urlPath;

- (UIImage*)cropImageWithSize:(CGSize)size;
- (UIImage*)cropImageWithSquare;

- (UIImage*)resizeImageWithSize:(CGSize)size;

@end
