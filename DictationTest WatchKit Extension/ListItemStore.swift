//
//  ListItemStore.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/28/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation

public class ListItemStore {
    static var listItems = [String]()
    static var list = ""
    
    static private var listItemObservers = [ListItemsChangedDelegate]()
    
    class func setListItems(items: [String], list: String) {
        listItems = items
        self.list = list
        for observer in listItemObservers {
            observer.listItemsDidChange(items, list:  list)
        }
    }
    
    class func addListItemObserver(observer: ListItemsChangedDelegate) {
        listItemObservers.append(observer)
    }
    
    class func removeListItemObserver(observer: ListItemsChangedDelegate) {
        if let object = observer as? NSObject {
            for (index, item) in listItemObservers.enumerate() {
                if let observerImplementation = item as? AnyObject where object.isEqual(observerImplementation) {
                    listItemObservers.removeAtIndex(index)
                }
            }
        }
    }
}