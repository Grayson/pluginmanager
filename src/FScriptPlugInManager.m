//
//  FScriptPlugInManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "FScriptPlugInManager.h"


@implementation FScriptPlugInManager

@synthesize plugins = _plugins;

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	// Assume that the framework exists if strings can respond to `asBlock`.
	if ([@"" respondsToSelector:@selector(asBlock)])
		[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"F-Script"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"fs", @"fscript", nil]; }

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

- (void)dealloc
{
	[self setPlugins:nil];
	[super dealloc];
}

- (void)build
{
	NSMutableDictionary *plugins = [NSMutableDictionary dictionary];
	self.plugins = plugins;
	for (NSString *path in [PluginManager pluginFilesForSubmanager:self])
	{
		FSInterpreter *interpreter = [FSInterpreter interpreter];
		NSString *fscriptCode = [NSString stringWithContentsOfFile:path];
		
		// Set up an FSInterpreter that will represent the plugin in memory.  Load the code using `execute:`
		// and then get references to its functions using `objectForIdentifier:found:`.
		FSInterpreterResult *result = [interpreter execute:fscriptCode];
		if (![result isOK]) continue;
		BOOL found;
		FSBlock *b = [interpreter objectForIdentifier:@"actionProperty" found:&found];
		if (!found) continue;
		NSString *property = [b value];
		if (property && [property isKindOfClass:[NSString class]])
		{
			NSMutableArray *arr = [plugins objectForKey:property];
			if (!arr) arr = [NSMutableArray array];
			[arr addObject:interpreter];
			[plugins setObject:arr forKey:property];						
		}
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!self.plugins) [self build];
	NSArray *plugins = [self.plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	FSInterpreter *interpreter = nil;
	NSMutableArray *ret = [NSMutableArray array];
	while (interpreter = [pluginEnumerator nextObject])
	{
		BOOL found = NO;
		FSBlock *b = [interpreter objectForIdentifier:@"actionEnable" found:&found];
		if (!found) continue;
		
		FSBoolean *isEnabled = [b value:forValue value:withValue];
		if (![isEnabled isKindOfClass:[True class]]) continue;
		
		b = [interpreter objectForIdentifier:@"actionTitle" found:&found];
		if (!found) continue;
		[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
			[b value:forValue value:withValue], @"title",
			interpreter, @"plugin",
			nil]];
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	FSInterpreter *interpreter = [plugin objectForKey:@"plugin"];
	BOOL found = NO;
	FSBlock *b = [interpreter objectForIdentifier:@"actionPerform" found:&found];
	if (!found) return;
	[b value:forValue value:withValue];
}

-(id)runScriptAtPath:(NSString *)path
{
	NSString *fscriptCode = [NSString stringWithContentsOfFile:path];
	return [[fscriptCode asBlock] value];
}

@end
