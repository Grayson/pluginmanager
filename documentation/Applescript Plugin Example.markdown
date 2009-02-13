# About writing Applescript plugins

Applescript is the best technology to absolutely frustrate hundreds upon hundreds (thousands upon thousands?) of Mac programmers.  Let's face it, everyone seems to like it but no one wants to implement it.  That's because it's hard and error-prone.  Worse, the errors often don't tell the programmer much about what is going wrong.  And often, something exceptionally minor can ruin someone's day.

This example application has defined a small SDEF file that shows how to implement the same basic plugin architecture as Apple's Address Book.

## The necessary setup

First and foremost, there's the sdef file.  Note that you merely need to define the stuff that you want in the file as a command.  You do not need to attach them to a class, but they need to be defined as a command.  Next, you need to make sure that you have the appropriate keys set in the Info.plist file.  You'll need NSAppleScriptEnabled set to YES and OSAScriptingDefinition set to the name of the sdef file (.sdef extension included).  Finally, make sure that you've set a 4 char code in the "Creator" pane of the Properties tab of your application's Target Info.

## The rest should take care of itself

If you've set up the sdef file as in the example (and you can copy it and just change the creator code and information although note that the commands also have the creator codes in them)