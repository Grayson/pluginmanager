# How to embed Nu in Cocoa applications

[Nu](http://programming.nu/) is a programming language built on top of Objective-C.  It's a combination of Lisp syntax, Ruby idioms, and the Cocoa framework.  Often, I find that it's very easy and efficient to prototype code in Nu and then port it to Objective-C when I need better performance.  I'm a bit fan of Nu and really like using it whenever I can.  Since Nu is dynamic and written on Objective-C, it was quick to embed.

## Getting started

Like most of the other plugin managers, it's necessary to link in the appropriate framework.  You can download Nu from its [download page](http://programming.nu/downloads).  Simply download, install, and then link it to your Xcode project.  Once that is done, simply add `#import <Nu/Nu.h>` to the top of your header file.

## Embedding Nu

Nu provides a full featured parser, so it's really easy to implement.  You just need to instantiate a parser, parse the code, and then run with it.

	id parser = [Nu parser];
	NSString *nuCode = [NSString stringWithContentsOfFile:nuFile];
	id returnedValue = [parser parseEval:nuCode];
	NSLog(@"%@", returnedValue);

Let's say we have the following Nu script file:

	(function nuExample() 
		"Hello, from Nu!")
	
	(function addMe(param1, param2)
		(+ param1 param2))

There are two ways to call into Nu.  I'll show the more direct method first and then show a more indirect method following.  I personally prefer the indirect method as it doesn't throw any warnings or use any of Nu's non-public methods.  However, this method is viable and nothing should go wrong if you use it.  The first way is to retrieve the Nu function and then call it.  Nu functions are [NuBlocks](http://programming.nu/doc/classes/NuBlock.html) and can be easily evaluated.

	id nuFunction = [parser valueForKey:@"nuExample"];
	NSLog(@"%@", [nuFunction evalWithArguments:nil context:[parser context]]);

This should print "Hello, from Nu!" in the console.  But, of course, we also want to be able to call functions with arguments.  For this, we need to do a little bit of fudging with an NSArray.  Nu's Lisp syntax likes NuCell lists.  Before we toss arguments at it, we'll need to convert them into a Nu list.  Luckily, Nu provides a method to NSArray that will handle this.

	id addMe = [parser valueForKey:@"addMe"];
	NSArray *args = [NSArray arrayWithObjects:[NSNumber numberWithInt:2], [NSNumber numberWithInt:3], nil];
	NSLog(@"%@", [addMe evalWithArguments:[args list] context:[parser context]]);

This works and is rather direct, but the Nu framework does not make `evalWithArguments:context:` or NSArray's new `list` method known to the compiler.  The headers for these aren't made public by the framework.  Nothing should fail, but the compiler will complain a bit.  You can stub out some categories that will define these methods or simply use `performSelector:` and its like in order to skirt these compiler warnings.

## An alternate method of calling into Nu

If you're as lazy as I am about dealing with the compiler, there's another way.  This way is less direct, but it avoids the compiler warnings and only uses what the Nu framework provides publicly.  Basically, since Nu can evaluate code on the fly, you can call into Nu functions using Nu commands.  Here's an example using the parser from above:

	NSLog(@"%@", [parser parseEval:@"(nuExample)"]);

The parser knows about nuExample.  All we are doing is telling it to call it using Nu.  It's simple, easy, and doesn't require any minor hacks to work around the compiler.  Of course, things get a bit hairier when calling functions with arguments.  Since you're not calling it directly, you'll need to insert some additional information into the parser.  You can inject global values into the parser using `setValue:forKey:` and then use those values when calling a function.

	// I'm using underscores in the name just to make sure that there aren't any other naming conflicts.
	[parser setValue:[NSNumber numberWithInt:2] forKey:@"__param1"];
	[parser setValue:[NSNumber numberWithInt:3] forKey:@"__param2"];
	NSLog(@"%@", [parser parseEval:@"(addMe __param1 __param2)"];

What we're doing above is simply putting two NSNumbers into the parser's global context (called "`__param1`" and "`__param2`", respectively) and then using them when we call "`addMe`" from Nu.  Nice and easy.
