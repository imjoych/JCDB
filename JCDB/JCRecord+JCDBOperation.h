//
//  JCRecord+JCDBOperation.h
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Boych<https://github.com/Boych>. All rights reserved.
//

#import "JCRecord.h"

/**
 * Database operation.
 */
@interface JCRecord (JCDBOperation)

#pragma mark - Table operation

/** Create table With class name. */
+ (BOOL)createTable;

/** Delete table */
+ (BOOL)dropTable;

/** Add column in the table. */
+ (BOOL)alterTableWithColumn:(NSString *)column;

#pragma mark - Records operation

/** Query a record with primary key value. */
+ (id)queryRecordWithPrimaryKeyValue:(id)value;

/** Query records with conditions which are properties values for properties names. */
+ (NSArray<JCRecord *> *)queryRecordListWithConditions:(NSDictionary *)conditions;

/** Query all records */
+ (NSArray<JCRecord *> *)queryAllRecords;

/** Count all records in the table. */
+ (uint64_t)countAllRecords;

/** Delete all records in the table. */
+ (BOOL)deleteAllRecords;

#pragma mark - Current record operation

/** Update or insert the record. */
- (BOOL)updateRecord;

/** Delete the record. */
- (BOOL)deleteRecord;

@end
