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
	if (NSClassFromString(@"MacRuby")) [PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(id)init
{
	self = [super init];
	if (!self) return nil;
	
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
		MacRuby *ruby = [MacRuby sharedRuntime];
		// id x = [ruby evaluateFileAtPath:scriptPath];
		// NSLog(@"%s %@", _cmd, x);
		VALUE script = rb_eval_string([[NSString stringWithContentsOfFile:scriptPath] UTF8String]);
		NSLog(@"%s WTF IS GOING ON?", _cmd);
		
		VALUE ret = rb_funcall(script, rb_intern("actionPerform"), 2, OC2RB(self), OC2RB(@"asdf"));
		NSLog(@"%s %@", _cmd, RB2OC(ret));
		
		return;
		
		// // RBObjects are really NSProxies.  RubyCocoa makes it easy to call functions in a Ruby script
		// // simply by calling the function name as a proxy method.  Here, it'll be calling `actionProperty()`
		// // from the loaded script.
		// NSString *property = [rb actionProperty];
		// NSMutableArray *arr = [plugins objectForKey:property];
		// if (!arr) arr = [NSMutableArray array];
		// [arr addObject:rb];
		// [plugins setObject:arr forKey:property];
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
