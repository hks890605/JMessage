//
//  NSString+Date.m
//  JabberClient
//
//  Created by cesarerocchi on 9/12/11.
//  Copyright 2011 studiomagnolia.com. All rights reserved.
//

#import "NSString+Utils.h"


@implementation NSString (Utils)

+ (NSString *) getCurrentTime {

	NSDate *nowUTC = [NSDate date];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setTimeZone:[NSTimeZone localTimeZone]];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	return [dateFormatter stringFromDate:nowUTC];
	
}

#define USE_EMOJI_COUNT 81
static NSString* jabberEmojiKey[USE_EMOJI_COUNT] = {
    @":-)",
    @":)",
    @";-)",
    @";)",
    @":-P",
    @":-p",
    @":P",
    @":p",
    @":-D",
    @":-d",
    @":D",
    @":d",
    @":->",
    @":>",
    @":-(",
    @":(",
    @":'-(",
    @":'(",
    @";-(",
    @";(",
    @":-O",
    @":-o",
    @":O",
    @":o",
    @":-@",
    @":@",
    @":-$",
    @":$",
    @":-|",
    @":|",
    @":-S",
    @":-s",
    @":S",
    @":s",
    @"B-)",
    @"B)",
    @"(H)",
    @"(h)",
    @":-[",
    @":[",
    @"(L)",
    @"(l)",
    @"(U)",
    @"(u)",
    @"(Y)",
    @"(y)",
    @"(N)",
    @"(n)",
    @"(Z)",
    @"(z)",
    @"(X)",
    @"(x)",
    @"(@)",
    @"(})",
    @"({)",
    @"(6)",
    @"(R)",
    @"(r)",
    @"(W)",
    @"(w)",
    @"(F)",
    @"(f)",
    @"(P)",
    @"(p)",
    @"(T)",
    @"(t)",
    @"(*)",
    @"(8)",
    @"(I)",
    @"(i)",
    @"(B)",
    @"(b)",
    @"(D)",
    @"(d)",
    @"(C)",
    @"(c)",
    @"(%)",
    @"(E)",
    @"(e)",
    @"(K)",
    @"(k)"
};
static NSString* JMessageEmojiKey[USE_EMOJI_COUNT] = {
    @"\ue415",
    @"\ue415",
    @"\ue405",
    @"\ue405",
    @"\ue105",
    @"\ue105",
    @"\ue105",
    @"\ue105",
    @"\ue057",
    @"\ue057",
    @"\ue057",
    @"\ue057",
    @"\ue057",
    @"\ue057",
    @"\ue403",
    @"\ue403",
    @"\ue412",
    @"\ue412",
    @"\ue412",
    @"\ue412",
    @"\ue40d",
    @"\ue40d",
    @"\ue40d",
    @"\ue40d",
    @"\ue059",
    @"\ue059",
    @"\ue414",
    @"\ue414",
    @"\ue40e",
    @"\ue40e",
    @"\ue416",
    @"\ue416",
    @"\ue416",
    @"\ue416",
    @"\ue107",
    @"\ue107",
    @"\ue107",
    @"\ue107",
    @"\ue053",
    @"\ue053",
    @"\ue022",
    @"\ue022",
    @"\ue023",
    @"\ue023",
    @"\ue00e",
    @"\ue00e",
    @"\ue00e",
    @"\ue00e",
    @"\ue002",
    @"\ue002",
    @"\ue005",
    @"\ue005",
    @"\ue04f",
    @"\ue111",
    @"\ue425",
    @"\ue10c",
    @"\ue44c",
    @"\ue44c",
    @"\ue444",
    @"\ue444",
    @"\ue306",
    @"\ue306",
    @"\ue008",
    @"\ue008",
    @"\ue009",
    @"\ue009",
    @"\ue32f",
    @"\ue03e",
    @"\ue10f",
    @"\ue10f",
    @"\ue047",
    @"\ue047",
    @"\ue044",
    @"\ue044",
    @"\ue045",
    @"\ue045",
    @"\ue311",
    @"\ue103",
    @"\ue103",
    @"\ue41c",
    @"\ue41c"
};

- (NSString *) substituteEmoticons {
	//See http://www.easyapns.com/iphone-emoji-alerts for a list of emoticons available
    NSString* res = self;
    for (int i = 0; i < USE_EMOJI_COUNT; i++) {
        res = [res stringByReplacingOccurrencesOfString:jabberEmojiKey[i] withString:JMessageEmojiKey[i]];
    }

	return res;
}

- (NSString *) substituteEmotiKeys {
	
	//See http://www.easyapns.com/iphone-emoji-alerts for a list of emoticons available
	
    NSString* res = self;
    for (int i = 0; i < USE_EMOJI_COUNT; i++) {
        res = [res stringByReplacingOccurrencesOfString:JMessageEmojiKey[i] withString:jabberEmojiKey[i]];
    }
	
	return res;
}

@end
