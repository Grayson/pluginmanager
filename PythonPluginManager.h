//
//  ObjCPluginManager.h
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Python/Python.h>
#import "PluginManager.h"
// #import "objc-class.h"
// #import "objc-object.h"

// Brought in from PyObjC
typedef struct {
	PyObject_HEAD
	__strong id objc_object;
	int 	    flags;
} PyObjCObject;

@interface PythonPluginManager : NSObject <PluginManagerProtocol> {
	NSMutableDictionary *_plugins;
}

-(NSString *)name;
-(NSArray *)extensions;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)value;
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
-(id)runScriptAtPath:(NSString *)path;

@end

id depythonify(PyObject *value);
PyObject *pythonify(id value);
PyObject *guaranteedTuple(PyObject *value);