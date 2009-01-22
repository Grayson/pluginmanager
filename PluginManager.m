//
//  PluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 1/25/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "PluginManager.h"

@interface PluginManager (PrivateMethods)
-(BOOL)canRunFileWithExtension:(NSString *)ext;
-(id)runScriptAtPath:(NSString *)path;
-(void)buildPluginsDictionary;
-(void)loadPluginManagers;
-(void)registerManager:(id)manager;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue;
-(NSArray *)managerInfo;
@end

static id _pluginManagerInstance = nil;

@implementation PluginManager

+(id)manager
{
	if (!_pluginManagerInstance) _pluginManagerInstance = [[self class] new];
	return _pluginManagerInstance;
}

+(void)registerManager:(id)manager
{
	[[PluginManager manager] registerManager:manager];
}

-(void)registerManager:(id)manager
{
	if (![_pluginManagers containsObject:manager]) [_pluginManagers addObject:manager];
}

+(BOOL)canRunFileWithExtension:(NSString *)ext
{
	return [[PluginManager manager] canRunFileWithExtension:ext];
}

-(BOOL)canRunFileWithExtension:(NSString *)ext
{
	NSEnumerator *e = [[_pluginManagers valueForKeyPath:@"extensions"] objectEnumerator];
	NSArray *arr = nil;
	while (arr = [e nextObject]) if ([arr containsObject:ext]) return YES;
	return NO;
}

+(id)runScriptAtPath:(NSString *)path
{
	return [[PluginManager manager] runScriptAtPath:path];
}

-(id)runScriptAtPath:(NSString *)path
{
	NSEnumerator *e = [_pluginManagers objectEnumerator];
	id m = nil;
	NSString *ext = [path pathExtension];
	while (m = [e nextObject]) 
	{
		NSLog(@"%s %@", _cmd, [m extensions]);
		if ([[m extensions] containsObject:ext])
			return [m runScriptAtPath:path];
	}
	return nil;
}

-(id)init
{
	self = [super init];
	if (!self) return nil;
	
	_pluginManagers = [NSMutableArray new];
	[self loadPluginManagers];
	
	return self;
}

-(void)dealloc
{
	NSEnumerator *e = [_pluginManagers objectEnumerator];
	id m = nil;
	while (m = [e nextObject])
	{
		[_pluginManagers removeObject:m];
		[m release];
	}
	
	[_pluginManagers release];
	_pluginManagers = nil;
	[super dealloc];
}

+(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue;
{
	return [[PluginManager manager] pluginsForProperty:property forValue:forValue withValue:withValue];
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue;
{
	NSMutableArray *plugins = [NSMutableArray array];
	
	NSEnumerator *e = [_pluginManagers objectEnumerator];
	id m = nil;
	while (m = [e nextObject])
	{
		NSMutableArray *arr = [NSMutableArray array];
		NSEnumerator *ee = [[m pluginsForProperty:property forValue:forValue withValue:withValue] objectEnumerator];
		NSDictionary *d = nil;
		while (d = [ee nextObject])
		{
			NSMutableDictionary *dd = [[d mutableCopy] autorelease];
			[dd setObject:m forKey:@"target_plugin"];
			[arr addObject:dd];
		}
		[plugins addObjectsFromArray:arr];
	}
	
	return plugins;
}

+(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
{
	id p = [plugin objectForKey:@"target_plugin"];
	[p runPlugin:plugin forValue:forValue withValue:withValue];
}

+(NSArray *)managerInfo { return [[PluginManager manager] managerInfo]; }	
-(NSArray *)managerInfo
{
	NSEnumerator *e = [_pluginManagers objectEnumerator];
	id p = nil;
	NSMutableArray *arr = [NSMutableArray array];
	while (p = [e nextObject])
		[arr addObject:[NSDictionary dictionaryWithObject:[p extensions] forKey:[p name]]];
	return arr;
}
	
	

#pragma mark -
#pragma mark Private methods

-(void)loadPluginManagers
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *pluginsPath = [[self class] pathToPluginsFolder];
	NSArray *plugins = [fm directoryContentsAtPath:pluginsPath];
	NSEnumerator *e = [plugins objectEnumerator];
	NSString *s = nil;
	while (s = [e nextObject])
	{
		if ([[s pathExtension] isEqualToString:@"plugin"])
		{
			NSString *path = [pluginsPath stringByAppendingPathComponent:s];
			NSBundle *b = [NSBundle bundleWithPath:path];
			if (b)
			{
				[b load];
				Class c = [b principalClass];
				id obj = [c new];
				if (c && [c conformsToProtocol:@protocol(PluginManagerProtocol)])
					[self registerManager:obj];//[c new]];
			}
			else
				NSLog(@"Couldn't load plugin at path %@", _cmd, path);
		}
	}
}

+(NSString *)pathToPluginsFolder
{
	return [[[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"Plugins"];
}

@end
