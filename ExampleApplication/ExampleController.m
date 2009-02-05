//
//  ExampleController.m
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/5/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "ExampleController.h"
#import "PluginManager.h"

@implementation ExampleController

- (void)awakeFromNib
{
	NSLog(@"%s", _cmd);
	NSArray *plugins = [PluginManager pluginsForProperty:@"label-click" forValue:nil withValue:nil];
	NSLog(@"%s %@", _cmd, plugins);
}

@end
