//
//  ObjCPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "JavascriptPluginManager.h"


@implementation JavascriptPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Javascript"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"js", @"javascript", nil]; }

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
		
		JSCocoaController *controller = [[JSCocoaController new] autorelease];
		[controller evalJSFile:[pluginsPath stringByAppendingPathComponent:path]];
		
		if (![controller hasJSFunctionNamed:@"actionProperty"] ||
			![controller hasJSFunctionNamed:@"actionEnable"] ||
			![controller hasJSFunctionNamed:@"actionTitle"] ||
			![controller hasJSFunctionNamed:@"actionPerform"]) goto next;
		
		JSValueRef value = [controller callJSFunctionNamed:@"actionProperty" withArguments:nil];
		NSString *property;
		if (![JSCocoaFFIArgument unboxJSValueRef:value toObject:&property inContext:[controller ctx]]) goto next;
		
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:controller];
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
	JSCocoaController *plugin;
	NSMutableArray *ret = [NSMutableArray array];
	while (plugin = [pluginEnumerator nextObject])
	{
		JSValueRef value = [plugin callJSFunctionNamed:@"actionEnable" withArguments:forValue, withValue, nil];
		NSNumber *shouldEnable = nil;
		if (![JSCocoaFFIArgument unboxJSValueRef:value toObject:&shouldEnable inContext:[plugin ctx]]) continue;
		if (shouldEnable && [shouldEnable boolValue])
		{
			JSValueRef titleRef = [plugin callJSFunctionNamed:@"actionTitle" withArguments:forValue, withValue, nil];
			NSString *title = nil;
			if (![JSCocoaFFIArgument unboxJSValueRef:titleRef toObject:&title inContext:[plugin ctx]]) continue;
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				title, @"title",
				plugin, @"plugin",
				forValue, @"forValue",
				withValue, @"value",
				nil]];
		}
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	JSCocoaController *p = [plugin objectForKey:@"plugin"];
	[p callJSFunctionNamed:@"actionPerform" withArguments:forValue, withValue, nil];
}

-(id)runScriptAtPath:(NSString *)path
{
	JSCocoaController *controller = [[JSCocoaController new] autorelease];
	JSValueRef valueRef;
	[controller evalJSFile:path toJSValueRef:&valueRef];
	id value = nil;
	if (![JSCocoaFFIArgument unboxJSValueRef:valueRef toObject:&value inContext:[controller ctx]]) return nil;
	return value;
}

-(BOOL)canRunAsScript { return YES; }

@end
