//
//  NSApplication+Applescript.h
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/6/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "PluginManager.h"

@interface NSApplication (Applescript)

- (id)ASRunScript:(NSScriptCommand *)aScriptCommand;

@end
