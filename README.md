# JCDB
A lightweight iOS database framework based on [FMDB](https://github.com/ccgus/fmdb) and [SQLite](http://sqlite.org).

## Features
This framework supports the development of iOS 7.0+ in ARC.

* Database table CREATE/DROP/ALERT.
* Database records queries with SELECT.
* Database records INSERT/REPLACE/UPDATE/DELETE.

### Create and close database
```objective-c
[[JCDBManager sharedManager] createWithDBName:@"testDB.sqlite"];
```
```objective-c
[[JCDBManager sharedManager] closeDB];
```
### Table operation

##### CREATE table
```objective-c
[JCTestRecord createTable];
```
##### ALERT table
```objective-c
[JCTestRecord alterTableWithColumn:@"testUnsignedLongLongInt"];
```
##### DROP table
```objective-c
[JCTestRecord dropTable];
```

### Current record operation

##### INSERT OR REPLACE statement
```objective-c
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

BOOL result = [record updateRecord];
```
    
##### UPDATE statement
```objective-c
result = [record updateRecordColumns:@[@"testBOOL", @"testDate", @"testNumber"]
                              values:@[@(NO), [NSDate dateWithTimeIntervalSince1970:9], @(6.22)]];
```

##### DELETE statement
```objective-c
result = [record deleteRecord];
```

### Records operation

##### SELECT records queries 
```objective-c
JCTestRecord *record = [JCTestRecord queryRecordWithPrimaryKeyValue:@"primaryKeyProperty2"];
```
```objective-c
NSArray *queryRecords = [JCTestRecord queryRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}];
```
```objective-c
queryRecords = [JCTestRecord queryRecordsWithConditionalExpression:@"WHERE testEnumType < ?"
                                                         arguments:@[@(JCTestEnumTypeTwo)]];
```
```objective-c
queryRecords = [JCTestRecord queryRecordsWithConditionalExpression:@"ORDER BY testEnumType DESC"
                                                         arguments:nil];
```
```objective-c
queryRecords = [JCTestRecord queryAllRecords];
```

##### SELECT record columns queries
```objective-c
NSArray *queryColumns = [JCTestRecord queryColumns:@[@"testPrimaryKey", @"testDate"]
                             conditionalExpression:@"WHERE testEnumType < ? ORDER BY testInteger DESC"
                                         arguments:@[@(JCTestEnumTypeOne)]];
```
##### SELECT count queries
```objective-c
uint64_t count = [JCTestRecord countRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}];
```
```objective-c
count = [JCTestRecord countRecordsWithConditionalExpression:@"WHERE testEnumType < ?"
                                                  arguments:@[@(JCTestEnumTypeOne)]];
```
```objective-c
count = [JCTestRecord countAllRecords];
```
##### DELETE statement
```objective-c
BOOL result = [JCTestRecord deleteRecordsWithConditions:@{@"testEnumType":@(JCTestEnumTypeTwo)}];
```
```objective-c
result = [JCTestRecord deleteRecordsWithConditionalExpression:@"WHERE testEnumType < ?"
                                                    arguments:@[@(JCTestEnumTypeOne)]];
```
```objective-c
result = [JCTestRecord deleteAllRecords];
```

## CocoaPods
To integrate JCDB into your iOS project, specify it in your Podfile:
    
	pod 'JCDB'

##Contacts
If you have any questions or suggestions about the framework, please E-mail to contact me.

Author: [Joych](https://github.com/imjoych)	
E-mail: imjoych@gmail.com

## License
JCDB is released under the [MIT License](https://github.com/imjoych/JCDB/blob/master/LICENSE).
