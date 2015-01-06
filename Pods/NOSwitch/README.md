# NOSwitch

A subclass of NSButton and NSButtonCell with looks similar to UISwitch control in iOS7.

![alt text](http://i.imgur.com/18RooVw.jpg "NOSwitch demo")


**Usage**

Place a Check Box in your nib. Open Utilities→Identity Inspector (```⌥⌘3```) and assign ```NOSwitchButton``` class.

Or, in code:

```obj-c
#import "NOSwitchButton.h"

NOSwitchButton *button = [[NOSwitchButton alloc] initWithFrame:NSMakeFrame(0,0,60,36)];
[self.window.contentView addSubview:button];
```

**Customization**

By default, ```NOSwitchButton``` uses same shade of green as iOS7 UISwitch. You can change it with ```tintColor``` property:

```obj-c
button.tintColor = [NSColor colorWithCalibratedHue:0.05 saturation:0.86 brightness:0.99 alpha:1];
```

**Limitations**

Currently this cell does not display text value.

**License**

This projected is licensed under the terms of the [MIT license](http://memega.mit-license.org/).
