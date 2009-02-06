//
//  ExampleController.h
//  ExampleApplication
//
//  Created by Grayson Hansard on 2/5/09.
//  Copyright 2009 From Concentrate Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AddressBook/AddressBook.h>


@interface ExampleController : NSObject {
	NSDictionary *_me;
}

@property (retain) NSDictionary *me;

- (IBAction)showPluginMenu:(id)sender;

@end
