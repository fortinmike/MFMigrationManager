//
//  MFMigrationManagerSpec.m
//  Obsidian
//
//  Created by Michaël Fortin on 2013-05-23.
//  Copyright (c) 2013 Michaël Fortin. All rights reserved.
//

#import <Kiwi.h>
#import <mach/mach_time.h>
#import "MFMigrationManager.h"

SPEC_BEGIN(MFMigrationManagerSpec)

describe(@"MFMigrationManager", ^
{
	context(@"when migrating", ^
	{
		__block MFMigrationManager *migrationManager;
		
		beforeEach(^
		{
			migrationManager = [[MFMigrationManager alloc] initWithName:NSStringFromClass([self class])];
			[migrationManager performSelector:@selector(setLastMigrationVersion:) withObject:nil];
		});
		
		it(@"should accept migrations with valid version strings", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"11.24"];
			
			[migrationManager migrateToVersion:@"1.0-0" action:^{}];
			[migrationManager migrateToVersion:@"1.0.7-8" action:^{}];
			[migrationManager migrateToVersion:@"1.0.12-8" action:^{}];
			[migrationManager migrateToVersion:@"1.1-2" action:^{}];
			[migrationManager migrateToVersion:@"1.1.2-1" action:^{}];
			[migrationManager migrateToVersion:@"1.3.5.6" action:^{}];
			[migrationManager migrateToVersion:@"1.5.2.7.1-1" action:^{}];
			[migrationManager migrateToVersion:@"10.21.1-0" action:^{}];
		});
		
		it(@"should migrate to zero sub-version", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.0"];
			
			__block BOOL migrated = NO;
			[migrationManager migrateToVersion:@"1.0-0" action:^{ migrated = YES; }];
			[[theValue(migrated) should] beYes];
		});
		
		it(@"should be able to migrate to sub-versions of the current app version", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.1"];
			
			__block BOOL migrated1 = NO;
			[migrationManager migrateToVersion:@"1.1-0" action:^{ migrated1 = YES; }];
			[[theValue(migrated1) should] beYes];
			
			__block BOOL migrated2 = NO;
			[migrationManager migrateToVersion:@"1.1-2" action:^{ migrated2 = YES; }];
			[[theValue(migrated2) should] beYes];
		});
		
		it(@"should throw when adding migrations with invalid version strings", ^
		{
			[[theBlock(^{ [migrationManager migrateToVersion:@"1" action:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager migrateToVersion:@"1b" action:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager migrateToVersion:@"1.1a" action:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager migrateToVersion:@"1.3.1rc1" action:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager migrateToVersion:@"1.9.a" action:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager migrateToVersion:@"1.0.123" action:^{}]; }) should] raise];
		});
		
		it(@"should run all migrations in the appropriate order given valid version strings", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0.5"];
			[migrationManager stub:@selector(appVersion) andReturn:@"2.0"];
			
			__block uint64_t migrationTime1 = 0;
			__block uint64_t migrationTime2 = 0;
			__block uint64_t migrationTime3 = 0;
			__block uint64_t migrationTime4 = 0;
			__block uint64_t migrationTime5 = 0;
			
			[migrationManager migrateToVersion:@"1.1" action:^{ migrationTime1 = mach_absolute_time(); }];
			[migrationManager migrateToVersion:@"1.1-1" action:^{ migrationTime2 = mach_absolute_time(); }];
			[migrationManager migrateToVersion:@"1.2-8" action:^{ migrationTime3 = mach_absolute_time(); }];
			[migrationManager migrateToVersion:@"1.3.0" action:^{ migrationTime4 = mach_absolute_time(); }];
			[migrationManager migrateToVersion:@"1.4.0-1" action:^{ migrationTime5 = mach_absolute_time(); }];
			
			[[theValue(migrationTime1) shouldNot] equal:theValue(0)];
			[[theValue(migrationTime2) shouldNot] equal:theValue(0)];
			[[theValue(migrationTime3) shouldNot] equal:theValue(0)];
			[[theValue(migrationTime4) shouldNot] equal:theValue(0)];
			[[theValue(migrationTime5) shouldNot] equal:theValue(0)];
			
			[[theValue(migrationTime2) should] beGreaterThan:theValue(migrationTime1)];
			[[theValue(migrationTime3) should] beGreaterThan:theValue(migrationTime2)];
			[[theValue(migrationTime4) should] beGreaterThan:theValue(migrationTime3)];
			[[theValue(migrationTime5) should] beGreaterThan:theValue(migrationTime4)];
		});
		
		it(@"should not run migrations whose version is smaller or equal to the initial version ran", ^
		{
			// Stub various methods to obtain the internal state that we want to test with
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.2"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.3"];
			
			__block BOOL ranEarlierVersionMigration = NO;
			[migrationManager migrateToVersion:@"1.1" action:^{ ranEarlierVersionMigration = YES; }];
			[[theValue(ranEarlierVersionMigration) should] beNo];
			
			__block BOOL ranInitialVersionMigration = NO;
			[migrationManager migrateToVersion:@"1.2" action:^{ ranInitialVersionMigration = YES; }];
			[[theValue(ranInitialVersionMigration) should] beNo];
			
			__block BOOL ranLaterVersionMigration1 = NO;
			[migrationManager migrateToVersion:@"1.2-1" action:^{ ranLaterVersionMigration1 = YES; }];
			[[theValue(ranLaterVersionMigration1) should] beYes];
			
			__block BOOL ranLaterVersionMigration2 = NO;
			[migrationManager migrateToVersion:@"1.3" action:^{ ranLaterVersionMigration2 = YES; }];
			[[theValue(ranLaterVersionMigration2) should] beYes];
		});
		
		it(@"should throw for migrations whose version is greater than the current app version", ^
		{
			// Stub various methods to obtain the internal state that we want to test with
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.2"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.3"];
			
			[[theBlock(^{ [migrationManager migrateToVersion:@"1.8" action:^{}]; }) should] raise];
		});
		
		it(@"should throw when defining migrations in the wrong version order", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.2"];
			
			[migrationManager migrateToVersion:@"1.0-1" action:^{}];
			[migrationManager migrateToVersion:@"1.1" action:^{}];
			[migrationManager migrateToVersion:@"1.2" action:^{}];
			[[theBlock(^{ [migrationManager migrateToVersion:@"1.1.1" action:^{}]; }) should] raise];
		});
	});
});

SPEC_END