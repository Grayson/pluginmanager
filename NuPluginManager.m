//
//  ObjCPluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 11/27/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "NuPluginManager.h"


@implementation NuPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Nu"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"nu"]; }

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
	NSString *pluginsPath = [PluginManager pathToPluginsFolder];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isFolder;
	if (![fm fileExistsAtPath:pluginsPath isDirectory:&isFolder] || !isFolder) return;
	
	NSArray *plugins = [fm directoryContentsAtPath:pluginsPath];
	plugins = [plugins arrayByAddingObjectsFromArray:[fm directoryContentsAtPath:[[NSBundle mainBundle] pathForResource:@"Plugins" ofType:nil]]];
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	NSString *path;
	NSArray *extensions = [self extensions];
	while (path = [pluginEnumerator nextObject])
	{
		if (![extensions containsObject:[path pathExtension]]) goto next;
		
		id parser = [Nu parser];
		NSString *nuCode = [NSString stringWithContentsOfFile:[pluginsPath stringByAppendingPathComponent:path]];
		[parser parseEval:nuCode];
		NSString *property = [parser parseEval:@"(actionProperty)"];
		
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:nuCode];
		[_plugins setObject:arr forKey:property];
		[parser close];
		
		next:;
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!_plugins) [self build];
	NSArray *plugins = [_plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	id plugin;
	NSMutableArray *ret = [NSMutableArray array];
	withValue = withValue ? withValue : [NSNull null];
	forValue = forValue ? forValue : [NSNull null];
	while (plugin = [pluginEnumerator nextObject])
	{
		id parser = [Nu parser];
		[parser parseEval:plugin];
		[parser setValue:forValue forKey:@"_pluginWithValue"];
		[parser setValue:withValue forKey:@"_pluginForValue"];
		if ([[parser parseEval:@"(actionEnable _pluginWithValue _pluginForValue)"] boolValue])
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[parser parseEval:@"(actionTitle _pluginWithValue _pluginForValue)"], @"title",
				plugin, @"plugin",
				nil]];
		[parser close];
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	withValue = withValue ? withValue : [NSNull null];
	forValue = forValue ? forValue : [NSNull null];
	NSString *nuCode = [plugin objectForKey:@"plugin"];
	id parser = [Nu parser];
	[parser parseEval:nuCode];
	[parser setValue:forValue forKey:@"_pluginWithValue"];
	[parser setValue:withValue forKey:@"_pluginForValue"];
	[parser parseEval:@"(actionPerform _pluginWithValue _pluginForValue)"];
	[parser close];
}

-(id)runScriptAtPath:(NSString *)path
{
	id parser = [Nu parser];
	id ret = [parser parseEval:[NSString stringWithContentsOfFile:path]];
	[parser close];
	return ret;
}

@end
