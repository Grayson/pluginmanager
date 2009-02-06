//
//  NSApplication+Applescript.m
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/6/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "NSApplication+Applescript.h"


@implementation NSApplication (Applescript)

- (id)ASRunScript:(NSScriptCommand *)aScriptCommand {
	NSString *path = [aScriptCommand directParameter];
	return [PluginManager runScriptAtPath:path];
}

@end
