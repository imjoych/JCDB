//
//  AppDelegate.m
//  JCDBDemo
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Boych<https://github.com/Boych>. All rights reserved.
//

#import "AppDelegate.h"
#import "JCTestRecord.h"
#import "JCDB.h"
#include <mach/mach_time.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)dbTest
{
    [[JCDBManager sharedManager] createWithDBName:@"testDB.sqlite"];
    [JCTestRecord createTable];
    [JCTestRecord alterTableWithColumn:@"testLongInt"];
    [JCTestRecord alterTableWithColumn:@"testLongLongInt"];
    [JCTestRecord alterTableWithColumn:@"testUnsignedLongLongInt"];
    [JCTestRecord alterTableWithColumn:@""];
    
    NSLog(@"start update record list...");
    [AppDelegate executeTime:^id {
        [self updateRecordListTest];
        return @(YES);
    }];
    
    __block JCTestRecord *record = nil;
    NSLog(@"queryRecordWithPrimaryKeyValue:");
    [AppDelegate executeTime:^id{
        record = [JCTestRecord queryRecordWithPrimaryKeyValue:@"primaryKeyProperty2"];
        return record;
    }];
    
    NSLog(@"updateRecordColumns:values:");
    [AppDelegate executeTime:^id{
        return @([record updateRecordColumns:@[@"testBOOL", @"testDate", @"testNumber"]
                                      values:@[@(NO), [NSDate dateWithTimeIntervalSince1970:9], @(6.22)]]);
    }];
    
    NSLog(@"deleteRecord");
    [AppDelegate executeTime:^id{
        return @([record deleteRecord]);
    }];

    __block NSArray *queryRecords = nil;
    NSLog(@"queryRecordsWithConditions:");
    [AppDelegate executeTime:^id{
        queryRecords = [JCTestRecord queryRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}];
        return @(queryRecords.count);
    }];
    
    NSLog(@"queryRecordsWithConditionalExpression:arguments:");
    [AppDelegate executeTime:^id{
        queryRecords = [JCTestRecord queryRecordsWithConditionalExpression:@"WHERE testEnumType < ?"
                                                                 arguments:@[@(JCTestEnumTypeTwo)]];
        return @(queryRecords.count);
    }];
    
    NSLog(@"queryRecordsWithConditionalExpression:arguments:");
    [AppDelegate executeTime:^id{
        queryRecords = [JCTestRecord queryRecordsWithConditionalExpression:@"ORDER BY testEnumType DESC"
                                                                 arguments:nil];
        return @(queryRecords.count);
    }];
    
    NSLog(@"queryAllRecords");
    [AppDelegate executeTime:^id{
        queryRecords = [JCTestRecord queryAllRecords];
        return @(queryRecords.count);
    }];
    
    NSLog(@"queryColumns:conditionalExpression:arguments:");
    [AppDelegate executeTime:^id{
        NSArray *queryColumns = [JCTestRecord queryColumns:@[@"testPrimaryKey", @"testDate"]
                                     conditionalExpression:@"WHERE testEnumType < ? ORDER BY testInteger DESC"
                                                 arguments:@[@(JCTestEnumTypeOne)]];
        return @(queryColumns.count);
    }];
    
    NSLog(@"countRecordsWithConditions:");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord countRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}]);
    }];
    
    NSLog(@"countRecordsWithConditionalExpression:arguments:");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord countRecordsWithConditionalExpression:@"WHERE testEnumType < ?"
                                                           arguments:@[@(JCTestEnumTypeOne)]]);
    }];
    
    NSLog(@"countAllRecords");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord countAllRecords]);
    }];
    
    NSLog(@"deleteRecordsWithConditions:");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord deleteRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}]);
    }];
    
    NSLog(@"deleteRecordsWithConditionalExpression:arguments:");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord deleteRecordsWithConditionalExpression:@"WHERE testEnumType < ?"
                                                            arguments:@[@(JCTestEnumTypeOne)]]);
    }];
    
    NSLog(@"deleteAllRecords");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord deleteAllRecords]);
    }];
    
    NSLog(@"dropTable");
    [AppDelegate executeTime:^id{
        return @([JCTestRecord dropTable]);
    }];
    
    [[JCDBManager sharedManager] closeDB];
}

+ (void)executeTime:(id(^)())completion;
{
    id result = nil;
    uint64_t beginTime = mach_absolute_time();
    if (completion) {
        result = completion();
    }
    uint64_t endTime = mach_absolute_time();
    NSLog(@"%@, %.5fs \n\n", result, (CGFloat)(endTime - beginTime)/1000000000);
}

- (void)updateRecordListTest
{
    for (NSInteger index = 0; index < 2016; index++) {
        JCTestRecord *record = [[JCTestRecord alloc] init];
        record.testPrimaryKey = [NSString stringWithFormat:@"primaryKeyProperty%@", @(index + 1)];
        record.testIgnore = @"ignoreProperty";
//        record.testMutableString = [[NSMutableString alloc] initWithString:@"mutableStringProperty"];
        record.testNumber = @(6.20);
        record.testDecimalNumber = [[NSDecimalNumber alloc] initWithString:@"2016"];
        record.testDate = [NSDate date];
        record.testData = [@"dataProperty" dataUsingEncoding:NSUTF8StringEncoding];
        record.testMutableData = [NSMutableData dataWithData:[@"mutableDataProperty" dataUsingEncoding:NSUTF8StringEncoding]];
        
        record.testBOOL = YES;
        record.testShort = 6;
        record.testInt = 20;
        record.testLong = 20160620;
        record.testInteger = index + 1;
        record.testEnumType = (index + 1) % 3;
        record.testInt64 = (index + 1)*24*3600;
        record.testUInteger = 201606;
        record.testFloat = 10.5;
        record.testCGFloat = 1.26;
        record.testDouble = 10.52;
        record.testTimeInterval = 978307200.0;
        record.testLongInt = 10000010;
        record.testLongLongInt = 1000000110;
        record.testUnsignedLongLongInt = 100000000111;
        
        BOOL success = [record updateRecord];
        if (success) {
//            NSLog(@"updateRecord %@", @(success));
        }
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    [self dbTest];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
