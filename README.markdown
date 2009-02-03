# The PluginManager

I really like scriptable applications.  I especially like applications that provide a plugin architecture.  I am ecstatic to find applications that provide script-based plugins.  Let's face it, writing a Cocoa bundle is kind of a pain in the ass even when using Python or Ruby.  Being able to read plain text files as plugins is not only convenient, but it drastically lowers the barrier to entry for writing plugins (no dealing with Xcode).

Unfortunately, very few applications provide this feature.  The PluginManager attempts to resolve this issue.  It's a series of classes that provides support for a vast number of scripting languages as well as standard Cocoa bundles.  It is designed based on AddressBook's applescript plugin support but can be used in a wide number of ways.  If nothing else, this project should provide an example into calling of scripts that you can adapt to your own applications.

## The Basic Design pattern

There are two basic design patterns at work here.  The first is the PluginManager pattern.  The PluginManager can be accessed from the PluginManager with basic agnosticism to what scripts are running underneath.  This is achieved by sub-managers registering themselves with the umbrella PluginManager.  For example, in the NuPluginManager's `+load` method, it calls `[PluginManager registerManager:[[self new] autorelease]];` to add itself to the umbrella PluginManager's list of registered submanagers.  All interactions should be done through this umbrella class.

The second design pattern is in using the actual plugins.  When a sub-manager loads, it generally finds all of the scripts that it can read and loads them into memory (perhaps inefficient, but the initial release was not coded for strict memory efficiency... this could change in future releases).  Then, when the application calls `pluginsForProperty:forValue:withValue:`, it returns an NSArray of NSDictionaries which describes the plugin.  At least one key will be relevant to the plugin (usually the actual plugin in memory), and one key will be `title` (as returned from the plugin's `actionTitle` function.  Other keys may refer to information necessary for internal use by the plugin manager or to provide additional information about the plugin to the application.  When the application is ready to run the plugin, it should call `runPlugin:forValue:withValue` and return the dictionary that was originally returned from `pluginsForProperty...`.

As a third option, you can usually just call `runScriptAtPath:` to execute a script at a particular path.  This won't work for Cocoa bundles at the moment, but I've got an idea or two.

## A Few Caveats

* Wherever possible, I made the decision to only use frameworks that were available as the stock install.  I'd love to use a custom build of PyObjC or MacRuby, but I made a concerted effort to only work with what was installed by default on Mac OS X 10.5.  However, in order to use other plugin managers, you'll have to download and install the Nu framework, a Lua bridge framework, and others as appropriate.  Frameworks and download locations necessary for managers that are not bundled with OS X 10.5 are listed below.

* Some of the languages don't play nicely.  Off the top of my head, I'm thinking about a conflict between Nu's `chomp` method and Ruby's.  They have different arities and Ruby will throw an exception when it finds chomp.  I will document these as they come up under the Bugs section below.  If anyone knows how to fix these, please let me know.  If you want all of the languages active in one application, please be sure to test thoroughly and share any insights so they can be documented here.

* At present, the plugin managers are not optimized for performance in any sense.  They inherited a half-thought out design pattern and my first instinct was to just get them to work.  I'll go back and make them more memory-efficient in the near future, but you should certain test for memory usage before shipping.  Right now, I consider this code to be proof of concept rather than shipping quality.

* The Python submanager requires a small linker change to make work and Ruby scripts must load the Cocoa bridge in a particular way.  These will be mentioned in the sections about the Python submanager and the Ruby submanager, respectively when they get written.  For now, though, if you are including Python, you'll need to add `-undefined dynamic_lookup` to get around a PyObjC issue (certain PyObjC functions are not made available except to modules, but this will skirt that).  Also, as mentioned above, Ruby and Nu don't play nicely at times but you can write Ruby scripts by catching exceptions (`begin...rescue Exception => e...end`) when using `require 'osx/cocoa'`.

* There are a few other issues that will be discussed in more detail in the documentation about the plugins whenever I get around to writing it (hopefully sooner rather than later).

## Todo

A short list of things that I'll be trying to take care of relatively quickly.

* Testing
* Code commenting
* Write F-Script submanager
* Write an example application
* Write an example sdef for applescript support
* Allow for dynamic loading of plugins based on user's installed 3rd party frameworks (useful so developers don't need to distribute the Nu framework, JSCocoa, or LuaCore in the application but can still offer that functionality for savvy users).
* Write additional documentation describing the different plugins, language issues, and whatnot

## Necessary frameworks

The Python, Ruby, Applescript, and Cocoa bundle submanagers only use frameworks that are instaled by default in OS X 10.5.  The Javascript, Nu, and Lua submanagers require additional downloads.  These frameworks can either be linked into the application or bundled with the app.

* [Nu](http://programming.nu/) - Nu is a great, newish language by Tim Burks.  I'm a big fan of Nu and have written several different components in it available on [Github](http://github.com/Grayson).  You can download Nu [here](http://programming.nu/downloads).

* [JSCocoa](http://inexdo.com/JSCocoa) - JSCocoa connects Cocoa to the JavascriptCore found in Webkit/Safari.  It works wonders with easy integration in Objective-C applications.  You can even use it as a framework or by compiling it directly into the code.  It can be downloaded from its [Github page](http://github.com/parmanoir/jscocoa/tree/master).

* [LuaCore](http://gusmueller.com/lua/) - Lua was one of my favorite plugin languages for a long time since it is so easily integrated with C.  Although I've rolled my own code around the [LuaObjCBridge](http://luaforge.net/projects/luaobjcbridge/), I decided to go with Gus Mueller's LuaCore framework for this project.  It can be downloaded from its [project page](http://gusmueller.com/lua/).

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

I skimmed a lot of mailing lists and documentation to figure how to make some of this stuff work.  Other times, I was fortunate enough to have direct access to the developers or other people with direct knowledge of how the necessary frameworks worked.  And then there was stuff I just had to figure out on my own.  I've tried to thank everyone that I could remember to thank, but if I forgot someone, I apollogize.

* [Tim Burks](http://blog.neontology.com/) - Mr. Burks not only is the guy responsible for [Nu](http://programming.nu) but was also very helpful in helping me figure out how to interact with Nu.
* [Gus Mueller](http://gusmueller.com) - Mr. Mueller compiled the LuaCore framework.  Although I'm intimately familiar with Lua, I was happy to see that he had put together a lot of the work into providing an Objective-C frontend to Lua.  I didn't want to compile a competing framework or increase the file noise with my own classes so I just extended his work a tiny bit (see LuaPluginManager.h).  I also used the code on Mr. Mueller's [blog](http://gusmueller.com/blog/archives/2009/01/jscocoa_and_acorn_plugins_in_javascript.html) to help me get running with JSCocoa quickly.
* [Patrick Geiller](http://parmanoir.com/) - Mr. Geiller created the JSCocoa package/framework.  This was a massive boon in adding a Javascript plugin manager.
* [Contributors to PyObjC](http://pyobjc.sourceforge.net/) - PyObjC is great.  I love Python and PyObjC is magic.  There were a few quirks that I had to work around, but once I got my head around it, PyObjC made everything else really easy.
* [Contributors to RubyCocoa](http://rubycocoa.sourceforge.net/HomePage) - Like PyObjC, RubyCocoa is really easy to use and really lowered the barrier to entry in working with Ruby.  I don't use Ruby and am rather unfamiliar with the language, but RubyCocoa was really easy to use and get working as I expected.

## Known bugs

* Ruby has a conflict with Nu's version of NSString's `chomp` method.  This can be worked around for the moment by wrapping `require 'osx/cocoa'`.