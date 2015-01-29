//
//  Created by Nick Snyder on 12/10/14.
//  Copyright (c) 2014 Example. All rights reserved.
//

import UIKit
import Foundation
import CoreData


func Log(msg: String) {
  println("%@", msg)
}

struct ObjectChange {
  var object: AnyObject
  var indexPath: NSIndexPath?
  var newIndexPath: NSIndexPath?
  var changeType: NSFetchedResultsChangeType
}

struct SectionChange {
  var section: NSFetchedResultsSectionInfo
  var index: Int
  var changeType: NSFetchedResultsChangeType
}

@objc
class FetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {
  
  weak var collectionView: UICollectionView? = nil
  
  var objectChanges: [ObjectChange] = []
  var sectionChanges: [SectionChange] = []
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
    println("controllerWillChangeContent")
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    objectChanges.append(ObjectChange(object: anObject, indexPath: indexPath, newIndexPath: newIndexPath, changeType: type))
  }
  
  func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    sectionChanges.append(SectionChange(section: sectionInfo, index: sectionIndex, changeType: type))
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
    println("controllerDidChangeContent")
    if shouldReloadCollectionView() {
      collectionView?.reloadData()
    } else {
      let currentObjectChanges = self.objectChanges
      let currentSectionChanges = self.sectionChanges
      self.objectChanges = []
      self.sectionChanges = []
      collectionView?.performBatchUpdates({
        Log("performBatchUpdates start")
        for objectChange in currentObjectChanges {
          switch objectChange.changeType {
          case .Insert:
            Log("insert object at indexPath \(objectChange.newIndexPath!)")
            self.collectionView?.insertItemsAtIndexPaths([objectChange.newIndexPath!])
          case .Update:
            Log("update object at indexPath \(objectChange.indexPath!)")
            self.collectionView?.reloadItemsAtIndexPaths([objectChange.indexPath!])
          case .Delete:
            Log("delete object at indexPath \(objectChange.indexPath!)")
            self.collectionView?.deleteItemsAtIndexPaths([objectChange.indexPath!])
          case .Move:
            Log("move object from \(objectChange.indexPath!) to \(objectChange.newIndexPath!)")
            self.collectionView?.moveItemAtIndexPath(objectChange.indexPath!, toIndexPath: objectChange.newIndexPath!)
          }
        }
        
        for sectionChange in currentSectionChanges {
          switch sectionChange.changeType {
          case .Insert:
            Log("insert section \(sectionChange.index)")
            self.collectionView?.insertSections(NSIndexSet(index: sectionChange.index))
          case .Delete:
            Log("delete section \(sectionChange.index)")
            self.collectionView?.deleteSections(NSIndexSet(index: sectionChange.index))
          case .Update:
            Log("update section \(sectionChange.index)")
            self.collectionView?.reloadSections(NSIndexSet(index: sectionChange.index))
          case .Move:
            Log("did not move section \(sectionChange)")
          }
        }
        }, completion: { bool in
          Log("performBatchUpdates done \(bool)")
      })
    }
  }
  
  func shouldReloadCollectionView() -> Bool {
    if collectionView?.window == nil {
      // http://aplus.rs/2014/one-not-weird-trick-to-save-your-sanity-with-nsfetchedresultscontroller/
      return true
    }
    // TODO: handle other types of bugs
    // https://github.com/ashfurrow/UICollectionView-NSFetchedResultsController/blob/master/AFMasterViewController.m
    // https://gist.github.com/iwasrobbed/5528897
    return false
  }
}
