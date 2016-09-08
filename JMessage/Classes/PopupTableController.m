
#import "PopupTableController.h"

#import "XMPPFramework.h"

#define CONTENT_WIDTH  160
#define ROW_HEIGHT  32

@implementation PopupTableController

@synthesize popupDelegate, itemsForDisplay, selectedItem, sourceView, selectByNone, popupTitle;

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"";
    //self.contentSizeForViewInPopover = CGSizeMake(300.0, 280.0);

	// Initially, there is no active sample (RootViewController will specify this)
	selectedItem = @"";
    
    self.tableView.rowHeight = ROW_HEIGHT;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.itemsForDisplay = nil;
	self.selectedItem = nil;
}

- (CGSize)contentSize {
    CGSize size;
    size.width = CONTENT_WIDTH;
    size.height = itemsForDisplay.count * ROW_HEIGHT + (popupTitle.isNotEmpty ? ROW_HEIGHT : 0);
    return size;
}

- (void)setItemsForDisplay:(NSArray *)items {
    itemsForDisplay = items;
    [self.tableView reloadData];
}

- (void)setSelectItemAndReload:(NSString*)selectItem {
    selectedItem = selectItem;
    [self.tableView reloadData];
}

#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [itemsForDisplay count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
	// Set the tableview cell text to the name of the sample at the given index
	id item = [itemsForDisplay objectAtIndex:indexPath.row];
    NSString *cellName = @"";
    if ([item isKindOfClass:XMPPUserCoreDataStorageObject.class]) {
        XMPPUserCoreDataStorageObject *user = (XMPPUserCoreDataStorageObject*)item;
        cellName = user.displayName;
    } else if ([item isKindOfClass:NSString.class]) {
        cellName = item;
    } else if ([item isKindOfClass:NSDictionary.class]) {
        cell.imageView.image = [UIImage imageNamed: item[kImageNameKey]];
        cellName = item[kTitleKey];
    }

    cell.textLabel.text = cellName;
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.textLabel.minimumFontSize = 10;

	if (!selectByNone && [selectedItem isEqual:item]) {
		cell.accessoryType = UITableViewCellAccessoryCheckmark;
	} else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id selectedOne = [itemsForDisplay objectAtIndex:indexPath.row];
    // Notify the delegate if a row is selected (adding back file extension for delegate)
	if (popupDelegate && [popupDelegate respondsToSelector:@selector(popupTableController:didSelectString:)]) {
		[popupDelegate popupTableController:self didSelectString:selectedOne];
	}
	self.selectedItem = selectedOne;
	[self.tableView reloadData]; // refresh tableView cells for selection state change
}

#pragma mark -

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (popupTitle.isNotEmpty)
        return ROW_HEIGHT;
    return 0;
}

- (UIView*)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    static UILabel* sHeaderLabel = nil;
    if (sHeaderLabel == nil) {
        sHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, ROW_HEIGHT)];
        sHeaderLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        sHeaderLabel.textColor = [UIColor whiteColor];
        sHeaderLabel.font = [UIFont systemFontOfSize:16];
    }
    sHeaderLabel.text = popupTitle;
    return sHeaderLabel;
}

@end

