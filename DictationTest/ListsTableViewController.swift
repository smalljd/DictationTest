//
//  ListsTableViewController.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/26/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import UIKit
import CoreData

class ListsTableViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var newListView: UIView!
    @IBOutlet weak var newListTextField: UITextField!
    
    var frc: NSFetchedResultsController?
    
    var lists: [ListModel]?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: true)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newListTextField.delegate = self
        
        ListStore.defaultStore.addListObserver(self)
        ListStore.defaultStore.fetchLists()
        
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lists = lists where lists.count > 0 else {
            return 1
        }
        
        return lists.count
    }
}

// MARK: Table View Delegate
extension ListsTableViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        guard let lists = lists where lists.count > 0 else {
            return 108
        }
        
        return 50
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard let lists = lists else {
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
    
    @IBAction func createNewListButtonTapped(sender: AnyObject) {
        guard let listName = newListTextField.text where listName.characters.count > 0 else {
            let alertController = UIAlertController(title: "Whoops!", message: "Enter a valid name for your list and try again.", preferredStyle: .Alert)
            let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alertController.addAction(okAction)
            presentViewController(alertController, animated: true, completion: nil)
            return
        }
        
        saveNewList(listName)
    }
    
    @IBAction func cancelButtonTapped(sender: AnyObject) {
        dismissNewListView()
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

extension ListsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let listName = textField.text where listName.characters.count > 0 {
            saveNewList(listName)
        }
        dismissNewListView()
        return true
    }
}

extension ListsTableViewController: ListChangeDelegate {
    func listsDidChange(lists: [ListModel]) {
        self.lists = lists
        tableView.reloadData()
    }
}
