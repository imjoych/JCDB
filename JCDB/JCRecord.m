//
//  JCRecord.m
//  JCDB
//
//  Created by ChenJianjun on 16/6/16.
//  Copyright © 2016 Joych<https://github.com/imjoych>. All rights reserved.
//
//  SQLite3 datatype link: http://sqlite.org/datatype3.html

#import "JCRecord.h"
#import <objc/runtime.h>
#import "JCRecordClassProperty.h"

static const char *kJCRecordClassPropertiesKey;
static const char *kJCPrimaryKeyPropertyNameKey;

@implementation JCRecord

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}

+ (NSArray<JCRecordClassProperty *> *)properties
{
    NSDictionary *classProperties = objc_getAssociatedObject([self class], &kJCRecordClassPropertiesKey);
    if (classProperties) {
        return [classProperties allValues];
    }
    
    [self inspectProperties];
    classProperties = objc_getAssociatedObject([self class], &kJCRecordClassPropertiesKey);
    return [classProperties allValues];
}

+ (NSString *)primaryKeyPropertyName
{
    return objc_getAssociatedObject([self class], &kJCPrimaryKeyPropertyNameKey);
}

+ (BOOL)propertyIsIgnored:(NSString *)propertyName
{
    return NO;
}

#pragma mark - inspect properties

- (void)setup
{
    if (!objc_getAssociatedObject([self class], &kJCRecordClassPropertiesKey)) {
        [[self class] inspectProperties];
    }
}

+ (void)inspectProperties
{
    NSMutableDictionary *propertiesForNames = [NSMutableDictionary dictionary];
    
    Class class = [self class];
    NSScanner *scanner = nil;
    NSString *propertyType = nil;
    
    while (class != [JCRecord class]) {
        
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
        
        for (NSUInteger i = 0; i < propertyCount; i++) {
            
            JCRecordClassProperty *p = [[JCRecordClassProperty alloc] init];
            
            //get property name
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            p.name = @(propertyName);
            
            //get property attributes
            const char *attrs = property_getAttributes(property);
            NSString *propertyAttributes = @(attrs);
            NSArray *attributeItems = [propertyAttributes componentsSeparatedByString:@","];
            
            //ignore read-only properties
            if ([attributeItems containsObject:@"R"]) {
                continue;
            }
            
            scanner = [NSScanner scannerWithString:propertyAttributes];
            [scanner scanUpToString:@"T" intoString: nil];
            [scanner scanString:@"T" intoString:nil];
            
            //check if the property is an instance of a class
            if ([scanner scanString:@"@\"" intoString:&propertyType]) {
                
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"]
                                        intoString:&propertyType];
                
                p.classType = NSClassFromString(propertyType);
                p.dbFieldType = [self fieldTypeWithClassType:p.classType];
                
                //read through the property protocols
                while ([scanner scanString:@"<" intoString:NULL]) {
                    
                    NSString *protocolName = nil;
                    [scanner scanUpToString:@">" intoString:&protocolName];
                    
                    if ([protocolName isEqualToString:@"JCRecordPrimaryKey"]) {
                        p.isPrimaryKey = YES;
                        objc_setAssociatedObject([self class],
                                                 &kJCPrimaryKeyPropertyNameKey,
                                                 p.name,
                                                 OBJC_ASSOCIATION_RETAIN);
                    } else if ([protocolName isEqualToString:@"JCRecordIgnore"]) {
                        p.isIgnore = YES;
                    }
                    
                    [scanner scanString:@">" intoString:NULL];
                }
            } else {
                //the property contains a primitive data type
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@","]
                                        intoString:&propertyType];
                
                //get the full name of the primitive type
                propertyType = [self primitivesTypesForTypeSigns][propertyType];
                p.primitiveType = propertyType;
                p.dbFieldType = [self fieldTypeWithPrimitiveType:p.primitiveType];
            }
            
            if (p.isIgnore || [[self class] propertyIsIgnored:p.name]) {
                p = nil;
            } else if (p.dbFieldType.length < 1) {
                [self throwException:p];
            }
            
            if (p && ![propertiesForNames objectForKey:p.name]) {
                [propertiesForNames setValue:p forKey:p.name];
            }
        }
        free(properties);
        
        class = [class superclass];
    }
    
    objc_setAssociatedObject([self class],
                             &kJCRecordClassPropertiesKey,
                             [propertiesForNames copy],
                             OBJC_ASSOCIATION_RETAIN);
}

/** The database type is not allowed, throw exception. */
+ (void)throwException:(JCRecordClassProperty *)p
{
    @throw [NSException exceptionWithName:@"JCRecordClassProperty type not allowed"
                                   reason:[NSString stringWithFormat:@"Property type of %@.%@ is not supported by JCRecord.", [self class], p.name]
                                 userInfo:nil];
}


#pragma mark - SQLite3 data type transformer

/** Database field type for property class type. */
+ (NSString *)fieldTypeWithClassType:(Class)classType
{
    NSDictionary *fieldTypes = [self allowedPropertyTypesForFieldTypes];
    for (NSString *key in fieldTypes) {
        NSArray *propertyTypes = fieldTypes[key];
        for (id type in propertyTypes) {
            if ([type isKindOfClass:[NSString class]]
                && type != [NSString class]) {
                continue;
            }
            if ([classType isSubclassOfClass:type]) {
                return key;
            }
        }
    }
    return nil;
}

/** Database field type for property primitive type. */
+ (NSString *)fieldTypeWithPrimitiveType:(NSString *)primitiveType
{
    NSDictionary *fieldTypes = [self allowedPropertyTypesForFieldTypes];
    for (NSString *key in fieldTypes) {
        NSArray *propertyTypes = fieldTypes[key];
        for (id type in propertyTypes) {
            if (![type isKindOfClass:[NSString class]]
                || type == [NSString class]) {
                continue;
            }
            if ([primitiveType isEqualToString:type]) {
                return key;
            }
        }
    }
    return nil;
}

/** Property primitives types for types signs. */
+ (NSDictionary *)primitivesTypesForTypeSigns
{
    return @{@"c":@"BOOL",
             @"B":@"BOOL", //__LP64__
             @"s":@"short",
             @"i":@"int",
             @"l":@"long",
             @"q":@"long",
             @"I":@"NSInteger",
             @"Q":@"NSUInteger",
             @"f":@"float",
             @"d":@"double"};
}

/** Sqlite3 database field types.
 *  NUMERIC type values stored by INTEGER type.
 */
+ (NSDictionary *)allowedPropertyTypesForFieldTypes
{
    return @{@"TEXT": @[[NSString class], [NSNumber class], [NSDate class]],
             @"INTEGER": @[@"BOOL", @"short", @"int", @"long", @"NSInteger", @"NSUInteger"],
             @"REAL": @[@"float", @"double"],
             @"BLOB": @[[NSData class]]
             };
}

@end
