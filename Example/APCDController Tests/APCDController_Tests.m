//
//  APCDController_Tests.m
//  APCDController Tests
//
//  Created by Deszip on 22/09/14.
//  Copyright (c) 2014 Alterplay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import <OCMock/OCMock.h>

#define EXP_SHORTHAND
#import "Expecta.h"

#import "APCDController.h"

static NSString * const kAPCDControllerDefaultModelName     = @"APCDController";
static NSString * const kAPCDControllerSecondModelName      = @"Foo";
static NSString * const kAPCDControllerFakeModelName        = @"NoSuchModel";


@interface APCDController_Tests : XCTestCase

@end

@implementation APCDController_Tests

- (void)setUp
{
    [super setUp];
}

- (void)tearDown
{
    [super tearDown];
}

- (void)testBuildTime
{
    [self measureBlock:^{
        [APCDController controllerWithStoreType:NSSQLiteStoreType andName:kAPCDControllerDefaultModelName];
    }];
}

- (void)testModelLoadingByName
{
    APCDController *controller_1 = [APCDController controllerWithStoreType:NSSQLiteStoreType andName:kAPCDControllerSecondModelName];
    APCDController *controller_2 = [APCDController controllerWithStoreType:NSSQLiteStoreType andName:kAPCDControllerDefaultModelName];

    NSURL *storeURL_1 = [[controller_1.persistentStoreCoordinator.persistentStores firstObject] URL];
    NSURL *storeURL_2 = [[controller_2.persistentStoreCoordinator.persistentStores firstObject] URL];
    
    BOOL store1Loaded = [[[storeURL_1 lastPathComponent] stringByDeletingPathExtension] isEqualToString:kAPCDControllerSecondModelName];
    BOOL store2Loaded = [[[storeURL_2 lastPathComponent] stringByDeletingPathExtension] isEqualToString:kAPCDControllerDefaultModelName];
    
    expect(store1Loaded && store2Loaded).to.beTruthy();
}

- (void)testModelLoadingByDefaultPath
{
    APCDController *controller = [APCDController controllerWithStoreType:NSSQLiteStoreType andName:kAPCDControllerDefaultModelName];
    NSURL *storeURL = [[controller.persistentStoreCoordinator.persistentStores firstObject] URL];
    BOOL storeLoaded = [[[storeURL lastPathComponent] stringByDeletingPathExtension] isEqualToString:kAPCDControllerDefaultModelName];
    
    expect(storeLoaded).to.beTruthy();
}

- (void)testModelLoadingFailure
{
    expect(^{
        [APCDController controllerWithStoreType:NSSQLiteStoreType andName:kAPCDControllerFakeModelName];
    }).to.raiseAny();
}

@end
