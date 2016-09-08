//
//  JSStausSelectViewController.m
//  JMessage
//
//  Created by lion1 on 2/21/14.
//  Copyright (c) 2014 SM. All rights reserved.
//

#import "JSStausSelectViewController.h"
#import "AppInfo.h"
#import "JSAppDelegate.h"
#import "SettingsViewController.h"

@interface JSStausSelectViewController ()

@end

@implementation JSStausSelectViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [AppInfo statusArray].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"StatusCellID";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

        cell.textLabel.font = [UIFont systemFontOfSize:16];
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumFontSize = 10;
    }
    
	// Set the tableview cell text to the name of the sample at the given index
	id item = [[AppInfo statusArray] objectAtIndex:indexPath.row];
    NSString *cellName = @"";
    cell.imageView.image = [UIImage imageNamed: item[kImageNameKey]];
    cellName = item[kTitleKey];
    
    cell.textLabel.text = cellName;
    
	if ([self.selectedItem isEqual:item]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id selectedOne = [[AppInfo statusArray] objectAtIndex:indexPath.row];
    // Notify the delegate if a row is selected (adding back file extension for delegate)
	self.selectedItem = selectedOne;
	[self.tableView reloadData]; // refresh tableView cells for selection state change
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/



/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

- (JSAppDelegate *)appDelegate {
	return (JSAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (XMPPStream *)xmppStream {
	return [[self appDelegate] xmppStream];
}

- (IBAction)gotoSettings:(id)sender {
    if (self.selectedItem) {
        if ([self.selectedItem[kStatusKey] isEqualToString:@"unavailable"]) {
            [[self appDelegate] goOffline];
        } else {
            XMPPPresence* presence = [XMPPPresence presence];
            NSXMLElement* show = [NSXMLElement elementWithName:@"show"];
            [show setStringValue:self.selectedItem[kStatusKey]];
            [presence addChild:show];
            [[self xmppStream] sendElement:presence];
        }
    }

    UINavigationController* navController = self.navigationController;
    [navController popViewControllerAnimated:YES];
    
    SettingsViewController* controller = (SettingsViewController*)navController.topViewController;
    if ([controller respondsToSelector:@selector(setStatusWithInfo:)]) {
        [controller setStatusWithInfo:self.selectedItem];
    }
}

@end
