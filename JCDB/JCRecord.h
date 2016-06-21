//
//  JCRecord.h
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Boych<https://github.com/Boych>. All rights reserved.
//

#import <Foundation/Foundation.h>

/** Protocol for defining the primary key property in a JCRecord class. */
@protocol JCRecordPrimaryKey <NSObject>
@end

/** Protocol for defining ignored properties in a JCRecord class. */
@protocol JCRecordIgnore <NSObject>
@end

/** Make all objects optional compatible to avoid compiler warnings. */
@interface NSObject(JCRecordPropertyCompatibility)<JCRecordPrimaryKey, JCRecordIgnore>
@end

@class JCRecordClassProperty;

/**
 * Super class of common data structure for database storage.
 */
@interface JCRecord : NSObject

/** Return class properties. */
+ (NSArray<JCRecordClassProperty *> *)properties;

/** Return property name of primary key. */
+ (NSString *)primaryKeyPropertyName;

/** Properties is ignored, implemented by subclass. */
+ (BOOL)propertyIsIgnored:(NSString *)propertyName;

@end
