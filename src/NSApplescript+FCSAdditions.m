//
//  NSApplescript+FCSAdditions.m
//  FCSFramework
//
//  Created by Grayson Hansard on 3/7/05.
//  Copyright 2005 From Concentrate Software. All rights reserved.
//

#import "NSApplescript+FCSAdditions.h"

@implementation NSAppleScript (FCSAdditions)

- (NSAppleEventDescriptor *) callHandler: (NSString *) handler 
						   withArguments: (NSAppleEventDescriptor *) arguments 
							   errorInfo: (NSDictionary **) errorInfo
{
	// Taken from Buzz Anderson, www.scifihifi.com
	
    NSAppleEventDescriptor* event; 
    NSAppleEventDescriptor* targetAddress; 
    NSAppleEventDescriptor* result;
	
    /* This will be a self-targeted AppleEvent, so we need to identify ourselves using our process id */
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    targetAddress = [[NSAppleEventDescriptor alloc] initWithDescriptorType: typeKernelProcessID bytes: &pid length: sizeof(pid)];
    
    /* Set up our root AppleEvent descriptor: a subroutine call (psbr) */
    event = [[NSAppleEventDescriptor alloc] initWithEventClass: 'ascr' eventID: 'psbr' targetDescriptor: targetAddress returnID: kAutoGenerateReturnID transactionID: kAnyTransactionID];
    
    /* Set up an AppleEvent descriptor containing the subroutine (handler) name */
    [event setParamDescriptor:[NSAppleEventDescriptor descriptorWithString: [handler lowercaseString]] forKeyword: 'snam'];
	
    /* Add the provided arguments to the handler call */
	if (arguments) [event setParamDescriptor: arguments forKeyword: keyDirectObject];
    
    /* Execute the handler */
    result = [self executeAppleEvent: event error: errorInfo];
    
    [targetAddress release];
    [event release];
    
    return result;	
}

-(NSAppleScript *)initWithContentsOfFile:(NSString *)path
{
	self = [self initWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
	return self;
}

+(NSAppleScript *)appleScriptWithContentsOfFile:(NSString *)path
{
	return [[[NSAppleScript alloc] initWithContentsOfFile:path] autorelease];
}

-(NSAppleEventDescriptor *)executeEvent:(AEEventID)eventCode eventClass:(AEEventClass)eventClass parameters:(NSDictionary *)parameters
{
	NSAppleEventDescriptor *procDesc = [NSAppleScript processDescriptor];
	
	NSAppleEventDescriptor *desc = [NSAppleEventDescriptor appleEventWithEventClass:eventClass eventID:eventCode targetDescriptor:procDesc returnID:kAutoGenerateReturnID transactionID:kAnyTransactionID];
	
	NSEnumerator *e = [parameters keyEnumerator];
	NSNumber *key = nil;
	while (key = [e nextObject])
		[desc setParamDescriptor:[[parameters objectForKey:key] ASDescriptor] forKeyword:[key unsignedLongValue]];
	
	NSDictionary *errorDict = nil;
	NSAppleEventDescriptor *returnDesc = [self executeAppleEvent:desc error:&errorDict];
	if (errorDict) NSLog(@"%@", errorDict);
	return returnDesc;
}

+(NSAppleEventDescriptor *)processDescriptor
{
	ProcessSerialNumber selfPSN = {0, kCurrentProcess}; //using the PSN for the target is fastest
    return [NSAppleEventDescriptor descriptorWithDescriptorType:typeProcessSerialNumber bytes:&selfPSN
														 length:sizeof(ProcessSerialNumber)];	
}

+(BOOL)sendRecordableEventWithEventCode:(AEEventID)eventCode eventClass:(AEEventClass)eventClass 
						directParameter:(id)directParam argumentsCodesAndValues:(id)firstCode, ...
{
	NSAppleEventDescriptor *procDesc = [NSAppleScript processDescriptor];
	NSAppleEventDescriptor *desc = [NSAppleEventDescriptor appleEventWithEventClass:eventClass
																			eventID:eventCode 
																   targetDescriptor:procDesc
																		   returnID:kAutoGenerateReturnID 
																	  transactionID:kAnyTransactionID];

	if (directParam) [desc setDescriptor:[directParam ASDescriptor] forKeyword:keyDirectObject];
	
	if (firstCode)
	{
		NSNumber *argCode = nil;
		id argValue = nil;
		va_list argList;
		
		argCode = firstCode;
		va_start(argList, firstCode);
		while (argValue = va_arg(argList, id))
		{
			[desc setParamDescriptor:[argValue ASDescriptor] forKeyword:[argCode unsignedLongValue]];
			argCode = va_arg(argList, NSNumber *);
		}
		va_end(argList);
	}

	AEDesc reply;
	OSErr err = AESend([desc aeDesc], &reply, kAENoReply | kAEDontExecute, kAENormalPriority, 
					   kAEDefaultTimeout, nil, nil);
	if (err != noErr) {
		NSLog(@"Error sending recordable AppleEvent.");
		NSLog(@"Reporting error #: %d", err);
	}
	return (err == noErr);
}

@end

@implementation NSObject (ASPrivateMethods)

-(NSAppleEventDescriptor *)ASDescriptor
{
	NSAppleEventDescriptor *desc = nil;
	if ([self isKindOfClass:[NSAppleEventDescriptor class]])
		desc = (NSAppleEventDescriptor *)self;
	else if ([self isKindOfClass:[NSString class]])
		desc = [NSAppleEventDescriptor descriptorWithString:(NSString *)self];
	else if ([self isKindOfClass:[NSNumber class]])
		desc = [NSAppleEventDescriptor descriptorWithInt32:[(NSNumber *)self intValue]];
	else if ([self respondsToSelector:@selector(objectSpecifier)])
		desc = [[self objectSpecifier] _asDescriptor];
	else
		desc = [NSAppleEventDescriptor nullDescriptor];
	return desc;
}

@end
