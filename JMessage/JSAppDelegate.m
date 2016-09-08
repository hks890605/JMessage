//
//  JSAppDelegate.m
//  JMessage
//
//  Created by Starlet on 11/7/13.
//  Copyright (c) 2013 SM. All rights reserved.
//

#import "JSAppDelegate.h"
#import <CFNetwork/CFNetwork.h>

#import "XMPPFramework.h"
#import "TURNSocket.h"
#import "DDLog.h"
#import "DDTTYLogger.h"
#import "XMPPMessage+XEP_0172.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
//static const int ddLogLevel = LOG_LEVEL_OFF;

#import "Base64.h"

@interface JSAppDelegate()

@property (strong, nonatomic) UINavigationController *navigationController;
@property (readwrite, nonatomic) UIBackgroundTaskIdentifier    bgTask;

- (void)setupStream;
- (void)teardownStream;

- (void)goOnline;
- (void)goOffline;

@end

@implementation JSAppDelegate

@synthesize xmppStream;
@synthesize xmppReconnect;
@synthesize xmppRoster;
@synthesize xmppRosterStorage;
@synthesize xmppvCardTempModule;
@synthesize xmppvCardAvatarModule;
@synthesize xmppCapabilities;
@synthesize xmppCapabilitiesStorage;

@synthesize window, navigationController, chatDelegate, messageDelegate;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //MY.Log
    [DDLog addLogger:[DDTTYLogger sharedInstance]];

    // Override point for customization after application launch.
    self.loginSuccess = YES;
    [AppInfo sharedInfo];
    
    // Setup the XMPP stream
    turnSockets = [[NSMutableArray alloc] init];
	[self setupStream];

    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor blackColor], UITextAttributeTextColor,
      [UIFont boldSystemFontOfSize:17], UITextAttributeFont,
      [UIColor lightGrayColor], UITextAttributeTextShadowColor,
      [NSValue valueWithUIOffset: UIOffsetMake(0, 0)], UITextAttributeTextShadowOffset,
      nil]];

	// Setup the view controllers
//    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:[[NSBundle mainBundle].infoDictionary objectForKey:@"UIMainStoryboardFile"] bundle:[NSBundle mainBundle]];
//    self.navigationController = [storyboard instantiateViewControllerWithIdentifier:@"SID_MainNav"];
//
//	[window setRootViewController:navigationController];
//	[window makeKeyAndVisible];
    
	if (![self connect])
	{
//		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.0 * NSEC_PER_SEC);
//		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//			[self.navigationController performSegueWithIdentifier:@"SegueID_ToSetting" sender:self.navigationController];
//		});
        self.loginSuccess = NO;
	}

    //DEL.MY
//    __block JSAppDelegate* dp = self;
//    self.bgTask = [application beginBackgroundTaskWithExpirationHandler:^{
//        NSLog(@"exipiration handler triggered");
//        [[UIApplication sharedApplication] endBackgroundTask:dp.bgTask];
//        dp.bgTask = UIBackgroundTaskInvalid;
//    }];
    
    return YES;
}

- (void)dealloc
{
	[self teardownStream];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Core Data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSManagedObjectContext *)managedObjectContext_roster
{
	return [xmppRosterStorage mainThreadManagedObjectContext];
}

- (NSManagedObjectContext *)managedObjectContext_capabilities
{
	return [xmppCapabilitiesStorage mainThreadManagedObjectContext];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Private
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)setupStream
{
	NSAssert(xmppStream == nil, @"Method setupStream invoked multiple times");
	
	// Setup xmpp stream
	//
	// The XMPPStream is the base class for all activity.
	// Everything else plugs into the xmppStream, such as modules/extensions and delegates.
    
	xmppStream = [[XMPPStream alloc] init];
	
#if !TARGET_IPHONE_SIMULATOR
	{
		// Want xmpp to run in the background?
		//
		// P.S. - The simulator doesn't support backgrounding yet.
		//        When you try to set the associated property on the simulator, it simply fails.
		//        And when you background an app on the simulator,
		//        it just queues network traffic til the app is foregrounded again.
		//        We are patiently waiting for a fix from Apple.
		//        If you do enableBackgroundingOnSocket on the simulator,
		//        you will simply see an error message from the xmpp stack when it fails to set the property.
		
		xmppStream.enableBackgroundingOnSocket = YES;
	}
#endif
	
	// Setup reconnect
	//
	// The XMPPReconnect module monitors for "accidental disconnections" and
	// automatically reconnects the stream for you.
	// There's a bunch more information in the XMPPReconnect header file.
	
	xmppReconnect = [[XMPPReconnect alloc] init];
	
	// Setup roster
	//
	// The XMPPRoster handles the xmpp protocol stuff related to the roster.
	// The storage for the roster is abstracted.
	// So you can use any storage mechanism you want.
	// You can store it all in memory, or use core data and store it on disk, or use core data with an in-memory store,
	// or setup your own using raw SQLite, or create your own storage mechanism.
	// You can do it however you like! It's your application.
	// But you do need to provide the roster with some storage facility.
	
	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] init];
    //	xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc] initWithInMemoryStore];
	
	xmppRoster = [[XMPPRoster alloc] initWithRosterStorage:xmppRosterStorage];
	
	xmppRoster.autoFetchRoster = YES;
	xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;

	// Setup vCard support
	//
	// The vCard Avatar module works in conjuction with the standard vCard Temp module to download user avatars.
	// The XMPPRoster will automatically integrate with XMPPvCardAvatarModule to cache roster photos in the roster.
	
	xmppvCardStorage = [XMPPvCardCoreDataStorage sharedInstance];
	xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:xmppvCardStorage];
	
	xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:xmppvCardTempModule];
	
	// Setup capabilities
	//
	// The XMPPCapabilities module handles all the complex hashing of the caps protocol (XEP-0115).
	// Basically, when other clients broadcast their presence on the network
	// they include information about what capabilities their client supports (audio, video, file transfer, etc).
	// But as you can imagine, this list starts to get pretty big.
	// This is where the hashing stuff comes into play.
	// Most people running the same version of the same client are going to have the same list of capabilities.
	// So the protocol defines a standardized way to hash the list of capabilities.
	// Clients then broadcast the tiny hash instead of the big list.
	// The XMPPCapabilities protocol automatically handles figuring out what these hashes mean,
	// and also persistently storing the hashes so lookups aren't needed in the future.
	//
	// Similarly to the roster, the storage of the module is abstracted.
	// You are strongly encouraged to persist caps information across sessions.
	//
	// The XMPPCapabilitiesCoreDataStorage is an ideal solution.
	// It can also be shared amongst multiple streams to further reduce hash lookups.
	
//	xmppCapabilitiesStorage = [XMPPCapabilitiesCoreDataStorage sharedInstance];
//    xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:xmppCapabilitiesStorage];
//    
//    xmppCapabilities.autoFetchHashedCapabilities = YES;
//    xmppCapabilities.autoFetchNonHashedCapabilities = NO;

    //ADD.MY
    xmppStreamInitiation = [[XMPPStreamInitiation alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    xmppFileTransfer = [[XMPPSIFileTransfer alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    
    xmppStreamIBB = [[XMPPStreamIBB alloc] initWithDispatchQueue:dispatch_get_main_queue()];

	// Activate xmpp modules
    
	[xmppReconnect         activate:xmppStream];
	[xmppRoster            activate:xmppStream];
	[xmppvCardTempModule   activate:xmppStream];
	[xmppvCardAvatarModule activate:xmppStream];
	[xmppCapabilities      activate:xmppStream];

    //ADD.MY
    [xmppStreamInitiation activate:xmppStream];
    [xmppFileTransfer activate:xmppStream];
    [xmppStreamIBB activate:xmppStream];

	// Add ourself as a delegate to anything we may be interested in
    
	[xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
	[xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    //ADD.MY
    [xmppFileTransfer addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [xmppStreamIBB addDelegate:self delegateQueue:dispatch_get_current_queue()];

	// Optional:
	//
	// Replace me with the proper domain and port.
	// The example below is setup for a typical google talk account.
	//
	// If you don't supply a hostName, then it will be automatically resolved using the JID (below).
	// For example, if you supply a JID like 'user@quack.com/rsrc'
	// then the xmpp framework will follow the xmpp specification, and do a SRV lookup for quack.com.
	//
	// If you don't specify a hostPort, then the default (5222) will be used.
	
    //	[xmppStream setHostName:@"talk.google.com"];
    //	[xmppStream setHostPort:5222];
	
    
	// You may need to alter these settings depending on the server you're connecting to
	allowSelfSignedCertificates = NO;
	allowSSLHostNameMismatch = NO;
}

- (void)teardownStream
{
	[xmppStream removeDelegate:self];
	[xmppRoster removeDelegate:self];
	
	[xmppReconnect         deactivate];
	[xmppRoster            deactivate];
	[xmppvCardTempModule   deactivate];
	[xmppvCardAvatarModule deactivate];
	[xmppCapabilities      deactivate];
    
    [xmppStreamIBB removeDelegate:self];
    [xmppStreamIBB deactivate];
    
    [xmppFileTransfer removeDelegate:self];
    [xmppStreamInitiation deactivate];
    [xmppFileTransfer deactivate];
	
	[xmppStream disconnect];
	
	xmppStream = nil;
	xmppReconnect = nil;
    xmppRoster = nil;
	xmppRosterStorage = nil;
	xmppvCardStorage = nil;
    xmppvCardTempModule = nil;
	xmppvCardAvatarModule = nil;
	xmppCapabilities = nil;
	xmppCapabilitiesStorage = nil;
}

// It's easy to create XML elments to send and to read received XML elements.
// You have the entire NSXMLElement and NSXMLNode API's.
//
// In addition to this, the NSXMLElement+XMPP category provides some very handy methods for working with XMPP.
//
// On the iPhone, Apple chose not to include the full NSXML suite.
// No problem - we use the KissXML library as a drop in replacement.
//
// For more information on working with XML elements, see the Wiki article:
// https://github.com/robbiehanson/XMPPFramework/wiki/WorkingWithElements

- (void)goOnline
{
	XMPPPresence *presence = [XMPPPresence presence]; // type="available" is implicit
	
	[[self xmppStream] sendElement:presence];
}

- (void)goOffline
{
	XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
	
	[[self xmppStream] sendElement:presence];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Connect/disconnect
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//ADD.MY
#include <ifaddrs.h>
#include <arpa/inet.h>

// Get IP Address
- (NSString *)getIPAddress {
    NSString *address = @"";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

- (BOOL)connect
{
	if (![xmppStream isDisconnected]) {
		return YES;
	}
    
	NSString *myJID = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyJID];
	NSString *myPassword = [[NSUserDefaults standardUserDefaults] stringForKey:kXMPPmyPassword];
    
	//
	// If you don't want to use the Settings view to set the JID,
	// uncomment the section below to hard code a JID and password.
	//
	// myJID = @"user@gmail.com/xmppframework";
	// myPassword = @"";
	
	if (myJID == nil || myPassword == nil) {
		return NO;
	}
    
    NSString *resource = @"iosuser";

	[xmppStream setMyJID:[XMPPJID jidWithString:myJID resource:resource]];
	password = myPassword;

//    xmppStream.hostName = @"im.sopranodesign.com";
//    xmppStream.hostPort = 3478;
    
	NSError *error = nil;
	if (![xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error])
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error connecting"
		                                                    message:@"See console for error details."
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Ok"
		                                          otherButtonTitles:nil];
		[alertView show];
        
		DDLogError(@"Error connecting: %@", error);
        
		return NO;
	}
    
	return YES;
}

- (void)disconnect
{
	[self goOffline];
	[xmppStream disconnect];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
#if TARGET_IPHONE_SIMULATOR
	DDLogError(@"The iPhone simulator does not process background network traffic. "
			   @"Inbound traffic is queued until the keepAliveTimeout:handler: fires.");
#endif
    
    __block JSAppDelegate* dp = self;
    if ([application respondsToSelector:@selector(setKeepAliveTimeout:handler:)])
	{
		[application setKeepAliveTimeout:600 handler:^{
			
			DDLogVerbose(@"KeepAliveHandler");
			
			// Do other keep alive stuff here.
            [dp goOnline];
		}];
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPStream Delegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    //MY ADDRESS
    //socket.localHost;
    //socket.localPort;
    
#if 0 // old XMPP version
    CFReadStreamSetProperty([socket readStream], kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
    CFWriteStreamSetProperty([socket writeStream], kCFStreamNetworkServiceType, kCFStreamNetworkServiceTypeVoIP);
#else
    // Tell the socket to stay around if the app goes to the background (only works on apps with the VoIP background flag set)
    [socket performBlock:^{
        [socket enableBackgroundingOnSocket];
    }];
#endif
}

- (void)xmppStream:(XMPPStream *)sender willSecureWithSettings:(NSMutableDictionary *)settings
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (allowSelfSignedCertificates)
	{
		[settings setObject:[NSNumber numberWithBool:YES] forKey:(NSString *)kCFStreamSSLAllowsAnyRoot];
	}
	
	if (allowSSLHostNameMismatch)
	{
		[settings setObject:[NSNull null] forKey:(NSString *)kCFStreamSSLPeerName];
	}
	else
	{
		// Google does things incorrectly (does not conform to RFC).
		// Because so many people ask questions about this (assume xmpp framework is broken),
		// I've explicitly added code that shows how other xmpp clients "do the right thing"
		// when connecting to a google server (gmail, or google apps for domains).
		
		NSString *expectedCertName = nil;
		
		NSString *serverDomain = xmppStream.hostName;
		NSString *virtualDomain = [xmppStream.myJID domain];
		
		if ([serverDomain isEqualToString:@"talk.google.com"])
		{
			if ([virtualDomain isEqualToString:@"gmail.com"])
			{
				expectedCertName = virtualDomain;
			}
			else
			{
				expectedCertName = serverDomain;
			}
		}
		else if (serverDomain == nil)
		{
			expectedCertName = virtualDomain;
		}
		else
		{
			expectedCertName = serverDomain;
		}
		
		if (expectedCertName)
		{
			[settings setObject:expectedCertName forKey:(NSString *)kCFStreamSSLPeerName];
		}
	}
}

- (void)xmppStreamDidSecure:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	isXmppConnected = YES;
	
	NSError *error = nil;
	
	if (![[self xmppStream] authenticateWithPassword:password error:&error])
	{
		DDLogError(@"Error authenticating: %@", error);
	}
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	[self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(NSXMLElement *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

#pragma mark -

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
    
	// A simple example of inbound message handling.
    
	if ([message isMessageWithBody]) //isChatMessageWithBody])
	{
		XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[message from]
		                                                         xmppStream:xmppStream
		                                               managedObjectContext:[self managedObjectContext_roster]];
		if (user == nil) {
            NSString* nickName = message.nick;
            if (!nickName.isNotEmpty)
                nickName = message.from.user;
            [xmppRoster addUser:message.from withNickname:nickName];
        }
        
        //ADD.MY.0107
        __block XMPPMessage* dbMessage = [message copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            [[AppInfo sharedInfo] addMessage:dbMessage.body from:dbMessage.from.bare to:dbMessage.to.bare date:[NSDate date]];

            if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(newMessageReceived:)]) {
                NSDictionary* lastMessage = [[AppInfo sharedInfo] lastMessageWith:message.from.bare];
                [messageDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
            }
            if (self.chatDelegate && [self.chatDelegate respondsToSelector:@selector(newMessageReceived:)] && [self.chatDelegate respondsToSelector:@selector(chatUserName)])
            {
                NSString * chatUserName = [self.chatDelegate chatUserName];
                if ([chatUserName isEqualToString:message.from.bare]) {
                    NSDictionary* lastMessage = [[AppInfo sharedInfo] lastMessageWith:message.from.bare];
                    [chatDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
                }
            }
        });

        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
		{
            NSString *body = [[message elementForName:@"body"] stringValue];
            NSString *displayName = (user ? [user displayName] : message.fromStr);
			// We are not active, so use a local notification instead
			UILocalNotification *localNotification = [[UILocalNotification alloc] init];
			localNotification.alertAction = @"Ok";
			localNotification.alertBody = [NSString stringWithFormat:@"From: %@\n\n%@", displayName, body];
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
			[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
		}
	}
}

- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@ - %@", THIS_FILE, THIS_METHOD, [presence fromStr]);
}

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	if (!isXmppConnected)
	{
		DDLogError(@"Unable to connect to server. Check xmppStream.hostName");
	}
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XMPPRosterDelegate
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)xmppRoster:(XMPPRoster *)sender didReceiveBuddyRequest:(XMPPPresence *)presence
{
	DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);
	
	XMPPUserCoreDataStorageObject *user = [xmppRosterStorage userForJID:[presence from]
	                                                         xmppStream:xmppStream
	                                               managedObjectContext:[self managedObjectContext_roster]];
	
	NSString *displayName = [user displayName];
	NSString *jidStrBare = [presence fromStr];
	NSString *body = nil;
	
	if (![displayName isEqualToString:jidStrBare])
	{
		body = [NSString stringWithFormat:@"Buddy request from %@ <%@>", displayName, jidStrBare];
	}
	else
	{
		body = [NSString stringWithFormat:@"Buddy request from %@", displayName];
	}
	
	
	if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
	{
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:displayName
		                                                    message:body
		                                                   delegate:nil
		                                          cancelButtonTitle:@"Not implemented"
		                                          otherButtonTitles:nil];
		[alertView show];
	}
	else
	{
		// We are not active, so use a local notification instead
		UILocalNotification *localNotification = [[UILocalNotification alloc] init];
		localNotification.alertAction = @"Not implemented";
		localNotification.alertBody = body;
		
		[[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
	}
}

#pragma mark -

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
    if (message.isChatMessageWithBody) {
        
        //ADD.MY.0107
        dispatch_async(dispatch_get_main_queue(), ^{
            BOOL isSuccess = [[AppInfo sharedInfo] addMessage:message.body from:sender.myJID.bare to:message.toStr date:[NSDate date]];
            
            if (isSuccess && self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(newMessageReceived:)]) {
                NSDictionary* lastMessage = [[AppInfo sharedInfo] lastMessageWith:message.from.bare];
                [messageDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
            }
            if (isSuccess && self.chatDelegate && [self.chatDelegate respondsToSelector:@selector(newMessageReceived:)] && [self.chatDelegate respondsToSelector:@selector(chatUserName)])
            {
                NSString * chatUserName = [self.chatDelegate chatUserName];
                if ([chatUserName isEqualToString:message.toStr]) {
                    NSDictionary* lastMessage = [[AppInfo sharedInfo] lastMessageWith:message.toStr];
                    [chatDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
                }
            }
        });
    }
}

#pragma mark -


///////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark XEP-0065 Support
///////////////////////////////////////////////////////////////////////////////////////////////////////////////

NSString* datastr = nil;
NSString* sendjid = nil;

- (void)sendToOtherDevice:(NSData *)fileData receiverJid:(NSString *)receiverJid type:(MessageType)nType filePath:(NSString*)filePath
{
    XMPPSIFileTransferMimeType mimeType = kXMPPSIFileTransferMimeTypeNone;
    if (nType == MessageType_Photo) {
        mimeType = kXMPPSIFileTransferMimeTypePNG;
    } else if (nType == MessageType_Audio) {
        mimeType = kXMPPSIFileTransferMimeTypeMP4Audio;
    } else if (nType == MessageType_Video) {
        mimeType = kXMPPSIFileTransferMimeTypeMP4Video;
    }
    
    XMPPJID *jid = [XMPPJID jidWithString:receiverJid];
#if 0
    [xmppFileTransfer initiateFileTransferTo:jid
                                    withData:fileData
                                    fileName:[filePath lastPathComponent]
                                    fileType:mimeType];
#else
    [xmppStreamIBB initiateIBBFileTransfer:fileData to:receiverJid fileName:[filePath lastPathComponent] fileType:(XMPPIBBMimeType)mimeType];
#endif
    
    BOOL success = [[AppInfo sharedInfo] addFileWithType:nType
                                        filePath:filePath
                                            from:xmppStream.myJID.bare
                                              to:jid.bare
                                            date:[NSDate date]];
    if (success == NO)
        return;
    
    //		if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
    //		{
    if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(newMessageReceived:)]) {
        NSDictionary* lastMessage = nil;//[[AppInfo sharedInfo] lastMessageWith:jid.bare];
        [messageDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
    }
    
    if (self.chatDelegate && [self.chatDelegate respondsToSelector:@selector(newMessageReceived:)] && [self.chatDelegate respondsToSelector:@selector(chatUserName)])
    {
        NSString * chatUserName = [self.chatDelegate chatUserName];
        if ([chatUserName isEqualToString:jid.bare]) {
            NSDictionary* lastMessage = [[AppInfo sharedInfo] lastMessageWith:jid.bare];
            [chatDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
        }
    }
}
#pragma mark XMPPStream Delegate
/**
 * When we receive an IQ with namespaces http://jabber.org/protocol/si and http://jabber.org/protocol/si/profile/file-transfer
 * then this means someone has initiated a file transfer. We need to respond back with a negotiation response telling the
 * sender that we support http://jabber.org/protocol/bytestreams. Finally, we receive the file with a SOCKS5 socket.
 *
 * It's the other way around when we are the initiator. We send the request by calling initiateFileTransferTo:withData
 * and then wait for the iq result with the si namespace of http://jabber.org/protocol/si, send a disco#info response,
 * open a SOCKS5 socket and then wait for the other side the connect to start the transfer.
 **/
//- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)inIq
//{
//    NSString *type = [inIq type];
//    
//    if ([type isEqualToString:@"result"]) {
//        if ([inIq.fromStr isEqualToString:sendjid]) {
//            [self sendFile:sendjid];
//        }
//    } else if ([type isEqualToString:@"set"]) {
//        NSXMLElement *open = [inIq elementForName:@"open" xmlns:@"http://jabber.org/protocol/ibb"];
//        if (open) {
//            XMPPIQ *iq = [XMPPIQ iqWithType:@"result" elementID:[[inIq attributeForName:@"id"] stringValue]];
//            [iq addAttributeWithName:@"to" stringValue:inIq.fromStr];
//            [iq addAttributeWithName:@"from" stringValue:inIq.toStr];
//            
//            [xmppStream sendElement:iq];
//        }
//    }
//    
//    return YES;
//};
//
#pragma mark -
//
//- (void)sendFile:(NSString*)tostr {
//    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
//    [body setStringValue:@"image sending"];
//
//    NSString *imageStr = datastr;
//    NSXMLElement *ImgAttachement = [NSXMLElement elementWithName:@"attachement"];
//    [ImgAttachement setStringValue:imageStr];
//
//    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
//    [message addAttributeWithName:@"type" stringValue:@"chat"];
//    [message addAttributeWithName:@"from" stringValue:xmppStream.myJID.full];
//    [message addAttributeWithName:@"to" stringValue:tostr];
//    [message addChild:body];
//    [message addChild:ImgAttachement];
//
//    [self.xmppStream sendElement:message];
//}

#pragma mark -

- (MessageType)messageTypeFromMIMEType:(XMPPSIFileTransferMimeType)mimeType {
    if (mimeType == kXMPPSIFileTransferMimeTypeJPG || mimeType == kXMPPSIFileTransferMimeTypeGIF || mimeType == kXMPPSIFileTransferMimeTypePNG)
        return MessageType_Photo;
    else if (mimeType == kXMPPSIFileTransferMimeTypeMP4Audio)
        return MessageType_Audio;
    else if (mimeType == kXMPPSIFileTransferMimeTypeMP4Video)
        return MessageType_Video;
    return MessageType_String;
}

- (void)receivedData:(NSString*)fileDataStr from:(NSString*)from filetype:(XMPPIBBMimeType)mimeType fileName:(NSString *)fileName {
    NSData* dataValue = [fileDataStr base64DecodedData];

    [self receivedData:dataValue from:[XMPPJID jidWithString:from] filetype:(XMPPSIFileTransferMimeType)mimeType filename:fileName];
    
    [xmppStreamIBB receiveDataSuccess];
}

- (void)receivedData:(NSData*)fileData from:(XMPPJID*)from filetype:(XMPPSIFileTransferMimeType)mimeType filename:(NSString*)fileName {

    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    //ADD.MY.0107
    dispatch_async(dispatch_get_main_queue(), ^{

        BOOL success = [[AppInfo sharedInfo] addFileData:fileData
                                                fileType:[self messageTypeFromMIMEType:mimeType]
                                                filename:fileName
                                                    from:from.bare
                                                      to:xmppStream.myJID.bare
                                                    date:[NSDate date]];
        if (success == NO)
            return;
        
        if (self.messageDelegate && [self.messageDelegate respondsToSelector:@selector(newMessageReceived:)]) {
            NSDictionary* lastMessage = nil;//[[AppInfo sharedInfo] lastMessageWith:from.bare];
            [messageDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
        }
        
        if (self.chatDelegate && [self.chatDelegate respondsToSelector:@selector(newMessageReceived:)] && [self.chatDelegate respondsToSelector:@selector(chatUserName)])
        {
            NSString * chatUserName = [self.chatDelegate chatUserName];
            if ([chatUserName isEqualToString:from.bare]) {
                NSDictionary* lastMessage = [[AppInfo sharedInfo] lastMessageWith:from.bare];
                [chatDelegate newMessageReceived:[NSMutableDictionary dictionaryWithDictionary:lastMessage]];
            }
        }
    });

    if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateActive)
    {
        NSString *body = @"You have received attachment from %@.";
        NSString *displayName = [from user];
        // We are not active, so use a local notification instead
        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.alertAction = @"Ok";
        localNotification.alertBody = [NSString stringWithFormat:body, displayName];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.applicationIconBadgeNumber = [UIApplication sharedApplication].applicationIconBadgeNumber + 1;
        [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
    }
}

- (void)sendedData:(NSData*)fileData to:(NSString*)toJID filetype:(XMPPSIFileTransferMimeType)mimeType filename:(NSString*)fileName {
    
    DDLogVerbose(@"%@: %@", THIS_FILE, THIS_METHOD);

    NSLog(@"====== Send file success!!! =====");
    
    return;
}


@end
