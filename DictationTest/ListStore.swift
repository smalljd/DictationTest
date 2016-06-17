//
//  ListStore.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/30/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation
import UIKit
import CoreData

public class ListStore {
    
    static let defaultStore = ListStore()
    var lists = [ListModel]()
    var listChangeObservers = [ListChangeDelegate]()
    var listItemChangeObservers = [ListItemChangeDelegate]()
    var fetchedResultsController: NSFetchedResultsController
    
    // Core Data Initialization
    private let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    private let managedContext: NSManagedObjectContext
    private let listEntityName = "ListModel"
    private let listItemEntityName = "ListItem"
    private var fetchRequest: NSFetchRequest
    private let listSortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    private let listItemSortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    
    private init() {
        managedContext = appDelegate.managedObjectContext
        fetchRequest = NSFetchRequest(entityName: listEntityName)
        fetchRequest.sortDescriptors = listSortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: managedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    
    func insertNewList(title: String) {
        let listEntity = NSEntityDescription.entityForName(listEntityName, inManagedObjectContext: managedContext)
        
        let newList = ListModel(entity: listEntity!, insertIntoManagedObjectContext: managedContext) as ListModel
        
        newList.title = title
        lists.append(newList)
        lists = lists.sort({
            if $0.title!.compare($1.title!) == .OrderedAscending {
                return true
            }
            return false
        })
        updateObserversOfListChange(lists)
        save()
    }
    
    func removeList(title: String) {
        for (index, list) in lists.enumerate() {
            if list.title!.compare(title) == .OrderedSame {
                managedContext.deleteObject(list)
                lists.removeAtIndex(index)
                // TODO: Remove all related elements in ListItems model
                save()
            }
        }
        updateObserversOfListChange(lists)
    }
    
    func removeAllLists() {
        for list in lists {
            managedContext.deleteObject(list)
            lists = []
            save()
        }
    }
    
    func fetchLists() {
        do {
            try fetchedResultsController.performFetch()
            if let fetchedLists = fetchedResultsController.fetchedObjects as? [ListModel] {
                lists = fetchedLists
                updateObserversOfListChange(lists)
            }
        } catch let error as NSError {
            print("Failed to fetch lists from core data: \(error)\n\(error.userInfo)")
        }
    }
    
    func save() {
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
    }
    
    func addListObserver(delegate: ListChangeDelegate) {
        listChangeObservers.append(delegate)
    }
    
    func wipeObservers() {
        listChangeObservers = [ListChangeDelegate]()
    }
    
    func updateObserversOfListChange(lists: [ListModel]) {
        for observer in listChangeObservers {
            observer.listsDidChange(lists)
        }
    }
    // TODO: Figure out how to remove an observer
    
    func listWithName(name: String) -> ListModel? {
        for list in lists {
            if list.title!.compare(name) == .OrderedSame {
                return list
            }
        }
        return nil
    }
}

// MARK: List Items
extension ListStore {
    
    func fetchListItems(list: ListModel) {
        let listItemsFetchRequest = NSFetchRequest(entityName: "ListItem")
        let predicate = NSPredicate(format: "list.title like %@", argumentArray: [list.title!])
        listItemsFetchRequest.predicate = predicate
        listItemsFetchRequest.sortDescriptors = listItemSortDescriptors
        
        let controller = NSFetchedResultsController(fetchRequest: listItemsFetchRequest,
            managedObjectContext: managedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        do {
            try controller.performFetch()
            if let listItems = controller.fetchedObjects as? [ListItem] {
                updateListItemObserversWithChange(list, listItems: listItems)
            }
        } catch let error as NSError {
            print("Failed to fetch items for \(list.title!)")
            print("\(error)\n\(error.userInfo)")
        }
    }
    
    func addListItem(name: String, list: ListModel) {
        let context = appDelegate.managedObjectContext
        let listItemsEntity = NSEntityDescription.entityForName("ListItem", inManagedObjectContext: context)
        let newItem = ListItem(entity: listItemsEntity!, insertIntoManagedObjectContext: context) as ListItem
        newItem.title = name
        newItem.creationDate = NSDate()
        
        if let itemSet = list.listItems, var listItems = Array(itemSet) as? [ListItem] {
            listItems.append(newItem)
            list.listItems = NSOrderedSet(array: listItems)
            updateListItemObserversWithChange(list, listItems: listItems)
        } else {
            list.listItems = NSOrderedSet(array: [newItem])
            updateListItemObserversWithChange(list, listItems: [newItem])
        }
        
        save()
    }
    
    func removeListItem(itemName: String, list: ListModel) {
        if let itemSet = list.listItems, var listItems = Array(itemSet) as? [ListItem] {
            print("List Items: \(listItems)")
            for (index, element) in listItems.enumerate() {
                if element.title!.compare(itemName) == .OrderedSame {
                    listItems.removeAtIndex(index)
                    list.listItems = NSOrderedSet(array: listItems)
                    updateListItemObserversWithChange(list, listItems: listItems)
                    save()
                }
            }
        }
    }
    
    func removeAllListItems(list: ListModel) {
        list.listItems = nil
        updateListItemObserversWithChange(list, listItems: [])
        save()
    }
    
    func addListItemChangeObserver(observer: ListItemChangeDelegate) {
        listItemChangeObservers.append(observer)
    }
    
    func removeListItemObserver(observer: ListItemChangeDelegate) {
        if let object = observer as? NSObject {
            for (index, item) in listItemChangeObservers.enumerate() {
                if let observerImplementation = item as? AnyObject where object.isEqual(observerImplementation) {
                    listItemChangeObservers.removeAtIndex(index)
                }
            }
        }
    }
    
    func removeAllListItemObservers() {
        listItemChangeObservers = []
    }
    
    func updateListItemObserversWithChange(list: ListModel, listItems: [ListItem]) {
        for observer in listItemChangeObservers {
            observer.listItemsDidChange(list, items: listItems)
        }
    }
}