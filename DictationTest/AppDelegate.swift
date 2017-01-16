//
//  AppDelegate.swift
//  DictationTest
//
//  Created by Small, Jeff on 11/27/15.
//  Copyright © 2015 Small, Jeff. All rights reserved.
//

import UIKit
import CoreData
import WatchConnectivity
import iAd

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate { // WCSessionDelegate, ADBannerViewDelegate
    
    var window: UIWindow?
    var sharedBannerView = ADBannerView(adType: .banner)
    
    enum ShortcutItem: String {
        case NewList
        
        init?(identifier: String) {
            guard let validIdentifer = identifier.components(separatedBy: ".").last else {
                return nil
            }
            self.init(rawValue: validIdentifer)
        }
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Override point for customization after application launch.
        if WCSession.isSupported() {
            let session = WCSession.default()
//            session.delegate = self
            session.activate()
        }
        
        ListStore.defaultStore.fetchLists()
//        sharedBannerView.delegate = self
        
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            handleShortcutItem(shortcutItem)
            return false
        }
        
        return true
    }
    
    func bannerView(_ banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        print("Failed to load the banner view, we should hide the banner now.")
    }
    
    func handleShortcutItem(_ shortcut: UIApplicationShortcutItem) -> Bool {
        let shortcutType = shortcut.type
        
        guard let validShortcut = ShortcutItem(identifier: shortcutType) else {
            print("Invalid shortcut")
            return false
        }
        
        if validShortcut == .NewList {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let navController = storyboard.instantiateInitialViewController() as? UINavigationController {
                window?.rootViewController = navController
                window?.makeKeyAndVisible()
                if let listVC = navController.viewControllers.first as? ListsTableViewController {
                    let _ = listVC.view
                    listVC.presentNewListView()
                }
            }
        }
        return true
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(handleShortcutItem(shortcutItem))
    }
    
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : AnyObject]) {
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
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.jeff.small.DictationTest" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
}

