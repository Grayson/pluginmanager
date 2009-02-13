//
//  RubyPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "RubyPluginManager.h"

@interface RubyPluginManager (PrivateMethods)
-(void)build;
@end

@implementation RubyPluginManager

@synthesize plugins = _plugins;

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	if (NSClassFromString(@"RBObject")) [PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(id)init
{
	self = [super init];
	if (!self) return nil;
	
	// Simple initialization of the Ruby runtime and loading of RubyCocoa.
	// Also RBObject is available in RubyCocoa but isn't made public.  It is loaded dynamically here.
	ruby_init();
	ruby_init_loadpath();
	RBRubyCocoaInit();
	RBObject = NSClassFromString(@"RBObject");
	
	return self;
}

-(void)build
{
	NSMutableDictionary *plugins = [NSMutableDictionary dictionary];
	self.plugins = plugins;
	
	for (NSString *scriptPath in [PluginManager pluginFilesForSubmanager:self])
	{
		// Could it be any easier to load a Ruby script with RubyCocoa?  Simply get a script as an NSString
		// and load it using RBObjectWithRubyScriptString:.
		
		id rb = [RBObject RBObjectWithRubyScriptString:[NSString stringWithContentsOfFile:scriptPath]];
		if (!rb) continue;
		
		// RBObjects are really NSProxies.  RubyCocoa makes it easy to call functions in a Ruby script
		// simply by calling the function name as a proxy method.  Here, it'll be calling `actionProperty()`
		// from the loaded script.
		NSString *property = [rb actionProperty];
		NSMutableArray *arr = [plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:rb];
		[plugins setObject:arr forKey:property];
	}
}

-(NSString *)name { return @"Ruby"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"rb"]; }
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!self.plugins) [self build];
	NSArray *arr = [self.plugins objectForKey:property];
	if (!arr || ![arr count]) return nil;
	
	NSEnumerator *pluginEnumerator = [arr objectEnumerator];
	id rb;
	NSMutableArray *ret = [NSMutableArray array];
	while (rb = [pluginEnumerator nextObject])
	{
		if ([rb actionEnable:nil :nil]) 
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[rb actionTitle:nil :nil], @"title",
				rb, @"plugin",
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
	NSString *rubyCode = [NSString stringWithContentsOfFile:path];
	if (!rubyCode) return nil;
	/*void *v = */(void *)rb_eval_string([rubyCode UTF8String]);
	// How do I get a return value from a script?  Can I with Ruby?
	return nil;
}

@end
