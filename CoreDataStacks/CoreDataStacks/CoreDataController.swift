//
//  Created by Nick Snyder on 9/9/14.
//  Copyright (c) 2014 Example. All rights reserved.
//

import CoreData
import Foundation

/// CoreDataController manages the NSManagedObjectContexts for the app.
/// Note that all NSManagedObjectContexts are created on the main thread, so they must be accessed on the main thread.
class CoreDataController {
  class var sharedInstance: CoreDataController { return _sharedCoreDataController }
  
  private let backgroundContext: NSManagedObjectContext
  let mainContext: NSManagedObjectContext
  private let persistentStoreCoordinator: NSPersistentStoreCoordinator
  
  enum Setup {
    // This is the recommended setup #3 described here: http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout
    // Each context listens to each other and merges changes, but both are children of the persistent store coordinator.
    // This setup can crash if the background context does a delete that is persisted to disk and the main context attempts to unfault that object before the changes are merged.
    // This project demonstrates this crash fairly reliably on startup (I use iPhone 5s 8.1 simulator)
    case Broken
    
    // This is the naive setup #1 described here: http://floriankugler.com/blog/2013/4/29/concurrent-core-data-stack-performance-shootout
    // It works to delete items in the background context because they never make it to the persistent
    // store before being merged into the main context.
    // This setup works reliably in this project.
    //
    // Perhaps it is still possible to cause this setup to crash if the background context attempts
    // to unfault an object that has been deleted from the main context (but the change has not been merged yet). I haven't experimented with this case, so I don't know if it is possible.
    case Working
    
    // This setup attemps to call mergeChangesFromContextDidSaveNotification on a background thread.
    // It crashes.
    case ClearlyWrong
  }
  
  let setup = Setup.Broken
  
  init() {
    persistentStoreCoordinator = CoreDataController.configuredPersistentStoreCoordinator()
    
    backgroundContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
    backgroundContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
    
    mainContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
    mainContext.persistentStoreCoordinator = persistentStoreCoordinator
    mainContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    

    switch setup {
    case .Broken:
      backgroundContext.persistentStoreCoordinator = persistentStoreCoordinator
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesIntoMain:", name: NSManagedObjectContextDidSaveNotification, object: backgroundContext)
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesIntoBackground:", name: NSManagedObjectContextDidSaveNotification, object: mainContext)
    case .Working:
      backgroundContext.parentContext = mainContext
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "saveMainContext", name: NSManagedObjectContextDidSaveNotification, object: mainContext)
    case .ClearlyWrong:
      backgroundContext.persistentStoreCoordinator = persistentStoreCoordinator
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesIntoMainImmediately:", name: NSManagedObjectContextDidSaveNotification, object: backgroundContext)
      NSNotificationCenter.defaultCenter().addObserver(self, selector: "mergeChangesIntoBackground:", name: NSManagedObjectContextDidSaveNotification, object: mainContext)
    }
  }
  
  @objc
  private func mergeChangesIntoBackground(notification: NSNotification) {
    println("mainContextDidSave begin")
    backgroundContext.mergeChangesFromContextDidSaveNotification(notification)
    println("mainContextDidSave end")
  }
  
  @objc
  private func mergeChangesIntoMain(notification: NSNotification) {
    println("mergeChangesIntoMain begin")
    mainContext.performBlockAndWait {
      println("mergeChangesIntoMain async begin")
      self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
      println("mergeChangesIntoMain async end")
    }
    println("mergeChangesIntoMain end")
  }
  
  @objc
  private func mergeChangesIntoMainImmediately(notification: NSNotification) {
    println("mergeChangesIntoMainImmediately begin")
    mainContext.mergeChangesFromContextDidSaveNotification(notification)
    println("mergeChangesIntoMainImmediately end")
  }
  
  /// performs block on the background context.
  /// The context is saved after block completes.
  /// The completion block is called on the main thread after all changes have been saved and merged.
  func performOnBackgroundContext(block: NSManagedObjectContext -> Void, completion: (Void -> Void)? = nil) {
    performInContext(backgroundContext, block: block, completion: completion)
  }
  
  /// saves changes that have been made on the main context (i.e. due to user interactions).
  func saveMainContext() {
    saveContext(mainContext)
  }
  
  private func saveContext(context: NSManagedObjectContext) {
    if context.hasChanges {
      var error: NSError?
      context.save(&error)
      if let error = error {
        println("unable to save context \(error)")
      }
    } else {
      println("no changes in context to save")
    }
  }
  
  private func performInContext(context: NSManagedObjectContext, block: NSManagedObjectContext -> Void, completion: (Void -> Void)? = nil) {
    context.performBlock {
      block(context)
      self.saveContext(context)
      // When we reach this point, the current context has been saved AND the changes have been merged into observing contexts.
      if let completion = completion {
        dispatch_async(dispatch_get_main_queue(), completion)
      }
    }
  }
  
  func entityDescription(entityName: String) -> NSEntityDescription? {
    return NSEntityDescription.entityForName(entityName, inManagedObjectContext: backgroundContext)
  }
  
  /// returns a NSManagedObject that is not associated with a NSManagedObjectContext.
  func unassociatedEntity(entityName: String) -> NSManagedObject? {
    if let entity = entityDescription(entityName) {
      return NSManagedObject(entity: entity, insertIntoManagedObjectContext: nil)
    }
    return nil
  }
  
  func fetchedResultsController(fetchRequest: NSFetchRequest, sectionNameKeyPath: String? = nil, cacheName: String? = nil) -> NSFetchedResultsController {
    return NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: mainContext,
      sectionNameKeyPath: sectionNameKeyPath,
      cacheName: cacheName
    )
  }
  
  func fetch(request: NSFetchRequest) -> [AnyObject] {
    var error: NSError?
    let results = mainContext.executeFetchRequest(request, error: &error)
    if let error = error {
      println("Error performing fetch request \(error)")
    }
    return results ?? [AnyObject]()
  }
  
  private class func configuredPersistentStoreCoordinator() -> NSPersistentStoreCoordinator {
    let model = NSManagedObjectModel.mergedModelFromBundles(nil)
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model!)
    var errorOption: NSError?
    let storeUrl = CoreDataController.persistentStoreUrl()
    let storeOptions = CoreDataController.persistentStoreOptions()
    psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: storeOptions, error: &errorOption)
    if let error = errorOption {
      //println("error adding persistent store \(error)")
      CoreDataController.deleteCoreData()
      errorOption = nil
      psc.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeUrl, options: storeOptions, error: &errorOption)
      if let error = errorOption {
        println("failed to recreate persistent store \(error)")
      }
    }
    return psc
  }
  
  private class func deleteCoreData() {
    let dir = CoreDataController.coreDataDir()
    let manager = NSFileManager.defaultManager()
    let files = manager.enumeratorAtURL(dir, includingPropertiesForKeys: nil, options: NSDirectoryEnumerationOptions(0), errorHandler: nil)
    let urls = (files?.allObjects ?? []) as? [NSURL]
    for url in urls ?? [] {
      var error: NSError?
      manager.removeItemAtURL(url as NSURL, error: &error)
      if let error = error {
        println("failed to delete file \(url) because \(error)")
      } else {
        println("deleted core data file \(url)")
      }
    }
  }
  
  private class func coreDataDir() -> NSURL {
    var error: NSError?
    let manager = NSFileManager.defaultManager()
    let docs = manager.URLForDirectory(.DocumentDirectory, inDomain: .UserDomainMask, appropriateForURL: nil, create: true, error: &error)
    if let error = error {
      println("failed to get documents directory \(error)")
    }
    let dir = docs!.URLByAppendingPathComponent("LeapCoreData")
    if !manager.fileExistsAtPath(dir.path!) {
      error = nil
      manager.createDirectoryAtURL(dir, withIntermediateDirectories: false, attributes: nil, error: &error)
      if let error = error {
        println("failed to create \(dir) because \(error)")
      }
    }
    return dir
  }
  
  private class func persistentStoreUrl() -> NSURL {
    return CoreDataController.coreDataDir().URLByAppendingPathComponent("Model.sqlite")
  }
  
  private class func persistentStoreOptions() -> [NSObject : AnyObject] {
    // MagicalRecord does NSSQLitePragmasOption and journal_mode = WAL
    // Unsure if we should fiddle with those options also.
    return [
      NSMigratePersistentStoresAutomaticallyOption: true,
      NSInferMappingModelAutomaticallyOption: true,
    ]
  }
}

private let _sharedCoreDataController = CoreDataController()