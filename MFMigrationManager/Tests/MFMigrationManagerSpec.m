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
			migrationManager = [[MFMigrationManager alloc] initWithName:[[NSUUID UUID] UUIDString]];
		});
		
		it(@"should accept migrations with valid version strings", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"11.24"];
			
			[migrationManager whenMigratingToVersion:@"1.0-0" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.0.7-8" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.0.12-8" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.1-2" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.1.2-1" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.3.5.6" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.5.2.7.1-1" run:^{}];
			[migrationManager whenMigratingToVersion:@"10.21.1-0" run:^{}];
		});
		
		it(@"should migrate to zero sub-version", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.0"];
			
			__block BOOL migrated = NO;
			[migrationManager whenMigratingToVersion:@"1.0-0" run:^{ migrated = YES; }];
			[[theValue(migrated) should] beYes];
		});
		
		it(@"should be able to migrate to sub-versions of the current app version", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.1"];
			
			__block BOOL migrated1 = NO;
			[migrationManager whenMigratingToVersion:@"1.1-0" run:^{ migrated1 = YES; }];
			[[theValue(migrated1) should] beYes];
			
			__block BOOL migrated2 = NO;
			[migrationManager whenMigratingToVersion:@"1.1-2" run:^{ migrated2 = YES; }];
			[[theValue(migrated2) should] beYes];
		});
		
		it(@"should throw when adding migrations with invalid version strings", ^
		{
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1" run:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1b" run:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1.1a" run:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1.3.1rc1" run:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1.9.a" run:^{}]; }) should] raise];
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1.0.123" run:^{}]; }) should] raise];
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
			
			[migrationManager whenMigratingToVersion:@"1.1" run:^{ migrationTime1 = mach_absolute_time(); }];
			[migrationManager whenMigratingToVersion:@"1.1-1" run:^{ migrationTime2 = mach_absolute_time(); }];
			[migrationManager whenMigratingToVersion:@"1.2-8" run:^{ migrationTime3 = mach_absolute_time(); }];
			[migrationManager whenMigratingToVersion:@"1.3.0" run:^{ migrationTime4 = mach_absolute_time(); }];
			[migrationManager whenMigratingToVersion:@"1.4.0-1" run:^{ migrationTime5 = mach_absolute_time(); }];
			
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
			[migrationManager whenMigratingToVersion:@"1.1" run:^{ ranEarlierVersionMigration = YES; }];
			[[theValue(ranEarlierVersionMigration) should] beNo];
			
			__block BOOL ranInitialVersionMigration = NO;
			[migrationManager whenMigratingToVersion:@"1.2" run:^{ ranInitialVersionMigration = YES; }];
			[[theValue(ranInitialVersionMigration) should] beNo];
			
			__block BOOL ranLaterVersionMigration1 = NO;
			[migrationManager whenMigratingToVersion:@"1.2-1" run:^{ ranLaterVersionMigration1 = YES; }];
			[[theValue(ranLaterVersionMigration1) should] beYes];
			
			__block BOOL ranLaterVersionMigration2 = NO;
			[migrationManager whenMigratingToVersion:@"1.3" run:^{ ranLaterVersionMigration2 = YES; }];
			[[theValue(ranLaterVersionMigration2) should] beYes];
		});
		
		it(@"should throw for migrations whose version is greater than the current app version", ^
		{
			// Stub various methods to obtain the internal state that we want to test with
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.2"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.3"];
			
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1.8" run:^{}]; }) should] raise];
		});
		
		it(@"should throw when defining migrations in the wrong version order", ^
		{
			[migrationManager stub:@selector(initialVersion) andReturn:@"1.0"];
			[migrationManager stub:@selector(appVersion) andReturn:@"1.2"];
			
			[migrationManager whenMigratingToVersion:@"1.0-1" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.1" run:^{}];
			[migrationManager whenMigratingToVersion:@"1.2" run:^{}];
			[[theBlock(^{ [migrationManager whenMigratingToVersion:@"1.1.1" run:^{}]; }) should] raise];
		});
	});
	
	context(@"multiple migration managers", ^
	{
		it(@"should run migrations independently of one another", ^
		{
			__block BOOL migration1Ran;
			__block BOOL migration2Ran;
			__block BOOL migration3Ran;
			__block BOOL migration4Ran;
			
			MFMigrationManager *manager1 = [MFMigrationManager migrationManagerWithName:@"Manager1"];
			[manager1 stub:@selector(initialVersion) andReturn:@"1.0"];
			[manager1 stub:@selector(appVersion) andReturn:@"1.2"];
			[manager1 performSelector:@selector(setLastMigrationVersion:) withObject:nil];
			
			MFMigrationManager *manager2 = [MFMigrationManager migrationManagerWithName:@"Manager2"];
			[manager2 stub:@selector(initialVersion) andReturn:@"1.0"];
			[manager2 stub:@selector(appVersion) andReturn:@"1.2"];
			[manager2 performSelector:@selector(setLastMigrationVersion:) withObject:nil];
			
			[manager1 whenMigratingToVersion:@"1.1" run:^{ migration1Ran = YES; }];
			[manager2 whenMigratingToVersion:@"1.1" run:^{ migration2Ran = YES; }];
			[manager2 whenMigratingToVersion:@"1.2" run:^{ migration3Ran = YES; }];
			[manager1 whenMigratingToVersion:@"1.2" run:^{ migration4Ran = YES; }];
			
			[[theValue(migration1Ran) should] beYes];
			[[theValue(migration2Ran) should] beYes];
			[[theValue(migration3Ran) should] beYes];
			[[theValue(migration4Ran) should] beYes];
		});
	});
});

SPEC_END