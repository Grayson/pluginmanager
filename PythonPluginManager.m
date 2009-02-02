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
	
	NSLog(@"[depythonify error] Unknown type: %@", type);
	return nil;
}

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
		if (![extensions containsObject:[path pathExtension]]) goto next;
		
		Py_SetProgramName("/usr/bin/python");
		PyGILState_STATE state;
		
		NSString *fullPath = [pluginsPath stringByAppendingPathComponent:path];
		
		FILE *pyFile = fopen([fullPath UTF8String], "r");
		// PyRun_SimpleFile(pyFile, (char *)[[fullPath lastPathComponent] UTF8String]);
		
		// PyObject *pName = PyString_FromString("actionProperty");
		PyObject *mainModule = PyImport_AddModule("__main__");
		PyObject *globals = PyModule_GetDict(mainModule);
		
		
		PyRun_File(pyFile, [fullPath UTF8String], Py_file_input, globals, globals);
		PyObject *pFunc = PyObject_GetAttrString(mainModule, "actionProperty");
		if (pFunc && PyCallable_Check(pFunc)) {
			state = PyGILState_Ensure();
			PyObject *pValue = PyObject_CallObject(pFunc, nil);
			NSLog(@"%s %@", _cmd, depythonify(pValue));
			Py_XDECREF(pFunc);
			PyGILState_Release(state);
		}
		
		// PyThreadState_Swap(NULL); 
		// Py_Finalize();
		// PyEval_ReleaseLock();
		
		// LCLua *lua = [LCLua readyLua];
		// NSString *luaCode = [NSString stringWithContentsOfFile:[pluginsPath stringByAppendingPathComponent:path]];
		// [lua runFileAtPath:[pluginsPath stringByAppendingPathComponent:path]];
		// 
		// NSString *property = [lua callEmptyFunctionNamed:@"actionProperty" expectReturnValue:YES];		
		// NSMutableArray *arr = [_plugins objectForKey:property];
		// if (!arr) arr = [NSMutableArray array];
		// [arr addObject:luaCode];
		// [_plugins setObject:arr forKey:property];
		
		next:;
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	NSLog(@"%s", _cmd);
	if (!_plugins) [self build];
	return nil;
	// NSArray *plugins = [_plugins objectForKey:property];
	// if (!plugins || ![plugins count]) return nil;
	// 
	// NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	// id plugin;
	// NSMutableArray *ret = [NSMutableArray array];
	// withValue = withValue ? withValue : [NSNull null];
	// forValue = forValue ? forValue : [NSNull null];
	// while (plugin = [pluginEnumerator nextObject])
	// {
	// 	LCLua *lua = [LCLua readyLua];
	// 	[lua runBuffer:plugin];
	// 	if ([[lua callFunction:@"actionEnable" expectReturnValue:YES arguments:forValue, withValue, nil] boolValue])
	// 	{
	// 		[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
	// 			[lua callFunction:@"actionTitle" expectReturnValue:YES arguments:forValue, withValue, nil], @"title",
	// 			plugin, @"plugin",
	// 			nil]];
	// 	}
	// }
	// 
	// return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	// NSString *luaCode = [plugin objectForKey:@"plugin"];
	// LCLua *lua = [LCLua readyLua];
	// [lua runBuffer:luaCode];
	// [lua callFunction:@"actionPerform" expectReturnValue:YES arguments:forValue, withValue, nil];
}

-(id)runScriptAtPath:(NSString *)path
{
	// LCLua *lua = [LCLua readyLua];
	// [lua runFileAtPath:path];
	return nil;
}

@end
