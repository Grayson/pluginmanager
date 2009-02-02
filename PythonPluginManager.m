//
//  ObjCPluginManager.m
//  SiteTagger
//
//  Created by Grayson Hansard on 11/27/06.
//  Copyright 2006 From Concentrate Software. All rights reserved.
//

#import "PythonPluginManager.h"

id depythonify(PyObject *value) {
	if (value == nil) return nil;
	NSString *type = [NSString stringWithUTF8String:value->ob_type->tp_name];
	Class c = NSClassFromString(type);
	if (c) {
		PyObjCObject *tmp = (PyObjCObject *)value;
		return tmp->objc_object;
	}
	if (PyInt_Check(value) || PyLong_Check(value) || PyBool_Check(value)) 
		return [NSNumber numberWithLong:PyInt_AsLong(value)];
	else if (PyFloat_Check(value)) return [NSNumber numberWithDouble:PyFloat_AsDouble(value)];
	else if (PyUnicode_Check(value)) return [NSString stringWithUTF8String:PyUnicode_AS_DATA(value)];
	else if (PyString_Check(value)) return [NSString stringWithUTF8String:PyString_AsString(value)];
	else if (PyTuple_Check(value)) {
		unsigned int size = PyTuple_Size(value);
		NSMutableArray *array = [NSMutableArray array];
		unsigned int idx = 0;
		for (idx = 0; idx < size; idx++) {
			id obj = depythonify(PyTuple_GetItem(value, idx));
			if (obj == nil) obj = [NSNull null];
			[array addObject:obj];
		}
		return [[array copy] autorelease]; // Convert to a standard array
	}
	else if (PyList_Check(value)) {
		unsigned int size = PyList_Size(value);
		NSMutableArray *array = [NSMutableArray array];
		unsigned int idx = 0;
		for (idx = 0; idx < size; idx++) {
			id obj = depythonify(PyList_GetItem(value, idx));
			if (obj == nil) obj = [NSNull null];
			[array addObject:obj];
		}
		return array;
	}
	else if (PyDict_Check(value)) {
		PyObject *keys = PyDict_Keys(value);
		unsigned int size = PyList_Size(keys);
		unsigned int idx = 0;
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		for (idx = 0; idx < size; idx++) {
			PyObject *key = PyList_GetItem(keys, idx);
			PyObject *obj = PyDict_GetItem(value, key);
			[dict setObject:depythonify(obj) forKey:depythonify(key)];
		}
		return dict;
	}
	else if (value == Py_None) return [NSNull null];
	
	// NSLog(@"[depythonify error] Unknown type: %@", type);
	Class OC_PythonObj = NSClassFromString(@"OC_PythonObject");
	if (OC_PythonObj) 
		return [[OC_PythonObj performSelector:@selector(newWithObject:) withObject:(id)value] autorelease];
	return nil;
}

PyObject *pythonify(id value) {
	if (value == nil) return nil;
	if ([value isKindOfClass:[NSString class]]) return PyString_FromString([value UTF8String]);
	else if ([value isKindOfClass:[NSNumber class]]) return PyFloat_FromDouble([value doubleValue]);
	else if ([value isKindOfClass:[NSMutableArray class]]) {
		PyObject *list = PyList_New([value count]);
		NSEnumerator *valueEnumerator = [value objectEnumerator];
		id obj;
		unsigned int idx = 0;
		while (obj = [valueEnumerator nextObject]) PyList_SetItem(list, idx++, pythonify(obj));
		return list;
	}
	else if ([value isKindOfClass:[NSArray class]]) {
		PyObject *tuple = PyTuple_New([value count]);
		NSEnumerator *valueEnumerator = [value objectEnumerator];
		id obj;
		unsigned int idx = 0;
		while (obj = [valueEnumerator nextObject]) PyTuple_SetItem(tuple, idx++, pythonify(obj));
		return tuple;
	}
	else if ([value isKindOfClass:[NSDictionary class]]) {
		PyObject *dict = PyDict_New();
		NSArray *keys = [value allKeys];
		NSEnumerator *keyEnumerator = [keys objectEnumerator];
		id key;
		while (key = [keyEnumerator nextObject])
		{
			id obj = [value objectForKey:key];
			PyDict_SetItem(dict, pythonify(key), pythonify(obj));			
		}
		return dict;
	}
	else if ([value isKindOfClass:[NSNull class]]) return Py_None;
	
	return (PyObject *)PyObjCObject_New(value, 0, NO);
	return nil;
}

// I suspect that there's some strange interactions if multiple plugins are loaded.
// NSArrays are comparably equivalent to NSMutableArrays by class but, of course, aren't mutable.
// This generally isn't a problem (for those who know), but it means that this can't call Python methods
// using the `pythonify` convenience function.  I couldn't find an easy way to coerce python lists to tuples
// so this was written to make sure that I get a tuple that can be used to call into Python methods
PyObject *guaranteedTuple(PyObject *value) {
	if (value == nil) return nil;
	if (PyTuple_Check(value)) return value;
	NSArray *tmp = depythonify(value);
	NSEnumerator *tmpEnumerator = [tmp objectEnumerator];
	id obj;
	PyObject *tuple = PyTuple_New([tmp count]);
	unsigned int idx = 0;
	while (obj = [tmpEnumerator nextObject]) PyTuple_SetItem(tuple, idx++, pythonify(obj));
	return tuple;
}

@interface PythonPluginManager (PrivateMethods)
- (id)callFunction:(NSString *)functionName ofModule:(PyObject *)module arguments:(NSArray *)args;
@end

@implementation PythonPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Python"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"py", @"python", nil]; }

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	Py_Initialize();
	
	return self;
}

- (void)build
{
	if (_plugins) [_plugins release];
	_plugins = [NSMutableDictionary new];
	NSString *pluginsPath = [PluginManager pathToPluginsFolder];
	NSFileManager *fm = [NSFileManager defaultManager];
	BOOL isFolder;
	if (![fm fileExistsAtPath:pluginsPath isDirectory:&isFolder] || !isFolder) return;
	
	NSArray *plugins = [fm directoryContentsAtPath:pluginsPath];
	plugins = [plugins arrayByAddingObjectsFromArray:[fm directoryContentsAtPath:[[NSBundle mainBundle] pathForResource:@"Plugins" ofType:nil]]];
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	NSString *path;
	NSArray *extensions = [self extensions];
	while (path = [pluginEnumerator nextObject])
	{
		if (![extensions containsObject:[path pathExtension]]) continue;
		
		Py_SetProgramName("/usr/bin/python");
		PyGILState_STATE state;
		
		NSString *fullPath = [pluginsPath stringByAppendingPathComponent:path];
		
		FILE *pyFile = fopen([fullPath UTF8String], "r");
		PyObject *mainModule = PyImport_AddModule("__main__");
		PyObject *globals = PyModule_GetDict(mainModule);
		
		
		PyRun_File(pyFile, [fullPath UTF8String], Py_file_input, globals, globals);
		PyObject *pFunc = PyObject_GetAttrString(mainModule, "actionProperty");
		NSString *property = nil;
		if (pFunc && PyCallable_Check(pFunc)) {
			state = PyGILState_Ensure();
			PyObject *pValue = PyObject_CallObject(pFunc, nil);
			property = depythonify(pValue);
			Py_XDECREF(pFunc);
			PyGILState_Release(state);
		}
				
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:[NSValue valueWithPointer:mainModule]];
		[_plugins setObject:arr forKey:property];
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!_plugins) [self build];
	NSArray *plugins = [_plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	NSValue *mainModuleValue;
	NSMutableArray *ret = [NSMutableArray array];
	forValue = forValue ? forValue : [NSNull null];
	withValue = withValue ? withValue : [NSNull null];
	NSArray *args = [NSArray arrayWithObjects:forValue, withValue, nil];
	while (mainModuleValue = [pluginEnumerator nextObject])
	{
		PyObject *mainModule = [mainModuleValue pointerValue];
		NSNumber *enabled = [self callFunction:@"actionEnable" ofModule:mainModule arguments:args];
		if ([enabled boolValue]) {
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[self callFunction:@"actionTitle" ofModule:mainModule arguments:args], @"title",
					mainModuleValue, @"module", nil]];
		}
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	PyObject *mainModule = [[plugin objectForKey:@"module"] pointerValue];
	NSArray *args = [NSArray arrayWithObjects:forValue ? forValue : [NSNull null], withValue ? withValue : [NSNull null], nil];
	[self callFunction:@"actionPerform" ofModule:mainModule arguments:args];
}

-(id)runScriptAtPath:(NSString *)path
{
	FILE *pyFile = fopen([path UTF8String], "r");
	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *globals = PyModule_GetDict(mainModule);
	return depythonify(PyRun_File(pyFile, [path UTF8String], Py_file_input, globals, globals));
}

- (id)callFunction:(NSString *)functionName ofModule:(PyObject *)module arguments:(NSArray *)args {
	PyObject *pFunc = PyObject_GetAttrString(module, [functionName UTF8String]);
	id ret = nil;
	if (pFunc && PyCallable_Check(pFunc)) {
		PyGILState_STATE state = PyGILState_Ensure();
		PyObject *pValue = PyObject_CallObject(pFunc, args ? guaranteedTuple(pythonify(args)) : nil);
		ret = depythonify(pValue);
		Py_XDECREF(pFunc);
		PyGILState_Release(state);
	}
	return ret;
}

@end
