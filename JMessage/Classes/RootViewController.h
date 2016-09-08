#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "SMMessageDelegate.h"

@interface RootViewController : UITableViewController <NSFetchedResultsControllerDelegate, SMMessageDelegate>
{
	NSFetchedResultsController *fetchedResultsController;
}

- (IBAction)settings:(id)sender;

@end

