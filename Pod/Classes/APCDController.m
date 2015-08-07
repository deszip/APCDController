//
//  APCDController.m
//  APCDController
//
//  Created by Deszip on 25.07.13.
//  Copyright (c) 2013 Alterplay. All rights reserved.
//

#import "APCDController.h"

/**
 *  Exceptions strings
 */
static NSString * const kAPCDControllerNoModelFileException         = @"Can't find model '%@'";
static NSString * const kAPCDControllerModelFailureException        = @"Failed to initialize NSManagedObjectModel '%@'";
static NSString * const kAPCDControllerStorAddingFailureException   = @"Failed to add store to coordinator: %@";

/**
 *  Compiled model file extensions.
 *  Note that 'mom' is used for a single model and 'momd' for a versioned model with 'mom' inside for each version.
 */
static NSString * const kAPCDControllerModelMOMExtension            = @"mom";
static NSString * const kAPCDControllerModelMOMDExtension           = @"momd";

/**
 *  Used to get default name for store
 */
static NSString * const kAPCDControllerAppBundleNameKey             = @"CFBundleName";

static APCDController *defaultController = nil;

@interface APCDController () {
    
}

@property (assign, nonatomic) NSString *appGroupIdentifier;
@property (strong, nonatomic) NSString *storeType;
@property (strong, nonatomic) NSString *storeName;
@property (strong, nonatomic) NSMutableDictionary *spawnedContexts;

/**
 *  Gets URL for model file. Due to lack of clear instructions in Apple documentation starting with .momd file. If this could not be found, tries .mom file, and fails with nil if it also wasn't found.
 *
 *  @return NSURL url for model file
 */
- (NSURL *)modelURL;

/**
 *  Gets URL fro store file. Takes in account passed in application container id
 *
 *  @return NSURL url for store file
 */
- (NSURL *)storeURL;

/**
 *  Wraps obtaining store name
 *
 *  @return NSString fro Info.plist CFBundleName key
 */
+ (NSString *)storeName;

/**
 *  Exception raising wrapper
 *
 *  @param reason NSString string used as reason for exception
 */
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
    APCDController *controller = [[self alloc] initWithStoreType:storeType andName:[self storeName] inAppGroupWithID:nil];
    
    return controller;
}

+ (instancetype)controllerWithStoreType:(NSString *)storeType andName:(NSString *)storeName
{
    APCDController *controller = [[self alloc] initWithStoreType:storeType andName:storeName inAppGroupWithID:nil];
    
    return controller;
}

+ (instancetype)controllerWithStoreType:(NSString *)storeType andName:(NSString *)storeName inAppGroupWithID:(NSString *)containerId
{
    APCDController *controller = [[self alloc] initWithStoreType:storeType andName:storeName inAppGroupWithID:containerId];
    
    return controller;
}

- (instancetype)initWithStoreType:(NSString *)storeType andName:(NSString *)storeName inAppGroupWithID:(NSString *)containerId
{
    self = [super init];
    if (self) {
        _appGroupIdentifier = containerId;
        _storeType = storeType;
        _storeName = storeName;
        _spawnedContexts = [NSMutableDictionary dictionary];
        
        [self buildMOCs];
    }
    
    return self;
}

- (instancetype)init
{
    return [self initWithStoreType:NSSQLiteStoreType andName:@"" inAppGroupWithID:@""];
}

#pragma mark - CoreData stack

- (NSManagedObjectModel *)dataModel
{
	if ( _mom == nil) {
        if (_storeName) {
            NSURL *modelURL = [self modelURL];
            if (!modelURL) {
                NSString *exceptionReason = [NSString stringWithFormat:kAPCDControllerNoModelFileException, _storeName];
                [self raiseExceptionWithReason:exceptionReason];
            }
            
            _mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
        } else {
            _mom = [NSManagedObjectModel mergedModelFromBundles:@[[NSBundle bundleForClass:[self class]]]];
        }
        
        if (!_mom) {
            NSString *exceptionReason = [NSString stringWithFormat:kAPCDControllerModelFailureException, _storeName];
            [self raiseExceptionWithReason:exceptionReason];
        }
	}
	
	return _mom;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_psc == nil) {
        NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @(YES),
                                        NSInferMappingModelAutomaticallyOption: @(YES)};
        
        _psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self dataModel]];
        NSError *error = nil;
        NSString *psName = [NSString stringWithFormat:@"%@.sqlite", _storeName];
        
        if (![_psc addPersistentStoreWithType:self.storeType configuration:nil URL:[[self storeURL] URLByAppendingPathComponent:psName] options:options error:&error]) {
            NSString *exceptionReason = [NSString stringWithFormat:kAPCDControllerStorAddingFailureException, error];
            [self raiseExceptionWithReason:exceptionReason];
        }
    }
    
    return _psc;
}

- (NSManagedObjectContext *)mainMOC
{
    return _mainMOC;
}

- (NSManagedObjectContext *)workerMOC
{
    return _workerMOC;
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

- (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread
{
    return [self spawnBackgroundContextWithName:thread.description];
}

- (NSManagedObjectContext *)spawnEphemeralBackgroundContext
{
    NSManagedObjectContext *newContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [newContext setParentContext:[self mainMOC]];

    return newContext;
}

- (void)performSave
{
    /* Check changes in both contexts */
    if (![[self mainMOC] hasChanges] && ![[self writerMOC] hasChanges]) return;
    
    /* Save main */
    [[self mainMOC] performBlockAndWait:^(void) {
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

- (NSURL *)modelURL
{
    NSString *modelPath = nil;
    NSBundle *currentBundle = [NSBundle bundleForClass:[self class]];
    
    modelPath = [currentBundle pathForResource:_storeName ofType:kAPCDControllerModelMOMDExtension];
    if (!modelPath) {
        modelPath = [currentBundle pathForResource:_storeName ofType:kAPCDControllerModelMOMExtension];
        if (!modelPath) {
            return nil;
        }
    }
    
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    
    return modelURL;
}

- (NSURL *)storeURL
{
#if TARGET_OS_IPHONE
    
    if (self.appGroupIdentifier.length > 0) {
        return [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:self.appGroupIdentifier];
    }
    
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

+ (NSString *)storeName
{
    return [[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:kAPCDControllerAppBundleNameKey];
}

- (void)raiseExceptionWithReason:(NSString *)reason
{
    NSException *exception = [NSException exceptionWithName:NSStringFromClass([self class]) reason:reason userInfo:@{}];
    [exception raise];
}

@end
