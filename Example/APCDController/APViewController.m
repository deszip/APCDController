//
//  APViewController.m
//  APCDController
//
//  Created by Deszip on 09/16/2014.
//  Copyright (c) 2014 Alterplay. All rights reserved.
//

#import "APViewController.h"

@interface APViewController () {
    
}

@property (strong, nonatomic) APCDController *cdController;
@property (strong, nonatomic) NSFetchedResultsController *frc;

@property (strong, nonatomic) NSArray *categoriesNames;
@property (strong, nonatomic) NSArray *productsNames;

@property (strong, nonatomic) NSTimer *tickTimer;

- (void)setupTickTimer;
- (void)setupFakeData;
- (void)setupFRC;

- (void)addItems:(NSUInteger)count;

- (void)updateCountItem;
- (void)updateTickItem;

@end

@implementation APViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTickTimer];
    [self setupFakeData];
    [self setupFRC];
    [self updateCountItem];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Setup

- (void)setupTickTimer
{
    NSMethodSignature *tickSignature = [self methodSignatureForSelector:@selector(updateTickItem)];
    NSInvocation *tickInvocation = [NSInvocation invocationWithMethodSignature:tickSignature];
    [tickInvocation setTarget:self];
    [tickInvocation setSelector:@selector(updateTickItem)];
    self.tickTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 invocation:tickInvocation repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.tickTimer forMode:NSRunLoopCommonModes];
}

- (void)setupFakeData
{
    self.productsNames = @[@"iPhone", @"iPad", @"iWatch"];
}

- (void)setupFRC
{
    self.cdController = [APCDController controllerWithStoreType:NSSQLiteStoreType];
    
    NSFetchRequest *productRequest = [NSFetchRequest fetchRequestWithEntityName:@"APProduct"];
    NSSortDescriptor *productSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES];
    [productRequest setSortDescriptors:@[productSortDescriptor]];
    
    self.frc = [[NSFetchedResultsController alloc] initWithFetchRequest:productRequest managedObjectContext:[self.cdController mainMOC] sectionNameKeyPath:nil cacheName:nil];
    [self.frc setDelegate:self];
    
    NSError *fetchError = nil;
    if (![self.frc performFetch:&fetchError]) {
        NSLog(@"FRC failed to fetch: %@", fetchError);
    }
}

#pragma mark - Actions

- (IBAction)addBunchOfProducts:(id)sender
{
    [self addItems:1000];
}

- (IBAction)addProduct:(id)sender
{
    [self addItems:1];
}

- (IBAction)wipe:(id)sender
{
    [[self.cdController workerMOC] performBlock:^{
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"APProduct"];
        NSError *fetchError = nil;
        NSArray *products = [[self.cdController workerMOC] executeFetchRequest:request error:&fetchError];
        if (products) {
            for (NSInteger i = 0; i < products.count; i++) {
                [[self.cdController workerMOC] deleteObject:products[i]];
                
                NSError *saveError = nil;
                if (![[self.cdController workerMOC] save:&saveError]) {
                    NSLog(@"Failed to save context: %@", saveError);
                }
                
                [self.cdController performSave];
            }
        } else {
            NSLog(@"Failed to fetch all products: %@", fetchError);
        }
    }];
}

- (void)addItems:(NSUInteger)count
{
    [[self.cdController workerMOC] performBlock:^{
        for (NSInteger i = 0; i < count; i++) {
            APProduct *newProduct = (APProduct *)[NSEntityDescription insertNewObjectForEntityForName:@"APProduct" inManagedObjectContext:[self.cdController workerMOC]];
            
            NSInteger index = arc4random() % 3;
            [newProduct setName:self.productsNames[index]];
            [newProduct setCreationDate:[NSDate date]];
        }
        
        NSError *saveError = nil;
        if (![[self.cdController workerMOC] save:&saveError]) {
            NSLog(@"Failed to save context: %@", saveError);
        }
        
        [self.cdController performSave];
    }];
}

- (void)updateCountItem
{
    id <NSFetchedResultsSectionInfo> sectionInfo = self.frc.sections[0];
    NSUInteger count = [sectionInfo numberOfObjects];
    NSString *title = [NSString stringWithFormat:@"Items: %lu", (unsigned long)count];
    [self.countItem setTitle:title];
}

- (void)updateTickItem
{
    NSUInteger currentValue = [self.tickItem.title integerValue];
    [self.tickItem setTitle:[NSString stringWithFormat:@"%u", (currentValue + 1)]];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.productsTable beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    [self updateCountItem];
    
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
    [[self.cdController mainMOC] deleteObject:productToRemove];
    [self.cdController performSave];
}

#pragma mark - UITableViewDelegate



@end
