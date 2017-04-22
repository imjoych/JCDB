//
//  JCTestRecord.h
//  JCDB
//
//  Created by ChenJianjun on 16/6/20.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import "JCRecord.h"
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger, JCTestEnumType) {
    JCTestEnumTypeZero,
    JCTestEnumTypeOne,
    JCTestEnumTypeTwo
};

@interface JCTestRecord : JCRecord

@property (nonatomic, strong) NSString<JCRecordPrimaryKey> *testPrimaryKey;
@property (nonatomic, strong) NSString<JCRecordIgnore> *testIgnore;
@property (nonatomic, strong) NSMutableString *testMutableString;
@property (nonatomic, strong) NSNumber *testNumber;
@property (nonatomic, strong) NSDecimalNumber *testDecimalNumber;
@property (nonatomic, strong) NSDate *testDate;
@property (nonatomic, strong) NSData *testData;
@property (nonatomic, strong) NSMutableData *testMutableData;

@property (nonatomic, assign) BOOL testBOOL;
@property (nonatomic, assign) short testShort;
@property (nonatomic, assign) int testInt;
@property (nonatomic, assign) long testLong;
@property (nonatomic, assign) NSInteger testInteger;
@property (nonatomic, assign) JCTestEnumType testEnumType;
@property (nonatomic, assign) int64_t testInt64;
@property (nonatomic, assign) NSUInteger testUInteger;
@property (nonatomic, assign) float testFloat;
@property (nonatomic, assign) CGFloat testCGFloat;
@property (nonatomic, assign) double testDouble;
@property (nonatomic, assign) NSTimeInterval testTimeInterval;
@property (nonatomic, assign) long int testLongInt;
@property (nonatomic, assign) long long int testLongLongInt;
@property (nonatomic, assign) unsigned long long int testUnsignedLongLongInt;

@end
