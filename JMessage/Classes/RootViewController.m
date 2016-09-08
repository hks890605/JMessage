#import "RootViewController.h"
#import "JSAppDelegate.h"
#import "SettingsViewController.h"

#import "XMPPFramework.h"
#import "DDLog.h"
#import "XMPPvCardTemp.h"

#import "SMChatViewController.h"
#import "JSNewMessageViewController.h"
#import "AppInfo.h"
#import "JSUserListCell.h"
#import "NSString+Utils.h"
#import "UIColor+Starlet.h"

// Log levels: off, error, warn, info, verbose
#if DEBUG
  static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#else
  static const int ddLogLevel = LOG_LEVEL_INFO;
#endif
//static const int ddLogLevel = LOG_LEVEL_OFF;


@interface RootViewController()
@property (strong, nonatomic) NSMutableArray*   contactList;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (![AppInfo isBeforeIOS70])
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    NSString* title = @"";
    if ([[self appDelegate] connect])
    {
        title = [[[[self appDelegate] xmppStream] myJID] bare];
    } else
    {
        title = @"No JID";
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Accessors
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (JSAppDelegate *)appDelegate
{
	return (JSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View lifecycle
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
  
//	UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 400, 44)];
//	titleLabel.backgroundColor = [UIColor clearColor];
//	titleLabel.textColor = [UIColor whiteColor];
//	titleLabel.font = [UIFont boldSystemFontOfSize:20.0];
//	titleLabel.numberOfLines = 1;
//	titleLabel.adjustsFontSizeToFitWidth = YES;
//	titleLabel.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.5];
//	titleLabel.textAlignment = NSTextAlignmentCenter;

    NSString* title = @"";
//    if ([[self appDelegate] connect])
//    {
        title = [[[[self appDelegate] xmppStream] myJID] bare];
//    } else
//    {
//        title = @"No JID";
//    }
    if (title.length <= 0)
        title = @"No JID";
    
    UILabel *titleLabel = (UILabel*)self.navigationItem.titleView;
    if (titleLabel) {
        titleLabel.text = title;
        [titleLabel sizeToFit];
    }
//	self.navigationItem.titleView = titleLabel;

    [self appDelegate].messageDelegate = self;

    [self sortContactListByDate];
    [self.tableView reloadData];
    
    //ADD.20140301
    if (self.tableView.indexPathsForVisibleRows.count > 0) {
        [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    [self appDelegate].messageDelegate = nil;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (![self appDelegate].loginSuccess) {
        [self appDelegate].loginSuccess = YES;
        [self settings:nil];
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark NSFetchedResultsController
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSFetchedResultsController *)fetchedResultsController
{
	if (fetchedResultsController == nil)
	{
		NSManagedObjectContext *moc = [[self appDelegate] managedObjectContext_roster];
		
		NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject"
		                                          inManagedObjectContext:moc];
		
		NSSortDescriptor *sd1 = [[NSSortDescriptor alloc] initWithKey:@"sectionNum" ascending:YES];
		NSSortDescriptor *sd2 = [[NSSortDescriptor alloc] initWithKey:@"displayName" ascending:YES];
		
		NSArray *sortDescriptors = [NSArray arrayWithObjects:sd1, sd2, nil];
		
		NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
		[fetchRequest setEntity:entity];
		[fetchRequest setSortDescriptors:sortDescriptors];
		[fetchRequest setFetchBatchSize:10];
		
		fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
		                                                               managedObjectContext:moc
		                                                                 sectionNameKeyPath:@"sectionNum"
		                                                                          cacheName:nil];
		[fetchedResultsController setDelegate:self];
		
		
		NSError *error = nil;
		if (![fetchedResultsController performFetch:&error])
		{
			DDLogError(@"Error performing fetch: %@", error);
		}
	
	}
	
	return fetchedResultsController;
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self sortContactListByDate];
	[[self tableView] reloadData];
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableViewCell helpers
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (NSString*)messageDateFrom:(NSString*)dateStr {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSDateFormatter new];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    }
    static NSArray *weekdays = nil;
    if (weekdays == nil) {
        weekdays = [NSDateFormatter new].weekdaySymbols;
    }
    NSDate* date = [formatter dateFromString:dateStr];
    NSDate* today = [NSDate date];
    
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* todaycomps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:today];
    today = [calendar dateFromComponents:todaycomps];
    NSDate* yesterday = [today dateByAddingTimeInterval:-24*60*60];
    NSDate* dayBeforeWeek = [today dateByAddingTimeInterval:-24*60*60*6];
    
    NSString* showDate = @"";
    if ([date compare:today] == NSOrderedDescending) {
        NSDateComponents* rcvcomps = [calendar components:NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:date];
        showDate = [NSString stringWithFormat:@"%02d:%02d", rcvcomps.hour, rcvcomps.minute];
    } else if ([date compare:yesterday] == NSOrderedDescending)
        showDate = @"Yesterday";
    else if ([date compare:dayBeforeWeek] == NSOrderedDescending) {
        NSDateComponents* rcvcomps = [calendar components:NSWeekdayCalendarUnit fromDate:date];
        showDate = weekdays[rcvcomps.weekday-1];
    } else {
        NSDateComponents* rcvcomps = [calendar components:NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit fromDate:date];
        showDate = [NSString stringWithFormat:@"%02d/%02d/%04d", rcvcomps.day, rcvcomps.month, rcvcomps.year];
    }
    return showDate;
}

- (void)configureForCell:(JSUserListCell *)cell user:(XMPPUserCoreDataStorageObject *)user
{
	// Our xmppRosterStorage will cache photos as they arrive from the xmppvCardAvatarModule.
	// We only need to ask the avatar module for a photo, if the roster doesn't have it.
	
    UIImage* image = nil;
	if (user.photo != nil)
	{
		image = user.photo;
	} 
	else
	{
		NSData *photoData = [[[self appDelegate] xmppvCardAvatarModule] photoDataForJID:user.jid];

		if (photoData != nil)
			image = [UIImage imageWithData:photoData];
		else
			image = [UIImage imageNamed:@"defaultPerson"];
	}
    
    NSString* title = user.displayName;
    if (!title.isNotEmpty) {
        XMPPvCardTemp *vcard = [[[self appDelegate] xmppvCardTempModule] vCardTempForJID:user.jid shouldFetch:NO];
        title = vcard.formattedName;
    }
    if (!title.isNotEmpty) {
        title = user.nickname;
    }
    if (!title.isNotEmpty) {
        title = user.jid.user;
    }
    
    cell.photoView.contentMode = UIViewContentModeScaleAspectFit;
    cell.photoView.image = image;
    cell.titleLabel.text = user.displayName;
    cell.detailLabel.text = @"";
    cell.dateLabel.text = @"";
    
    if (user.primaryResource == nil) {
        cell.markImageView.image = nil;
    } else {
        switch (user.section) {
            case 0://chat
                cell.markImageView.image = [UIImage imageNamed:@"available"];
                break;
            case 1://dnd - do not disturb
                cell.markImageView.image = [UIImage imageNamed:@"dnd"];
                break;
            case 2://away
                cell.markImageView.image = [UIImage imageNamed:@"busy"];
                break;
            case 3://xa (extended away
                cell.markImageView.image = [UIImage imageNamed:@"invisible"];
                break;
            case 4://unavailable
            default:
                cell.markImageView.image = nil;
        }
    }
    
    AppInfo* appInfo = [AppInfo sharedInfo];
    NSDictionary* lastMessage = [appInfo lastMessageWith:user.jidStr];
    if (lastMessage) {
        MessageType nType = MessageType_String;
        id msgTypeObj = lastMessage[kMessageTypeKey];
        if ([msgTypeObj respondsToSelector:@selector(intValue)])
            nType = [msgTypeObj intValue];
        switch (nType) {
            case MessageType_String:
                cell.detailLabel.text = [lastMessage[kMessageKey] substituteEmoticons];
                break;
            case MessageType_Photo:
                cell.detailLabel.text = @"Attachment: 1 Image";
                break;
            case MessageType_Audio:
                cell.detailLabel.text = @"Attachment: 1 VoiceNote";
                break;
            case MessageType_Video:
                cell.detailLabel.text = @"Attachment: 1 VideoNote";
                break;
            default:
                break;
        }
        cell.dateLabel.text = [self messageDateFrom: lastMessage[kDateKey]];
        
        if ([lastMessage[kMessageReadKey] intValue] == 0) {
            cell.detailLabel.textColor = [UIColor blueTextColor];
            cell.dateLabel.textColor = [UIColor blueTextColor];
        } else {
            cell.detailLabel.textColor = [UIColor darkGrayColor];
            cell.dateLabel.textColor = [UIColor darkGrayColor];
        }
    }
}

- (void)sortContactListByDate {
    if (self.contactList == nil)
        self.contactList = [NSMutableArray new];

    [self.contactList removeAllObjects];
    
    NSArray* registerdUserList = [[AppInfo sharedInfo] sortedUserArrayWithDate];
    NSMutableArray* userArray = [NSMutableArray arrayWithArray:[[self fetchedResultsController] fetchedObjects]];

    for (int i = registerdUserList.count - 1; i >= 0; i--) {
        NSDictionary* chatUserInfo = registerdUserList[i];
        for (XMPPUserCoreDataStorageObject *userInfo in userArray) {
            if ([chatUserInfo[kChatUserKey] isEqualToString:userInfo.jidStr]) {
                [self.contactList addObject:userInfo];
                [userArray removeObject:userInfo];
                break;
            }
        }
    }
    
    [self.contactList addObjectsFromArray:userArray];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark UITableView
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;//[[[self fetchedResultsController] sections] count];
}

//- (NSString *)tableView:(UITableView *)sender titleForHeaderInSection:(NSInteger)sectionIndex
//{
//	NSArray *sections = [[self fetchedResultsController] sections];
//	
//	if (sectionIndex < [sections count])
//	{
//		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
//        
//		int section = [sectionInfo.name intValue];
//		switch (section)
//		{
//			case 0  : return @"Available";
//			case 1  : return @"Away";
//			default : return @"Offline";
//		}
//	}
//	
//	return @"";
//}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)sectionIndex
{
//	NSArray *sections = [[self fetchedResultsController] sections];
//	
//	if (sectionIndex < [sections count])
//	{
//		id <NSFetchedResultsSectionInfo> sectionInfo = [sections objectAtIndex:sectionIndex];
//		return sectionInfo.numberOfObjects;
//	}
//	
//	return 0;
    return self.contactList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *CellIdentifier = @"UserListTableCellID";
	
	JSUserListCell *cell = (JSUserListCell*)[tableView dequeueReusableCellWithIdentifier:JSUserListCellID /*forIndexPath:indexPath*/];
	if (cell == nil)
	{
		cell = (JSUserListCell*)[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                          reuseIdentifier:CellIdentifier];
	}
	
	XMPPUserCoreDataStorageObject *user = self.contactList[indexPath.row];//[[self fetchedResultsController] objectAtIndexPath:indexPath];
	
	[self configureForCell:cell user:user];
	
	return cell;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//}

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"SegueID_ToNewMessage"]) {
        NSArray* users = self.contactList;//[[self fetchedResultsController] fetchedObjects];
        if (users.count < 1)
            return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SegueID_ToNewMessage"]) {
        JSNewMessageViewController* controller = (JSNewMessageViewController*)segue.destinationViewController;
        if (controller) {
            controller.userArray = self.contactList;//[[self fetchedResultsController] fetchedObjects];
        }
    } else if ([segue.identifier isEqualToString:@"SegueID_ToChat"]) {
        SMChatViewController *chatController = (SMChatViewController*) segue.destinationViewController;
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        if (chatController && indexPath) {
            XMPPUserCoreDataStorageObject *user = self.contactList[indexPath.row]; //[[self fetchedResultsController] objectAtIndexPath:indexPath];
            
            chatController.chatUser = user;
            
            [chatController setMessageList:[[AppInfo sharedInfo] messageArrayWith:user.jidStr]];
        }
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (IBAction)settings:(id)sender
{
//    [[self appDelegate] disconnect];
//	[[[self appDelegate] xmppvCardTempModule] removeDelegate:self];

	[self.navigationController performSegueWithIdentifier:@"SegueID_ToSetting" sender:self];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark -

- (void)newMessageReceived:(NSMutableDictionary *)messageContent {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self sortContactListByDate];
        [self.tableView reloadData];
        
//        if (self.tableView.indexPathsForVisibleRows.count > 0) {
//            [self.tableView reloadRowsAtIndexPaths:self.tableView.indexPathsForVisibleRows withRowAnimation:UITableViewRowAnimationAutomatic];
//        }
    });
}

@end
