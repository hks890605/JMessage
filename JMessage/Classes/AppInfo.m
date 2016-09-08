//
//  AppInfo.m
//  JabberClient
//
//  Created by Starlet on 11/6/13.
//
//

#import "AppInfo.h"
#import "SQLiteManager.h"

NSString *const kXMPPmyJID = @"kXMPPmyJID";
NSString *const kXMPPmyPassword = @"kXMPPmyPassword";

#define DBName      @"JMessageDatabase.db"
NSString *const kSenderKey =  @"send_user";
NSString *const kMessageKey =  @"message";
NSString *const kDateKey    = @"msg_date";
NSString *const kChatUserKey = @"chat_user";
NSString *const kMessageTypeKey = @"message_type";
NSString *const kMessageReadKey = @"message_read";

@interface AppInfo()
@property (strong, nonatomic) SQLiteManager *dbManager;

@end

@implementation AppInfo
@synthesize dbManager;

+ (AppInfo*)sharedInfo {
    static AppInfo *sAppInfo = nil;
    if (sAppInfo == nil)
        sAppInfo = [AppInfo new];
    return sAppInfo;
}

+ (BOOL)isBeforeIOS70 {
    NSString* reqSysVer = @"7.0";
    NSString* sysVer = [[UIDevice currentDevice] systemVersion];
    if ([sysVer compare:reqSysVer options:NSNumericSearch] == NSOrderedAscending)
        return YES;
    return NO;
}

- (id)init {
    self = [super init];
    if (self) {
        [self openDB];
    }
    return self;
}

- (void)dealloc {
    [self.dbManager closeDatabase];
    self.dbManager = nil;
    //[super dealloc];
}

- (NSString*)databasePath {
    // Get the documents directory
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];
    
    NSString* path = [docsDir stringByAppendingPathComponent:DBName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
        return path;
    }
    return nil;
}

- (void)openDB {
    NSString* dbPath = [self databasePath];
    
    if (dbPath) {
        self.dbManager = [[SQLiteManager alloc] initWithDatabaseNamed:dbPath];
    }
    
    if (self.dbManager == nil) {
        self.dbManager = [[SQLiteManager alloc] initWithDatabaseNamed:DBName];
    }
    [self addTable];
}

- (void) addTable {
	NSError *error = [dbManager doQuery:@"CREATE TABLE IF NOT EXISTS messages (id integer primary key autoincrement, current_user text, send_user text, receive_user text, message text, msg_date datetime, message_type integer default '0');"];
	if (error != nil) {
		//NSLog(@"Error: %@",[error localizedDescription]);
	}
#if 1
    [dbManager getColumeInfo:@"select * from messages"];
    if (![dbManager.columnArray containsObject:@"message_read"]) {
        error = [dbManager doQuery:@"ALTER TABLE messages ADD message_read integer default 0;"];
        if (error != nil) {
            //NSLog(@"Error: %@",[error localizedDescription]);
        }
    }
//    NSString *dump = [dbManager getDatabaseDump];
//    NSLog(dump);
#endif
    NSString* dbPath = [self databasePath];
    if (dbPath) {
        NSDictionary* permission = [NSDictionary dictionaryWithObjectsAndKeys:NSFileProtectionNone, NSFileProtectionKey, [NSNumber numberWithInteger:0x1FF], NSFilePosixPermissions, nil];
        NSError* error = nil;
        [[NSFileManager defaultManager] setAttributes:permission ofItemAtPath:dbPath error:&error];
    }
}

- (NSString*)currentUser {
    NSString* userID = [[NSUserDefaults standardUserDefaults] objectForKey:kXMPPmyJID];
    return userID;
}

- (BOOL) addMessage:(NSString*)message from:(NSString*)sender to:(NSString*)receiver date:(NSDate*)date {
    static NSDateFormatter* dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    NSString *dateStr = [dateFormatter stringFromDate:date];
    
    message = [message stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
    //This message is send by me, read flag is yes.
    NSInteger nRead = ([sender isEqualToString:self.currentUser] ? 1 : 0);
    
	NSString *sqlStr = [NSString stringWithFormat:@"insert into messages (current_user, send_user, receive_user, message, msg_date, message_type, message_read) values ('%@','%@','%@','%@','%@',%d, %d);", self.currentUser, sender, receiver, message, dateStr, MessageType_String, nRead];
	NSError *error = [dbManager doQuery:sqlStr];
	if (error != nil) {
		NSLog(@"Error: %@",[error localizedDescription]);
        return NO;
	}
//    NSString *dump = [dbManager getDatabaseDump];
//    NSLog(dump);
    return YES;
}

+ (void)createDirectoryAtPath:(NSString*)folderPath {
//    BOOL isDir = NO, isExist = NO;
    NSError *err = nil;
//    if ((isExist = [[NSFileManager defaultManager] fileExistsAtPath:folderPath isDirectory:&isDir]) && isDir == NO) {
//        [[NSFileManager defaultManager] removeItemAtPath:folderPath error:&err];
//        isExist = NO;
//    }
//    
//    if (isExist == NO) {
        NSDictionary* permission = [NSDictionary dictionaryWithObjectsAndKeys:NSFileProtectionNone, NSFileProtectionKey, [NSNumber numberWithInteger:0x1FF], NSFilePosixPermissions, nil];
        [[NSFileManager defaultManager] createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:permission error:&err];
//    }
}

+ (NSString*)fileDirectoryPathWithFileType:(MessageType)fileType user:(NSString*)userName {
    NSString* folderName = @"";
    if (fileType == MessageType_Photo)
        folderName = @"Photo";
    else if (fileType == MessageType_Audio)
        folderName = @"Audio";
    else if (fileType == MessageType_Video)
        folderName = @"Video";
    
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = [dirPaths objectAtIndex:0];

    if (!userName.isNotEmpty)
        return docsDir;

    NSString* folderPath = [docsDir stringByAppendingPathComponent:userName];
    folderPath = [folderPath stringByAppendingPathComponent:folderName];
    
    [AppInfo createDirectoryAtPath:folderPath];
    
    return folderPath;
}

+ (NSString*)tempFilePathWithFileType:(MessageType)nType filename:(NSString*)fileName {
    if (fileName.length < 1) {
        if (nType == MessageType_Photo)
            fileName = @"tempPhoto";
        else if (nType == MessageType_Audio)
            fileName = @"tempAudio";
        else if (nType == MessageType_Video)
            fileName = @"tempVideo";
        else
            fileName = @"temp";
    }
    
    NSString* filext = @"";
    if (nType == MessageType_Photo)
        filext = @"png";
    else if (nType == MessageType_Audio)
        filext = @"aac";
    else if (nType == MessageType_Video)
        filext = @"mp4";

    fileName = [fileName stringByAppendingPathExtension:filext];
    
    NSString* folderPath = [AppInfo fileDirectoryPathWithFileType:nType user:nil];
    NSString* filePath = [folderPath stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError* error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    }
    return filePath;
}

+ (NSString*)filePathWithFileType:(MessageType)nType user:(NSString*)userName filename:(NSString*)fileName {
    if (fileName.length < 1) {
        if (nType == MessageType_Photo)
            fileName = [NSDate photoFileNameFromDate];
        else if (nType == MessageType_Audio)
            fileName = [NSDate audioFileNameFromDate];
        else if (nType == MessageType_Video)
            fileName = [NSDate videoFileNameFromDate];
        else
            fileName = @"test.test";
    }

    NSString* filext = [fileName pathExtension];
    if (filext.length < 1) {
        if (nType == MessageType_Photo)
            filext = @"png";
        else if (nType == MessageType_Audio)
            filext = @"aac";
        else if (nType == MessageType_Video)
            filext = @"mp4";
        fileName = [fileName stringByAppendingPathExtension:filext];
    }
    
    NSString* folderPath = [AppInfo fileDirectoryPathWithFileType:nType user:userName];
    NSString* filePath = [folderPath stringByAppendingPathComponent:fileName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        filePath = [filePath stringByDeletingPathExtension];
        filePath = [filePath stringByAppendingString:[NSDate fileNameFromDate]];
        filePath = [filePath stringByAppendingPathExtension:filext];
    }
    return filePath;
}

+ (NSString*)writeFileData:(NSData*)data withType:(MessageType)nType user:(NSString*)userName filename:(NSString*)fileName {
    NSString *filePath = [AppInfo filePathWithFileType:nType user:userName filename:fileName];
    NSError* err = nil;
    BOOL isSuccess = [data writeToFile:filePath options:NSDataWritingAtomic error:&err];
    if (isSuccess == NO) {
        NSLog(@"Write file fail.(%@)", [err description]);
        return nil;
    }
    return filePath;
}

- (BOOL)addFileData:(NSData*)fileData fileType:(MessageType)nType filename:(NSString*)fileName from:(NSString*)sender to:(NSString*)receiver date:(NSDate*)date {
    if (fileName.length < 1) {
        if (nType == MessageType_Photo)
            fileName = [date photoFileName];
        else if (nType == MessageType_Audio)
            fileName = [date audioFileName];
        else if (nType == MessageType_Video)
            fileName = [date videoFileName];
        else
            fileName = @"test";
    }

    NSString* filePath = [AppInfo writeFileData:fileData withType:nType user:sender filename:fileName];
    if (filePath == nil)
        return NO;
    return [self addFileWithType:nType filePath:filePath from:sender to:receiver date:date];
}

- (BOOL)addFileWithType:(MessageType)nType filePath:(NSString*)filePath from:(NSString*)sender to:(NSString*)receiver date:(NSDate*)date {
    filePath = [filePath stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    
    static NSDateFormatter* dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    }
    NSString *dateStr = [dateFormatter stringFromDate:date];
    
    //This message is send by me, read flag is yes.
    NSInteger nRead = ([sender isEqualToString:self.currentUser] ? 1 : 0);
    
	NSString *sqlStr = [NSString stringWithFormat:@"insert into messages (current_user, send_user, receive_user, message, msg_date, message_type, message_read) values ('%@','%@','%@','%@','%@', %d, %d);", self.currentUser, sender, receiver, filePath, dateStr, nType, nRead];
	NSError *error = [dbManager doQuery:sqlStr];
	if (error != nil) {
		NSLog(@"Error: %@",[error localizedDescription]);
        return NO;
	}
    //    NSString *dump = [dbManager getDatabaseDump];
    //    NSLog(dump);
    return YES;
}

- (NSDictionary*)lastMessageWith:(NSString*)contactID {
	NSString *sqlStr = [NSString stringWithFormat:@"select * from messages where current_user='%@' AND ((send_user='%@' AND receive_user='%@') OR (send_user='%@' AND receive_user='%@')) order by msg_date DESC, id DESC;", self.currentUser, self.currentUser, contactID, contactID, self.currentUser];

    NSArray* results = [dbManager getRowsForQuery:sqlStr];
    
//    NSString *dump = [dbManager getDatabaseDump];
//    NSLog(dump);

    if (results.count > 0) {
        return results[0];
    }
    
    return nil;
}

- (NSArray*)messageArrayWith:(NSString*)contactID {
    //Read all message
    NSString *sqlStr = [NSString stringWithFormat:@"update messages set message_read = 1 where current_user='%@' AND ((send_user='%@' AND receive_user='%@') OR (send_user='%@' AND receive_user='%@'));", self.currentUser, self.currentUser, contactID, contactID, self.currentUser];
	NSError *error = [dbManager doQuery:sqlStr];
    if (error) {
        NSLog(@"Update read flag Error: %@", error);
    }
    
	sqlStr = [NSString stringWithFormat:@"select * from messages where current_user='%@' AND ((send_user='%@' AND receive_user='%@') OR (send_user='%@' AND receive_user='%@')) order by msg_date ASC;", self.currentUser, self.currentUser, contactID, contactID, self.currentUser];
    
    NSArray* results = [dbManager getRowsForQuery:sqlStr];
    
//    NSString *dump = [dbManager getDatabaseDump];
//    NSLog(dump);

    return results;
}

- (BOOL)deleteMessage:(NSDictionary*)messageInfo {
    NSString *sqlStr = [NSString stringWithFormat:@"delete from messages where id=%d;", [[messageInfo objectForKey:@"id"] intValue]];
    NSError *error = [dbManager doQuery:sqlStr];
	if (error != nil) {
		NSLog(@"Error: %@",[error localizedDescription]);
        return NO;
	}
    return YES;
}

- (NSArray*)sortedUserArrayWithDate {
	NSString *sqlStr = [NSString stringWithFormat:@"select distinct (case when current_user=send_user then receive_user else send_user end) as chat_user, msg_date from messages where current_user='%@' order by msg_date ASC;", self.currentUser];

    NSArray* results = [dbManager getRowsForQuery:sqlStr];
    
    //    NSString *dump = [dbManager getDatabaseDump];
    //    NSLog(dump);
    
    return results;
}

+ (NSArray*) statusArray {
    static NSArray* statusItems = nil;
    if (statusItems == nil) {
        statusItems = @[
                         @{kImageNameKey: @"available", kTitleKey: @"Available", kStatusKey: @"chat"},
                         @{kImageNameKey: @"busy", kTitleKey: @"Busy", kStatusKey: @"away"},
                         @{kImageNameKey: @"dnd", kTitleKey: @"Do not disturb", kStatusKey: @"dnd"},
                         @{kImageNameKey: @"invisible", kTitleKey: @"Invisible", kStatusKey: @"xa"},
                         @{kImageNameKey: @"invisible", kTitleKey: @"Offline", kStatusKey: @"unavailable"}];
    }
    return statusItems;
}

@end
