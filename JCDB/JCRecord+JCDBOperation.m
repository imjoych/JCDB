//
//  JCRecord+JCDBOperation.m
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//
//  SQLite language link: http://sqlite.org/lang.html

#import "JCRecord+JCDBOperation.h"
#import "JCDBManager.h"
#import "JCRecordClassProperty.h"
#import <FMDB/FMDB.h>

#ifdef DEBUG
#define JCDBLog(...) NSLog(__VA_ARGS__)
#else
#define JCDBLog(...)
#endif

static NSString *const CREATE_TABLE_SQL = @"CREATE TABLE IF NOT EXISTS %@ (%@)";

static NSString *const DROP_TABLE_SQL = @"DROP TABLE IF EXISTS %@";

static NSString *const ALTER_TABLE_SQL = @"ALTER TABLE %@ ADD %@ %@";

static NSString *const UPDATE_RECORD_SQL = @"INSERT OR REPLACE INTO %@ (%@) VALUES (%@)";

static NSString *const UPDATE_RECORD_COLUMNS_SQL = @"UPDATE %@ SET %@ WHERE %@ = ?";

static NSString *const SELECT_ALL_SQL = @"SELECT * FROM %@";

static NSString *const SELECT_RECORD_SQL = @"SELECT * FROM %@ WHERE %@ = ? LIMIT 1";

static NSString *const SELECT_COLUMNS_SQL = @"SELECT %@ FROM %@";

static NSString *const COUNT_ALL_SQL = @"SELECT COUNT(*) AS 'count' FROM %@";

static NSString *const DELETE_ALL_SQL = @"DELETE FROM %@";

static NSString *const DELETE_RECORD_SQL = @"DELETE FROM %@ WHERE %@ = ?";

@implementation JCRecord (JCDBOperation)

#pragma mark - Table operation

+ (BOOL)createTable
{
    NSArray *properties = [self properties];
    NSAssert([self primaryKeyPropertyName].length > 0, @"primary key is not exist");
    
    NSString *propertiesString = nil;
    for (JCRecordClassProperty *property in properties) {
        NSString *propertyNameAndType = [NSString stringWithFormat:@"%@ %@", property.name, property.dbFieldType];
        if (property.isPrimaryKey) {
            propertyNameAndType = [NSString stringWithFormat:@"%@ PRIMARY KEY NOT NULL", propertyNameAndType];
        }
        if (propertiesString) {
            propertiesString = [NSString stringWithFormat:@"%@, %@", propertiesString, propertyNameAndType];
        } else {
            propertiesString = propertyNameAndType;
        }
    }
    NSString *sql = [NSString stringWithFormat:CREATE_TABLE_SQL, NSStringFromClass([self class]), propertiesString];
    return [self executeUpdateWithSql:sql
                            arguments:nil];
}

+ (BOOL)dropTable
{
    NSString *sql = [NSString stringWithFormat:DROP_TABLE_SQL, NSStringFromClass([self class])];
    return [self executeUpdateWithSql:sql
                            arguments:nil];
}

+ (BOOL)alterTableWithColumn:(NSString *)column
{
    if (column.length < 1) {
        return NO;
    }
    if ([self columnExists:column]) {
        return NO;
    }
    
    NSArray *properties = [self properties];
    NSString *fieldType = nil;
    for (JCRecordClassProperty *property in properties) {
        if ([property.name isEqualToString:column]) {
            fieldType = property.dbFieldType;
            break;
        }
    }
    if (fieldType.length < 1) {
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:ALTER_TABLE_SQL, NSStringFromClass([self class]), column, fieldType];
    return [self executeUpdateWithSql:sql
                            arguments:nil];
}

#pragma mark - Records operation

+ (id)queryRecordWithPrimaryKeyValue:(id)value
{
    if (!value) {
        return nil;
    }
    
    NSString *sql = [NSString stringWithFormat:SELECT_RECORD_SQL, NSStringFromClass([self class]), [self primaryKeyPropertyName]];
    __block JCRecord *record = nil;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql, value];
        if ([rs next]) {
            record = [self recordWithResultSet:rs];
        }
        [rs close];
    }];
    return record;
}

+ (NSArray<JCRecord *> *)queryRecordsWithConditions:(NSDictionary *)conditions
{
    if (conditions.count < 1) {
        return nil;
    }
    NSArray *expressionAndArguments = [self conditionalExpressionAndArguments:conditions];
    return [self queryRecordsWithConditionalExpression:expressionAndArguments[0]
                                             arguments:expressionAndArguments[1]];
}

+ (NSArray<JCRecord *> *)queryRecordsWithConditionalExpression:(NSString *)conditionalExpression
                                                     arguments:(NSArray *)arguments
{
    if (conditionalExpression.length < 1) {
        return nil;
    }
    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, NSStringFromClass([self class])];
    sql = [NSString stringWithFormat:@"%@ %@", sql, conditionalExpression];
    return [self queryRecordsWithSql:sql
                           arguments:arguments];
}

+ (NSArray<JCRecord *> *)queryAllRecords
{
    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, NSStringFromClass([self class])];
    return [self queryRecordsWithSql:sql
                           arguments:nil];
}

+ (NSArray<NSDictionary *> *)queryColumns:(NSArray<NSString *> *)columns
                    conditionalExpression:(NSString *)conditionalExpression
                                arguments:(NSArray *)arguments
{
    if (columns.count < 1
        || conditionalExpression.length < 1) {
        return nil;
    }
    
    NSString *columnsString = nil;
    for (NSString *column in columns) {
        if (![self columnExists:column]) {
            JCDBLog(@"column named '%@' is not exist in the table!!!", column);
            return nil;
        }
        if (columnsString) {
            columnsString = [NSString stringWithFormat:@"%@,%@", columnsString, column];
        } else {
            columnsString = column;
        }
    }
    NSString *sql = [NSString stringWithFormat:SELECT_COLUMNS_SQL, columnsString, NSStringFromClass([self class])];
    sql = [NSString stringWithFormat:@"%@ %@", sql, conditionalExpression];
    __block NSMutableArray *columnsList = [NSMutableArray array];
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:arguments];
        while ([rs next]) {
            NSMutableDictionary *columnsDict = [NSMutableDictionary dictionaryWithCapacity:columns.count];
            for (NSString *column in columns) {
                columnsDict[column] = [rs objectForColumnName:column];
            }
            [columnsList addObject:columnsDict];
        }
        [rs close];
    }];
    return columnsList;
}

+ (uint64_t)countRecordsWithConditions:(NSDictionary *)conditions
{
    if (conditions.count < 1) {
        return 0;
    }
    NSArray *expressionAndArguments = [self conditionalExpressionAndArguments:conditions];
    return [self countRecordsWithConditionalExpression:expressionAndArguments[0]
                                             arguments:expressionAndArguments[1]];
}

+ (uint64_t)countRecordsWithConditionalExpression:(NSString *)conditionalExpression
                                        arguments:(NSArray *)arguments
{
    if (conditionalExpression.length < 1) {
        return 0;
    }
    
    NSString *sql = [NSString stringWithFormat:COUNT_ALL_SQL, NSStringFromClass([self class])];
    sql = [NSString stringWithFormat:@"%@ %@", sql, conditionalExpression];
    return [self countRecordsWithSql:sql
                           arguments:arguments];
}

+ (uint64_t)countAllRecords
{
    NSString *sql = [NSString stringWithFormat:COUNT_ALL_SQL, NSStringFromClass([self class])];
    return [self countRecordsWithSql:sql
                           arguments:nil];
}

+ (BOOL)deleteRecordsWithConditions:(NSDictionary *)conditions
{
    if (conditions.count < 1) {
        return NO;
    }
    NSArray *expressionAndArguments = [self conditionalExpressionAndArguments:conditions];
    return [self deleteRecordsWithConditionalExpression:expressionAndArguments[0]
                                              arguments:expressionAndArguments[1]];
}

+ (BOOL)deleteRecordsWithConditionalExpression:(NSString *)conditionalExpression
                                     arguments:(NSArray *)arguments
{
    if (conditionalExpression.length < 1) {
        return NO;
    }
    
    NSString *sql = [NSString stringWithFormat:DELETE_ALL_SQL, NSStringFromClass([self class])];
    sql = [NSString stringWithFormat:@"%@ %@", sql, conditionalExpression];
    return [self executeUpdateWithSql:sql
                            arguments:arguments];
}

+ (BOOL)deleteAllRecords
{
    NSString *sql = [NSString stringWithFormat:DELETE_ALL_SQL, NSStringFromClass([self class])];
    return [self executeUpdateWithSql:sql
                            arguments:nil];
}

#pragma mark - Current record operation

- (BOOL)updateRecord
{
    NSArray *properties = [[self class] properties];
    NSString *propertyKeys = nil;
    NSString *propertyValueSigns = nil;
    NSMutableArray *propertyValues = [NSMutableArray array];
    for (JCRecordClassProperty *property in properties) {
        id value = [self valueForKey:property.name];
        if (!value || [value isKindOfClass:[NSNull class]]) {
            if ([property.name isEqualToString:[[self class] primaryKeyPropertyName]]) {
                JCDBLog(@"primary key value is not valid!!!");
                return NO;
            }
            continue;
        }
        if (!propertyKeys) {
            propertyKeys = property.name;
            propertyValueSigns = @"?";
        } else {
            propertyKeys = [NSString stringWithFormat:@"%@, %@", propertyKeys, property.name];
            propertyValueSigns = [NSString stringWithFormat:@"%@, ?", propertyValueSigns];
        }
        [propertyValues addObject:value];
    }
    if (!propertyKeys || !propertyValueSigns) {
        return NO;
    }
    
    NSString *sql = [NSString stringWithFormat:UPDATE_RECORD_SQL, NSStringFromClass([self class]), propertyKeys, propertyValueSigns];
    return [[self class] executeUpdateWithSql:sql
                                    arguments:propertyValues];
}

- (BOOL)updateRecordColumns:(NSArray<NSString *> *)columns
                     values:(NSArray *)values
{
    if (columns.count < 1
        || values.count < 1) {
        return NO;
    }
    
    NSString *primaryKeyPropertyName = [[self class] primaryKeyPropertyName];
    NSString *primaryKeyPropertyValue = [self valueForKey:primaryKeyPropertyName];
    if (!primaryKeyPropertyValue) {
        JCDBLog(@"primary key value is not valid!!!");
        return NO;
    }
    if ([columns containsObject:primaryKeyPropertyName]) {
        JCDBLog(@"columns should not contains the primary key, which can't be updated!!!");
        return NO;
    }
    
    NSString *columnsNamesAndValueSigns = nil;
    for (NSString *column in columns) {
        if (![[self class] columnExists:column]) { // column is not exist in the table
            return NO;
        }
        
        NSString *nameAndValueSign = [NSString stringWithFormat:@"%@ = ?", column];
        if (!columnsNamesAndValueSigns) {
            columnsNamesAndValueSigns = nameAndValueSign;
        } else {
            columnsNamesAndValueSigns = [NSString stringWithFormat:@"%@, %@", columnsNamesAndValueSigns, nameAndValueSign];
        }
    }
    
    NSString *sql = [NSString stringWithFormat:UPDATE_RECORD_COLUMNS_SQL, NSStringFromClass([self class]), columnsNamesAndValueSigns, primaryKeyPropertyName];
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:values];
    [arguments addObject:primaryKeyPropertyValue];
    return [[self class] executeUpdateWithSql:sql
                                    arguments:arguments];
}

- (BOOL)deleteRecord
{
    NSString *primaryKeyPropertyName = [[self class] primaryKeyPropertyName];
    NSString *primaryKeyPropertyValue = [self valueForKey:primaryKeyPropertyName];
    if (!primaryKeyPropertyValue) {
        JCDBLog(@"primary key value is not valid!!!");
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:DELETE_RECORD_SQL, NSStringFromClass([self class]), primaryKeyPropertyName];
    return [[self class] executeUpdateWithSql:sql
                                    arguments:@[primaryKeyPropertyValue]];
}

#pragma mark - Private

/** Check column is exists in the table. */
+ (BOOL)columnExists:(NSString *)column
{
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db columnExists:column inTableWithName:NSStringFromClass([self class])];
    }];
    return result;
}

/** Execute update with sql and arguments. */
+ (BOOL)executeUpdateWithSql:(NSString *)sql
                   arguments:(NSArray *)arguments
{
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withArgumentsInArray:arguments];
    }];
    return result;
}

/** Query records with sql and arguments. */
+ (NSArray<JCRecord *> *)queryRecordsWithSql:(NSString *)sql
                                   arguments:(NSArray *)arguments
{
    __block NSMutableArray *recordList = [NSMutableArray array];
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:arguments];
        while ([rs next]) {
            JCRecord *record = [self recordWithResultSet:rs];
            [recordList addObject:record];
        }
        [rs close];
    }];
    return recordList;
}

/** Return JCRecord instance from query item FMResultSet. */
+ (JCRecord *)recordWithResultSet:(FMResultSet *)rs
{
    JCRecord *record = [[[self class] alloc] init];
    NSArray *properties = [self properties];
    for (JCRecordClassProperty *property in properties) {
        id value = [rs objectForColumnName:property.name];
        if (value && ![value isKindOfClass:[NSNull class]]) {
            [record setValue:value forKey:property.name];
        }
    }
    return record;
}

/** Count records with sql. */
+ (uint64_t)countRecordsWithSql:(NSString *)sql
                      arguments:(NSArray *)arguments
{
    __block uint64_t count = 0;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql withArgumentsInArray:arguments];
        if ([rs next]) {
            count = [rs unsignedLongLongIntForColumn:@"count"];
        }
        [rs close];
    }];
    return count;
}

/** conditional AND expression and arguments with conditions. */
+ (NSArray *)conditionalExpressionAndArguments:(NSDictionary *)conditions
{
    NSString *conditionalExpression = nil;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:conditions.count];
    for (NSString *key in conditions) {
        NSString *conditionStr = [NSString stringWithFormat:@"%@ = ?", key];
        if (conditionalExpression) {
            conditionalExpression = [NSString stringWithFormat:@"%@ AND %@", conditionalExpression, conditionStr];
        } else {
            conditionalExpression = conditionStr;
        }
        [values addObject:conditions[key]];
    }
    conditionalExpression = [NSString stringWithFormat:@" WHERE %@", conditionalExpression];
    return @[conditionalExpression, values];
}

@end
