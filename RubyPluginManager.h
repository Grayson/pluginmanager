//
//  RubyPluginManager.h
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <RubyCocoa/RBRuntime.h>
// #include <Ruby/ruby.h>
#import "PluginManager.h"
#import "PluginManagerProtocol.h"

@interface RubyPluginManager : NSObject <PluginManagerProtocol> {
	NSMutableDictionary *_plugins;
	Class RBObject;
}

-(NSString *)name;
-(NSArray *)extensions;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue;
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
-(id)runScriptAtPath:(NSString *)path;

@end

@interface NSObject (RBObject)
-(id) RBObjectWithRubyScriptString:(NSString *)script;
@end

@interface NSObject(RubyPlugin)
-actionProperty;
-actionEnable:withValue :forValue;
-actionTitle:withValue :forValue;
-actionPerform:withValue :forValue;
@end