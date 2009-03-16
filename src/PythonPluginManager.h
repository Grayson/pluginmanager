//
//  ObjCPluginManager.h
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Python/Python.h>
#include <dlfcn.h>
#import "PluginManager.h"

// Brought in from PyObjC
typedef struct {
	PyObject_HEAD
	__strong id objc_object;
	int 	    flags;
} PyObjCObject;

struct pyobjc_api {
	int	      api_version;
	size_t	      struct_len;
	PyTypeObject* class_type;
	PyTypeObject* object_type;
	PyTypeObject* select_type;
	void *register_method_mapping;
	int (*register_signature_mapping)(char*, PyObject *(*)(PyObject*, PyObject*, PyObject*), void (*)(void*, void*, void**, void*));
	id (*obj_get_object)(PyObject*);
	void (*obj_clear_object)(PyObject*);
	Class (*cls_get_class)(PyObject*);
	PyObject* (*cls_to_python)(Class cls);
	id (*python_to_id)(PyObject*);
	PyObject* (*id_to_python)(id);
};


typedef id(*PythonToId_t)(PyObject*);
typedef PyObject*(*IdToPython_t)(id);

PythonToId_t PythonToId;
IdToPython_t IdToPython;

@interface PythonPluginManager : NSObject <PluginManagerProtocol> {
	NSMutableDictionary *_plugins;
}

@property (retain) NSMutableDictionary *plugins;

-(NSString *)name;
-(NSArray *)extensions;
-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)value;
-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue;
-(id)runScriptAtPath:(NSString *)path;

@end

id depythonify(PyObject *value);
PyObject *pythonify(id value);
PyObject *guaranteedTuple(PyObject *value);

// A convenience method used internally by the PythonPluginManager that wraps some boilerplate code
// around calling into a Python module.
@interface PythonPluginManager (PrivateMethods)
- (id)callFunction:(NSString *)functionName ofModule:(PyObject *)module arguments:(NSArray *)args;
@end
