//
//  ObjCPluginManager.h
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginManager.h"
#import "PluginManagerProtocol.h"


@interface ObjCPluginManager : NSObject <PluginManagerProtocol> {
	NSMutableDictionary *_plugins;
}

-(NSString *)name;
-(NSArray *)extensions;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)value;
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
-(id)runScriptAtPath:(NSString *)path;

-(BOOL)canRunAsScript;

@end

@protocol ObjCPlugin

-(NSString *)actionProperty;
-(BOOL)actionEnableForValue:(id)forValue withValue:(id)withValue;
-(NSString *)actionTitleForValue:(id)forValue withValue:(id)withValue;
-(void)actionPerformForValue:(id)forValue withValue:(id)withValue;

@end
