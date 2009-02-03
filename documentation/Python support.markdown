# How to embed Python in a Cocoa application

Learning to call into Python was one of my biggest headaches when writing the PythonPluginManager.  I wasn't able to find any example code other than simple embedding and PyObjC doesn't expose some of the more useful stuff to applications.  There also isn't some nice Cocoa wrapper around Python like RubyCocoa provides for Ruby.  However, by trial, error, and lots of swearing, it now appears to work.

Embedding Python in a C application is actually fairly straightforward.  Python itself provides several high-level functions that make it easier.  To start, simply link the Python framework found at /System/Library/Frameworks/Python.framework into your application.  Next, you'll want to import the Python header.  From there, you can pretty much follow the [basic embedding instructions][embed] (note that I'm linking to the 2.6 docs simply because I prefer the page style; the instructions are basically the same for 2.5.x which ships with OS X).

	#import <Python/Python.h>
	Py_Initialize();
	PyRun_SimpleString("print \"Hi, from Python.\"");
	Py_Finalize();

[embed]: http://docs.python.org/extending/embedding.html

## Setup for better embedding

The above example was nice, but quaint.  There's not really a lot of work that can be done by using `PyRun_SimpleString`.  You as well have just used NSTask.  No, you'll want to really get into Python a bit deeper.  You want to be able to run a file and then interact with it a bit.  Right?  First, you initialize Python with `Py_Initialize`, open the file as FILE* descriptor, get the main module and globals, and then run it using `PyRun_File`.  In the example below, we haven't really used mainModule, but we will in the next section.

	Py_Initialize();
	Py_SetProgramName("/usr/bin/python");
	FILE *pyFile = fopen([pythonPath fileSystemRepresentation], "r");

	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *globals = PyModule_GetDict(mainModule);

	PyRun_File(pyFile, [pythonPath UTF8String], Py_file_input, globals, globals);

## Now for something more entertaining

Now that you've loaded a file using `PyRun_File` (or a similar high-level function), you can interact with it through its main module.  Let's say that you wanted to call a function.  Let's call this function "pythonExample" and make it have one parameter:

	# A python script
	def pythonExample(x):
		print x
		return "Nice to meet you!"

Now, you can get the function as a PyObject using `PyObject_GetAttrString` on the main module:

	// Back into C/Objective-C/etc. now
	PyObject *pFunc = PyObject_GetAttrString(mainModule, "pythonExample");

Note in the above that `PyObject_GetAttrString` expects a standard C string (char *) as its second parameter.  Convert NSStrings as appropriate.

Okay.  You've got a function.  You just need the arguments.  Arguments are handled using a python tuple.  Creating these in C is fairly simple.

	PyObject *tuple = PyTuple_New(1); // Only have 1 item in this tuple, if your function has more parameters, put the number of parameters in place of the 1
	PyObject *x = PyString_FromString("Hi, from Python"); // Turn a C string into a PyObject
	PyTuple_SetItem(tuple, 0, x); // Insert the PyObject into the tuple at index 0

Now, you'll want to call this function.  That's also fairly simple given the high level API provided by Python.  However, on OS X, it's possible to get an unwaranted crash caused by the GIL state.  This is easy to resolve:

	if (pFunc && PyCallable_Check(pFunc)) {
		PyGILState_STATE state = PyGILState_Ensure();
		PyObject *pValue = PyObject_CallObject(pFunc, tuple);
		Py_XDECREF(pFunc);
		PyGILState_Release(state);
	}

If the function returned a value, it would be set in pValue.  In the Python script above, we're returning a string ("Nice to meet you!") so pValue is a PyObject that represents that string.

	NSLog(@"%s", PyString_AsString(pValue));

## Putting it all together

Here is another example of all of the steps above put together.  However, I'm using a slightly different python method just to make sure that some of the concepts are demonstrated fully.

	# The new python script
	def anotherExample(param1, param2):
		return param1 * param2
	
	def anExampleWithNoParameters()
		return 42


	// Back to the C/Objective-C/etc. file
	// Assume pythonPath points to the python script above
	Py_Initialize();
	Py_SetProgramName("/usr/bin/python");
	FILE *pyFile = fopen([pythonPath fileSystemRepresentation], "r");
	
	PyObject *mainModule = PyImport_AddModule("__main__");
	PyObject *globals = PyModule_GetDict(mainModule);
	
	PyRun_File(pyFile, [pythonPath UTF8String], Py_file_input, globals, globals);
	
	// anotherExample() takes two parameters.
	PyObject *tuple = PyTuple_New(2);
	PyObject *param1 = PyInt_FromLong(5);
	PyObject *param2 = PyInt_FromLong(4);
	PyTuple_SetItem(tuple, 0, param1);
	PyTuple_SetItem(tuple, 1, param2);
	
	PyObject *pFunc = PyObject_GetAttrString(mainModule, "anotherExample");
	if (pFunc && PyCallable_Check(pFunc)) {
		PyGILState_STATE state = PyGILState_Ensure();
		PyObject *pValue = PyObject_CallObject(pFunc, tuple);
		Py_XDECREF(pFunc);
		PyGILState_Release(state);
		NSLog(@"%d", PyInt_AsLong(pValue));
	}

## Reusing the main module

Okay, so you've called `anotherExample` above, but we also have `anExampleWithNoParameters`.  What if you want to call it after you've called `anotherExample`?  It's easy.  Just hold on to the reference to mainModule and call it just like you normally would.

	PyObject *anotherFunc = PyObject_GetAttrString(mainModule, "anExampleWithNoParameters");
	if (pFunc && PyCallable_Check(anotherFunc)) {
		PyGILState_STATE state = PyGILState_Ensure();
		PyObject *pValue = PyObject_CallObject(anotherFunc, nil);
		Py_XDECREF(anotherFunc);
		PyGILState_Release(state);
		NSLog(@"%d", PyInt_AsLong(pValue));
	}

Since there were no parameters, you can simply toss `nil` into `PyObject_CallObject` without worrying about creating another tuple.  As long as you hold on to a valid reference to the main module, you can keep calling its functions in this manner.  Of course, if you are going to call certain functions frequently, you can just hold on to those function references and call them more directly.

## A note about Py_Initialize()

In all of these examples, I've shown `Py_Initialize()` as the first item to do.  However, I read on some mailing lists that it is inefficient to call it multiple times in a program.  Worse, it may have a memory leak in it (again, according to mailings lists).  If you plan on running multiple files, you can simply load them as you normally would and use them.

If you plan on doing this, do not call `Py_Finalize()` until you are done using the Python interpreter.  I haven't tried it yet, but I expect that if you call `Py_Finalize()` and then try to call Python functions and whatnot, bad things could happen.  You should, of course, call `Py_Finalize()` when you are done with the interpreter, but if the Python interpreter be running during the entire application, I don't suppose there's much harm in just forgetting about it and letting it get cleaned up with everything else when the user quits your app.

## Converting PyObjects into their Cocoa equivalents and vice versa

PyObjC provides some nice functions that would convert PyObjects.  I'd much prefer to actually use those methods, but unfortunately they don't seem to be provided to code outside of creating PyObjC modules.  That's okay because it's fairly simple to convert basic classes (strings, numbers, dictionaries, arrays, etc.) into their Cocoa equivalents.  PyObjC also wraps custom Cocoa classes in such a way as to make it easy to get to their values.  Examples of this can be seen in PythonManagerPlugin.m.  I won't repeat the code here, but take a look at the `pythonify` and `depythonify` functions at the top.