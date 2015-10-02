//
//  ViewController.swift
//  Alert
//
//  Created by Nick Snyder on 10/1/15.
//  Copyright © 2015 Nick Snyder. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var window = UIWindow()
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let windowFrameYOffset: CGFloat = 200
        window.frame = CGRect(x: 0, y: windowFrameYOffset, width: UIScreen.mainScreen().bounds.width, height: 100)
        window.windowLevel = UIWindowLevelStatusBar
        window.backgroundColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 0.5)
        window.hidden = false

        let alert = AlertView(frame: CGRectZero)
        alert.translatesAutoresizingMaskIntoConstraints = false
        alert.backgroundColor = UIColor(red: 0, green: 0, blue: 1.0, alpha: 0.5)

        // Expected: This constraint should pin the top of the alert to the bottom of the window.
        // Actual:   This constraint pins the top of the alert to the bottom of the window plus windowFrameYOffset, so the alert view ends up being much lower than it should (you can see the gap).
        let misbehavingConstraint = NSLayoutConstraint(item: alert, attribute: .Top, relatedBy: .Equal, toItem: window, attribute: .Bottom, multiplier: 1, constant: -windowFrameYOffset)
        let constraints = [
            misbehavingConstraint,
            NSLayoutConstraint(item: alert, attribute: .Leading, relatedBy: .Equal, toItem: window, attribute: .Leading, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: alert, attribute: .Trailing, relatedBy: .Equal, toItem: window, attribute: .Trailing, multiplier: 1, constant: 0),
        ]

        window.addSubview(alert)
        window.addConstraints(constraints)
        window.layoutIfNeeded()
    }
}

private class AlertView: UIView {
    private override func intrinsicContentSize() -> CGSize {
        return CGSize(width: UIViewNoIntrinsicMetric, height: 75)
    }
}