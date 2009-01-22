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
-(NSArray *)pluginsForProperty:(NSString *)property forBookmark:(Bookmark *)bk withValue:(id)value;
-(void)runPlugin:(NSDictionary *)plugin forBookmark:(Bookmark *)bk withValue:(id)value;
-(id)runScriptAtPath:(NSString *)path;

-(BOOL)canRunAsScript;

@end

@protocol ObjCPlugin

-(NSString *)actionProperty;
-(BOOL)actionEnableForBookmark:(Bookmark *)b withValue:(id)value;
-(NSString *)actionTitleForBookmark:(Bookmark *)b withValue:(id)value;
-(void)actionPerformForBookmark:(Bookmark *)b withValue:(id)value;

@end
