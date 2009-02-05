//
//  ExamplePlugin.h
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/5/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ObjCPluginManager.h"

@interface ExamplePlugin : NSObject<ObjCPlugin> {

}

-(NSString *)actionProperty;
-(BOOL)actionEnableForValue:(id)forValue withValue:(id)withValue;
-(NSString *)actionTitleForValue:(id)forValue withValue:(id)withValue;
-(void)actionPerformForValue:(id)forValue withValue:(id)withValue;
-(id)run;

@end
