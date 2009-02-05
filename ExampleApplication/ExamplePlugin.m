//
//  ExamplePlugin.m
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/5/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "ExamplePlugin.h"


@implementation ExamplePlugin

-(NSString *)actionProperty { return @"label-click"; }
-(BOOL)actionEnableForValue:(id)forValue withValue:(id)withValue { return YES; }
-(NSString *)actionTitleForValue:(id)forValue withValue:(id)withValue { return @"Perform ObjC Example plugin";}
-(void)actionPerformForValue:(id)forValue withValue:(id)withValue {
	NSLog(@"%s", _cmd);
}
-(id)run {
	NSLog(@"%s", _cmd);
	return nil;
}

@end
