# How to embed Ruby in Cocoa applications

Ruby was easily the most difficult language I tried to get working in the PluginManager.  However, most of that difficulty was from working with RubyCocoa.  I want to say again that I like RubyCocoa and want to use it, but it simply wasn't built for embedding, especially with other languages.  Getting full Ruby support meant going with [MacRuby](http://macruby.org).

## Getting started

MacRuby is a complete Ruby system.  There aren't any other requirements.  You can simply drag the MacRuby framework into your application and link it.  Well, you do that and turn on garbage collection.  Simply open your app's target, switch to the "Build" tab, and search for "garbage".  You then need to change the Objective-C Garbage Collection from "Unsupported" to "Supported" or "Required."  Note that this may change your app's behavior, especially in regards to loading external bundles and frameworks.  Once you've turned on GC, you can add the following to your header file:

	#import <MacRuby/MacRuby.h>

## Ruby isn't hard

MacRuby doesn't provide as useful convenience methods.  There are some useful stuff, but not quite for what we want to do.  If you use MacRuby's `evaluateFileAtPath:`, you won't receive the script object that we need to work with.  For this, we'll have to delve into Ruby's embedding layer.

	[MacRuby sharedRuntime];
	VALUE script = rb_eval_string([[NSString stringWithContentsOfFile:scriptPath] UTF8String]);

The first line simply starts the MacRuby runtime.  You can receive a reference to the runtime and use some of MacRuby's convenience methods, but we're not doing that today.  Today, we're calling into scripts.  The second line simply uses rb\_eval_string (excuse the backslash if you're reading this in plain text), to evaluate the script.  The script object is returned as a result.

Let's assume that the ruby script just loaded was the following:

	def rubyExample
	  return "Hi, from Ruby!"
	end
	
	def printMe (param1, param2)
		puts param1
		puts param2
	end

We're going to need to use a bit more of the plain C embedding layer to call into these.  First things first, calling a method is fairly easy.  Ruby provides `rb_funcall`.  It can be used in the following manner:

	VALUE ret = rb_funcall(script, rb_intern("rubyExample"), 0);
	NSLog(@"%@", RB2OC(ret));
	
	rb_funcall(script, rb_intern("printMe"), 2, OC2RB(@"this will be printed"), OC2RB(@"this is param2"));

There are several `rb_funcall` functions.  This is the basic one.  The first parameter is the object that should be called.  Since we're working with the script object from above, it'll be passed.  The second parameter is Ruby's representation of the method, found using `rb_intern`.  Note that we're using standard C strings (`char *`) and not NSStrings.  The third parameter is the number of arguments to pass.  In the case of no arguments, this will be the last parameter.  However, if there are arguments, they'll simply be passed following this (as noted in the last line).  Objects can be converted from Ruby using `RB2OC` and to Ruby using `OC2RB`.

`rb_funcall` is great if you know exactly how many parameters you will pass (or otherwise like building var_arg lists).  If you'd prefer a more convenient method, `rb_funcall2` may be appropriate.  `rb_funcall2` works pretty much like `rb_funcall` except for it takes 4 arguments (instead of the variable number for `rb_funcall`) where the last argument is a C array of values that represent the arguments to pass to the script.

	VALUE args[2];
	args[0] = OC2RB(@"this will be printed");
	args[1] = OC2RB(@"this is param2");
	rb_funcall2(script, rb_intern("printMe"), 2, args);
	NSLog(@"%@", RB2OC( rb_funcall2(script, rb_intern("rubyExample"), 0, nil) ));
