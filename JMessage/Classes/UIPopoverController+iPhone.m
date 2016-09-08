//
//  UIPopoverController+iPhone.m
//  NoonDate
//
//  Created by Starlet on 8/8/13.
//  Copyright (c) 2013 Starlet. All rights reserved.
//

#import "UIPopoverController+iPhone.h"

@implementation UIPopoverController (iPhone)

+ (BOOL)_popoversDisabled {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return NO;
    return YES;
}

@end
