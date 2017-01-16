//
//  ListItemStore.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/28/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation

open class ListItemStore {
    static var listItems = [String]()
    static var list = ""
    
    static fileprivate var listItemObservers = [ListItemsChangedDelegate]()
    
    class func setListItems(_ items: [String], list: String) {
        listItems = items
        self.list = list
        for observer in listItemObservers {
            observer.listItemsDidChange(items, list:  list)
        }
    }
    
    class func addListItemObserver(_ observer: ListItemsChangedDelegate) {
        listItemObservers.append(observer)
    }
    
    class func removeListItemObserver(_ observer: ListItemsChangedDelegate) {
        if let object = observer as? NSObject {
            for (index, item) in listItemObservers.enumerated() {
                if let observerImplementation = item as? AnyObject, object.isEqual(observerImplementation) {
                    listItemObservers.remove(at: index)
                }
            }
        }
    }
}
