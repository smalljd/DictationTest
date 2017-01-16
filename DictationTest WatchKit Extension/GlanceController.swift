//
//  GlanceController.swift
//  DictationTest WatchKit Extension
//
//  Created by Small, Jeff on 11/25/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import WatchKit
import Foundation


class GlanceController: WKInterfaceController {

    @IBOutlet var listTitleLabel: WKInterfaceLabel!
    @IBOutlet var numberOfListItemsLabel: WKInterfaceLabel!
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        ListItemStore.addListItemObserver(self)
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        numberOfListItemsLabel.setText("\(ListItemStore.listItems.count)")
        listTitleLabel.setText(ListItemStore.list)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}

extension GlanceController: ListItemsChangedDelegate {
    func listItemsDidChange(_ items: [String], list: String) {
        numberOfListItemsLabel.setText("\(items.count)")
        listTitleLabel.setText(list)
    }
}
