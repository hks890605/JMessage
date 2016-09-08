//
//  JSAppDelegate.h
//  JMessage
//
//  Created by Starlet on 11/7/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XMPPFramework.h"
#import "SMMessageDelegate.h"
#import "SMChatDelegate.h"
#import "AppInfo.h"
#import "XMPPStreamIBB.h"

@interface JSAppDelegate : UIResponder <UIApplicationDelegate, XMPPRosterDelegate, XMPPStreamDelegate> {
    XMPPStream *xmppStream;
	XMPPReconnect *xmppReconnect;
    XMPPRoster *xmppRoster;
	XMPPRosterCoreDataStorage *xmppRosterStorage;
    XMPPvCardCoreDataStorage *xmppvCardStorage;
	XMPPvCardTempModule *xmppvCardTempModule;
	XMPPvCardAvatarModule *xmppvCardAvatarModule;
	XMPPCapabilities *xmppCapabilities;
	XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;
    
    XMPPStreamInitiation    *xmppStreamInitiation;
    XMPPSIFileTransfer  *xmppFileTransfer;
    
    XMPPStreamIBB   *xmppStreamIBB;
    
	NSString *password;
	
	BOOL allowSelfSignedCertificates;
	BOOL allowSSLHostNameMismatch;
	
	BOOL isXmppConnected;

	NSMutableArray *turnSockets;
}

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) XMPPStream *xmppStream;
@property (nonatomic, strong, readonly) XMPPReconnect *xmppReconnect;
@property (nonatomic, strong, readonly) XMPPRoster *xmppRoster;
@property (nonatomic, strong, readonly) XMPPRosterCoreDataStorage *xmppRosterStorage;
@property (nonatomic, strong, readonly) XMPPvCardTempModule *xmppvCardTempModule;
@property (nonatomic, strong, readonly) XMPPvCardAvatarModule *xmppvCardAvatarModule;
@property (nonatomic, strong, readonly) XMPPCapabilities *xmppCapabilities;
@property (nonatomic, strong, readonly) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

@property (nonatomic, strong) id<SMMessageDelegate> messageDelegate;
@property (nonatomic, strong) id<SMMessageDelegate> chatDelegate;
@property (nonatomic, readwrite) BOOL loginSuccess;

- (NSManagedObjectContext *)managedObjectContext_roster;
- (NSManagedObjectContext *)managedObjectContext_capabilities;

- (BOOL)connect;
- (void)disconnect;

- (void)goOnline;
- (void)goOffline;

- (void)sendToOtherDevice:(NSData *)fileData receiverJid:(NSString *)receiverJid type:(MessageType)nType filePath:(NSString*)filePath;

@end
