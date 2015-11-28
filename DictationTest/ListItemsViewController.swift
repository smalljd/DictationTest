//
//  ListItemsViewController.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/27/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import UIKit
import CoreData

class ListItemsViewController: UIViewController {

    var list: ListModel?
    var listItems = [ListItem]()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addItemView: UIView!
    @IBOutlet weak var newItemTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = list?.title
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.delegate = self
        tableView.dataSource = self
        
        newItemTextField.delegate = self
        
        addItemView.layer.borderColor = UIColor.lightGrayColor().CGColor
        addItemView.layer.borderWidth = 1.0
        addItemView.layer.cornerRadius = 5.0
    }
    
    func configureWithList(list: ListModel) {
        self.list = list
        title = list.title
        fetchListItems()
    }
    
    private func fetchListItems() {
        guard let list = list else {
            return
        }
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "ListItem")
        let predicate = NSPredicate(format: "list.title like %@", argumentArray: [list.title!])
        fetchRequest.predicate = predicate
        
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest)
            if let items = results as? [ListItem] {
                print("List Items: \(items)")
                listItems = items
            }
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }

    @IBAction func addAnotherItemTapped(sender: AnyObject) {
        if let itemName = newItemTextField.text where itemName.characters.count > 0 {
            addItemWithName(itemName)
            newItemTextField.becomeFirstResponder()
        }
        return
    }
    
    @IBAction func doneButtonTapped(sender: AnyObject) {
        if let itemName = newItemTextField.text where itemName.characters.count > 0 {
            addItemWithName(itemName)
        }
        dismissAddItemView()
    }
    
    @IBAction func addNewItemButtonTapped(sender: AnyObject) {
        presentAddItemView()
    }
    
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        navigationController?.popViewControllerAnimated(true)
    }
    
    private func addItemWithName(name: String) {
        let context = appDelegate.managedObjectContext
        let listItemsEntity = NSEntityDescription.entityForName("ListItem", inManagedObjectContext: context)
        let newItem = ListItem(entity: listItemsEntity!, insertIntoManagedObjectContext: context) as ListItem
        newItem.title = name
        listItems.append(newItem)
        list!.setValue(NSOrderedSet(array: listItems), forKey: "listItems")
        
        do {
            try context.save()
        } catch let error as NSError {
            print("Could not save \(error), \(error.userInfo)")
        }
        
        fetchListItems()
        tableView.reloadData()
    }
    
    private func presentAddItemView() {
        if !addItemView.hidden {
            return
        }
        addItemView.alpha = 0.0
        addItemView.hidden = false
        tableView.userInteractionEnabled = false
        UIView.animateWithDuration(0.6, animations: {
            self.addItemView.alpha = 1.0
            self.tableView.alpha = 0.25
            }, completion: { finished in
                self.newItemTextField.becomeFirstResponder()
        })
    }
    
    private func dismissAddItemView() {
        tableView.userInteractionEnabled = true
        UIView.animateWithDuration(0.6, animations: {
            self.addItemView.alpha = 0.0
            self.tableView.alpha = 1.0
            }, completion: { finished in
                self.addItemView.hidden = true
                self.newItemTextField.text = ""
                self.newItemTextField.resignFirstResponder()
        })
    }
}

extension ListItemsViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if listItems.count == 0 {
            if let cell = tableView.dequeueReusableCellWithIdentifier("noListItemsCell") {
               return cell
            }
        }
        
        if let cell = tableView.dequeueReusableCellWithIdentifier("listItemCell") as? ListItemTableViewCell {
            cell.titleLabel.text = listItems[indexPath.row].title
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listItems.count == 0 {
            return 1
        }
        return listItems.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
}

extension ListItemsViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if listItems.count == 0 {
            return 175.0
        }
        return 50.0
    }
}

extension ListItemsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let itemName = textField.text where itemName.characters.count > 0 {
            addItemWithName(itemName)
            textField.text = ""
            return false
        }
        textField.resignFirstResponder()
        return true
    }
}
