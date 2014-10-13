NWLogging
=========

*A minimalistic logging framework for Cocoa.*


<a name="NWL_About"></a>
About
-----
NWLogging is a Cocoa logging framework that provides logging functions similar to NSLog. It consists of a light-weight core written in C that needs little configuration, and a collection of tools for convenient configuration and log access.

What makes it particularly useful is the flexibility with which logs can be filtered and directed to different outputs, both in source and at runtime. This makes NWLogging a tool for both debugging and error reporting, without the log spam of a growing project.


<a name="NWL_GettingStarted"></a>
Getting Started
---------------
You can get started with NWLogging in your Cocoa or Cocoa Touch application in just a few steps. Say you want to log when your app starts in the AppDelegate.m file:

1. Add `NWLCore.h` and `NWLCore.m` to your app target.
2. Include `NWLCore.h` at the top of your source file (`AppDelegate.m` in this case):

        #include "NWLCore.h"

3. Add the log statement to your code (`applicationDidFinishLaunching:` in this case):

        NWLog(@"Application did finish launching");

4. Start your app (in debug mode) and keep an eye on the console output:

        [12:34:56.789000 AppDelegate.m:123] Application did finish launching

This is just a minimal setup to demonstrate the necessary steps to get NWLogging to run. See the [Project Setup](#NWL_ProjectSetup) section for detailed instructions. For more example code, check out the source and take a look a the TouchDemo and MacDemo applications.


<a name="NWL_Features"></a>
Features
--------
+ *Logging functionality similar to NSLog.*

   <p>Although NWLogging offers configurable filters and outputs, by default it just prints what you tell it to. Simply replace `NSLog` by `NWLog`.</p>

+ *Log filtering based on target, file, function, and custom tags.*

   <p>No useless floods of log messages, but fine-grained filtering so you only get the logs you need.</p>

+ *Log output to console, file, and custom printers.*

   <p>By default all logs are printed to stderr, but you also can redirect this to a file, stream, or a text view for in-app display.</p>

+ *Alternative log actions like pause debugger or throw exception.*

   <p>Use logs to handle your asserts and exceptions. Configure which lines should trigger the debugger to break. Simply replace `NSAssert` with `NWAssert`.</p>

+ *Configuration both statically from source code and from the debugger at runtime.*

   <p>Configuration methods are available both in source and debugger. This allows you to run a standard configuration and further configure while debugging.</p>

+ *Supports pure C and C++ projects.*

   <p>The core of NWLogging is not tied to Objective-C or Cocoa. It only requires standard C and Core Foundation libraries.</p>

+ *Concurrent, but free of locking.*

   <p>To have a minimal impact on your app's runtime, NWLogging avoids thread locking, heap allocation, and message sending.</p>


<a name="NWL_ProjectSetup"></a>
Project setup
-------------
There are various ways to add NWLogging to your project setup. Which approach fits best depends on the target configurations, which components you want to use, and how closely your code interacts with the framework. This section covers two common configurations: the minimal core and static integration.

The minimal setup has already been introduced in the [Getting Started](#NWL_GettingStarted) section. In short: add the NWLCore files to your project and include the NWLCore header where needed. To avoid collision with uses in other projects, it is recommended to *not* compile `NWLCore.m` into any shared library, but only in the final application binary.

NWLogging can also included as static or dynamic framework into your Cocoa Touch or Cocoa application. While this approach doesn't include the NWLogging source, it does provide a single package that can be conveniently included in Xcode. To build `NWLogging.framework`, run the `NWLoggingUniversal` target, which outputs to the `build` folder in the project root.

To make NWLogging functions available throughout your project, include the main `NWLogging.h` header in your project by referencing it in your Prefix Header file (`.pch`). For example:

    #import <NWLogging/NWLogging.h>

To filter logs based on the library they occur in, you should set the library name by defining the `NWL_LIB` preprocessor variable, for example by adding `NWL_LIB=$(TARGET_NAME)` to the 'Preprocessor Macros' parameter in your target's build settings:

     Debug    DEBUG=1 NWL_LIB=$(TARGET_NAME)

By default NWLogging is *only* enabled in DEBUG configurations. To ensure logging in other configurations you must explicitly set NWL_LIB in the preprocessor:

     Release  NWL_LIB=$(TARGET_NAME)

To see if NWLogging has been set up properly, add the following in your application main or launch method:

    NWLog(@"Works like a charm");

When run, this should output something like:

    [12:34:56.789000 MyApp main.c:012] Works like a charm

Having completed the setup, it's time for some action in the [How to](#NWL_HowTo) section. If you'd like a more conceptual understanding, take a look in the [Design](#NWL_Design) section.


<a name="NWL_HowTo"></a>
How to
------
*How to log some text to the console output?*

    NWLog(@"some text");

*How to format my log statements?*

    NWLogInfo(@"Works just like %@.", @"NSLog(..)");

*How to log debug text that can be filtered out later on?*

    NWLPrintDbug();  // turn on printing of 'dbug' tag
    NWLogDbug(@"debug text that is printed");
    NWLClearDbug();  // turn off printing of 'dbug' tag
    NWLogDbug(@"debug text that is not shown");

*How to log a warning text?*

    NWLogWarn(@"warning text!");

*How to log some warning text when a condition fails?*

    NWAssert(1 != 1); // '1 != 1' is printed
    NWLBreakWarn();   // turn on breaking of 'warn' tag
    NWAssert(1 != 1); // '1 != 1' is printed and the debugger is paused

*How to log an `NSError`?*

    NSError *error = nil;
    [moc executeFetchRequest:request error:&error];
    NWError(error);  // if error then print description

*How to print text of the 'info' level?*

    NWLPrintInfo();  // turn on 'info' tag
    NWLogInfo(@"some info");

*How to log stuff related to file I/O?*

    NWLPrintTag("fileio");
    NWLogTag(fileio, @"Reading from file: %@", filename);
    NWLogTag(fileio, @"Writing to file: %@", filename);

*How to see which filters and printers are active?*

    NWLDump();


<a name="NWL_Design"></a>
Design
------

### Conceptual
The three primary concepts in NWLogging are *filters*, *actions*, and *printers*. When a log statement is executed, it is first passed though a series of filters. The filter that matches the properties of that log statement best decides which action should be performed. A printer is function that formats and outputs the log text and its properties.

A filter is a set of constrains on the properties of the log statement. For example: "should be in file X.m" or "should be in library Y and have tag Z". Filters have a fixed format, which allows them to be efficiently matched. For every property of a log statement, it either specifies its value or doesn't care about that property. Available properties are:

* *tag* - A short string specified in the log statement, e.g. `info` or `warn`.
* *lib* - The library in which this log call is made.
* *file* - Name of the file where this log call is made.
* *function* - Name of the function where this log call is made.

Every filter has an associated action. When the best-matching filter has been found, the log text is passed to that action. Available actions are:

* *print* - Forward this log statement to all printers.
* *break* - Forward to all printers and send the SIGINT signal allowing the debugger to break.
* *raise* - Raise an exception with the log text as reason.
* *assert* - Assert false with the log text as description.

In most cases, a filter is associated with the print action, which forwards the log text and its properties to the set of printer functions. The default printer formats the log properties conveniently, appends the log text, and outputs to STDERR. In contrast to filters, printers designed to be open-ended, allowing any formatting and outputting, for example to file, stream, UI views, etc.

One important concept shortly mentioned earlier, is that of *tags*. Tags provide a flexible way to control the filtering of log statements. By associating a tag with every log statement, the printing of log text can also be controlled based on these tag, next to the function, file, or library they are in. By default NWLogging uses the tags *warn*, *info*, and *dbug*, which mimmic the log *levels* often used in logging frameworks. It is however possible to define new tags, tailored to the different modules or cross-sections of your code.


### Core
NWLogging consists of a small core written in C and a collection of tools written in Objective-C. The core has been designed with a simplicity and performance focus. It has three main parts:

1. Generic logging methods for direct logging and filtered logging. `NWLLogWithoutFilter` simply forwards the log message to all printers. The NWLog method is based on this. `NWLLogWithFilter` first matches properties like tag, file and function with available filters to see if that message needs printing.

2. Configuration methods to manage filters, printers, and the clock. Th

3. A set of convenience methods for general use. These define the standard tags 'Dbug', 'Info' and 'Warn', which are not present in the previous two parts.

### Tools
The NWLogging tools set focusses on extending the core into Cocoa. It provide Objective-C interfaces to the core functionality allowing it to be easily integrated into a Cocoa or Cocoa Touch application.


<a name="NWL_FAQ"></a>
FAQ
---
#### Why does my log message not appear in the output?

First make sure your console *does show stderr* output, for example by printing some text with `NSLog(@"some text")`. Now assuming your console is properly set up, there are several reasons a line is not displayed:

1. You're logging on a tag that is not active. For example, to log on the 'info' tag, you need to activate it first:

        NWLPrintInfo();  // activate all logging of info tag
        NWLogInfo(@"This line should be logged");

    If you want to see which filters are active, use the `NWLDump()` method, which should give you something like:

        action       : print tag:warn
        action       : print tag:info
        printer      : default
        time-offset  : 0.000000

    Optionally, you can replace your `NWLogInfo(..)` call with `NWLog(..)`, without the 'info'. `NWLog` always logs, ignoring all filters, just like `NSLog` does.

2. Another cause might be that the default (stderr) printer is not active. Activate the default printer with:

        NWLRestoreDefaultPrinters();

3. You might run a complex configuration of filters and have no clue which filter does what. Reset all filter actions using:

        NWLRestoreDefaultFilters();

4. Possibly you didn't do all necessary setup. If you run in Release configuration, you need to explicitly define NWL_LIB. Make sure you followed the steps described in the [Project Setup](#NWL_ProjectSetup) section.

    Still not working? Drop me a line: leonardvandriel at gmail.


#### Which log levels are there?

Technically, NWLogging does not have log levels. Instead, it offers *tags*, which offer the same functionality as levels, but are more flexible. There are three default tags (read levels): `warn`, `info`, `dbug`, but you can use any tag you want. For example, if you want to do very fine grained logging on the trace 'level', use:

    NWLogTag(trace, @"Lots of stuff happening here");

You can activate the trace logs with:

    NWLPrintTag("trace");

Note that tags don't have any natural ordering. Activating the 'dbug' tag does *not* automatically activate the 'info' tag.


#### What's the meaning of the stuff `NWLDump()` prints?

The `NWLDump()` function prints the internals of the NWLogging configuration at a specific point in code and execution. It can be invoked both from de debugger and from source. A call to NWLDump from source typically provides the following information:

    file         : MyClass.m:88
    function     : -[MyClass myMethod]

The location in source where this particular `NWLDump();` statement is run.

    DEBUG        : YES

Indicates whether this NWLDump call was compiled in debug configuration. By default, NWLogging is enabled in debug, but disabled in release.

    NWL_LIB      : MyLibName

The name of the library that compiled this NWLDump call. This value can be configured by setting `NWL_LIB=$(TARGET_NAME)` in the preprocessor.

    NWLog macros : YES

If `YES`, NWLogging calls like NWLog(..) and NWLogInfo(..) are compiled into the binary. If `NO`, all logging calls are stripped out. This value is derived from the `NWL_LIB` macro.

    action       : print tag=warn

A list of active filters, formatted: `<action> <property>=<value>`. Filters can be added using `NWLAddFilter(..)`.

    printer      : default

A list of printers, where `default` refers to the stderr printer. Printers can be added using `NWLAddPrinter(..)`.

    time-offset  : 0.000000

The offset that is applied to all timestamps. Can be configured with `NWLOffsetPrintClock(..)`.


<a name="NWL_License"></a>
License
-------
NWLogging is licensed under the terms of the BSD 2-Clause License, see the included LICENSE file.


<a name="NWL_Authors"></a>
Authors
-------
- [Noodlewerk](http://www.noodlewerk.com/)
- [Leonard van Driel](http://www.leonardvandriel.nl/)