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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
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
        
        addItemView.layer.borderColor = UIColor.lightGray.cgColor
        addItemView.layer.borderWidth = 1.0
        addItemView.layer.cornerRadius = 5.0
    }

    override func viewWillAppear(_ animated: Bool) {
        if let _ = list {
            sendListItemsToWatch(listItems)
        }
    }
    
    fileprivate func configureTableView() {
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 25.0
    }
    
    fileprivate func addBannerViewToTheBottomOfTheListItemsTableView() {
        let adBanner = appDelegate.sharedBannerView ?? ADBannerView()
        adBanner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(adBanner)
        
        let bottomConstraint = NSLayoutConstraint(item: adBanner, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        let leadingConstraint = NSLayoutConstraint(item: adBanner, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
        let trailingConstraint = NSLayoutConstraint(item: adBanner, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
        
        view.addConstraints([bottomConstraint, leadingConstraint, trailingConstraint])
    }
    
    func configureWithList(_ list: ListModel) {
        self.list = list
        title = list.title
    }
    
    func sendListItemsToWatch(_ items: [ListItem]) {
        do {
            if WCSession.isSupported() {
                try WCSession.default().updateApplicationContext(["listName": list?.title! ?? "", "listItems": items.map({"\($0.title!)"})])
            }
        } catch let error as NSError {
            print("Unable to update context: \(error.userInfo)")
        }
    }

    @IBAction func addAnotherItemTapped(_ sender: AnyObject) {
        if let itemName = newItemTextField.text, itemName.characters.count > 0 {
            addItemWithName(itemName)
            newItemTextField.becomeFirstResponder()
            newItemTextField.text = ""
        }
        return
    }
    
    @IBAction func doneButtonTapped(_ sender: AnyObject) {
        if let itemName = newItemTextField.text, itemName.characters.count > 0 {
            addItemWithName(itemName)
        }
        dismissAddItemView()
    }
    
    @IBAction func addNewItemButtonTapped(_ sender: AnyObject) {
        presentAddItemView()
    }
    
    
    @IBAction func backButtonTapped(_ sender: AnyObject) {
        _ = navigationController?.popViewController(animated: true)
    }
    
    fileprivate func addItemWithName(_ name: String) {
        guard let list = list else {
            return
        }
        ListStore.defaultStore.addListItem(name, list: list)
        tableView.reloadData() // Re-sizes the cell based on the content size
        sendListItemsToWatch(listItems)
    }
    
    func presentAddItemView() {
        if !addItemView.isHidden {
            return
        }
        addItemView.alpha = 0.0
        addItemView.isHidden = false
        tableView.isUserInteractionEnabled = false
        UIView.animate(withDuration: 0.6, animations: {
            self.addItemView.alpha = 1.0
            self.tableView.alpha = 0.25
            self.view.bringSubview(toFront: self.addItemView) 
            }, completion: { finished in
                self.newItemTextField.becomeFirstResponder()
        })
    }
    
    fileprivate func dismissAddItemView() {
        tableView.isUserInteractionEnabled = true
        UIView.animate(withDuration: 0.6, animations: {
            self.addItemView.alpha = 0.0
            self.tableView.alpha = 1.0
            }, completion: { finished in
                self.addItemView.isHidden = true
                self.newItemTextField.text = ""
                self.newItemTextField.resignFirstResponder()
                self.view.sendSubview(toBack: self.addItemView)
        })
    }
    
}

extension ListItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if listItems.count == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "noListItemsCell") {
               return cell
            }
        }
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: "listItemCell") as? ListItemTableViewCell {
            cell.titleLabel.text = listItems[indexPath.row].title
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listItems.count == 0 {
            return 1
        }
        return listItems.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
}

extension ListItemsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        return nil
        // TODO: Implement this
    }
    
    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        // TODO: Implement this
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        return .delete
        // TODO: Make this smart so it can be edited too
    }
    
    // Enable re-ordering
    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        return proposedDestinationIndexPath
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard let list = list else {
            return
        }
        
        if editingStyle == .delete {
            ListStore.defaultStore.removeListItem(listItems[indexPath.row].title ?? "", list: list)
        }
    }
}

extension ListItemsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let itemName = textField.text, itemName.characters.count > 0 {
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
    func listItemsDidChange(_ list: ListModel, items: [ListItem]) {
        guard let currentList = self.list else {
            return
        }
        
        DispatchQueue.main.async(execute: {
            if let listTitle = list.title, let currentTitle = currentList.title, listTitle.compare(currentTitle) == .orderedSame {
                self.listItems = items
                self.sendListItemsToWatch(items)
                self.tableView.reloadData()
            }
        })
    }
}

extension ListItemsViewController {
    override var previewActionItems : [UIPreviewActionItem] {
        
        if listItems.count > 0 {
            let clearListAction = UIPreviewAction(title: "Clear List", style: .destructive, handler: { (action, viewController) in
                if let listItemsVC = viewController as? ListItemsViewController, let list = listItemsVC.list {
                    ListStore.defaultStore.removeAllListItems(list)
                }
            })
            
            return [clearListAction]
        }
        return []
    }
}
