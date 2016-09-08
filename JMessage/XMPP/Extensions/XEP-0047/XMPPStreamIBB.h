//
//  XMPPStreamIBB.h
//
//
//  Created by  on 3/11/13.
//  Copyright (c) 2013 Starlet. All rights reserved.
//
//  Implementation of http://xmpp.org/extensions/xep-0095.html

#import <Foundation/Foundation.h>
#import "XMPP.h"

typedef enum {
    kXMPPIBBMimeTypeNone,
    kXMPPIBBMimeTypeJPG,
    kXMPPIBBMimeTypePNG,
    kXMPPIBBMimeTypeGIF,
    kXMPPIBBMimeTypeMP4Audio,
    kXMPPIBBMimeTypeMP4Video
} XMPPIBBMimeType;

@interface XMPPStreamIBB : XMPPModule {
}


- (void)initiateIBBFileTransfer:(NSData*)sendData to:(NSString*)toStr fileName:(NSString*)fileName fileType:(XMPPIBBMimeType)fileMimeType;
- (void)receiveDataSuccess;

@end

@protocol XMPPStreamIBBDelegate <NSObject>
@required
- (void)receivedData:(NSString*)fileDataStr from:(NSString*)from filetype:(XMPPIBBMimeType)mimeType fileName:(NSString*)fileName;
@end