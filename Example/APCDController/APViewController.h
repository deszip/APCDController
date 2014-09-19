//
//  APViewController.h
//  APCDController
//
//  Created by Deszip on 09/16/2014.
//  Copyright (c) 2014 Deszip. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "APCDController.h"
#import "APProduct.h"

@interface APViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate> {
    
}

@property (weak, nonatomic) IBOutlet UITableView *productsTable;

- (IBAction)addProduct:(id)sender;

@end
