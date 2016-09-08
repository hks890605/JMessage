//
//  JSContactsViewController.h
//  JMessage
//
//  Created by lion1 on 2/21/14.
//  Copyright (c) 2014 SM. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^SelectContactBlock) (id contact);

@interface JSContactsViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UITableView*    tableView;
@property (strong, nonatomic) NSArray*      contactList;
@property (strong, nonatomic) SelectContactBlock  select_contact_block;

- (IBAction)doSelectCancel:(id)sender;

@end
