//
//  ListItemsChangedDelegate.swift
//  DictationTest
//
//  Created by Small, Jeff on 12/6/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation

protocol ListItemsChangedDelegate {
    func listItemsDidChange(items: [String], list: String)
}