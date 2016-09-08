//
//  SMMessageDelegate.h
//  jabberClient
//
//  Created by cesarerocchi on 8/2/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol SMMessageDelegate <NSObject>
@optional
- (void)newMessageReceived:(NSMutableDictionary *)messageContent;
- (NSString*)chatUserName;

@end
