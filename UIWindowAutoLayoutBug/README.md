Apple Bug Report 
----------------

22981888: "Positioning views with auto layout inside of a UIWindow with a non-zero origin results in incorrect offsets"

Using autolayout to position the height of a UIView inside of a UIWindow incorrectly offsets the view by the desired amount plus any offset that the window has relative to the screen (i.e. its origin).

See the comments in ViewController.swift.
