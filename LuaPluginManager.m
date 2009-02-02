//
//  ObjCPluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 11/27/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "LuaPluginManager.h"


@implementation LuaPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Lua"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"lua", @"L", nil]; }

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
		
		LCLua *lua = [LCLua readyLua];
		NSString *luaCode = [NSString stringWithContentsOfFile:[pluginsPath stringByAppendingPathComponent:path]];
		[lua runFileAtPath:[pluginsPath stringByAppendingPathComponent:path]];
		
		NSString *property = [lua callEmptyFunctionNamed:@"actionProperty" expectReturnValue:YES];		
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:luaCode];
		[_plugins setObject:arr forKey:property];
		
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
		LCLua *lua = [LCLua readyLua];
		[lua runBuffer:plugin];
		if ([[lua callFunction:@"actionEnable" expectReturnValue:YES arguments:forValue, withValue, nil] boolValue])
		{
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[lua callFunction:@"actionTitle" expectReturnValue:YES arguments:forValue, withValue, nil], @"title",
				plugin, @"plugin",
				nil]];
		}
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	NSString *luaCode = [plugin objectForKey:@"plugin"];
	LCLua *lua = [LCLua readyLua];
	[lua runBuffer:luaCode];
	[lua callFunction:@"actionPerform" expectReturnValue:YES arguments:forValue, withValue, nil];
}

-(id)runScriptAtPath:(NSString *)path
{
	LCLua *lua = [LCLua readyLua];
	[lua runFileAtPath:path];
	return nil;
}

@end
