//
//  Label.swift
//  AutoLayoutBug
//
//  Created by Nick Snyder on 7/24/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

import UIKit

class Label : UILabel {
  override func layoutSubviews() {
    super.layoutSubviews()
    // Reset the preferredMaxLayoutWidth any time the bounds change (e.g. orientation change)
    // so the label will fill the available horizontal space.
    // This works fine in iOS 7.0.3 and 7.1 simulators
    // This does NOT work in iOS 8 Beta 4 simulator because layoutSubviews never gets called.
    self.preferredMaxLayoutWidth = self.bounds.size.width
  }
}
