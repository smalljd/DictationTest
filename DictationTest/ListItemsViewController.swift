//
//  ListItemsViewController.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/27/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity
import iAd

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
        
        ListStore.defaultStore.addListItemChangeObserver(self)
        ListStore.defaultStore.fetchListItems(list!)
        newItemTextField.delegate = self
        
        configureTableView()
        
        addBannerViewToTheBottomOfTheListItemsTableView()
        
        addItemView.layer.borderColor = UIColor.lightGrayColor().CGColor
        addItemView.layer.borderWidth = 1.0
        addItemView.layer.cornerRadius = 5.0
    }

    override func viewWillAppear(animated: Bool) {
        if let _ = list {
            sendListItemsToWatch(listItems)
        }
    }
    
    private func configureTableView() {
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 25.0
    }
    
    private func addBannerViewToTheBottomOfTheListItemsTableView() {
        let adBanner = appDelegate.sharedBannerView
        adBanner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adBanner)
        
        let bottomConstraint = NSLayoutConstraint(item: adBanner, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: adBanner, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: adBanner, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([bottomConstraint, leadingConstraint, trailingConstraint])
    }
    
    func configureWithList(list: ListModel) {
        self.list = list
        title = list.title
    }
    
    func sendListItemsToWatch(items: [ListItem]) {
        do {
            if WCSession.isSupported() {
                try WCSession.defaultSession().updateApplicationContext(["listName": list?.title! ?? "", "listItems": items.map({"\($0.title!)"})])
            }
        } catch let error as NSError {
            print("Unable to update context: \(error.userInfo)")
        }
    }

    @IBAction func addAnotherItemTapped(sender: AnyObject) {
        if let itemName = newItemTextField.text where itemName.characters.count > 0 {
            addItemWithName(itemName)
            newItemTextField.becomeFirstResponder()
            newItemTextField.text = ""
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
        guard let list = list else {
            return
        }
        ListStore.defaultStore.addListItem(name, list: list)
        tableView.reloadData() // Re-sizes the cell based on the content size
        sendListItemsToWatch(listItems)
    }
    
    func presentAddItemView() {
        if !addItemView.hidden {
            return
        }
        addItemView.alpha = 0.0
        addItemView.hidden = false
        tableView.userInteractionEnabled = false
        UIView.animateWithDuration(0.6, animations: {
            self.addItemView.alpha = 1.0
            self.tableView.alpha = 0.25
            self.view.bringSubviewToFront(self.addItemView) 
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
                self.view.sendSubviewToBack(self.addItemView)
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
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
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
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        return nil
        // TODO: Implement this
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath?) {
        // TODO: Implement this
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return .Delete
        // TODO: Make this smart so it can be edited too
    }
    
    // Enable re-ordering
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        return proposedDestinationIndexPath
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        guard let list = list else {
            return
        }
        
        if editingStyle == .Delete {
            ListStore.defaultStore.removeListItem(listItems[indexPath.row].title ?? "", list: list)
        }
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
        dismissAddItemView()
        return true
    }
}

extension ListItemsViewController: ListItemChangeDelegate {
    func listItemsDidChange(list: ListModel, items: [ListItem]) {
        guard let currentList = self.list else {
            return
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            if let listTitle = list.title, currentTitle = currentList.title where listTitle.compare(currentTitle) == .OrderedSame {
                self.listItems = items
                self.sendListItemsToWatch(items)
                self.tableView.reloadData()
            }
        })
    }
}

extension ListItemsViewController {
    override func previewActionItems() -> [UIPreviewActionItem] {
        
        if listItems.count > 0 {
            let clearListAction = UIPreviewAction(title: "Clear List", style: .Destructive, handler: { (action, viewController) in
                if let listItemsVC = viewController as? ListItemsViewController, list = listItemsVC.list {
                    ListStore.defaultStore.removeAllListItems(list)
                }
            })
            
            return [clearListAction]
        }
        return []
    }
}
