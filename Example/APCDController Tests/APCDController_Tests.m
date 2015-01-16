//
//  APCDController_Tests.m
//  APCDController Tests
//
//  Created by Deszip on 22/09/14.
//  Copyright (c) 2014 Alterplay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

#import "APCDController.h"

@interface APCDController_Tests : XCTestCase

@end

@implementation APCDController_Tests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testBuildTime {
    [self measureBlock:^{
        [APCDController defaultController];
    }];
}



@end
