# CamelBones in 2009

I really want to like CamelBones.  And I do.  It's a great piece of technology.  But it hasn't been updated in a long time and it shows.  If you download the latest version of CamelBones from the website, there's a rather high probability that it won't work for you.  The one I downloaded didn't work for me.  However, I fiddled with it until I got it to work.  I'm going to post those instructions below as well as how to embed a Perl app using CamelBones.  I do warn you that if it's this difficult to get a working version of CamelBones, you may consider avoiding Perl support since common users probably won't even apply.  Or, perhaps, hosting a built version so they don't have to go through these steps.

## Building your own CamelBones

When I downloaded CamelBones from its SourceForge page, the installer installed a framework that simply wouldn't load on my Intel-based Mac.  Not being one to suffer this mild injustice, I downloaded the source package from SourceForge and tried building it.  Well, the Xcode installer didn't work properly and make kept failing on me.  Then I figured it out.

1. Download the source package from SourceForge.  You'll need the files, after all.
2. Unarchive the source package and store it somewhere where there are no spaces or illegal characters in the path name.  You'll avoid a small but annoying compiling bug with this one.
3. Open up Terminal.app and navigate to the source folder.
4. Run `./configure` in the Terminal.  This creates the necessary files that Xcode will need when it does its stuff.
5. Open the xcode project and select the appropriate target.  The appropriate target should be the nickname of your operating system.  Since PluginManager uses ObjC 2.0 features at some places, go with "Leopard."
6. Build CamelBones using Xcode.
7. Navigate to the build/Release/ folder in the source folder and drag CamelBones.framework to /Library/Frameworks/.
8. There may be another step, but I'm not sure.  The installer package probably installs a few other files that you may need to make sure everything works properly.  If you figure this out, please let me know and I'll update these steps.

## Embedding Perl with CamelBones

Sure, it's a bit of a hassle to install CamelBones, but it's a rather awesome technology so some of that can be forgiven by developers (for users that don't even know what Xcode is, it's probably still just a pain in the ass).  First things first, import the CamelBones header.

	#import <CamelBones/CamelBones.h>

Now, the interpreter is really easy to use.  It will eval code on the fly, so you just have to load it up.

	NSString *perlCode = [NSString stringWithContentsOfFile:filePath];
	CBPerl *perl = [CBPerl sharedPerl];
	NSLog(@"%@", [perl eval:perlCode]);

## Calling subroutines in Perl

Unfortunately, although CamelBones provides lots of ways to retrieve objects, it doesn't let you retrieve subroutines.  That's okay because we can use the same method that we used with Nu.  You can inject objects into the Perl runtime and then call them by executing code on the fly.

	[perl setValue:@"example string" forKey:@"_exampleParameter"];
	[perl eval:@"doSomething($_exampleParameter);"];

Note that Perl will still prefix variables with a "$", so don't forget about that.  Also, since we're using CamelBones, you'll need to load it in the Perl file or else you'll experience some lovely crashes.  The magic stuff is to simply put `use CamelBones qw(:All);` at the beginning of your Perl file.  After that, you're ready to go.