//
//  PluginManagerProtocol.h
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

@protocol PluginManagerProtocol

-(NSString *)name;
-(NSArray *)extensions;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue;
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
-(id)runScriptAtPath:(NSString *)path;

@end
