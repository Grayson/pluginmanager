//
//  ObjCPluginManager.h
//  SiteTagger
//
//  Created by Grayson Hansard on 11/27/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
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
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)value;
-(id)runScriptAtPath:(NSString *)path;

-(BOOL)canRunAsScript;

@end

@protocol ObjCPlugin

-(NSString *)actionProperty;
-(BOOL)actionEnableForValue:(id)forValue withValue:(id)withValue;
-(NSString *)actionTitleForValue:(id)forValue withValue:(id)withValue;
-(void)actionPerformForValue:(id)forValue withValue:(id)withValue;

@end
