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
- (id)callRubyMethod:(NSString *)method ofScript:(VALUE)script withArguments:(NSArray *)args;
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
	
	[MacRuby sharedRuntime];
	for (NSString *scriptPath in [PluginManager pluginFilesForSubmanager:self])
	{
		VALUE script = rb_eval_string([[NSString stringWithContentsOfFile:scriptPath] UTF8String]);
		NSString *property = [self callRubyMethod:@"actionProperty" ofScript:script withArguments:nil];
		
		NSMutableArray *arr = [plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:[NSValue valueWithPointer:(const void *)script]];
		[plugins setObject:arr forKey:property];
	}
}

-(NSString *)name { return @"Ruby"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"rb", @"ruby", nil]; }
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!self.plugins) [self build];
	NSArray *arr = [self.plugins objectForKey:property];
	if (!arr || ![arr count]) return nil;
	
	NSEnumerator *pluginEnumerator = [arr objectEnumerator];
	id rb;
	NSMutableArray *ret = [NSMutableArray array];
	NSArray *arguments = [NSArray arrayWithObjects:forValue ? forValue : [NSNull null], withValue ? withValue : [NSNull null], nil];
	while (rb = [pluginEnumerator nextObject])
	{
		VALUE script = (VALUE)[rb pointerValue];
		NSNumber *shouldEnable = [self callRubyMethod:@"actionEnable" ofScript:script withArguments:arguments];
		if ([shouldEnable boolValue]) 
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[self callRubyMethod:@"actionTitle" ofScript:script withArguments:arguments], @"title",
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
	NSArray *arguments = [NSArray arrayWithObjects:forValue ? forValue : [NSNull null], withValue ? withValue : [NSNull null], nil];
	[self callRubyMethod:@"actionPerform" ofScript:(VALUE)[rb pointerValue] withArguments:arguments];
}

-(id)runScriptAtPath:(NSString *)path
{
	NSString *rubyCode = [NSString stringWithContentsOfFile:path];
	if (!rubyCode) return nil;
	VALUE ret = rb_eval_string([rubyCode UTF8String]);
	return RB2OC(ret);
}

- (id)callRubyMethod:(NSString *)method ofScript:(VALUE)script withArguments:(NSArray *)args {
	VALUE rubyArgs[ [args count] ];
	unsigned int idx = 0;
	for (id arg in args) rubyArgs[idx++] = OC2RB(arg);
	VALUE ret = rb_funcall2(script, rb_intern([method UTF8String]), [args count], rubyArgs);
	if (ret) return RB2OC(ret);
	return nil;
}

@end
