//
//  Created by Nick Snyder on 11/11/14.
//  Copyright (c) 2014 Example. All rights reserved.
//

import Foundation
import CoreData

class Person: NSManagedObject {
  @NSManaged var name: NSString!
  @NSManaged var personId: NSString!
  @NSManaged var section: NSNumber!
}
