//
//  ApplescriptPluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 7/20/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "ApplescriptPluginManager.h"

@interface ApplescriptPluginManager (PrivateMethods)
-(void)build;
@end

@implementation ApplescriptPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
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
	if (_plugins) [_plugins release];
	_plugins = [NSMutableDictionary new];
	
	NSString *pluginsPath = [PluginManager pathToPluginsFolder];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isFolder;
	if (![fm fileExistsAtPath:pluginsPath isDirectory:&isFolder] || !isFolder) return;
	
	NSEnumerator *e = [[fm directoryContentsAtPath:pluginsPath] objectEnumerator];
	NSString *path = nil;
	NSAppleEventDescriptor *procDesc = [NSAppleScript processDescriptor];
	while (path = [e nextObject])
	{
		if ([[path pathExtension] isEqualToString:@"scpt"])
		{
			NSAppleScript *as = [NSAppleScript appleScriptWithContentsOfFile:[pluginsPath stringByAppendingPathComponent:path]];
			if (as)
			{
				NSAppleEventDescriptor *desc = [NSAppleEventDescriptor appleEventWithEventClass:ASPluginAppClassCode eventID:ASPluginPropertyEventCode targetDescriptor:procDesc returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
				NSAppleEventDescriptor *ret = [as executeAppleEvent:desc error:nil];
				if (ret)
				{
					NSString *property = [ret stringValue];
					NSMutableArray *arr = [_plugins objectForKey:property];
					if (!arr) arr = [NSMutableArray array];
					[arr addObject:as];
					[_plugins setObject:arr forKey:property];
				}
			}
		}
	}
}

-(NSString *)name { return @"Applescript"; }
-(NSArray *)extensions { return [NSArray arrayWithObject:@"scpt"]; }
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!_plugins) [self build];
	NSArray *arr = [_plugins objectForKey:property];
	if (!arr || ![arr count]) return nil;
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	if (forValue) [parameters setObject:forValue forKey:[NSNumber numberWithUnsignedLong:ASPluginForCode]];
	if (withValue) [parameters setObject:withValue forKey:[NSNumber numberWithUnsignedLong:ASPluginWithCode]];
	
	NSEnumerator *e = [arr objectEnumerator];
	NSMutableArray *ret = [NSMutableArray array];
	NSAppleScript *as = nil;
	
	while (as = [e nextObject])
	{
		NSAppleEventDescriptor *enabledDesc = [as executeEvent:ASPluginEnableEventCode eventClass:ASPluginAppClassCode parameters:parameters];
		if (enabledDesc && [enabledDesc booleanValue])
		{
			NSAppleEventDescriptor *desc = [as executeEvent:ASPluginTitleEventCode eventClass:ASPluginAppClassCode parameters:parameters];
			if (desc) 
				[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
					[desc stringValue], @"title",
					as, @"applescript",
					nil]];
		}
	}
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
	if (forValue) [parameters setObject:forValue forKey:[NSNumber numberWithUnsignedLong:ASPluginForCode]];
	if (withValue) [parameters setObject:withValue forKey:[NSNumber numberWithUnsignedLong:ASPluginWithCode]];
	[[plugin objectForKey:@"applescript"] executeEvent:ASPluginPerformEventCode eventClass:ASPluginAppClassCode parameters:parameters];
}

-(id)runScriptAtPath:(NSString *)path
{
	return [[NSAppleScript appleScriptWithContentsOfFile:path] executeAndReturnError:nil];
}

@end
