//
//  ListsTableViewController.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/26/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import UIKit
import CoreData
import iAd

class ListsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newListView: UIView!
    @IBOutlet weak var newListTextField: UITextField!
    
    var adBannerView: ADBannerView?
    
    var frc: NSFetchedResultsController?
    
    var lists: [ListModel]?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
        
        addBannerViewToBottomOfListsTableView()
    }
    
    override func viewWillDisappear(animated: Bool) {
        removeAdBannerView()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newListTextField.delegate = self
        
        ListStore.defaultStore.addListObserver(self)
        ListStore.defaultStore.fetchLists()
        
        registerForPreviewingWithDelegate(self, sourceView: tableView)
        
        addBannerViewToBottomOfListsTableView()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRectZero)
        tableView.registerNib(UINib(nibName: "NoListsTableViewCell", bundle: nil),forCellReuseIdentifier: "noListsCellReuseId")
        
        newListView.layer.borderColor = UIColor.lightGrayColor().CGColor
        newListView.layer.cornerRadius = 5.0
        newListView.layer.borderWidth = 1.0
    }
}

// MARK: Table View Data Source
extension ListsTableViewController: UITableViewDataSource {
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        guard let lists = lists where lists.count > 0 else {
            if let noListsCell = tableView.dequeueReusableCellWithIdentifier("noListsCellReuseId") {
                return noListsCell
            }
            return UITableViewCell()
        }
    
        if let cell = tableView.dequeueReusableCellWithIdentifier("listCellReuseId") as? ListTableViewCell {
            let row = indexPath.row
            cell.titleLabel.text = lists[row].title
            return cell
        }
        return UITableViewCell()
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lists = lists where lists.count > 0 else {
            return 1
        }
        
        return lists.count
    }
}

// MARK: Table View Delegate
extension ListsTableViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, targetIndexPathForMoveFromRowAtIndexPath sourceIndexPath: NSIndexPath, toProposedIndexPath proposedDestinationIndexPath: NSIndexPath) -> NSIndexPath {
        return proposedDestinationIndexPath
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            guard let list = lists?[indexPath.row] else {
                return
            }
            let alertController = UIAlertController(title: "Are you sure?", message: "Delete \(list.title!) and all of it's contents?", preferredStyle: .Alert)
            let confirmAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.Destructive, handler: { action in
                if let listToDelete = ListStore.defaultStore.listWithName(list.title!) {
                    // Remove from Core Data
                    ListStore.defaultStore.removeAllListItems(listToDelete)
                    ListStore.defaultStore.removeList(listToDelete.title!)
                    // Update UI
//                    if var lists = self.lists {
//                        lists.removeAtIndex(indexPath.row)
//                        self.tableView.reloadData()
//                    }
                }
            })
            let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.Cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            
            presentViewController(alertController, animated: true, completion: nil)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let lists = lists where lists.count > 0 else {
            return 108
        }
        
        return 50
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let lists = lists where lists.count > indexPath.row else {
            tableView.deselectRowAtIndexPath(indexPath, animated: false)
            return
        }
        
        let list = lists[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let listItemsViewController = storyboard.instantiateViewControllerWithIdentifier("listItemsViewController") as? ListItemsViewController {
            listItemsViewController.configureWithList(list)
            navigationController?.pushViewController(listItemsViewController, animated: true)
        }
    }
}

// MARK: IBActions
extension ListsTableViewController {
    @IBAction func addNewListButtonTapped(sender: AnyObject) {
        if !newListView.hidden {
            return
        }
        presentNewListView()
    }
    
    @IBAction func createNewListButtonTapped(sender: AnyObject) {
        guard let listName = newListTextField.text where listName.characters.count > 0 else {
            return
        }
        
        saveNewList(listName)
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        dismissNewListView()
    }
    
    func presentNewListView() {
        tableView.userInteractionEnabled = false
        newListView.alpha = 0.0
        newListView.hidden = false
        UIView.animateWithDuration(0.6, animations: {
            self.newListView.alpha = 1.0
            self.tableView.alpha = 0.2
            }, completion: { finished in
                self.newListTextField.becomeFirstResponder()
        })
    }
    
    private func dismissNewListView() {
        tableView.userInteractionEnabled = true
        UIView.animateWithDuration(0.4, animations: {
            self.newListView.alpha = 0.0
            self.tableView.alpha = 1.0
            }, completion: { finished in
                self.newListView.hidden = true
                self.newListTextField.text = ""
                self.newListTextField.resignFirstResponder()
        })
    }
    
    func saveNewList(name: String) {
        ListStore.defaultStore.insertNewList(name)
        dismissNewListView()
    }
    
    func deleteList(title: String) {
        ListStore.defaultStore.removeList(title)
    }
}

// MARK: UITextFieldDelegate
extension ListsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let listName = textField.text where listName.characters.count > 0 {
            saveNewList(listName)
        }
        dismissNewListView()
        return true
    }
}

// MARK: ListChangeDelegate
extension ListsTableViewController: ListChangeDelegate {
    func listsDidChange(lists: [ListModel]) {
        self.lists = lists
        tableView.reloadData()
    }
}

// MARK: Segue / Peek Pop Handling
extension ListsTableViewController: UIViewControllerPreviewingDelegate {
    func viewControllerForIndexPath(indexPath: NSIndexPath) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let listItemsVC = storyboard.instantiateViewControllerWithIdentifier("listItemsViewController") as? ListItemsViewController, list = lists?[indexPath.row] {
            listItemsVC.configureWithList(list)
            return listItemsVC
        }
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRowAtPoint(location) {
            previewingContext.sourceRect = tableView.rectForRowAtIndexPath(indexPath)
            return viewControllerForIndexPath(indexPath)
        }
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}

// MARK: Advertisements
extension ListsTableViewController {
    func addBannerViewToBottomOfListsTableView() {
        guard let appDelegate = UIApplication.sharedApplication().delegate as? AppDelegate, sharedAdBanner = appDelegate.sharedBannerView else {
            return
        }
        
        adBannerView = sharedAdBanner
        adBannerView!.delegate = sharedAdBanner.delegate
        
        adBannerView!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adBannerView!)
        
        let bottomConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 50)
        
        view.addConstraints([bottomConstraint,
            leadingConstraint,
            trailingConstraint,
            heightConstraint,
        ])
    }
    
    func removeAdBannerView() {
        guard let adBannerView = adBannerView else {
            return
        }
        
        adBannerView.removeFromSuperview()
    }
}
