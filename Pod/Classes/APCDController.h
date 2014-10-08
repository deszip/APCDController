//
//  APCDController.h
//  Avaamo
//
//  Created by Deszip on 25.07.13.
//  Copyright (c) 2013 Igor. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

static NSString * const kDBName = @"APCDController";

@interface APCDController : NSObject {
    NSManagedObjectModel *_mom;
    NSPersistentStoreCoordinator *_psc;
    NSManagedObjectContext *_mainMOC;
    NSManagedObjectContext *_workerMOC;
    NSManagedObjectContext *_writerMOC;
    
    NSMutableDictionary *_spawnedContexts;
}

/**
 *  Singleton constructor.
 *  Returns singleton instance with NSSQLiteStoreType store sat up with DB name from kDBName constant
 *
 *  @return AVMCDController with NSSQLiteStoreType store, fully initialized with sat up store and built MOCs
 */
+ (instancetype)defaultController;

/**
 *  Convinience initializer
 *
 *  @param storeType NSString indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
 *
 *  @return AVMCDController with store of passed type.
 */
+ (instancetype)controllerWithStoreType:(NSString *)storeType;

/**
 *  Convinience initializer
 *
 *  @param storeType NSString indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
 *  @param storeName NSString used for store name in case store type is set to NSSQLiteStoreType. Ignored for other store types.
 *
 *  @return AVMCDController with store of passed type.
 */
+ (instancetype)controllerWithStoreType:(NSString *)storeType andName:(NSString *)storeName;

/**
 *  Designated initializer
 *
 *  @param storeType NSString indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
 *
 *  @return AVMCDController with store of passed type. Avoid using any except NSSQLiteStoreType.
 */
- (instancetype)initWithStoreType:(NSString *)storeType andName:(NSString *)storeName __attribute__((objc_designated_initializer));

/* CoreData stack */
+ (NSManagedObjectModel *)dataModel;
- (NSManagedObjectModel *)dataModel;
+ (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
+ (NSManagedObjectContext *)mainMOC;
- (NSManagedObjectContext *)mainMOC;
+ (NSManagedObjectContext *)workerMOC;
- (NSManagedObjectContext *)workerMOC;
+ (NSManagedObjectContext *)writerMOC;
- (NSManagedObjectContext *)writerMOC;
+ (NSMutableDictionary *)spawnedContexts;
- (NSMutableDictionary *)spawnedContexts;

/* CoreData routines */
+ (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;
- (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;

+ (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread;
- (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread;

+ (void)performSave;
- (void)performSave;

@end
