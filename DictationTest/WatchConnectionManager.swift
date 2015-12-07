//
//  WatchConnectionManager.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/30/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import Foundation
import WatchConnectivity

public class WatchConnectionManager: NSObject, WCSessionDelegate {
    
    var listDelegates = [ListChangeDelegate]()
    var listItemDelegates = [ListItemChangeDelegate]()
    
    private let session: WCSession? = WCSession.isSupported() ?  WCSession.defaultSession() : nil
    
    private override init() {
        super.init()
    }
    
    func startSession() {
        guard let session = session else {
            return
        }
        session.delegate = self
        session.activateSession()
    }
    
    func addListDelegate(delegate: ListChangeDelegate) {
        listDelegates.append(delegate)
    }
    
    public func session(session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
        if let action = userInfo["action"] as? String {
            // Remove Item From List
            if action.caseInsensitiveCompare("delete") == .OrderedSame {
                let listItem = userInfo["listItem"] as! String
                let listName = userInfo["list"] as! String
                if let list = ListStore.defaultStore.listWithName(listName) {
                    ListStore.defaultStore.removeListItem(listItem, list: list)
                }
            // Add an item to the list
            } else if action.caseInsensitiveCompare("insert") == .OrderedSame {
                let listItem = userInfo["listItem"] as! String
                let listName = userInfo["list"] as! String
                if let list = ListStore.defaultStore.listWithName(listName) {
                    ListStore.defaultStore.addListItem(listItem, list: list)
                }
            }
        }
    }
}




