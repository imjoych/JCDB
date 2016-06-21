//
//  JCDBManager.h
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Boych<https://github.com/Boych>. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

/**
 * Database manager class.
 */
@interface JCDBManager : NSObject

@property (nonatomic, strong, readonly) FMDatabaseQueue *dbQueue;

+ (instancetype)sharedManager;

/** Create database with dbName. */
- (void)createWithDBName:(NSString *)dbName;

/** Create database with dbPath. */
- (void)createWithDBPath:(NSString *)dbPath;

/** Close the database. */
- (void)closeDB;

@end
