//
//  Created by Nick Snyder on 11/10/14.
//  Copyright (c) 2014 Example. All rights reserved.
//

import UIKit
import CoreData

class RootViewController: UICollectionViewController {

  let frcDelegate = FetchedResultsControllerDelegate()
  var fetchedResultsController: NSFetchedResultsController!
  
  override init() {
    super.init(collectionViewLayout: UICollectionViewFlowLayout())
  }

  required init(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    collectionView?.backgroundColor = UIColor.blueColor()
    
    collectionView?.registerNib(UINib(nibName: "Cell", bundle: nil), forCellWithReuseIdentifier: "Cell")
    
    frcDelegate.collectionView = collectionView
    
    let fr = NSFetchRequest(entityName: "Person")
    fr.sortDescriptors = [NSSortDescriptor(key: "personId", ascending: true)]
    fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: CoreDataController.sharedInstance.mainContext, sectionNameKeyPath: "section", cacheName: nil)
    fetchedResultsController.delegate = self
    var error: NSError? = nil
    fetchedResultsController.performFetch(&error)
    if let error = error {
      println("error \(error)")
    }
  }

  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    stepOne()
  }
  
  override func viewDidAppear(animated: Bool) {
    super.viewDidAppear(animated)
    
  }
  
  override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
    return fetchedResultsController.sections?.count ?? 1
  }
  
  override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return (fetchedResultsController.sections?[section] as? NSFetchedResultsSectionInfo)?.numberOfObjects ?? 0
  }
  
  override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
    let person = fetchedResultsController.objectAtIndexPath(indexPath) as Person
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Cell", forIndexPath: indexPath) as Cell
    cell.label.text = person.name
    return cell
  }
  
  private func stepOne() {
    insertOrUpdate(createJsonPeopleWithSectionId(0, count: 10))
  }
  
  private func createJsonPeopleWithSectionId(sectionId: Int, count: Int) -> [JsonPerson] {
    var section: [JsonPerson] = []
    for var i = 0; i < count; i++ {
      section.append(JsonPerson(personId: "\(sectionId):\(i)", section: sectionId))
    }
    return section
  }

  struct JsonPerson {
    var personId: String
    var section: Int
    var name: String {
      return "Person \(personId)"
    }
  }
  
  private func fetchPeople(context: NSManagedObjectContext, ids: [String]) -> [String: Person] {
    var toUpdate = [String: Person]()
    if ids.count > 0 {
      for person in context.fetch(entityName: "Person", key: "personId", values: ids) ?? [] {
        if let person = person as? Person {
          toUpdate[person.personId] = person
        }
      }
    }
    return toUpdate
  }
  
  
  private func insertOrUpdate(people: [JsonPerson], truncate: Bool = false) {
    println("start insertOrUpdate")
    CoreDataController.sharedInstance.performOnBackgroundContext({ context in
      context.deleteAll(entityName: "Person")
      let ids = people.map({ $0.personId })
      let toUpdate = self.fetchPeople(context, ids: ids)
      for person in people {
        var entity: Person? = toUpdate[person.personId]
        if entity == nil {
          println("creating \(person.name)")
          entity = NSEntityDescription.insertNewObjectForEntityForName("Person", inManagedObjectContext: context) as? Person
        } else {
          println("updating \(person.name)")
        }
        if let entity = entity {
          entity.personId = person.personId
          entity.name = person.name
        }
      }
    }, completion: {
      println("completion")
    })
  }
  
}

extension RootViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
    return collectionView.bounds.size
  }
}

extension RootViewController: NSFetchedResultsControllerDelegate {
  /*
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    println("didChangeObject")
  }
  

  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    println("didChangeSection")
  }*/
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    println("controllerDidChangeContent")

    switch CoreDataController.sharedInstance.setup {
    case .Working:
      collectionView?.reloadData()
    case .ClearlyWrong:
      dispatch_async(dispatch_get_main_queue(), {
        println("reloading data on main thread")
        self.collectionView?.reloadData()
        return
      })
    case .Broken:
      collectionView?.reloadData()
    }
    
  }
}