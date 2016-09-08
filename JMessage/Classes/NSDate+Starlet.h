//
//  NSDate+Starlet.h
//  JMessage
//
//  Created by Starlet on 12/1/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Starlet)

+ (NSString*)fileNameFromDate;
+ (NSString*)photoFileNameFromDate;
+ (NSString*)audioFileNameFromDate;
+ (NSString*)videoFileNameFromDate;

- (NSString*)photoFileName;
- (NSString*)audioFileName;
- (NSString*)videoFileName;

@end
