//
//  APCDController.h
//  APCDController
//
//  Created by Deszip on 25.07.13.
//  Copyright (c) 2013 Alterplay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface APCDController : NSObject {
    NSManagedObjectModel *_mom;
    NSPersistentStoreCoordinator *_psc;
    NSManagedObjectContext *_mainMOC;
    NSManagedObjectContext *_workerMOC;
    NSManagedObjectContext *_writerMOC;
}

#pragma mark - Initializers

/**
 *  Singleton constructor.
 *  Returns singleton instance with NSSQLiteStoreType store sat up with DB name from CFBundleName Info.plist value
 *
 *  @return AVMCDController with NSSQLiteStoreType store, fully initialized with sat up store and built MOCs
 */
+ (instancetype)defaultController;

/**
 *  Convinience initializer
 *
 *  @param storeType    NSString    indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType. Using CFBundleName Info.plist value as model file name.
 *
 *  @return AVMCDController with store of passed type.
 */
+ (instancetype)controllerWithStoreType:(NSString *)storeType;

/**
 *  Convinience initializer
 *
 *  @param storeType    NSString    indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
 *  @param storeName    NSString    used for store name in case store type is set to NSSQLiteStoreType. Ignored for other store types.
 *
 *  @return AVMCDController with store of passed type.
 */
+ (instancetype)controllerWithStoreType:(NSString *)storeType andName:(NSString *)storeName;

/**
 *  Convinience initializer
 *
 *  @param storeType    NSString    indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
 *  @param storeName    NSString    used for store name in case store type is set to NSSQLiteStoreType. Ignored for other store types.
 *  @param containerId  NSString    identifier for application group to use for persistent store. Used to share store with app extension or XPC service.
 *
 *  @return AVMCDController with store of passed type.
 */
+ (instancetype)controllerWithStoreType:(NSString *)storeType andName:(NSString *)storeName inAppGroupWithID:(NSString *)containerId;

/**
 *  Designated initializer
 *
 *  @param storeType    NSString    indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType
 *  @param storeName    NSString    used for store name in case store type is set to NSSQLiteStoreType. Ignored for other store types.
 *  @param containerId  NSString    identifier for application group to use for persistent store. Used to share store with app extension or XPC service.
 *
 *  @return AVMCDController with store of passed type. Avoid using any except NSSQLiteStoreType.
 */
- (instancetype)initWithStoreType:(NSString *)storeType andName:(NSString *)storeName inAppGroupWithID:(NSString *)containerId
 __attribute__((objc_designated_initializer));

#pragma mark - Core Data Stack Accessors

- (NSManagedObjectModel *)dataModel;
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectContext *)mainMOC;
- (NSManagedObjectContext *)workerMOC;
- (NSManagedObjectContext *)writerMOC;

#pragma mark - CoreData routines

/**
 *  Creates new MOC with NSPrivateQueueConcurrencyType or return already existed using provided name as a key.
 *
 *  @param contextName  NSString    name to use for context
 *
 *  @return NSManagedObjectContext context attached as a child to mainMOC
 */
- (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;

/**
 *  Creates new MOC with NSPrivateQueueConcurrencyType or return already existed using return value of provided NSThread description method as a key.
 *
 *  @note Returned context will use its own thread and you should access it only with one of 'performBlock' methods. Thread passed in argument is used only for key generation.
 *
 *  @param thread       NSThread    thread to be used as a key for context
 *
 *  @return NSManagedObjectContext context attached as a child to mainMOC
 */
- (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread;

/**
 *  Creates new ephemeral context with NSPrivateQueueConcurrencyType. Will not be cached. You are responsive for its memory management.
 *
 *  @note Returned context will use its own thread and you should access it only with one of 'performBlock' methods. 
 *  @return NSManagedObjectContext context attached as a child to mainMOC
 */
- (NSManagedObjectContext *)spawnEphemeralBackgroundContext;

/**
 *  Saves main and writer MOCs, saving of worker MOC and any spawned contexts should be performed manually.
 */
- (void)performSave;

@end
