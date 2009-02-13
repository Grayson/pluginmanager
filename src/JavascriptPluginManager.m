//
//  ObjCPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "JavascriptPluginManager.h"


@implementation JavascriptPluginManager

@synthesize plugins = _plugins;

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

- (void)dealloc
{
	self.plugins = nil;
	[super dealloc];
}

- (void)build
{
	NSMutableDictionary *plugins = [NSMutableDictionary dictionary];
	self.plugins = plugins;
	
	for (NSString *path in [PluginManager pluginFilesForSubmanager:self])
	{
		JSCocoaController *controller = [[JSCocoaController new] autorelease];
		[controller evalJSFile:path];
		
		if (![controller hasJSFunctionNamed:@"actionProperty"] ||
			![controller hasJSFunctionNamed:@"actionEnable"] ||
			![controller hasJSFunctionNamed:@"actionTitle"] ||
			![controller hasJSFunctionNamed:@"actionPerform"]) continue;
		
		JSValueRef value = [controller callJSFunctionNamed:@"actionProperty" withArguments:nil];
		NSString *property;
		if (![JSCocoaFFIArgument unboxJSValueRef:value toObject:&property inContext:[controller ctx]]) continue;
		
		NSMutableArray *arr = [plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:controller];
		[plugins setObject:arr forKey:property];		
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!self.plugins) [self build];
	NSArray *plugins = [self.plugins objectForKey:property];
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
