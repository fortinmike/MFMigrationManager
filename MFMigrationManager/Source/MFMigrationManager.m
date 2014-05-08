//
//  MFMigrationManager.m
//  Obsidian
//
//  Created by Michaël Fortin on 10/21/2013.
//  Copyright (c) 2013 Michaël Fortin. All rights reserved.
//
//  Note: Inspired by https://github.com/mysterioustrousers/MTMigration
//

#import "MFMigrationManager.h"
#import "NSString+Regexer.h"

@implementation MFMigrationManager
{
	VersionProviderBlock _currentVersionProviderBlock;
	
	NSString *_initialVersionKey;
	NSString *_lastVersionKey;
	
	NSString *_previousVersion;
}

static NSString *MFMigrationManagerInitialVersionKey = @"MFMigrationManagerInitialVersionKey";
static NSString *MFMigrationManagerLastVersionKey = @"MFMigrationManagerLastVersionKey";

static NSString *MFMigrationManagerVersionRegexString = @"^([0-9]{1,2}\\.)+[0-9]{1,2}(-[0-9]{1,2})?$";

#pragma mark Lifetime

+ (instancetype)migrationManager
{
	return [[self alloc] init];
}

+ (instancetype)migrationManagerWithName:(NSString *)name
{
	return [[self alloc] initWithName:name currentVersionProvider:nil];
}

+ (instancetype)migrationManagerWithName:(NSString *)name currentVersionProvider:(VersionProviderBlock)currentVersionProviderBlock
{
	return [[self alloc] initWithName:name currentVersionProvider:currentVersionProviderBlock];
}

- (id)init
{
	return [self initWithName:nil];
}

- (id)initWithName:(NSString *)name
{
	return [self initWithName:name currentVersionProvider:nil];
}

- (id)initWithName:(NSString *)name currentVersionProvider:(VersionProviderBlock)currentVersionProviderBlock
{
	self = [super init];
	if (self)
	{
		_currentVersionProviderBlock = currentVersionProviderBlock;
		
		_initialVersionKey = name ? [MFMigrationManagerInitialVersionKey stringByAppendingFormat:@"-%@", name] : MFMigrationManagerInitialVersionKey;
		_lastVersionKey = name ? [MFMigrationManagerLastVersionKey stringByAppendingFormat:@"-%@", name] : MFMigrationManagerLastVersionKey;
		
		[self storeInitialVersion];
	}
	return self;
}

#pragma mark Public Methods

- (void)whenMigratingToVersion:(NSString *)version run:(void (^)())action
{
	[self assertVersionMatchesRegex:version];
	[self assertVersionSmallerThanAppVersion:version];
	[self assertVersionOrderIsValid:version];
	
	if ([self shouldMigrateToVersion:version])
	{
		action();
		
		[self setLastMigrationVersion:version];
		
		if ([self.delegate respondsToSelector:@selector(migrationManager:didMigrateToVersion:)])
			[self.delegate migrationManager:self didMigrateToVersion:version];
	}
}

- (void)reset
{
    [self setLastMigrationVersion:nil];
}

#pragma mark Implementation

- (void)storeInitialVersion
{
	if ([[self initialVersion] isEqualToString:@""])
		[self setInitialVersion:[self appVersion]];
}

- (void)assertVersionOrderIsValid:(NSString *)version
{
	if (_previousVersion && ![self isVersion:version greaterThan:_previousVersion])
	{
		NSString *reason = [NSString stringWithFormat:@"Migration version %@ is defined after version %@, which is not permitted!", version, _previousVersion];
		@throw [NSException exceptionWithName:@"Migration Exception" reason:reason userInfo:nil];
	}
	
	_previousVersion = version;
}

- (void)assertVersionMatchesRegex:(NSString *)version
{
	if (!version || ![version rx_matchesPattern:MFMigrationManagerVersionRegexString])
	{
		NSString *reason = [NSString stringWithFormat:@"Invalid version string \"%@\", see regex and spec for appropriate version format", version];
		@throw [NSException exceptionWithName:@"Migration Exception" reason:reason userInfo:nil];
	}
}

- (void)assertVersionSmallerThanAppVersion:(NSString *)version
{
	if ([self isVersionGreaterThanAppVersion:version])
	{
		NSString *reason = [NSString stringWithFormat:@"Cannot run migration for a version (%@) that is bigger than the current app version", version];
		@throw [NSException exceptionWithName:@"Migration Exception" reason:reason userInfo:nil];
	}
}

- (BOOL)shouldMigrateToVersion:(NSString *)version
{
	return [self isVersion:version greaterThan:[self initialVersion]] &&
		   [self isVersion:version greaterThan:[self lastMigrationVersion]];
}

- (BOOL)isVersionGreaterThanAppVersion:(NSString *)version
{
	NSString *versionWithoutSubVersion = [version componentsSeparatedByString:@"-"][0];
	return [self isVersion:versionWithoutSubVersion greaterThan:[self appVersion]];
}

- (BOOL)isVersion:(NSString *)version1 greaterThan:(NSString *)version2
{
	return ([version1 compare:version2 options:NSNumericSearch] == NSOrderedDescending);
}

- (NSString *)lastMigrationVersion
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:_lastVersionKey] ?: @"";
}

- (void)setLastMigrationVersion:(NSString *)version
{
	[[NSUserDefaults standardUserDefaults] setValue:version forKey:_lastVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)initialVersion
{
	return [[NSUserDefaults standardUserDefaults] valueForKey:_initialVersionKey] ?: @"";
}

- (void)setInitialVersion:(NSString *)version
{
    [[NSUserDefaults standardUserDefaults] setValue:version forKey:_initialVersionKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark Helper Methods

- (NSString *)appVersion
{
	if (_currentVersionProviderBlock)
	{
		return _currentVersionProviderBlock();
	}
	else
	{
		return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	}
}

@end