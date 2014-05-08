//
//  MFMigrationManager.h
//  Obsidian
//
//  Created by Michaël Fortin on 10/21/2013.
//  Copyright (c) 2013 Michaël Fortin. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSString *(^VersionProviderBlock)();

@class MFMigrationManager;

@protocol MFMigrationManagerDelegate <NSObject>

- (void)migrationManager:(MFMigrationManager *)migrationManager didMigrateToVersion:(NSString *)version;

@end

@interface MFMigrationManager : NSObject

@property (weak) id<MFMigrationManagerDelegate> delegate;

#pragma mark Lifetime

+ (instancetype)migrationManager;
+ (instancetype)migrationManagerWithName:(NSString *)name;
+ (instancetype)migrationManagerWithName:(NSString *)name currentVersionProvider:(VersionProviderBlock)currentVersionProviderBlock;

- (id)init;
- (id)initWithName:(NSString *)name;
- (id)initWithName:(NSString *)name currentVersionProvider:(VersionProviderBlock)currentVersionProviderBlock;

#pragma mark Public Methods

- (void)whenMigratingToVersion:(NSString *)version run:(void (^)())action;
- (void)reset;

@end