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

/** Query records with AND conditions which are properties values for properties names. */
+ (NSArray<JCRecord *> *)queryRecordsWithConditions:(NSDictionary *)conditions;

/** Query records with conditional expression and arguments. */
+ (NSArray<JCRecord *> *)queryRecordsWithConditionalExpression:(NSString *)conditionalExpression
                                                     arguments:(NSArray *)arguments;

/** Query all records */
+ (NSArray<JCRecord *> *)queryAllRecords;

/** Query columns values for columns names with conditional expression and arguments. */
+ (NSArray<NSDictionary *> *)queryColumns:(NSArray<NSString *> *)columns
                    conditionalExpression:(NSString *)conditionalExpression
                                arguments:(NSArray *)arguments;

/** Count all records in the table. */
+ (uint64_t)countAllRecords;

/** Delete all records in the table. */
+ (BOOL)deleteAllRecords;

#pragma mark - Current record operation

/** Insert or replace the record. */
- (BOOL)updateRecord;

/** Update some columns values of the record. */
- (BOOL)updateRecordColumns:(NSArray<NSString *> *)columns
                     values:(NSArray *)values;

/** Delete the record. */
- (BOOL)deleteRecord;

@end
