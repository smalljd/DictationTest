//
//  ListChangeDelegate.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/30/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation

protocol ListChangeDelegate {
    func listsDidChange(lists: [ListModel])
}