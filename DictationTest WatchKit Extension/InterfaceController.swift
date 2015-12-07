//
//  InterfaceController.swift
//  DictationTest WatchKit Extension
//
//  Created by Small, Jeff on 11/25/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation


class InterfaceController: WKInterfaceController, WCSessionDelegate {

    var listItems = [WKPickerItem]()
    @IBOutlet var inputGroup: WKInterfaceGroup!
    @IBOutlet var textInputButton: WKInterfaceButton!
    @IBOutlet var textInputSpacerGroup: WKInterfaceGroup!
    @IBOutlet var listPicker: WKInterfacePicker!
    @IBOutlet var pickerSpacerGroup: WKInterfaceGroup!
    
    var list: String?
    var removeItemIndex: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)

        // Fetch objects from Core Data
        let session = WCSession.defaultSession()
        session.delegate = self
        session.activateSession()
        
        hideDisplays()
        updateListItems()
        ListItemStore.addListItemObserver(self)
        pickerItemSelected(0)
    }
    
    func session(session: WCSession, didReceiveApplicationContext applicationContext: [String : AnyObject]) {
        if let items = applicationContext["listItems"] as? [String] {
            listItems = []
            for itemName in items {
                let newItem = WKPickerItem()
                newItem.title = itemName
                listItems.append(newItem)
            }
            ListItemStore.setListItems(items, list: applicationContext["listName"] as! String)
            updateListItems()
        }
        
        if let listName = applicationContext["listName"] as? String {
            self.list = listName
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        hideDisplays()
        animateWithDuration(1.0, animations: {
            self.showDisplays()
        })
    }
    
    override func willDisappear() {
        hideDisplays()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        hideDisplays()
    }
    
    func showDisplays() {
        self.textInputSpacerGroup.setWidth(0)
        self.pickerSpacerGroup.setHeight(0)
    }
    
    func hideDisplays() {
        textInputSpacerGroup.setWidth(150)
        pickerSpacerGroup.setHeight(200)
    }

    @IBAction func inputButtonTapped() {
        let suggestions = ["Milk", "Eggs", "Bread", "Cereal", "Peanut Butter",]
        presentTextInputControllerWithSuggestions(suggestions   , allowedInputMode: .AllowEmoji) { input in
            if let voiceInput = input {
                if let words = voiceInput as? [String] {
                    for word in words {
                        if word.characters.count > 0 {
                            let newPickerItem = WKPickerItem()
                            newPickerItem.title = word
                            self.listItems.append(newPickerItem)
                            if let list = self.list {
                                self.addItemToList(word, listName: list)
                            }
                        }
                    }
                    self.updateListItems()
                }
            }
        }
    }
    
    func addItemToList(itemName: String, listName: String) {
        let userInfo = ["action": "insert",
            "listItem": itemName,
            "list": listName,
        ]
        WCSession.defaultSession().transferUserInfo(userInfo)
    }
    @IBAction func pickerItemSelected(value: Int) {
        removeItemIndex = value
    }
    
    @IBAction func deleteItemButtonTapped() {
        if let removeItemIndex = removeItemIndex {
            let itemToRemove = listItems[removeItemIndex].title!
            if let listName = list {
                print("Attempting to remove \(itemToRemove) from the \(listName) list")
                let userInfo = ["action": "delete",
                    "listItem": itemToRemove,
                    "list": listName,
                ]
                WCSession.defaultSession().transferUserInfo(userInfo)
            }
            listItems.removeAtIndex(removeItemIndex)
            updateListItems()
        }
    }
    
    func updateListItems() {
        listItems = listItems.sort(){
            if $0.title?.compare($1.title!) == .OrderedAscending {
                return true
            }
            return false
        }
        listPicker.setItems(listItems)
    }
}

extension InterfaceController: ListItemsChangedDelegate {
    func listItemsDidChange(items: [String], list: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.listItems = []
            for item in items {
                let pickerItem = WKPickerItem()
                pickerItem.title = item
                self.listItems.append(pickerItem)
            }
            self.list = list
            self.updateListItems()
        })
    }
}