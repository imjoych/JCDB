//
//  JCRecordClassProperty.h
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//

#import <Foundation/Foundation.h>

/** 
 * Property attributes class of JCRecord class.
 */
@interface JCRecordClassProperty : NSObject

@property (nonatomic, strong) NSString *name; ///< Property name

@property (nonatomic, strong) Class classType; ///< Property class type

@property (nonatomic, strong) NSString *primitiveType; ///< Property primitive type

@property (nonatomic, strong) NSString *dbFieldType; ///< The field type of property in the database, it should not be nil.

@property (nonatomic, assign) BOOL isPrimaryKey; ///< Property is the primary key

@property (nonatomic, assign) BOOL isIgnore; ///< Property is ignored

@end
