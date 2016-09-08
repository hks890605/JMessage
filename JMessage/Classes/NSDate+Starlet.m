//
//  NSDate+Starlet.m
//  JMessage
//
//  Created by Starlet on 12/1/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "NSDate+Starlet.h"

@implementation NSDate (Starlet)

+ (NSDateFormatter*)defaultFormatter {
    static NSDateFormatter* sDateFormatter = nil;
    if (sDateFormatter == nil) {
        sDateFormatter = [NSDateFormatter new];
        sDateFormatter.dateFormat = @"ddMMYYhhmmssms";
    }
    return sDateFormatter;
}

+ (NSString*)fileNameFromDate {
    return [[NSDate defaultFormatter] stringFromDate:[NSDate date]];
}
+ (NSString*)photoFileNameFromDate {
    return [[NSDate date] photoFileName];
}
+ (NSString*)audioFileNameFromDate {
    return [[NSDate date] audioFileName];
}
+ (NSString*)videoFileNameFromDate {
    return [[NSDate date] videoFileName];
}

- (NSString*)photoFileName {
    return [NSString stringWithFormat:@"photo%@.png", [[NSDate defaultFormatter] stringFromDate:self]];
}
- (NSString*)audioFileName {
    return [NSString stringWithFormat:@"audio%@.aac", [[NSDate defaultFormatter] stringFromDate:self]];
}
- (NSString*)videoFileName {
    return [NSString stringWithFormat:@"video%@.m4v", [[NSDate defaultFormatter] stringFromDate:self]];
}

@end
