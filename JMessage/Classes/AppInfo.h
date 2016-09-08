//
//  AppInfo.h
//  JabberClient
//
//  Created by Starlet on 11/6/13.
//
//

#import <Foundation/Foundation.h>

extern NSString *const kXMPPmyJID;
extern NSString *const kXMPPmyPassword;

extern NSString *const kSenderKey;
extern NSString *const kMessageKey;
extern NSString *const kDateKey;
extern NSString *const kChatUserKey;
extern NSString *const kMessageTypeKey;
extern NSString *const kMessageReadKey;

//for status
#define kImageNameKey   @"ImageNameKey"
#define kTitleKey   @"TitleKey"
#define kStatusKey  @"StatusKey"

typedef enum
{
    MessageType_String = 0,
    MessageType_Photo,
    MessageType_Audio,
    MessageType_Video
} MessageType;

@interface AppInfo : NSObject

+ (AppInfo*)sharedInfo;
+ (NSString*)tempFilePathWithFileType:(MessageType)nType filename:(NSString*)fileName;
+ (NSString*)filePathWithFileType:(MessageType)nType user:(NSString*)userName filename:(NSString*)fileName;
+ (NSString*)writeFileData:(NSData*)data withType:(MessageType)nType user:(NSString*)userName filename:(NSString*)fileName;

+ (BOOL)isBeforeIOS70;

- (NSString*)currentUser;
- (BOOL)addMessage:(NSString*)message from:(NSString*)sender to:(NSString*)receiver date:(NSDate*)date;
- (BOOL)addFileData:(NSData*)fileData fileType:(MessageType)nType filename:(NSString*)fileName from:(NSString*)sender to:(NSString*)receiver date:(NSDate*)date;
- (BOOL)addFileWithType:(MessageType)nType filePath:(NSString*)filePath from:(NSString*)sender to:(NSString*)receiver date:(NSDate*)date;
- (NSDictionary*)lastMessageWith:(NSString*)contactID;
- (NSArray*)messageArrayWith:(NSString*)contactID;
- (BOOL)deleteMessage:(NSDictionary*)messageInfo;
- (NSArray*)sortedUserArrayWithDate;

+ (NSArray*) statusArray;

@end
