//
//  ListItem+CoreDataProperties.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/27/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension ListItem {

    @NSManaged var title: String?
    @NSManaged var list: ListModel?
    @NSManaged var creationDate: Date?

}
