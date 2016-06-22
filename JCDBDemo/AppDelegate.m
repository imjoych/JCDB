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
    
    NSLog(@"start update record list...");
    uint64_t beginTime = mach_absolute_time();
    [self updateRecordListTest];
    uint64_t endTime = mach_absolute_time();
    NSLog(@"update record list times: %.2fs", (CGFloat)(endTime - beginTime)/1000000000);
    
    JCTestRecord *record = [JCTestRecord queryRecordWithPrimaryKeyValue:@"primaryKeyProperty2"];
    NSLog(@"queryRecordWithPrimaryKeyValue: %@", record);
    
    BOOL result = [record updateRecordColumns:@[@"testBOOL", @"testDate", @"testNumber"]
                                       values:@[@(NO), [NSDate dateWithTimeIntervalSince1970:9], @(6.22)]];
    NSLog(@"updateRecordColumns:values: %@", @(result));
    
    result = [record deleteRecord];
    NSLog(@"deleteRecord %@", @(result));
    
    NSArray *queryRecords = [JCTestRecord queryRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}];
    NSLog(@"queryRecordsWithConditions: %@", @(queryRecords.count));
    
    queryRecords = [JCTestRecord queryRecordsWithConditionalExpression:@"WHERE testEnumType < ?" arguments:@[@(JCTestEnumTypeTwo)]];
    NSLog(@"queryRecordsWithConditionalExpression:arguments: %@", @(queryRecords.count));
    
    queryRecords = [JCTestRecord queryRecordsWithConditionalExpression:@"ORDER BY testEnumType DESC" arguments:nil];
    NSLog(@"queryRecordsWithConditionalExpression:arguments: %@", @(queryRecords.count));
    
    queryRecords = [JCTestRecord queryAllRecords];
    NSLog(@"queryAllRecords %@", @(queryRecords.count));
    
    NSArray *queryColumns = [JCTestRecord queryColumns:@[@"testPrimaryKey", @"testDate"]
                                 conditionalExpression:@"WHERE testEnumType < ? ORDER BY testInteger DESC"
                                             arguments:@[@(JCTestEnumTypeOne)]];
    NSLog(@"queryColumns:conditionalExpression:arguments: %@", @(queryColumns.count));
    
    uint64_t count = [JCTestRecord countAllRecords];
    NSLog(@"countAllRecords %@", @(count));
    
    result = [JCTestRecord deleteAllRecords];
    NSLog(@"deleteAllRecords %@", @(result));
    
    result = [JCTestRecord dropTable];
    NSLog(@"dropTable %@", @(result));
}

- (void)updateRecordListTest
{
    for (NSInteger index = 0; index < 2016; index++) {
        JCTestRecord *record = [[JCTestRecord alloc] init];
        record.testPrimaryKey = [NSString stringWithFormat:@"primaryKeyProperty%@", @(index + 1)];
        record.testIgnore = @"ignoreProperty";
        record.testMutableString = [[NSMutableString alloc] initWithString:@"mutableStringProperty"];
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
            NSLog(@"updateRecord %@", @(success));
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
