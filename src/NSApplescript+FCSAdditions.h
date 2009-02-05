//
//  NSApplescript+FCSAdditions.h
//  FCSFramework
//
//  Created by Grayson Hansard on 3/7/05.
//  Copyright 2005 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 NSAppleScript+FCSAdditions
 Additions that extends NSApplescript.
*/
@interface NSAppleScript (FCSAdditions)

/**
 A method that lets you call functions inside of applescripts.
 @param handler The function to call as a string.
 @param arguments The arguments sent to the function.
 @param errorInfo An NSDictionary pointer for error messages.
 @return Returns an NSAppleEventDescriptor.
*/
- (NSAppleEventDescriptor *) callHandler: (NSString *) handler 
						   withArguments: (NSAppleEventDescriptor *) arguments 
							   errorInfo: (NSDictionary **) errorInfo;

/**
 Convenience method for initializing an applescript from a file using a string path.
 @param path The path to a *.scpt file.
 @return Returns an NSAppleScript object.
*/
-(NSAppleScript *)initWithContentsOfFile:(NSString *)path;

/**
 Convenience method for getting an NSAppleScript from a file at a path.
 @param path The path to a *.scpt file.
 @return Returns an autoreleased NSAppleScript object.
*/
+(NSAppleScript *)appleScriptWithContentsOfFile:(NSString *)path;

-(NSAppleEventDescriptor *)executeEvent:(AEEventID)eventCode eventClass:(AEEventClass)eventClass parameters:(NSDictionary *)parameters;

+(NSAppleEventDescriptor *)processDescriptor;

+(BOOL)sendRecordableEventWithEventCode:(AEEventID)eventCode eventClass:(AEEventClass)eventClass 
						directParameter:(id)directParam argumentsCodesAndValues:(id)firstCode, ...;

@end

@interface NSObject(HiddenMethods)
- (NSAppleEventDescriptor *) _asDescriptor;
@end

@interface NSObject (ASPrivateMethods)
-(NSAppleEventDescriptor *)ASDescriptor;
@end
