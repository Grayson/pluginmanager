//
//  ObjCPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "ObjCPluginManager.h"


@implementation ObjCPluginManager

@synthesize plugins = _plugins;

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Objective-C"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"bundle"]; }

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
	NSMutableDictionary *plugins = [self plugins];
	if (!plugins) {
		plugins = [NSMutableDictionary dictionary];
		[self setPlugins:plugins];
	}

	NSArray *foundPlugins = [PluginManager pluginFilesForSubmanager:self];
	NSEnumerator *pluginEnumerator = [foundPlugins objectEnumerator];
	NSString *path;
	NSArray *extensions = [self extensions];
	while (path = [pluginEnumerator nextObject])
	{
		if (![extensions containsObject:[path pathExtension]]) continue;
		
		NSBundle *b = [NSBundle bundleWithPath:path];
		if (!b) continue;
		
		Class c = [b principalClass];
		if (![c conformsToProtocol:@protocol(ObjCPlugin)]) continue;

		id<ObjCPlugin> plugin = [c new];
		NSString *property = [plugin actionProperty];
		NSMutableArray *arr = [plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:plugin];
		[plugins setObject:arr forKey:property];
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (![self plugins]) [self build];
	NSArray *plugins = [[self plugins] objectForKey:property];
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

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	id p = [plugin objectForKey:@"plugin"];
	[p actionPerformForValue:forValue withValue:withValue];
}

-(id)runScriptAtPath:(NSString *)path
{
	if (!path) return nil;
	NSMutableDictionary *plugins = [self plugins];
	if (!plugins) plugins = [NSMutableDictionary dictionary];
	id<ObjCPlugin> plugin = [plugins objectForKey:path];
	unsigned int errorCode = 0;
	NSString *errorString = nil;
	if (!plugin) {
		NSBundle *b = [NSBundle bundleWithPath:path];
		if (![b load]) {
			errorString = [NSString stringWithFormat:NSLocalizedString(@"File at path '%@' is not a valid bundle.", @"error message"), path];
			errorCode = ObjCPMBundleLoadError;
			goto error;
		}
		plugin = [[[b class] new] autorelease];
		if (!plugin) {
			errorString = [NSString stringWithFormat:NSLocalizedString(@"Could not load class from Cocoa bundle at path: %@", @"error message"), path];
			errorCode = ObjCPMClassLoadError;
			goto error;
		}
		if (![(id)plugin respondsToSelector:@selector(run)]) {
			errorString = [NSString stringWithFormat:NSLocalizedString(@"Loaded bundle at path '%@' does not respond to -(id)run.", @"error message"), path];
			errorCode = 3;
			goto error;
		}
		[plugins setObject:plugin forKey:path];
	}
	
	return [plugin run];
	
	// If a plugin can't be loaded and used, create an NSError and return it.  I dislike using exceptions here
	// since plugins aren't really show stoppers and shouldn't stop an application to deal with them.
	error:;
	if (!errorString) return nil;
	NSDictionary *errorDict = [NSDictionary dictionaryWithObject:errorString forKey:NSLocalizedDescriptionKey];
	return [NSError errorWithDomain:@"com.fcs.objcpluginmanager" code:errorCode userInfo:errorDict];
}

-(BOOL)canRunAsScript { return YES; }


@end
