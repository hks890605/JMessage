//
//  UIColor+Starlet.m
//  Starlet
//
//  Created by Lion User on 9/26/13.
//  Copyright (c) 2013 Starlet. All rights reserved.
//

#import "UIColor+Starlet.h"

#define GetR(rgb) ((unsigned char)((unsigned int)rgb >> 16))
#define GetG(rgb) ((unsigned char)((unsigned int)rgb >> 8))
#define GetB(rgb) ((unsigned char)((unsigned int)rgb))

@implementation UIColor (Starlet)

+ (UIColor*)colorWithHex:(NSUInteger)rgbValue {
    return [UIColor colorWithRed:(CGFloat)(GetR(rgbValue)) / 255.f
                           green:(CGFloat)(GetG(rgbValue)) / 255.f
                            blue:(CGFloat)(GetB(rgbValue)) / 255.f
                           alpha:1.f];
}

+ (UIColor*)whiteGrayColor {
    return [UIColor colorWithRed:0.8/*0xCC/0xFF*/ green:0.8 blue:0.8 alpha:1.f];
}

+ (UIColor*)lightBlueColor {
    return [UIColor colorWithRed:0.3 green:0.54 blue:0.8 alpha:1.f];
}

+ (UIColor*)desertColor {
    return [UIColor colorWithRed:0.77 green:0.74 blue:0.6 alpha:1.f];
}

+ (UIColor*)darkRedColor {
    return [UIColor colorWithRed:0.65 green:0.45 blue:0.44 alpha:1.f];
}
+ (UIColor*)darkBrownColor {
    return [UIColor colorWithRed:0.96 green:0.84 blue:0.7 alpha:1.f];
}
+ (UIColor*)darkGreenColor {
    return [UIColor colorWithRed:0.61 green:0.73 blue:0.45 alpha:1.f];
}
+ (UIColor*)lightGreenColor {
    return [UIColor colorWithRed:0.84 green:0.9 blue:0.74 alpha:1.f];
}
+ (UIColor*)darkBlueColor {
    return [UIColor colorWithRed:0.86 green:0.9 blue:0.95 alpha:1.f];
}
+ (UIColor*)whiteLightGrayColor {
    return [UIColor colorWithRed:0.92/*0xCC/0xFF*/ green:0.92 blue:0.92 alpha:1.f];
}

+ (UIColor*)mainBackgroundColor {
    return [UIColor colorWithHex:0xECE6DA];
}
+ (UIColor*)lightRedColor {
    return [UIColor colorWithHex:0xFC7A6D];
}
+ (UIColor*)yellowRoseCountColor {
    return [UIColor colorWithHex:0xF2CD5D];
}
+ (UIColor*)redTextColor {
    return [UIColor colorWithHex:0xAF4A40];
}

+ (UIColor*)blueTextColor {
    return [UIColor colorWithHex:0x007AFF];
}

@end
