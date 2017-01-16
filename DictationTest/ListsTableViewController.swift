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
    
    var frc: NSFetchedResultsController<NSFetchRequestResult>?
    
    var lists: [ListModel]?
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexPath, animated: true)
        }
        
        addBannerViewToBottomOfListsTableView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        removeAdBannerView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newListTextField.delegate = self
        
        ListStore.defaultStore.addListObserver(self)
        ListStore.defaultStore.fetchLists()
        
        registerForPreviewing(with: self, sourceView: tableView)
        
        addBannerViewToBottomOfListsTableView()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.register(UINib(nibName: "NoListsTableViewCell", bundle: nil),forCellReuseIdentifier: "noListsCellReuseId")
        
        newListView.layer.borderColor = UIColor.lightGray.cgColor
        newListView.layer.cornerRadius = 5.0
        newListView.layer.borderWidth = 1.0
    }
}

// MARK: Table View Data Source
extension ListsTableViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let lists = lists, lists.count > 0 else {
            if let noListsCell = tableView.dequeueReusableCell(withIdentifier: "noListsCellReuseId") {
                return noListsCell
            }
            return UITableViewCell()
        }
    
        if let cell = tableView.dequeueReusableCell(withIdentifier: "listCellReuseId") as? ListTableViewCell {
            let row = indexPath.row
            cell.titleLabel.text = lists[row].title
            return cell
        }
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let lists = lists, lists.count > 0 else {
            return 1
        }
        
        return lists.count
    }
}

// MARK: Table View Delegate
extension ListsTableViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            guard let list = lists?[indexPath.row] else {
                return
            }
            let alertController = UIAlertController(title: "Are you sure?", message: "Delete \(list.title!) and all of it's contents?", preferredStyle: .alert)
            let confirmAction = UIAlertAction(title: "Yes", style: UIAlertActionStyle.destructive, handler: { action in
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
            let cancelAction = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel, handler: nil)
            
            alertController.addAction(cancelAction)
            alertController.addAction(confirmAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let lists = lists, lists.count > 0 else {
            return 108
        }
        
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let lists = lists, lists.count > indexPath.row else {
            tableView.deselectRow(at: indexPath, animated: false)
            return
        }
        
        let list = lists[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let listItemsViewController = storyboard.instantiateViewController(withIdentifier: "listItemsViewController") as? ListItemsViewController {
            listItemsViewController.configureWithList(list)
            navigationController?.pushViewController(listItemsViewController, animated: true)
        }
    }
}

// MARK: IBActions
extension ListsTableViewController {
    @IBAction func addNewListButtonTapped(_ sender: AnyObject) {
        if !newListView.isHidden {
            return
        }
        presentNewListView()
    }
    
    @IBAction func createNewListButtonTapped(_ sender: AnyObject) {
        guard let listName = newListTextField.text, listName.characters.count > 0 else {
            return
        }
        
        saveNewList(listName)
    }
    
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        dismissNewListView()
    }
    
    func presentNewListView() {
        tableView.isUserInteractionEnabled = false
        newListView.alpha = 0.0
        newListView.isHidden = false
        UIView.animate(withDuration: 0.6, animations: {
            self.newListView.alpha = 1.0
            self.tableView.alpha = 0.2
            }, completion: { finished in
                self.newListTextField.becomeFirstResponder()
        })
    }
    
    fileprivate func dismissNewListView() {
        tableView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.4, animations: {
            self.newListView.alpha = 0.0
            self.tableView.alpha = 1.0
            }, completion: { finished in
                self.newListView.isHidden = true
                self.newListTextField.text = ""
                self.newListTextField.resignFirstResponder()
        })
    }
    
    func saveNewList(_ name: String) {
        ListStore.defaultStore.insertNewList(name)
        dismissNewListView()
    }
    
    func deleteList(_ title: String) {
        ListStore.defaultStore.removeList(title)
    }
}

// MARK: UITextFieldDelegate
extension ListsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let listName = textField.text, listName.characters.count > 0 {
            saveNewList(listName)
        }
        dismissNewListView()
        return true
    }
}

// MARK: ListChangeDelegate
extension ListsTableViewController: ListChangeDelegate {
    func listsDidChange(_ lists: [ListModel]) {
        self.lists = lists
        tableView.reloadData()
    }
}

// MARK: Segue / Peek Pop Handling
extension ListsTableViewController: UIViewControllerPreviewingDelegate {
    func viewControllerForIndexPath(_ indexPath: IndexPath) -> UIViewController? {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let listItemsVC = storyboard.instantiateViewController(withIdentifier: "listItemsViewController") as? ListItemsViewController, let list = lists?[indexPath.row] {
            listItemsVC.configureWithList(list)
            return listItemsVC
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if let indexPath = tableView.indexPathForRow(at: location) {
            previewingContext.sourceRect = tableView.rectForRow(at: indexPath)
            return viewControllerForIndexPath(indexPath)
        }
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        navigationController?.pushViewController(viewControllerToCommit, animated: true)
    }
}

// MARK: Advertisements
extension ListsTableViewController {
    func addBannerViewToBottomOfListsTableView() {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate, let sharedAdBanner = appDelegate.sharedBannerView else {
            return
        }
        
        adBannerView = sharedAdBanner
        adBannerView!.delegate = sharedAdBanner.delegate
        
        adBannerView!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adBannerView!)
        
        let bottomConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        let heightConstraint = NSLayoutConstraint(item: adBannerView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 50)
        
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
