//
//  ApplescriptPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "ApplescriptPluginManager.h"

@interface ApplescriptPluginManager (PrivateMethods)
-(void)build;
@end

// Creates the 4-char code used by applescript to identify the application.  This means the user does not have to
// hard-code the app class code somewhere in the application.
unsigned long ASPluginAppClassCode() {
	NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
	NSString *sig = [infoPlist objectForKey:@"CFBundleSignature"];
	unsigned long code = 0;
	code += [sig characterAtIndex:0] << 24;
	code += [sig characterAtIndex:1] << 16;
	code += [sig characterAtIndex:2] << 8;
	code += [sig characterAtIndex:3];
	return code;
}

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
	
	NSArray *foundPlugins = [PluginManager pluginFilesForSubmanager:self];
	NSAppleEventDescriptor *procDesc = [NSAppleScript processDescriptor];
	for (NSString *path in foundPlugins)
	{
		NSAppleScript *as = [NSAppleScript appleScriptWithContentsOfFile:path];
		if (!as) continue;
		NSAppleEventDescriptor *desc = [NSAppleEventDescriptor appleEventWithEventClass:ASPluginAppClassCode() eventID:ASPluginPropertyEventCode targetDescriptor:procDesc returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
		id err = nil;
		NSAppleEventDescriptor *ret = [as executeAppleEvent:desc error:&err];
		NSLog(@"%s %@", _cmd, err);
		NSLog(@"%s %@", _cmd, ret);
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
		NSAppleEventDescriptor *enabledDesc = [as executeEvent:ASPluginEnableEventCode eventClass:ASPluginAppClassCode() parameters:parameters];
		if (enabledDesc && [enabledDesc booleanValue])
		{
			NSAppleEventDescriptor *desc = [as executeEvent:ASPluginTitleEventCode eventClass:ASPluginAppClassCode() parameters:parameters];
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
	[[plugin objectForKey:@"applescript"] executeEvent:ASPluginPerformEventCode eventClass:ASPluginAppClassCode() parameters:parameters];
}

-(id)runScriptAtPath:(NSString *)path
{
	return [[NSAppleScript appleScriptWithContentsOfFile:path] executeAndReturnError:nil];
}

@end
