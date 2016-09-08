//
//  JSContactsViewController.m
//  JMessage
//
//  Created by lion1 on 2/21/14.
//  Copyright (c) 2014 SM. All rights reserved.
//

#import "JSContactsViewController.h"

#import "XMPPFramework.h"

@interface JSContactsViewController ()
@property (nonatomic, strong) NSMutableDictionary*  friendList;//{name first charactor, [friend dict]}
@property (nonatomic, strong) NSArray*              friendNameKeyList;
@property (nonatomic, strong) NSMutableArray*       searchFriendList;

@end

@implementation JSContactsViewController

@synthesize select_contact_block;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.friendList = [NSMutableDictionary new];
    self.searchFriendList = [NSMutableArray new];
    
    self.searchDisplayController.searchResultsTableView.rowHeight = self.tableView.rowHeight;
    //self.searchDisplayController.searchBar.placeholder = L(@"Name, Phone No.");
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSCharacterSet* engCharSet = [NSCharacterSet uppercaseLetterCharacterSet];
    
    NSMutableDictionary* friendsWithContactName = [NSMutableDictionary dictionary];
    NSString* contactName = nil;
    for (id contact in self.contactList) {
        if (![contact isKindOfClass:XMPPUserCoreDataStorageObject.class])
            continue;
        XMPPUserCoreDataStorageObject* theContact = (XMPPUserCoreDataStorageObject*)contact;

        contactName = theContact.nickname;
        if (contactName == nil)
            contactName = theContact.jid.user;

        NSString* letter = [[contactName decomposedStringWithCanonicalMapping] substringWithRange:NSMakeRange(0, 1)];
        letter = letter.uppercaseString;
        if (![engCharSet characterIsMember:[letter characterAtIndex:0]])
            letter = @"#";
        
        NSMutableArray* array = [friendsWithContactName objectForKey:letter];
        if (array == nil) {
            array = [NSMutableArray new];
            [friendsWithContactName setObject:array forKey:letter];
        }
        
        [array addObject:theContact];
    }

    [self.friendList setDictionary:friendsWithContactName];
    self.friendNameKeyList = [[self.friendList allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if (tableView == self.tableView)
        return self.friendNameKeyList.count;
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView == self.tableView)
        return self.tableView.sectionHeaderHeight;
    return 0;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [self.friendNameKeyList objectAtIndex:section];
}
//- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//    if (tableView != self.tableView)
//        return nil;
//    
//    NSString* strHeaderViewIdentifier = @"SectionHeaderView";
//    UITableViewHeaderFooterView* headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:strHeaderViewIdentifier];
//    if (headerView == nil) {
//        headerView = [[UITableViewHeaderFooterView alloc] initWithReuseIdentifier:strHeaderViewIdentifier];
//        headerView.backgroundView = [[UIView alloc] initWithFrame:CGRectZero];
//        headerView.backgroundView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
//    }
//    
//    headerView.textLabel.text = [self.friendNameKeyList objectAtIndex:section];
//    
//    return headerView;
//}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.6;
}

- (UIView*)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    UIView* view = [UIView new];
    view.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.5];
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return self.searchFriendList.count;
    }
    NSArray *sectionArray = [self.friendList objectForKey:[self.friendNameKeyList objectAtIndex:section]];
    return sectionArray.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    //검색할 때 tableView가 달라지므로 항상 본래의 tableVeiw rowHegith를 리용하기로 한다.
    return self.tableView.rowHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"JSContactTableCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    XMPPUserCoreDataStorageObject* theContact = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        theContact = self.searchFriendList[indexPath.row];
    } else {
        NSArray *sectionArray = [self.friendList objectForKey:[self.friendNameKeyList objectAtIndex:indexPath.section]];
        
        theContact = [sectionArray objectAtIndex:indexPath.row];
    }
    
    NSString* contactName = theContact.nickname;
    if (contactName == nil)
        contactName = theContact.jid.user;

    cell.textLabel.text = contactName;
    //cell.detailTextLabel.text = theContact.jid.user;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    XMPPUserCoreDataStorageObject* theContact = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        theContact = self.searchFriendList[indexPath.row];
    } else {
        NSArray *sectionArray = [self.friendList objectForKey:[self.friendNameKeyList objectAtIndex:indexPath.section]];
        
        theContact = [sectionArray objectAtIndex:indexPath.row];
    }

    if (theContact) {
        select_contact_block(theContact);
    }
}


- (BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    if (self.friendList.count < 1)
        return NO;
    
    NSPredicate* predicateNickName = [NSPredicate predicateWithFormat:@"nickname.uppercaseString contains %@", searchString.uppercaseString];
    NSPredicate* predicatePhoneNumber = [NSPredicate predicateWithFormat:@"jid.user.uppercaseString contains %@", searchString.uppercaseString];
    NSPredicate* predicate = [NSCompoundPredicate orPredicateWithSubpredicates:[NSArray arrayWithObjects:predicateNickName, predicatePhoneNumber, nil]];
    
    NSMutableArray* allValues = [NSMutableArray array];
    for (NSString* key in self.friendList) {
        [allValues addObjectsFromArray:self.friendList[key]];
    }
    
    [self.searchFriendList setArray:[allValues filteredArrayUsingPredicate:predicate]];
    
    return YES;
}

- (void) searchDisplayControllerDidEndSearch:(UISearchDisplayController *)controller {
    [self.tableView reloadData];
}

- (NSArray*)sectionIndexTitlesForTableView:(UITableView *)tableView {
    if (tableView == self.tableView) {
        NSArray *indexArray = [NSArray arrayWithObjects:@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z", @"#", nil];
        return indexArray;
        //return self.friendNameKeyList;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return index;
}

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (IBAction)doSelectCancel:(id)sender {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
