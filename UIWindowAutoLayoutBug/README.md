Bug report
----------

Using autolayout to position the height of a UIView inside of a UIWindow incorrectly offsets the view by the desired amount plus any offset that the window has relative to the screen (i.e. its origin).

See the comments in ViewController.swift.
