//
//  ObjCPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "PythonPluginManager.h"

// depythonify attempts to turn a PyObject value into its id/Cocoa counterpart.
id depythonify(PyObject *value) {
	return PythonToId(value);
	
	if (value == nil) return nil;
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
			id convertedObj = depythonify(obj);
			id convertedKey = depythonify(key);
			if (convertedKey && convertedObj) [dict setObject:convertedObj forKey:convertedKey];
		}
		return dict;
	}
	else if (value == Py_None) return [NSNull null];
	else {
		NSString *type = [NSString stringWithUTF8String:value->ob_type->tp_name];
		if ([type isEqualToString:@"True"]) return [NSNumber numberWithBool:YES];
		else if ([type isEqualToString:@"False"]) return [NSNumber numberWithBool:NO];
		Class c = NSClassFromString(type);
		if (c) {
			PyObjCObject *tmp = (PyObjCObject *)value;
			return tmp->objc_object;
		}
	}
	
	Class OC_PythonObj = NSClassFromString(@"OC_PythonObject");
	if (OC_PythonObj) 
		return [[OC_PythonObj performSelector:@selector(newWithObject:) withObject:(id)value] autorelease];
	return nil;
}

// pythonify converts ids to their PyObject values.
typedef PyObject *(*pyobjcobject_new_t)(id, int, int); // Function signature for PyObjCObject_New.  Used in dynamic lookup.
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
	
	return IdToPython(value);
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

@implementation PythonPluginManager

@synthesize plugins = _plugins;

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

- (void)dealloc
{
	self.plugins = nil;
	Py_Finalize();
	[super dealloc];
}

- (void)build
{
	NSMutableDictionary *plugins = [NSMutableDictionary dictionary];
	self.plugins = plugins;
	for (NSString *path in [PluginManager pluginFilesForSubmanager:self]) {
		Py_SetProgramName("/usr/bin/python");
		FILE *pyFile = fopen([path fileSystemRepresentation], "r");
		
		// The main module (__main__ in Python) pretty much represents the Python script.  When it is loaded,
		// the main module will contain references to the functions that will be called.
		PyObject *mainModule = PyImport_AddModule("__main__");
		PyObject *globals = PyModule_GetDict(mainModule);
		
		// Load the Python file using PyRun_File and then call the actionProperty() function
		PyRun_File(pyFile, [path UTF8String], Py_file_input, globals, globals);
		
		if (PythonToId == nil) {
			PyObject *objcModule = PyImport_Import(PyString_FromString("objc"));
			Py_DECREF(objcModule);
			PyObject *objcGlobals = PyModule_GetDict(objcModule);
			PyObject *apiObj = PyDict_GetItemString(objcGlobals, "__C_API__");
			struct pyobjc_api *pyobjc = PyCObject_AsVoidPtr(apiObj);
			PythonToId = pyobjc->python_to_id;
			IdToPython = pyobjc->id_to_python;
		}
		
		NSString *property = [self callFunction:@"actionProperty" ofModule:mainModule arguments:nil];
		if (!property) continue;
		
		NSMutableArray *arr = [plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:[NSValue valueWithPointer:mainModule]];
		[plugins setObject:arr forKey:property];
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!self.plugins) [self build];
	NSArray *plugins = [self.plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	NSValue *mainModuleValue;
	NSMutableArray *ret = [NSMutableArray array];
	// Python doesn't allow for functions with a dynamic number of arguments.  Well, it does the *kwargs and **kwargs
	// stuff, but I'm not using it for this script.  For this reason, the arguments must represent some object.
	// Since pythonify() converts NSNulls to Py_Nones, we're making sure that these values aren't just nil.
	forValue = forValue ? forValue : [NSNull null];
	withValue = withValue ? withValue : [NSNull null];
	NSArray *args = [NSArray arrayWithObjects:forValue, withValue, nil];
	while (mainModuleValue = [pluginEnumerator nextObject])
	{
		// Retrieve the main module and call its actionEnable() function with the forValue and the withValue
		// If the script decides that it should be enabled, get its title by calling actionTitle() and creating
		// the plugin dictionary.
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
	// Like in pluginsForProperty:forValue:withValue:, the arguments should represent some real Python object.
	// We'll turn them into Py_Nones again if they are nil and then call actionPerform().
	PyObject *mainModule = [[plugin objectForKey:@"module"] pointerValue];
	NSArray *args = [NSArray arrayWithObjects:forValue ? forValue : [NSNull null], withValue ? withValue : [NSNull null], nil];
	[self callFunction:@"actionPerform" ofModule:mainModule arguments:args];
}

-(id)runScriptAtPath:(NSString *)path
{
	// Can it get easier to call a Python script?
	// Note that this hasn't been tested.  Due to the GIL state, it's possible that this could cause a crash.
	// More information on GIL states are documented in callFunction:ofModule:arguments:.
	FILE *pyFile = fopen([path UTF8String], "r");
	PyImport_ImportModule("objc");
	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *globals = PyModule_GetDict(mainModule);
	return depythonify(PyRun_File(pyFile, [path UTF8String], Py_file_input, globals, globals));
}

// The PythonPluginManager calls into functions of a module fairly often and it tends to boilerplate code, so
// this is a convenience method to make it easier.
- (id)callFunction:(NSString *)functionName ofModule:(PyObject *)module arguments:(NSArray *)args {
	// In the PythonPluginManager, the module will usually be the main module.  We get the function using
	// PyObject_GetAttrString from the module, check to see if it exists and is callable, and then call it with
	// PyObject_CallObject().
	PyObject *pFunc = PyObject_GetAttrString(module, [functionName UTF8String]);
	id ret = nil;
	if (pFunc && PyCallable_Check(pFunc)) {
		// The GIL state is a bit of a pain in the ass at first.  If the user imports objc into Python, the app
		// will crash with some GIL state error.  Simply using PyGILState_Ensure() and releasing the GIL state after
		// seems to resolve this issue.
		PyGILState_STATE state = PyGILState_Ensure();
		PyObject *pValue = PyObject_CallObject(pFunc, args ? guaranteedTuple(pythonify(args)) : nil);
		if (pValue == nil) PyErr_Print();
		else ret = depythonify(pValue);
		Py_XDECREF(pFunc);
		PyGILState_Release(state);
	}
	return ret;
}

@end
