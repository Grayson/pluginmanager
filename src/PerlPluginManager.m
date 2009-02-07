//
//  PerlPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "PerlPluginManager.h"


@implementation PerlPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	if (NSClassFromString(@"CBPerl")) [PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Perl"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"pl", @"perl", nil]; }

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

- (void)build
{
	if (_plugins) [_plugins release];
	_plugins = [NSMutableDictionary new];
	for (NSString *path in [PluginManager pluginFilesForSubmanager:self])
	{
		CBPerl *perl = [CBPerl sharedPerl];
		NSString *perlCode = [NSString stringWithContentsOfFile:path];
		[perl eval:perlCode];
		NSString *property = [perl eval:@"actionProperty();"];
		if (!property) continue;
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:perlCode];
		[_plugins setObject:arr forKey:property];
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!_plugins) [self build];
	NSArray *plugins = [_plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	NSString *perlCode = nil;
	NSMutableArray *ret = [NSMutableArray array];
	CBPerl *perl = [CBPerl sharedPerl];
	withValue = withValue ? withValue : [NSNull null];
	forValue = forValue ? forValue : [NSNull null];
	while (perlCode = [pluginEnumerator nextObject])
	{
		[perl eval:perlCode];
		[perl setValue:forValue forKey:@"_forValue"];
		[perl setValue:withValue forKey:@"_withValue"];
		if ([[perl eval:@"actionEnable($_forValue, $_withValue);"] boolValue]) {
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[perl eval:@"actionTitle($_forValue, $_withValue);"], @"title",
				perlCode, @"code", nil]];
		}
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	NSString *perlCode = [plugin objectForKey:@"code"];
	if (!perlCode) return;
	CBPerl *perl = [CBPerl sharedPerl];
	[perl eval:perlCode];
	[perl setValue:forValue ? forValue : [NSNull null] forKey:@"_forValue"];
	[perl setValue:withValue ? withValue : [NSNull null] forKey:@"_withValue"];
	[perl eval:@"actionPerform($_withValue, $_forValue);"];
}

-(id)runScriptAtPath:(NSString *)path
{
	return [[CBPerl sharedPerl] eval:[NSString stringWithContentsOfFile:path]];
}

@end
