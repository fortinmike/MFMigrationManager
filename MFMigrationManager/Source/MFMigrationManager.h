//
//  MFMigrationManager.h
//  Obsidian
//
//  Created by Michaël Fortin on 10/21/2013.
//  Copyright (c) 2013 Michaël Fortin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MFMigrationManager;

@protocol MFMigrationManagerDelegate <NSObject>

- (void)migrationManager:(MFMigrationManager *)migrationManager didMigrateToVersion:(NSString *)version;

@end

@interface MFMigrationManager : NSObject

@property (weak) id<MFMigrationManagerDelegate> delegate;

#pragma mark Lifetime

+ (instancetype)migrationManagerWithName:(NSString *)name;
- (id)initWithName:(NSString *)name;

#pragma mark Public Methods

- (void)migrateToVersion:(NSString *)version action:(void (^)())action;
- (void)reset;

@end