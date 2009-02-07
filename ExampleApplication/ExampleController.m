//
//  ExampleController.m
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/5/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import "ExampleController.h"
#import "PluginManager.h"

@implementation ExampleController

@synthesize me = _me;

- (void)awakeFromNib
{
	ABAddressBook *book = [ABAddressBook sharedAddressBook];
	ABPerson *me = [book me];
	ABMultiValue *mv = [me valueForProperty:kABPhoneProperty];
	NSMutableArray *array = [NSMutableArray array];
	unsigned int count = [mv count];
	unsigned int idx = 0;
	for (idx = 0; idx < count; idx++) [array addObject:[mv valueAtIndex:idx]];
	NSDictionary *meDict = [NSDictionary dictionaryWithObjectsAndKeys:
		[NSString stringWithFormat:@"%@ %@", [me valueForProperty:kABFirstNameProperty], [me valueForProperty:kABLastNameProperty], nil], @"name",
			array, @"phone", nil];
	self.me = meDict;
}

- (IBAction)showPluginMenu:(id)sender {
	id value = nil;
	if ([sender tag] == 0) value = [self.me objectForKey:@"name"];
	else if ([sender tag] == 1) value = [self.me objectForKey:@"phone"];
	NSArray *plugins = [PluginManager pluginsForProperty:@"label-click" forValue:self.me withValue:value];
	
	NSMenu *m = [[[NSMenu alloc] initWithTitle:@"pluginMenu"] autorelease];
	for (NSDictionary *plugin in plugins) {
		NSDictionary *pluginDict = [NSDictionary dictionaryWithObjectsAndKeys:
			plugin, @"plugin",
			value, @"value", nil];
		NSMenuItem *mi = [m addItemWithTitle:[plugin objectForKey:@"title"] action:@selector(performPlugin:) keyEquivalent:@""];
		[mi setRepresentedObject:pluginDict];
		[mi setTarget:self];
	}
	[NSMenu popUpContextMenu:m withEvent:[NSApp currentEvent] forView:sender];
}

- (IBAction)performPlugin:(id)sender {
	NSDictionary *pluginDict = [sender representedObject];
	[PluginManager runPlugin:[pluginDict objectForKey:@"plugin"] forValue:self.me withValue:[pluginDict objectForKey:@"value"]];
}

@end
