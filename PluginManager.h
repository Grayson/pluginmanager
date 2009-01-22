//
//  PluginManager.h
//  SiteTagger
//
//  Created by Grayson Hansard on 1/25/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>
#import "PluginManagerProtocol.h"

@interface PluginManager : NSObject {
	NSMutableArray *_pluginManagers;
}

+(id)manager;
+(NSString *)pathToPluginsFolder;
+(void)registerManager:(id)manager;

+(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue;
+(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;

+(BOOL)canRunFileWithExtension:(NSString *)ext;
+(id)runScriptAtPath:(NSString *)path;

+(NSArray *)managerInfo;

@end
