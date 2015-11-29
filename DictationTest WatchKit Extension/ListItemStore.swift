//
//  ListItemStore.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/28/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation

public class ListItemStore {
    static var listItems = [ListItem]()
    
    class func setListItems(items: [ListItem]) {
        listItems = items
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: "ListItemsUpdated", object: nil))
    }
}