//
//  APCDController.m
//  APCDController
//
//  Created by Deszip on 25.07.13.
//  Copyright (c) 2013 Alterplay. All rights reserved.
//

#import "APCDController.h"

static NSString * const kAPCDControllerAppBundleNameKey = @"CFBundleName";

NSURL * storeURL() {
#if TARGET_OS_IPHONE
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
#elif TARGET_OS_MAC
    NSURL *appSupportURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:kAPCDControllerAppBundleNameKey];
    appSupportURL = [appSupportURL URLByAppendingPathComponent:appName isDirectory:YES];
    
    BOOL isDirectory;
    if (![[NSFileManager defaultManager] fileExistsAtPath:[appSupportURL path] isDirectory:&isDirectory]) {
        NSError *creationError = nil;
        [[NSFileManager defaultManager] createDirectoryAtURL:appSupportURL withIntermediateDirectories:YES attributes:nil error:&creationError];
    }
    
    return appSupportURL;
#endif
}

NSString * storeName() {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:kAPCDControllerAppBundleNameKey];
}

static APCDController *defaultController = nil;

@interface APCDController () {
    
}

@property (strong, nonatomic) NSString *storeType;
@property (strong, nonatomic) NSString *storeName;
@property (strong, nonatomic) NSMutableDictionary *spawnedContexts;

- (void)raiseExceptionWithReason:(NSString *)reason;

@end

@implementation APCDController

+ (instancetype)defaultController
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultController = [APCDController controllerWithStoreType:NSSQLiteStoreType];
    });
    
    return defaultController;
}

+ (instancetype)controllerWithStoreType:(NSString *)storeType
{
    APCDController *controller = [[APCDController alloc] initWithStoreType:storeType andName:storeName()];
    
    return controller;
}

+ (instancetype)controllerWithStoreType:(NSString *)storeType andName:(NSString *)storeName
{
    APCDController *controller = [[APCDController alloc] initWithStoreType:storeType andName:storeName];
    
    return controller;
}

- (instancetype)initWithStoreType:(NSString *)storeType andName:(NSString *)storeName
{
    self = [super init];
    if (self) {
        _storeType = storeType;
        _storeName = storeName;
        _spawnedContexts = [NSMutableDictionary dictionary];
        
        [self buildMOCs];
    }
    
    return self;
}

#pragma mark - CoreData stack

+ (NSManagedObjectModel *)dataModel
{
    return [defaultController dataModel];
}

- (NSManagedObjectModel *)dataModel
{
	if ( _mom == nil) {
		NSString *momdPath = [[NSBundle mainBundle] pathForResource:_storeName ofType:@"momd"];
        if (momdPath) {
            NSURL *momdURL = [NSURL fileURLWithPath:momdPath];
            _mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:momdURL];
        } else {
            NSString *exceptionReason = [NSString stringWithFormat:@"No model file with name: %@.momd", _storeName];
            [self raiseExceptionWithReason:exceptionReason];
        }
	}
	
	return _mom;
}

+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    return [defaultController persistentStoreCoordinator];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_psc == nil) {
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                        NSInferMappingModelAutomaticallyOption: @(YES)};
        
        _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self dataModel]];
        NSError *error = nil;
        NSString *psName = [NSString stringWithFormat:@"%@.sqlite", _storeName];
        [_psc addPersistentStoreWithType:self.storeType configuration:nil URL:[storeURL() URLByAppendingPathComponent:psName] options:options error:&error];
    }
    
    return _psc;
}

+ (NSManagedObjectContext *)mainMOC
{
    return [[APCDController defaultController] mainMOC];
}

- (NSManagedObjectContext *)mainMOC
{
    return _mainMOC;
}

+ (NSManagedObjectContext *)workerMOC
{
    return [[APCDController defaultController] workerMOC];
}

- (NSManagedObjectContext *)workerMOC
{
    return _workerMOC;
}

+ (NSManagedObjectContext *)writerMOC
{
    return [[APCDController defaultController] writerMOC];
}

- (NSManagedObjectContext *)writerMOC
{
    return _writerMOC;
}

#pragma mark - CoreData setup

- (void)buildMOCs
{
    /* Writer */
    if (_writerMOC == nil) {
        _writerMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_writerMOC setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    }
    
    /* Main */
	if (_mainMOC == nil) {
		_mainMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainMOC setParentContext:_writerMOC];
	}
    
    /* Worker */
    if (_workerMOC == nil) {
        _workerMOC = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [_workerMOC setParentContext:_mainMOC];
    }
}

#pragma mark - CoreData routines

+ (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName
{
    return [[APCDController defaultController] spawnBackgroundContextWithName:contextName];
}

- (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName
{
    if (_spawnedContexts[contextName]) {
        return _spawnedContexts[contextName];
    } else {
        NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [newContext setParentContext:[self mainMOC]];
        [_spawnedContexts setObject:newContext forKey:contextName];
        
        return newContext;
    }
}

+ (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread
{
    return [APCDController spawnBackgroundContextWithName:thread.description];
}

- (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread
{
    return [self spawnBackgroundContextWithName:thread.description];
}

+ (void)performSave
{
    [[APCDController defaultController] performSave];
}

- (void)performSave
{
    /* Save main */
    [[self mainMOC] performBlock:^(void) {
        NSError *error = nil;
        if (![[self mainMOC] save:&error]) {
            NSLog(@"_mainMOC save error: %@", [error description]);
        }
        
        /* Save writer */
        [[self writerMOC] performBlock:^(void) {
            NSError *error = nil;
            if (![[self writerMOC] save:&error]) {
                NSLog(@"_writerMOC save error: %@", [error description]);
            }
        }];
    }];
}

#pragma mark - Tools

- (void)raiseExceptionWithReason:(NSString *)reason
{
    NSException *exception = [NSException exceptionWithName:NSStringFromClass([self class]) reason:reason userInfo:@{}];
    [exception raise];
}

@end
