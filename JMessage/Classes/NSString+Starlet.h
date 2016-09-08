//
//  NSString+Starlet.h
//  Starlet
//
//  Created by Lion User on 20/08/2013.
//  Copyright (c) 2013 Starlet. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma once

@interface NSString (Starlet)

@property (nonatomic, readonly, getter = isNotEmpty) BOOL notEmpty;

-(BOOL)isValidEmail;
-(BOOL)isValidPassword;

-(NSString*)unformattedPhoneNumber;
-(int)unformattedLengthOfPhoneNumber;

- (NSString *)trimWhitespace;
- (NSUInteger)numberOfLines;

+ (NSString*)intString:(NSInteger)intValue;

//string format: "YYYY:MM:DD HH:mm:ss"
- (NSString*)monthDayString;

- (BOOL)stringContainsEmoji;

+ (NSString*)mimeTypeFromUTI:(NSString*)strUTI;
- (NSString*)fileUTIFromExtension;
- (BOOL)isImageFile;
- (BOOL)isAudioFile;
- (BOOL)isVideoFile;

@end

inline BOOL NSStringEmpty(NSString* aString) {
    return !(aString.isNotEmpty);
}

#define L(key) [[NSBundle mainBundle] localizedStringForKey:(key) value:@"" table:nil]
#define LF1(format, value1) [NSString stringWithFormat:L(format), value1]
#define LF2(format, value1, value2) [NSString stringWithFormat:L(format), value1, value2]
#define LF3(format, value1, value2, value3) [NSString stringWithFormat:L(format), value1, value2, value3]
