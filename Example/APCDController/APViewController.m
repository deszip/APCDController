//
//  APViewController.m
//  APCDController
//
//  Created by Deszip on 09/16/2014.
//  Copyright (c) 2014 Deszip. All rights reserved.
//

#import "APViewController.h"

@interface APViewController () {
    
}

@property (strong, nonatomic) NSFetchedResultsController *frc;

@property (strong, nonatomic) NSArray *categoriesNames;
@property (strong, nonatomic) NSArray *productsNames;

- (void)setupFakeData;
- (void)setupFRC;

@end

@implementation APViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [APCDController defaultController];
    
    [self setupFakeData];
    [self setupFRC];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Setup

- (void)setupFakeData
{
    self.productsNames = @[@"iPhone", @"iPad", @"iWatch"];
}

- (void)setupFRC
{
    NSFetchRequest *productRequest = [NSFetchRequest fetchRequestWithEntityName:@"APProduct"];
    NSSortDescriptor *productSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    [productRequest setSortDescriptors:@[productSortDescriptor]];
    
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:productRequest managedObjectContext:[APCDController mainMOC] sectionNameKeyPath:nil cacheName:nil];
    [self.frc setDelegate:self];
    
    NSError *fetchError = nil;
    if (![self.frc performFetch:&fetchError]) {
        NSLog(@"FRC failed to fetch: %@", fetchError);
    }
    
    NSLog(@"Objects: %@", self.frc.fetchedObjects);
}

#pragma mark - Actions

- (IBAction)addProduct:(id)sender
{
    [[APCDController workerMOC] performBlock:^{
        APProduct *newProduct = (APProduct *)[NSEntityDescription insertNewObjectForEntityForName:@"APProduct" inManagedObjectContext:[APCDController workerMOC]];
        
        NSInteger index = arc4random() % 3;
        [newProduct setName:self.productsNames[index]];
        [newProduct setCreationDate:[NSDate date]];
        
        NSError *saveError = nil;
        if (![[APCDController workerMOC] save:&saveError]) {
            NSLog(@"Failed to save context: %@", saveError);
        }
        
        [APCDController performSave];
    }];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.productsTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    switch (type) {
        case NSFetchedResultsChangeMove:
            [self.productsTable moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.productsTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationRight];
            break;
            
        case NSFetchedResultsChangeInsert:
            [self.productsTable insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationLeft];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.productsTable reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
            break;
            
        default:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.productsTable endUpdates];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.frc.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id<NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"APCell"];
    
    APProduct *product = (APProduct *)[self.frc objectAtIndexPath:indexPath];
    [cell.textLabel setText:product.name];
    [cell.detailTextLabel setText:product.creationDate.description];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    APProduct *productToRemove = [self.frc objectAtIndexPath:indexPath];
    [[APCDController mainMOC] deleteObject:productToRemove];
    [APCDController performSave];
}

#pragma mark - UITableViewDelegate



@end
