
#import <UIKit/UIKit.h>

#define kImageNameKey   @"ImageNameKey"
#define kTitleKey   @"TitleKey"
#define kStatusKey  @"StatusKey"

@class PopupTableController;

// Delegate protocol for communicating popover results back to root
@protocol PopupTableDelegate <NSObject>
// Sent when the user selects a row in the samples list.
- (void)popupTableController:(PopupTableController *)controller didSelectString:(id)selectedItem;
@end


@interface PopupTableController : UITableViewController <UIActionSheetDelegate> {
    NSArray                 *itemsForDisplay;     // list of popup items for UI
 	NSString                *selectedItem;    // current document
}

@property (nonatomic, retain) id <PopupTableDelegate> popupDelegate;
@property (nonatomic, retain) NSString  *popupTitle;
@property (nonatomic, retain) NSArray   *itemsForDisplay;
@property (nonatomic, retain) id        selectedItem;
@property (nonatomic, retain) UIView    *sourceView;
@property (nonatomic, readwrite) BOOL   selectByNone;//NO: check, YES: no check

- (void)setSelectItemAndReload:(id)selectItem;
- (CGSize)contentSize;

@end
