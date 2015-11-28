//
//  InterfaceController.swift
//  DictationTest WatchKit Extension
//
//  Created by Small, Jeff on 11/25/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import WatchKit
import Foundation


class InterfaceController: WKInterfaceController {

    var listItems = [WKPickerItem]()
    @IBOutlet var inputGroup: WKInterfaceGroup!
    @IBOutlet var textInputButton: WKInterfaceButton!
    @IBOutlet var textInputSpacerGroup: WKInterfaceGroup!
    @IBOutlet var listPicker: WKInterfacePicker!
    @IBOutlet var pickerSpacerGroup: WKInterfaceGroup!
    var removeItemIndex: Int?
    
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
        
        // Configure interface objects here.
        // Set picker items
        let item1 = WKPickerItem()
        let item2 = WKPickerItem()
        let item3 = WKPickerItem()
        let item4 = WKPickerItem()
        let item5 = WKPickerItem()
        let item6 = WKPickerItem()
        let item7 = WKPickerItem()
        let item8 = WKPickerItem()
        
        item1.title = "Milk"
        item2.title = "Dog food"
        item3.title = "Toothpaste"
        item4.title = "Ice cream"
        item5.title = "Bread"
        item6.title = "Tomatoes"
        item7.title = "Avocados"
        item8.title = "Hot sauce"
        
        listItems = [
            item1,
            item2,
            item3,
            item4,
            item5,
            item6,
            item7,
            item8,
        ]
        
        updateListItems()
        pickerItemSelected(0)
    }
    
    override func didAppear() {
        super.didAppear()
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        textInputSpacerGroup.setWidth(150)
        pickerSpacerGroup.setHeight(200)
        animateWithDuration(1.0, animations: {
            self.textInputSpacerGroup.setWidth(0)
            self.pickerSpacerGroup.setHeight(0)
        })
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    @IBAction func inputButtonTapped() {
        presentTextInputControllerWithSuggestions([], allowedInputMode: .Plain) { input in
            if let voiceInput = input {
                print(voiceInput)
                if let words = voiceInput as? [String] {
                    for word in words {
                        if word.characters.count > 0 {
                            let newPickerItem = WKPickerItem()
                            newPickerItem.title = word
                            self.listItems.append(newPickerItem)
                        }
                    }
                    self.updateListItems()
                }
            }
        }
    }
    
    @IBAction func pickerItemSelected(value: Int) {
        removeItemIndex = value
    }
    
    @IBAction func deleteItemButtonTapped() {
        if let removeItemIndex = removeItemIndex {
            print("Removing \(listItems[removeItemIndex].title!)")
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