//
//  Created by Nick Snyder on 9/10/14.
//  Copyright (c) 2014 Example. All rights reserved.
//

import CoreData

extension NSManagedObjectContext {
  
  func deleteAll(#entityName: String, predicate: NSPredicate? = nil) {
    let entities = fetch(entityName: entityName, predicate: predicate, includesPropertyValues: false)
    for entity in entities {
      println("deleting \(entity)")
      deleteObject(entity)
    }
  }
  
  func fetch(#entityName: String, key: String, values: [AnyObject]) -> [NSManagedObject] {
    return fetch(entityName: entityName, predicate: predicate(key: key, values: values))
  }
  
  private func predicate(#key: String, values: [AnyObject]) -> NSPredicate? {
    return NSPredicate(format: "%K IN (%@)", key, values)
  }
  
  func fetch(#entityName: String, predicate: NSPredicate? = nil, includesPropertyValues: Bool = true) -> [NSManagedObject] {
    var fetchRequest = NSFetchRequest()
    fetchRequest.entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: self)
    fetchRequest.includesPropertyValues = includesPropertyValues
    fetchRequest.predicate = predicate
    var error: NSError?
    let entities = executeFetchRequest(fetchRequest, error: &error)
    if let error = error {
      println("fetch failed: \(entities)")
    }
    return entities as? [NSManagedObject] ?? []
  }
}