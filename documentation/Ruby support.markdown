# How to embed Ruby in Cocoa applications

I have to say at the outset how utterly surprised I was at how easy it is to get Ruby support working in an application.  RubyCocoa really provides the right tools with interacting with Ruby.  Getting Ruby running was almost as easy as reading the header files in the RubyCocoa framework and asking, "What if?"

## Getting started

The first thing you'll need to do is to load all of the necessary frameworks and libraries.  RubyCocoa is separated from Ruby, so you'll need to link both RubyCocoa (found at /System/Library/Frameworks/RubyCocoa.framework) and libruby (which I found at /System/Library/Frameworks/Ruby.framework/Versions/1.8/usr/lib/libruby.1.dylib).  When I tried adding Ruby.framework, Xcode complained that the Ruby framework couldn't be found.

With the library and framework linked, you'll want to import the RBRuntime header from RubyCocoa into your header file.

	#import <RubyCocoa/RBRuntime.h>

## Ruby is easy

The first thing you need to do with Ruby is start it up.  You'll want to load not only Ruby but also RubyCocoa.

	ruby_init();
	ruby_init_loadpath();
	RBRubyCocoaInit();

Now, the part that's surprisingly easy.  Let's say you have the following Ruby script:

	def rubyExample
	  return "Hi, from Ruby!"
	end
	
	def printMe (param)
		puts param
	end

You can load it using RubyCocoa's RBObject class.  Unfortunately, RBObject isn't readily available.  You could import RubyCocoa/RBObject.h, but that imports RubyCocoa/osx_ruby.h which ran into a long list of compiling errors when I did it.  I didn't want to mess with that, so I call up RBObject using `NSClassFromString`.

	Class RBObject = NSClassFromString(@"RBObject");
	id rb = [RBObject RBObjectWithRubyScriptString:[NSString stringWithContentsOfFile:scriptPath]];

You now have an NSProxy object called "rb" that represents the ruby script that was just loaded.  This proxy makes it so easy to call into the script.

	NSLog(@"%@", [rb rubyExample]); // This will call the scripts "rubyExample" function

Could it get easier?  What's better still, RubyCocoa will automatically handle conversion between types.

	[rb printMe:[NSObject new]];
	[rb printMe:[NSArray arrayWithObject:@"example"]];

NSObject will be converted into an object that Ruby can work with and base types (strings, dictionaries, arrays, etc.) will be automatically converted to their Ruby equivalents.

## A word about compiler warnings

You may notice that if you try to compile the above code, you'll get a lot of compiler warnings.  That's because `RBObjectWithRubyScriptString`, `printMe`, and `rubyExample` aren't defined by any class that the compiler knows about.  You can get around this by using `performSelector:` and the like or you can define simple categories that declare these methods to avoid the warning.

	@interface NSObject (AvoidRubyCocoaWarnings)
	-(id)RBObjectWithRubyScriptString:(NSString *)script;
	-(NSString *)rubyExample;
	-(void)printMe:(id)param;
	@end
