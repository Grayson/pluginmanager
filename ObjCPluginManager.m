//
//  ObjCPluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 11/27/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "ObjCPluginManager.h"


@implementation ObjCPluginManager

-(NSString *)name { return @"Objective-C"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"bundle"]; }

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
		
		NSBundle *b = [NSBundle bundleWithPath:path];
		if (!b) goto next;
		
		Class c = [b principalClass];
		if (![c conformsToProtocol:@protocol(ObjCPlugin)]) goto next;

		id<ObjCPlugin> plugin = [c new];
		NSString *property = [plugin actionProperty];
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:plugin];
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
	while (plugin = [pluginEnumerator nextObject])
	{
		if ([plugin actionEnableForValue:forValue withValue:withValue]) 
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[plugin actionTitleForValue:forValue withValue:withValue], @"title",
				plugin, @"plugin",
				forValue, @"forValue",
				withValue, @"value",
				nil]];
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)value
{
	id p = [plugin objectForKey:@"plugin"];
	[p actionPerformForValue:forValue withValue:value];
}

-(id)runScriptAtPath:(NSString *)path
{
	return NSLocalizedString(@"Objective-C plugins cannot be done run.  They must be compiled using Xcode.", @"Error string");
}

-(BOOL)canRunAsScript { return NO; }

@end
