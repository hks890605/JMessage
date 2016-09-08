//
//  XMPPStreamIBB.m
//
//  Created by Starlet on 3/11/13.
//  Copyright (c) 2013 Starlet. All rights reserved.
//

#if ! __has_feature(objc_arc)
#warning This file must be compiled with ARC. Use -fobjc-arc flag (or convert project to ARC).
#endif

#import "XMPPStreamIBB.h"
#import "XMPPLogging.h"
#import "XMPPMessage.h"
#import "NSXMLElement+XMPP.h"
#import "Base64.h"

#if DEBUG
    static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN; // | XMPP_LOG_FLAG_TRACE;
#else
    static const int xmppLogLevel = XMPP_LOG_LEVEL_WARN;
#endif

@interface XMPPStreamIBB ()
@property (strong, nonatomic) NSString* encodedFileData;
@property (strong, nonatomic) NSString* decodedFileData;
@property (strong, nonatomic) NSString* fileRecipient;
@property (strong, nonatomic) NSString* transferUUID;
@property (strong, nonatomic) NSString* senderID;
@property (strong, nonatomic) NSString* recipientID;
@property (strong, nonatomic) NSString* fileName;
@property (readwrite, nonatomic) XMPPIBBMimeType mimeType;

@end

@implementation XMPPStreamIBB

- (id)init {
    return [self initWithDispatchQueue:NULL];
}

- (id)initWithDispatchQueue:(dispatch_queue_t)queue {
	if ((self = [super initWithDispatchQueue:queue])) {
	}
	return self;
}

- (BOOL)activate:(XMPPStream *)aXmppStream {
	if ([super activate:aXmppStream]) {
		return YES;
	}
	return NO;
}

- (void)deactivate {
    XMPPLogTrace();
    
	[super deactivate];
}

- (void)initiateIBBFileTransfer:(NSData*)sendData to:(NSString*)toStr fileName:(NSString*)fileName fileType:(XMPPIBBMimeType)fileMimeType {
    self.encodedFileData = [sendData base64EncodedString];
    self.fileRecipient = toStr;
    
    self.transferUUID = [xmppStream generateUUID];
    
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" elementID:self.transferUUID];
    [iq addAttributeWithName:@"to" stringValue:toStr];
    [iq addAttributeWithName:@"from" stringValue:[[xmppStream myJID] full]];
    
    self.recipientID = [xmppStream generateUUID];
    self.senderID = nil;

    NSXMLElement *open = [NSXMLElement elementWithName:@"open" xmlns:@"http://jabber.org/protocol/ibb"];
    [open addAttributeWithName:@"sid" stringValue:self.recipientID];
    [open addAttributeWithName:@"block-size" stringValue:[NSString stringWithFormat:@"%d", self.encodedFileData.length]];
    [iq addChild:open];

    NSXMLElement *other = [NSXMLElement elementWithName:@"other" xmlns:@"http://jabber.org/protocol/ibb"];
    if (fileMimeType == kXMPPIBBMimeTypePNG || fileMimeType == kXMPPIBBMimeTypePNG || fileMimeType == kXMPPIBBMimeTypeGIF)
        [other addAttributeWithName:@"mime-type" stringValue:@"image/png"];
    else if (fileMimeType == kXMPPIBBMimeTypeMP4Audio)
        [other addAttributeWithName:@"mime-type" stringValue:@"audio/mp4"];
    else if (fileMimeType == kXMPPIBBMimeTypeMP4Video)
        [other addAttributeWithName:@"mime-type" stringValue:@"video/mp4"];
    [other addAttributeWithName:@"name" stringValue:fileName];
    [iq addChild:other];
    
    [xmppStream sendElement:iq];
}

- (BOOL)isSender {
    return (self.recipientID && (self.senderID == nil));
}
- (BOOL)isReceiver {
    return (self.senderID && (self.recipientID == nil));
}

#pragma mark XMPPStream Delegate

// When we receive disco#info, we must advertise what we support.  IM clients like
// Apple's iMessage won't even show you the option to share files if you don't reply
// back with the features below.
- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)inIq
{
    if ([inIq.type isEqualToString:@"result"]) {
        //Sender
        if ([self isSender] && [inIq.fromStr isEqualToString:self.fileRecipient] &&
            [[inIq attributeStringValueForName:@"id"] isEqualToString:self.transferUUID])
        {
            //received - file transfer request, so send file
            [self sendFile:self.fileRecipient];
            return YES;
        }
        //Receiver
        if ([self isReceiver] && [inIq.fromStr isEqualToString:self.fileRecipient] &&
            [[inIq attributeStringValueForName:@"id"] isEqualToString:self.transferUUID])
        {
            self.senderID = nil;

            //closed - file transfer
            return YES;
        }
    } else if ([inIq.type isEqualToString:@"set"]) {
        //Receiver
        NSXMLElement *open = [inIq elementForName:@"open" xmlns:@"http://jabber.org/protocol/ibb"];
        if (open) {
            //accept file transfer request
            self.senderID = [open attributeStringValueForName:@"sid"];
            self.recipientID = nil;

            NSXMLElement *other = [inIq elementForName:@"other" xmlns:@"http://jabber.org/protocol/ibb"];
            if (other) {
                self.fileName = [other attributeStringValueForName:@"name"];

                NSString* filetype = [[other attributeForName:@"mime-type"] stringValue];
                self.mimeType = kXMPPIBBMimeTypeNone;
                if (filetype.length > 0) {
                    if ([@"image/jpg" caseInsensitiveCompare:filetype] == NSOrderedSame || [@"image/jpeg" caseInsensitiveCompare:filetype] == NSOrderedSame)
                        self.mimeType = kXMPPIBBMimeTypeJPG;
                    else if ([@"image/png" caseInsensitiveCompare:filetype] == NSOrderedSame)
                        self.mimeType = kXMPPIBBMimeTypePNG;
                    else if ([@"image/gif" caseInsensitiveCompare:filetype] == NSOrderedSame)
                        self.mimeType = kXMPPIBBMimeTypeGIF;
                    else if ([@"audio/mp4" caseInsensitiveCompare:filetype] == NSOrderedSame)
                        self.mimeType = kXMPPIBBMimeTypeMP4Audio;
                    else if ([@"video/mp4" caseInsensitiveCompare:filetype] == NSOrderedSame)
                        self.mimeType = kXMPPIBBMimeTypeMP4Video;
                }
                if (self.mimeType == kXMPPIBBMimeTypeNone) {
                    NSString* fileUTI = [self.fileName fileUTIFromExtension];
                    if ([fileUTI isImageFile])
                        self.mimeType = kXMPPIBBMimeTypePNG;
                    else if ([fileUTI isAudioFile])
                        self.mimeType = kXMPPIBBMimeTypeMP4Audio;
                    else if ([fileUTI isVideoFile])
                        self.mimeType = kXMPPIBBMimeTypeMP4Video;
                    else //error
                        self.mimeType = kXMPPIBBMimeTypePNG;
                }
            }
            
            XMPPIQ *iq = [XMPPIQ iqWithType:@"result" elementID:[inIq attributeStringValueForName:@"id"]];
            [iq addAttributeWithName:@"to" stringValue:inIq.fromStr];
            [iq addAttributeWithName:@"from" stringValue:inIq.toStr];
            
            [xmppStream sendElement:iq];
            
            return YES;
        }
        
        NSXMLElement *data = [inIq elementForName:@"data" xmlns:@"http://jabber.org/protocol/ibb"];
        if (data) {
            //accept file
            NSString* senderID = [data attributeStringValueForName:@"sid"];
            if ([senderID isEqualToString:self.senderID]) {
                self.fileRecipient = inIq.fromStr;
                self.decodedFileData = [data stringValue];

                [multicastDelegate receivedData:self.decodedFileData from:inIq.fromStr filetype:self.mimeType  fileName:self.fileName];
                return YES;
            }
        }
        //Sender
        NSXMLElement *close = [inIq elementForName:@"close" xmlns:@"http://jabber.org/protocol/ibb"];
        if (close && [[close attributeStringValueForName:@"sid"] isEqualToString:self.recipientID]) {
            //end file transfer
            XMPPIQ *iq = [XMPPIQ iqWithType:@"result" elementID:[inIq attributeStringValueForName:@"id"]];
            [iq addAttributeWithName:@"to" stringValue:inIq.fromStr];
            [iq addAttributeWithName:@"from" stringValue:inIq.toStr];
            
            [xmppStream sendElement:iq];
            
            self.recipientID = nil;
            
            return YES;
        }
    }
    return NO;
}

- (void)sendFile:(NSString*)tostr {
    NSString *uuid = [xmppStream generateUUID];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" elementID:uuid];
    [iq addAttributeWithName:@"to" stringValue:self.fileRecipient];
    [iq addAttributeWithName:@"from" stringValue:[[xmppStream myJID] full]];
    
    NSXMLElement *data = [NSXMLElement elementWithName:@"data" xmlns:@"http://jabber.org/protocol/ibb"];
    [data addAttributeWithName:@"sid" stringValue:self.recipientID];
    [data addAttributeWithName:@"seq" stringValue:@"0"];
    [data setStringValue:self.encodedFileData];
    [iq addChild:data];
    
    [xmppStream sendElement:iq];

    self.encodedFileData = nil;
}

- (void)receiveDataSuccess {
    self.transferUUID = [xmppStream generateUUID];
    XMPPIQ *iq = [XMPPIQ iqWithType:@"set" elementID:self.transferUUID];
    [iq addAttributeWithName:@"to" stringValue:self.fileRecipient];
    [iq addAttributeWithName:@"from" stringValue:[[xmppStream myJID] full]];
    
    NSXMLElement *close = [NSXMLElement elementWithName:@"close" xmlns:@"http://jabber.org/protocol/ibb"];
    [close addAttributeWithName:@"sid" stringValue:self.senderID];
    [iq addChild:close];
    
    [xmppStream sendElement:iq];
    
    self.decodedFileData = nil;
    self.fileName = nil;
    self.mimeType = kXMPPIBBMimeTypeNone;
}

@end
