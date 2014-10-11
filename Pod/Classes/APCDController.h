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
 *  @param storeType NSString indicating store type. Available are NSSQLiteStoreType, NSXMLStoreType, NSBinaryStoreType, NSInMemoryStoreType. Using CFBundleName Info.plist value as model file name.
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

/* CoreData stack accessors */
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

/**
 *  Convinience version of '- (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;
' which uses defaultController instance.
 *
 * @see - (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;
 */
+ (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;

/**
 *  Creates new MOC with NSPrivateQueueConcurrencyType or return already existed using provided name as a key.
 *
 *  @param contextName NSString name to use for context
 *
 *  @return NSManagedObjectContext context attached as a child to mainMOC
 */
- (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;

/**
 *  Convinience version of '- (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;
 ' which uses defaultController instance.
 *
 *  @see - (NSManagedObjectContext *)spawnBackgroundContextWithName:(NSString *)contextName;
 */
+ (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread;

/**
 *  Creates new MOC with NSPrivateQueueConcurrencyType or return already existed using return value of provided NSThread description method as a key.
 *
 *  @note Returned context will use its own thread and you should access it only with one of 'performBlock' methods. Thread passed in argument is used only for key generation.
 *
 *  @param thread NSThread to be used as a key for context
 *
 *  @return NSManagedObjectContext context attached as a child to mainMOC
 */
- (NSManagedObjectContext *)spawnBackgroundContextForThread:(NSThread *)thread;

/**
 *  Convinience version of '- (void)performSave' which uses defaultController instance.
 *
 *  @see - (void)performSave
 */
+ (void)performSave;

/**
 *  Saves main and writer MOCs, saving of worker MOC and any spawned contexts should be performed manually.
 */
- (void)performSave;

@end
