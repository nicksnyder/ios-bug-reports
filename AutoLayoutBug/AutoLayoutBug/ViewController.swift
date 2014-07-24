//
//  ViewController.swift
//  AutoLayoutBug
//
//  Created by Nick Snyder on 7/24/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  @IBOutlet weak var one: Label!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.one.text = "This is some very long text that will wrap to six lines on the portrait orientation of an iPhone 5s form factor and three lines on the landscape orientation of an iPhone 5s form factor";
    logStuff()
  }

  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    logStuff();
  }
  
  private func logStuff(label: String = __FUNCTION__) {
    println(label)
    println("\(self.view.bounds.width) view width ")
    println("\(self.one.bounds.width) label width ")
    println("\(self.one.preferredMaxLayoutWidth) label preferred width ")
  }
}

