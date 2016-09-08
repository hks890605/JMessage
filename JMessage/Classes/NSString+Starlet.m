//
//  NSString+Starlet.m
//  Starlet
//
//  Created by Lion User on 20/08/2013.
//  Copyright (c) 2013 Starlet. All rights reserved.
//

#import "NSString+Starlet.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation NSString (Starlet)

- (BOOL)isNotEmpty {
    return (((NSInteger)self.length) > 0) ? YES : NO;
}

-(BOOL)isValidEmail
{
    if (self.length < 1)
        return NO;
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

-(BOOL)isValidPassword {
    if (self.length < 1)
        return NO;
    NSString *laxString = @"[A-Za-z0-9]{8}[A-Za-z0-9]*";
    NSPredicate *passwordTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", laxString];
    return [passwordTest evaluateWithObject:self];
}

-(NSString*)unformattedPhoneNumber {
    NSString* mobileNumber;
    mobileNumber = [self stringByReplacingOccurrencesOfString:@"(" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
//    int length = [mobileNumber length];
//    if(length > 10)
//    {
//        mobileNumber = [mobileNumber substringFromIndex: length - 10];
//    }
    
    return mobileNumber;
}

-(int)unformattedLengthOfPhoneNumber {
    NSString* mobileNumber;
    mobileNumber = [self stringByReplacingOccurrencesOfString:@"(" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@")" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@" " withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"-" withString:@""];
    mobileNumber = [mobileNumber stringByReplacingOccurrencesOfString:@"+" withString:@""];
    
    int length = [mobileNumber length];
    
    return length;
}

- (NSString *)trimWhitespace
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSUInteger)numberOfLines
{
    return [self componentsSeparatedByString:@"\n"].count + 1;
}

+ (NSString*)intString:(NSInteger)intValue {
    return [NSString stringWithFormat:@"%d", intValue];
}

- (NSString*)monthDayString {
    static NSDateFormatter *inputDF = nil;
    static NSDateFormatter *outDF = nil;
    if (inputDF == nil) {
        inputDF = [NSDateFormatter new];
        [inputDF setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    if (outDF == nil) {
        outDF = [NSDateFormatter new];
        [outDF setDateFormat:@"MM.dd"];
    }
    
    NSDate* date = [inputDF dateFromString:self];
    return [outDF stringFromDate:date];
}

- (BOOL)stringContainsEmoji {
    __block BOOL returnValue = NO;
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByComposedCharacterSequences usingBlock:
     ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
         
         const unichar hs = [substring characterAtIndex:0];
         // surrogate pair
         if (0xd800 <= hs && hs <= 0xdbff) {
             if (substring.length > 1) {
                 const unichar ls = [substring characterAtIndex:1];
                 const int uc = ((hs - 0xd800) * 0x400) + (ls - 0xdc00) + 0x10000;
                 if (0x1d000 <= uc && uc <= 0x1f77f) {
                     returnValue = YES;
                 }
             }
         } else if (substring.length > 1) {
             const unichar ls = [substring characterAtIndex:1];
             if (ls == 0x20e3) {
                 returnValue = YES;
             }
             
         } else {
             // non surrogate
             if (0x2100 <= hs && hs <= 0x27ff) {
                 returnValue = YES;
             } else if (0x2B05 <= hs && hs <= 0x2b07) {
                 returnValue = YES;
             } else if (0x2934 <= hs && hs <= 0x2935) {
                 returnValue = YES;
             } else if (0x3297 <= hs && hs <= 0x3299) {
                 returnValue = YES;
             } else if (hs == 0xa9 || hs == 0xae || hs == 0x303d || hs == 0x3030 || hs == 0x2b55 || hs == 0x2b1c || hs == 0x2b1b || hs == 0x2b50) {
                 returnValue = YES;
             }
         }
     }];
    
    return returnValue;
}

+ (NSString*)mimeTypeFromUTI:(NSString*)strUTI {
    NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)strUTI, kUTTagClassMIMEType);
    return mimeType;
}

- (NSString*)fileUTIFromExtension {
    // Get the UTI from the file's extension:
    CFStringRef pathExtension = (__bridge CFStringRef)[self pathExtension];
    CFStringRef utiType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
    return (__bridge NSString*) utiType;
}

- (BOOL)isImageFile {
    return UTTypeConformsTo((__bridge CFStringRef)self, kUTTypeImage);
}
- (BOOL)isAudioFile {
    return UTTypeConformsTo((__bridge CFStringRef)self, kUTTypeAudio);
}
- (BOOL)isVideoFile {
    return UTTypeConformsTo((__bridge CFStringRef)self, kUTTypeVideo);
}

@end
