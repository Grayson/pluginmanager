//
//  ObjCPluginManager.m
//  PluginManager
//
//  Created by Grayson Hansard
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "LuaPluginManager.h"


@implementation LuaPluginManager

+(void)load {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[PluginManager registerManager:[[self new] autorelease]];
	[pool release];
}

-(NSString *)name { return @"Lua"; }
-(NSArray *)extensions { return [NSArray arrayWithObjects:@"lua", @"L", nil]; }

- (id)init
{
	self = [super init];
	if (!self) return nil;
	
	return self;
}

- (void)build
{
	if (_plugins) [_plugins release];
	_plugins = [NSMutableDictionary new];
	for (NSString *path in [PluginManager pluginFilesForSubmanager:self])
	{
		LCLua *lua = [LCLua readyLua];
		NSString *luaCode = [NSString stringWithContentsOfFile:path];
		[lua runFileAtPath:path];
		
		NSString *property = [lua callEmptyFunctionNamed:@"actionProperty" expectReturnValue:YES];		
		NSMutableArray *arr = [_plugins objectForKey:property];
		if (!arr) arr = [NSMutableArray array];
		[arr addObject:luaCode];
		[_plugins setObject:arr forKey:property];
	}
}

-(NSArray *)pluginsForProperty:(NSString *)property forValue:(id)forValue withValue:(id)withValue
{
	if (!_plugins) [self build];
	NSArray *plugins = [_plugins objectForKey:property];
	if (!plugins || ![plugins count]) return nil;
	
	NSEnumerator *pluginEnumerator = [plugins objectEnumerator];
	id plugin;
	NSMutableArray *ret = [NSMutableArray array];
	withValue = withValue ? withValue : [NSNull null];
	forValue = forValue ? forValue : [NSNull null];
	while (plugin = [pluginEnumerator nextObject])
	{
		LCLua *lua = [LCLua readyLua];
		[lua runBuffer:plugin];
		if ([[lua callFunction:@"actionEnable" expectReturnValue:YES arguments:forValue, withValue, nil] boolValue])
		{
			[ret addObject:[NSDictionary dictionaryWithObjectsAndKeys:
				[lua callFunction:@"actionTitle" expectReturnValue:YES arguments:forValue, withValue, nil], @"title",
				plugin, @"plugin",
				nil]];
		}
	}
	
	return ret;
}

-(void)runPlugin:(NSDictionary *)plugin forValue:(id)forValue withValue:(id)withValue
{
	NSString *luaCode = [plugin objectForKey:@"plugin"];
	LCLua *lua = [LCLua readyLua];
	[lua runBuffer:luaCode];
	[lua callFunction:@"actionPerform" expectReturnValue:YES arguments:forValue, withValue, nil];
}

-(id)runScriptAtPath:(NSString *)path
{
	LCLua *lua = [LCLua readyLua];
	[lua runFileAtPath:path];
	return nil;
}

@end


@implementation LCLua (LuaPluginManagerAdditions)
- (id)callEmptyFunctionNamed:(NSString *)functionName expectReturnValue:(BOOL)expect {
	// Push the function name onto the stack
    lua_pushstring (L, [functionName UTF8String]);
    
    // Function is located in the Global Table
    lua_gettable (L, LUA_GLOBALSINDEX);  
    
    lua_pcall (L, 0, expect, 0);
	if (expect) {
		id ret = (id)lua_objc_topropertylist(L, -1);
		if (!ret) ret = (id)lua_objc_getid(L, -1);
		return ret;
	}
	return nil;
}

- (id)callFunction:(NSString *)functionName expectReturnValue:(BOOL)expect arguments:(id)firstArg, ... {
	int functionCount = 0;
    
    [[[NSThread currentThread] threadDictionary] setObject:[NSNumber numberWithBool:YES] forKey:@"LCRunningInLua"];
    
    lua_getglobal(L, [functionName UTF8String]);

	id eachArg;
	va_list argumentList;
	if (firstArg)
	{
		lua_objc_pushid(L, firstArg);
		functionCount++;
		va_start(argumentList, firstArg);
		while (eachArg = va_arg(argumentList, id)) {
			lua_objc_pushid(L, eachArg);
			functionCount++;
		}
		va_end(argumentList);
	}
    
    if (lua_pcall(L, functionCount, expect, 0) != 0) {
        NSLog(@"Error running function '%@': %s", functionName, lua_tostring(L, -1));
    }
    
    [[[NSThread currentThread] threadDictionary] removeObjectForKey:@"LCRunningInLua"];
	if (expect) {
		id ret = (id)lua_objc_topropertylist(L, -1);
		if (!ret) ret = (id)lua_objc_getid(L, -1);
		return ret;
	}
	return nil;
}
@end