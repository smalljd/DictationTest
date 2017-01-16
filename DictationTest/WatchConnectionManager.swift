//
//  WatchConnectionManager.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/30/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation
import WatchConnectivity

open class WatchConnectionManager: NSObject { // , WCSessionDelegate
    
    var listDelegates = [ListChangeDelegate]()
    var listItemDelegates = [ListItemChangeDelegate]()
    
    fileprivate let session: WCSession? = WCSession.isSupported() ?  WCSession.default() : nil
    
    fileprivate override init() {
        super.init()
    }
    
    func startSession() {
        guard let session = session else {
            return
        }
//        session.delegate = self
        session.activate()
    }
    
    func addListDelegate(_ delegate: ListChangeDelegate) {
        listDelegates.append(delegate)
    }
    
    open func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        if let action = userInfo["action"] as? String {
            // Remove Item From List
            if action.caseInsensitiveCompare("delete") == .orderedSame {
                let listItem = userInfo["listItem"] as! String
                let listName = userInfo["list"] as! String
                if let list = ListStore.defaultStore.listWithName(listName) {
                    ListStore.defaultStore.removeListItem(listItem, list: list)
                }
            // Add an item to the list
            } else if action.caseInsensitiveCompare("insert") == .orderedSame {
                let listItem = userInfo["listItem"] as! String
                let listName = userInfo["list"] as! String
                if let list = ListStore.defaultStore.listWithName(listName) {
                    ListStore.defaultStore.addListItem(listItem, list: list)
                }
            }
        }
    }
}




