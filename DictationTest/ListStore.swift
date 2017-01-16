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

open class ListStore {
    
    static let defaultStore = ListStore()
    var lists = [ListModel]()
    var listChangeObservers = [ListChangeDelegate]()
    var listItemChangeObservers = [ListItemChangeDelegate]()
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>
    
    // Core Data Initialization
    fileprivate let appDelegate = UIApplication.shared.delegate as! AppDelegate
    fileprivate let managedContext: NSManagedObjectContext
    fileprivate let listEntityName = "ListModel"
    fileprivate let listItemEntityName = "ListItem"
    fileprivate var fetchRequest: NSFetchRequest<NSFetchRequestResult>
    fileprivate let listSortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
    fileprivate let listItemSortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    
    fileprivate init() {
        managedContext = appDelegate.managedObjectContext
        fetchRequest = NSFetchRequest(entityName: listEntityName)
        fetchRequest.sortDescriptors = listSortDescriptors
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: managedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
    }
    
    
    func insertNewList(_ title: String) {
        let listEntity = NSEntityDescription.entity(forEntityName: listEntityName, in: managedContext)
        
        let newList = ListModel(entity: listEntity!, insertInto: managedContext) as ListModel
        
        newList.title = title
        lists.append(newList)
        lists = lists.sorted(by: {
            if $0.title!.compare($1.title!) == .orderedAscending {
                return true
            }
            return false
        })
        updateObserversOfListChange(lists)
        save()
    }
    
    func removeList(_ title: String) {
        for (index, list) in lists.enumerated() {
            if list.title!.compare(title) == .orderedSame {
                managedContext.delete(list)
                lists.remove(at: index)
                // TODO: Remove all related elements in ListItems model
                save()
            }
        }
        updateObserversOfListChange(lists)
    }
    
    func removeAllLists() {
        for list in lists {
            managedContext.delete(list)
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
    
    func addListObserver(_ delegate: ListChangeDelegate) {
        listChangeObservers.append(delegate)
    }
    
    func wipeObservers() {
        listChangeObservers = [ListChangeDelegate]()
    }
    
    func updateObserversOfListChange(_ lists: [ListModel]) {
        for observer in listChangeObservers {
            observer.listsDidChange(lists)
        }
    }
    // TODO: Figure out how to remove an observer
    
    func listWithName(_ name: String) -> ListModel? {
        for list in lists {
            if list.title!.compare(name) == .orderedSame {
                return list
            }
        }
        return nil
    }
}

// MARK: List Items
extension ListStore {
    
    func fetchListItems(_ list: ListModel) {
        let listItemsFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ListItem")
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
    
    func addListItem(_ name: String, list: ListModel) {
        let context = appDelegate.managedObjectContext
        let listItemsEntity = NSEntityDescription.entity(forEntityName: "ListItem", in: context)
        let newItem = ListItem(entity: listItemsEntity!, insertInto: context) as ListItem
        newItem.title = name
        newItem.creationDate = Date()
        
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
    
    func removeListItem(_ itemName: String, list: ListModel) {
        if let itemSet = list.listItems, var listItems = Array(itemSet) as? [ListItem] {
            print("List Items: \(listItems)")
            for (index, element) in listItems.enumerated() {
                if element.title!.compare(itemName) == .orderedSame {
                    listItems.remove(at: index)
                    list.listItems = NSOrderedSet(array: listItems)
                    updateListItemObserversWithChange(list, listItems: listItems)
                    save()
                }
            }
        }
    }
    
    func removeAllListItems(_ list: ListModel) {
        list.listItems = nil
        updateListItemObserversWithChange(list, listItems: [])
        save()
    }
    
    func addListItemChangeObserver(_ observer: ListItemChangeDelegate) {
        listItemChangeObservers.append(observer)
    }
    
    func removeListItemObserver(_ observer: ListItemChangeDelegate) {
        if let object = observer as? NSObject {
            for (index, item) in listItemChangeObservers.enumerated() {
                if object.isEqual(item) {
                    listItemChangeObservers.remove(at: index)
                }
            }
        }
    }
    
    func removeAllListItemObservers() {
        listItemChangeObservers = []
    }
    
    func updateListItemObserversWithChange(_ list: ListModel, listItems: [ListItem]) {
        for observer in listItemChangeObservers {
            observer.listItemsDidChange(list, items: listItems)
        }
    }
}
