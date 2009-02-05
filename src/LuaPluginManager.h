//
//  ObjCPluginManager.h
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <LuaCore/LuaCore.h>
#import "PluginManager.h"


@interface LuaPluginManager : NSObject <PluginManagerProtocol> {
	NSMutableDictionary *_plugins;
}

-(NSString *)name;
-(NSArray *)extensions;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)value;
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
-(id)runScriptAtPath:(NSString *)path;

@end

// These additions are made to LCLua.
// They are simply convenience methods to retrieve return values from Lua functions.
// These changes have been sent to Gus Mueller for review and addition to LCLua.
// When they (or similar ones) are added, these methods can be removed.
@interface LCLua (LuaPluginManagerAdditions)
- (id)callEmptyFunctionNamed:(NSString *)functionName expectReturnValue:(BOOL)expect;
- (id)callFunction:(NSString *)functionName expectReturnValue:(BOOL)expect arguments:(id)firstArg, ...;
@end
