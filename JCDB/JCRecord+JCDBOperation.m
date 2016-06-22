//
//  JCRecord+JCDBOperation.m
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Boych<https://github.com/Boych>. All rights reserved.
//
//  SQLite language link: http://sqlite.org/lang.html

#import "JCRecord+JCDBOperation.h"
#import "JCDBManager.h"
#import "JCRecordClassProperty.h"
#import <FMDB/FMDB.h>

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

static NSString *const RECORD_VALUE_SIGN_FLAG = @"?";

@implementation JCRecord (JCDBOperation)

#pragma mark - Table operation

+ (BOOL)createTable
{
    NSArray *properties = [self properties];
    NSAssert([self primaryKeyPropertyName].length > 0, @"primary key is not exist");
    
    NSString *tableName = NSStringFromClass([self class]);
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
    NSString *sql = [NSString stringWithFormat:CREATE_TABLE_SQL, tableName, propertiesString];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    return result;
}

+ (BOOL)dropTable
{
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:DROP_TABLE_SQL, tableName];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    return result;
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
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:ALTER_TABLE_SQL, tableName, column, fieldType];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    return result;
}

#pragma mark - Records operation

+ (id)queryRecordWithPrimaryKeyValue:(id)value
{
    if (!value) {
        return nil;
    }
    NSString *tableName = NSStringFromClass([self class]);
    NSString *primaryKeyPropertyName = [self primaryKeyPropertyName];
    NSString *sql = [NSString stringWithFormat:SELECT_RECORD_SQL, tableName, primaryKeyPropertyName];
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
    NSString *conditionalExpression = nil;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:conditions.count];
    for (NSString *key in conditions) {
        NSString *conditionStr = [NSString stringWithFormat:@"%@ = %@", key, RECORD_VALUE_SIGN_FLAG];
        if (conditionalExpression) {
            conditionalExpression = [NSString stringWithFormat:@"%@ AND %@", conditionalExpression, conditionStr];
        } else {
            conditionalExpression = conditionStr;
        }
        [values addObject:conditions[key]];
    }
    conditionalExpression = [NSString stringWithFormat:@" WHERE %@", conditionalExpression];
    return [self queryRecordsWithConditionalExpression:conditionalExpression
                                             arguments:values];
}

+ (NSArray<JCRecord *> *)queryRecordsWithConditionalExpression:(NSString *)conditionalExpression
                                                     arguments:(NSArray *)arguments
{
    if (conditionalExpression.length < 1) {
        return nil;
    }
    
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, tableName];
    sql = [NSString stringWithFormat:@"%@ %@", sql, conditionalExpression];
    return [self queryRecordsWithSql:sql
                           arguments:arguments];
}

+ (NSArray<JCRecord *> *)queryAllRecords
{
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:SELECT_ALL_SQL, tableName];
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
        if (![self columnExists:column]) { // column is not exist in the table
            return nil;
        }
        if (columnsString) {
            columnsString = [NSString stringWithFormat:@"%@,%@", columnsString, column];
        } else {
            columnsString = column;
        }
    }
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:SELECT_COLUMNS_SQL, columnsString, tableName];
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

+ (uint64_t)countAllRecords
{
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:COUNT_ALL_SQL, tableName];
    __block uint64_t count = 0;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:sql];
        if ([rs next]) {
            count = [rs unsignedLongLongIntForColumn:@"count"];
        }
        [rs close];
    }];
    return count;
}

+ (BOOL)deleteAllRecords
{
    NSString *tableName = NSStringFromClass([self class]);
    NSString *sql = [NSString stringWithFormat:DELETE_ALL_SQL, tableName];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql];
    }];
    return result;
}

#pragma mark - Current record operation

- (BOOL)updateRecord
{
    NSString *tableName = NSStringFromClass([self class]);
    NSArray *properties = [[self class] properties];
    NSString *propertyKeys = nil;
    NSString *propertyValueSigns = nil;
    NSString *valueSignFlag = RECORD_VALUE_SIGN_FLAG;
    NSMutableArray *propertyValues = [NSMutableArray array];
    for (JCRecordClassProperty *property in properties) {
        if (!propertyKeys) {
            propertyKeys = property.name;
            propertyValueSigns = valueSignFlag;
        } else {
            propertyKeys = [NSString stringWithFormat:@"%@, %@", propertyKeys, property.name];
            propertyValueSigns = [NSString stringWithFormat:@"%@, %@", propertyValueSigns, valueSignFlag];
        }
        [propertyValues addObject:[self valueForKey:property.name]];
    }
    NSString *sql = [NSString stringWithFormat:UPDATE_RECORD_SQL, tableName, propertyKeys, propertyValueSigns];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withArgumentsInArray:propertyValues];
    }];
    return result;
}

- (BOOL)updateRecordColumns:(NSArray<NSString *> *)columns
                     values:(NSArray *)values
{
    if (columns.count < 1
        || values.count < 1) {
        return NO;
    }
    NSString *tableName = NSStringFromClass([self class]);
    NSString *primaryKeyPropertyName = [[self class] primaryKeyPropertyName];
    NSString *columnsNamesAndValueSigns = nil;
    NSString *valueSignFlag = RECORD_VALUE_SIGN_FLAG;
    for (NSString *column in columns) {
        if (![[self class] columnExists:column]) { // column is not exist in the table
            return NO;
        }
        if ([column isEqualToString:primaryKeyPropertyName]) { // update column should not be primary key
            return NO;
        }
        
        NSString *nameAndValueSign = [NSString stringWithFormat:@"%@ = %@", column, valueSignFlag];
        if (!columnsNamesAndValueSigns) {
            columnsNamesAndValueSigns = nameAndValueSign;
        } else {
            columnsNamesAndValueSigns = [NSString stringWithFormat:@"%@, %@", columnsNamesAndValueSigns, nameAndValueSign];
        }
    }
    
    NSString *sql = [NSString stringWithFormat:UPDATE_RECORD_COLUMNS_SQL, tableName, columnsNamesAndValueSigns, primaryKeyPropertyName];
    NSMutableArray *arguments = [NSMutableArray arrayWithArray:values];
    [arguments addObject:[self valueForKey:primaryKeyPropertyName]];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql withArgumentsInArray:arguments];
    }];
    return result;
}

- (BOOL)deleteRecord
{
    NSString *tableName = NSStringFromClass([self class]);
    NSString *primaryKeyPropertyName = [[self class] primaryKeyPropertyName];
    NSString *sql = [NSString stringWithFormat:DELETE_RECORD_SQL, tableName, primaryKeyPropertyName];
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db executeUpdate:sql, [self valueForKey:primaryKeyPropertyName]];
    }];
    return result;
}

#pragma mark - Private

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

+ (BOOL)columnExists:(NSString *)column
{
    NSString *tableName = NSStringFromClass([self class]);
    __block BOOL result = NO;
    [[JCDBManager sharedManager].dbQueue inDatabase:^(FMDatabase *db) {
        result = [db columnExists:column inTableWithName:tableName];
    }];
    return result;
}

@end
