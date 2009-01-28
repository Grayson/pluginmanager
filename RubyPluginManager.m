//
//  RubyPluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 7/20/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "RubyPluginManager.h"

@interface RubyPluginManager (PrivateMethods)
-(void)build;
@end

@implementation RubyPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(id)init
{
	self = [super init];
	if (!self) return nil;
	
	ruby_init();
	ruby_init_loadpath();
	RBRubyCocoaInit();
	RBObject = NSClassFromString(@"RBObject");
	
	return self;
}

-(void)build
{
	if (_plugins) [_plugins release];
	_plugins = [NSMutableDictionary new];
	
	NSString *pluginsPath = [PluginManager pathToPluginsFolder];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isFolder;
	if (![fm fileExistsAtPath:pluginsPath isDirectory:&isFolder] || !isFolder) return;
	
	NSEnumerator *e = [[fm directoryContentsAtPath:pluginsPath] objectEnumerator];
	NSString *path = nil;
	while (path = [e nextObject])
	{
		if ([[path pathExtension] isEqualToString:@"rb"])
		{
			NSString *scriptPath = [pluginsPath stringByAppendingPathComponent:path];
			id rb = [NSClassFromString(@"RBObject") RBObjectWithRubyScriptString:[NSString stringWithContentsOfFile:scriptPath]];
			if (!rb) continue;
			
			NSString *property = [rb actionProperty];			
			NSMutableArray *arr = [_plugins objectForKey:property];
			if (!arr) arr = [NSMutableArray array];
			[arr addObject:rb];
			[_plugins setObject:arr forKey:property];
		}
	}
}

-(NSString *)name { return @"Ruby"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"rb"]; }
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!_plugins) [self build];
	NSArray *arr = [_plugins objectForKey:property];
	if (!arr || ![arr count]) return nil;
	
	NSEnumerator *pluginEnumerator = [arr objectEnumerator];
	id plugin;
	NSMutableArray *ret = [NSMutableArray array];
	while (plugin = [pluginEnumerator nextObject])
	{
		if ([plugin actionEnable:forValue :withValue]) 
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[plugin actionTitle:forValue :withValue], @"title",
				plugin, @"plugin",
				forValue, @"forValue",
				withValue, @"value",
				nil]];
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	id rb = [plugin objectForKey:@"plugin"];
	[rb actionPerform:forValue :withValue];
}

-(id)runScriptAtPath:(NSString *)path
{
	return nil;
	// return [[NSAppleScript appleScriptWithContentsOfFile:path] executeAndReturnError:nil];
}

@end
