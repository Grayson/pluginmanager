# The PluginManager

I really like scriptable applications.  I especially like applications that provide a plugin architecture.  I am ecstatic to find applications that provide script-based plugins.  Let's face it, writing a Cocoa bundle is kind of a pain in the ass even when using Python or Ruby.  Being able to read plain text files as plugins is not only convenient, but it drastically lowers the barrier to entry for writing plugins (no dealing with Xcode).

Unfortunately, very few applications provide this feature.  The PluginManager attempts to resolve this issue.  It's a series of classes that provides support for a vast number of scripting languages as well as standard Cocoa bundles.  It is designed based on AddressBook's applescript plugin support but can be used in a wide number of ways.  If nothing else, this project should provide an example into calling of scripts that you can adapt to your own applications.

## The Basic Design pattern

There are two basic design patterns at work here.  The first is the PluginManager pattern.  The PluginManager can be accessed from the PluginManager with basic agnosticism to what scripts are running underneath.  This is achieved by sub-managers registering themselves with the umbrella PluginManager.  For example, in the NuPluginManager's `+load` method, it calls `[PluginManager registerManager:[[self new] autorelease]];` to add itself to the umbrella PluginManager's list of registered submanagers.  All interactions should be done through this umbrella class.

The second design pattern is in using the actual plugins.  When a sub-manager loads, it generally finds all of the scripts that it can read and loads them into memory (perhaps inefficient, but the initial release was not coded for strict memory efficiency... this could change in future releases).  Then, when the application calls `pluginsForProperty:forValue:withValue:`, it returns an NSArray of NSDictionaries which describes the plugin.  At least one key will be relevant to the plugin (usually the actual plugin in memory), and one key will be `title` (as returned from the plugin's `actionTitle` function.  Other keys may refer to information necessary for internal use by the plugin manager or to provide additional information about the plugin to the application.  When the application is ready to run the plugin, it should call `runPlugin:forValue:withValue` and return the dictionary that was originally returned from `pluginsForProperty...`.

As a third option, you can usually just call `runScriptAtPath:` to execute a script at a particular path.  This won't work for Cocoa bundles at the moment, but I've got an idea or two.

## Please note the following

At present, the plugin managers are not optimized for performance in any sense.  They inherited a half-thought out design pattern and my first instinct was to just get them to work.  I'll go back and make them more memory-efficient in the near future, but you should certain test for memory usage before shipping.  Right now, I consider this code to be proof of concept rather than shipping quality.

## Todo

A short list of things that I'll be trying to take care of relatively quickly.

* Testing
* Code commenting
* Allow for dynamic loading of plugins based on user's installed 3rd party frameworks (useful so developers don't need to distribute the Nu framework, JSCocoa, or LuaCore in the application but can still offer that functionality for savvy users).
* Write additional documentation describing the different plugins, language issues, and whatnot

## Necessary frameworks

The Python, Ruby, Applescript, and Cocoa bundle submanagers only use frameworks that are instaled by default in OS X 10.5.  The Javascript, Nu, Perl, and Lua submanagers require additional downloads.  These frameworks can either be linked into the application or bundled with the app.

* [Nu](http://programming.nu/) - Nu is a great, newish language by Tim Burks.  I'm a big fan of Nu and have written several different components in it available on [Github](http://github.com/Grayson).  You can download Nu [here](http://programming.nu/downloads).

* [MacRuby](http://www.macruby.org/) - Sure, [RubyCocoa](http://rubycocoa.sourceforge.net/) is included with Mac OS X, but I got tired of fighting with it.  MacRuby is a pain in a lot of ways, but it's less buggy and much easier to work with than RubyCocoa.  I still wish I could have gotten RC to work, but if you want Ruby, you'll need to get MacRuby as well.  Make sure to read the note below if using MacRuby.

* [JSCocoa](http://inexdo.com/JSCocoa) - JSCocoa connects Cocoa to the JavascriptCore found in Webkit/Safari.  It works wonders with easy integration in Objective-C applications.  You can even use it as a framework or by compiling it directly into the code.  It can be downloaded from its [Github page](http://github.com/parmanoir/jscocoa/tree/master).

* [LuaCore](http://gusmueller.com/lua/) - Lua was one of my favorite plugin languages for a long time since it is so easily integrated with C.  Although I've rolled my own code around the [LuaObjCBridge](http://luaforge.net/projects/luaobjcbridge/), I decided to go with Gus Mueller's LuaCore framework for this project.  It can be downloaded from its [project page](http://gusmueller.com/lua/).

* [CamelBones](http://camelbones.sourceforge.net/index.html) - CamelBones provides Perl support.  However, I have to encourage lots of testing prior to using it.  I had problems getting a version of CamelBones that worked on my Mac and I've heard that there are some problems based on which version of Perl you're using or which processor your Mac uses.  Just the same, I'm assuming that if you have a version of CamelBones that works for you, the plugin manager will work as well.  If you want Perl and Ruby support in the same application, make sure you read the note below on MacRuby.

## Contact information

Patches, questions, comments, and any other communication can be sent via email to:  
Grayson Hansard  
[info@fromconcentratesoftware.com](mailto:info@fromconcentratesoftware)

Patches, forks and other git stuff can be sent to PluginManager's github page at [http://github.com/Grayson/pluginmanager/](http://github.com/Grayson/pluginmanager/).  However, I sometimes don't immediately notice pushes and whatnot so feel free to email me as well, especially if I don't incorporate or respond to changes in a day or two.

Simple inquiries or comments can also be sent to [my Twitter account](http://twitter.com/Grayson): @Grayson.

## License information

A lot of the frameworks that PluginManager relies upon have their own licenses.  Make sure that if you bundle them with your application that you are following their license and giving credit where credit is due.  As for PluginManager, I have not added a license at this time.  I don't really feel the need but I would appreciate the following considerations:

* If you fork or patch PluginManager, please send the changes on so that I can incorporate them.  I'm happy to provide thanks for your work and it'd benefit the Mac programming community.
* If you use PluginManager, please let me know.  I like to see what applications are making use of the code and how it's working.  I just like to visit my code and I'll provide a link in this readme that may move some random traffic your way (or at least increase your Google PageRank).
* I also appreciate any remarks in a readme or About box, but that isn't necessary.  I also won't turn down free software licenses. :)

## Special thanks

I skimmed a lot of mailing lists and documentation to figure how to make some of this stuff work.  Other times, I was fortunate enough to have direct access to the developers or other people with direct knowledge of how the necessary frameworks worked.  And then there was stuff I just had to figure out on my own.  I've tried to thank everyone that I could remember to thank, but if I forgot someone, I apologize.

* [Tim Burks](http://blog.neontology.com/) - Mr. Burks is not only is the guy responsible for [Nu](http://programming.nu) but was also very helpful in helping me figure out how to interact with Nu.
* [Gus Mueller](http://gusmueller.com) - Mr. Mueller compiled the LuaCore framework.  Although I'm intimately familiar with Lua, I was happy to see that he had put together a lot of the work into providing an Objective-C frontend to Lua.  I didn't want to compile a competing framework or increase the file noise with my own classes so I just extended his work a tiny bit (see LuaPluginManager.h).  I also used the code on Mr. Mueller's [blog](http://gusmueller.com/blog/archives/2009/01/jscocoa_and_acorn_plugins_in_javascript.html) to help me get running with JSCocoa quickly.
* [Patrick Geiller](http://parmanoir.com/) - Mr. Geiller created the JSCocoa package/framework.  This was a massive boon in adding a Javascript plugin manager.
* [Contributors to PyObjC](http://pyobjc.sourceforge.net/) - PyObjC is great.  I love Python and PyObjC is magic.  There were a few quirks that I had to work around, but once I got my head around it, PyObjC made everything else really easy.
* [Contributors to RubyCocoa](http://rubycocoa.sourceforge.net/HomePage) - Like PyObjC, RubyCocoa is really easy to use and really lowered the barrier to entry in working with Ruby.  I don't use Ruby and am rather unfamiliar with the language, but RubyCocoa was really easy to use and get working as I expected.
* [Sherm Pendley](http://camelbones.sourceforge.net/) - CamelBones was a very early bridge and despite the fact that it often gets forgotten about, it's still pretty good.  There's a lot of good work there and I'm not aware of any other Cocoa-Perl bridge.  I sure wasn't about to write one so if you use PluginManager's Perl support, thank Mr. Pendley.

## A note about MacRuby

I tried really hard to make RubyCocoa support work.  I really did.  But nothing seemed to go right.  There were a ton of weird bugs and crashes that I got tired of trying to work around.  I actually like RubyCocoa and would have preferred it to MacRuby for a few reasons (no garbage collection requirement, installed on OSX, better convenience methods), but I couldn't make it work.  Maybe I'll return to it and try again in the future.

However, I went with MacRuby.  It has a lot going for it and it worked for me.  Unfortunately, it has one rather sizeable issue: it require's Objective-C's new garbage collection.  That may not sound like a bit deal, but it can be a problem if you're integrating plugins into a large codebase.  You'll need to turn on garbage collection support (-fobjc-gc) for your project (which isn't too big of a deal), but you'll also need to make sure all of your frameworks, loadable bundles, and other stuff are also garbage collection-supported.  For small projects, this may not be a big deal.  For larger ones, this could be a deal breaker.  Regardless, expect to see a lot of junk in the console when you turn on garbage collection and expect to crash until you update all of the compiled bits that your app depends on.

For those of you who want to include Perl and Ruby in one project, I have bad news for you.  I tried to find a way to compile CamelBones with garbage collection.  As may be expected, that did *not* work very well.  I haven't exactly racked my brain trying to figure this out, but I also don't really see many options here.  This may be an instance where you have to pick one.  Since CamelBones is kind of iffy anyway (you'll need to compile your own version for Leopard) and, perhaps, dying code, you may want to side with Ruby here.  However, since Ruby support means turning on garbage collection support, it may be easier to just go with Perl.  Again, I'll continue to evaluate RubyCocoa and incorporate it when possible.