//
//  AppDelegate.swift
//  VashenCleaner
//
//  Created by Alan on 8/20/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyAk33tRPYRLW3jQfD463DSgt-Jr8tX4LO0")
        FIRApp.configure()
        let notificationType: UIUserNotificationType = [UIUserNotificationType.Alert,UIUserNotificationType.Badge,UIUserNotificationType.Sound]
        let notificationSettings = UIUserNotificationSettings(forTypes: notificationType, categories: nil)
        application.registerForRemoteNotifications()
        application.registerUserNotificationSettings(notificationSettings)
        FIRMessaging.messaging().connectWithCompletion({ (error) in
            if (error != nil){
                print("Unable to connect with FCM = \(error)")
            } else {
                print("Connected to FCM")
            }
        })
        return true
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print(userInfo)
        if let state = userInfo["state"] as? String{
            switch state {
            case "-1":
                if let rating = userInfo["rating"] as? String{
                    let user = DataBase.readUser()
                    user.rating = Double(rating)
                    DataBase.saveUser(user)
                }
                break
            case "6":
                if userInfo["message"] as? String == "5" {
                    sendPopUp("Canceled")
                }
                if let serviceJson = userInfo["serviceInfo"] as? String{
                    let data = serviceJson.dataUsingEncoding(NSUTF8StringEncoding)
                    do {
                        let service = try NSJSONSerialization.JSONObjectWithData(data!, options: []) as! NSDictionary
                        print(service)
                        saveNewServiceState(service)
                    } catch {}
                    
                    //TODO: check if notify or popup
                }
                break
            default:
                break
            }
        }
        
    }
    
    func saveNewServiceState(serviceJson:NSDictionary){
        var services = DataBase.readServices()
        let id = serviceJson["id"] as! String
        let i = services?.indexOf({$0.id == id})
        let format = NSDateFormatter()
        format.dateFormat = "yyy-MM-dd HH:mm:ss"
        if i == nil {
            services?.append(addService(serviceJson))
        } else {
            services![i!].startedTime = format.dateFromString((serviceJson["fechaEmpezado"] as? String)!)
            services![i!].status = serviceJson["status"] as! String
            if let finalTime = serviceJson["horaFinalEstimada"] as? String{
                services![i!].finalTime = format.dateFromString(finalTime)
            }
        }
        
        DataBase.saveServices(services!)
        AppData.notifyNewData(true)
    }
    
    func addService(jsonService: NSDictionary) -> Service{
        let service = Service()
        service.id = jsonService["id"] as! String
        service.car = jsonService["coche"] as! String
        service.status = jsonService["status"] as! String
        service.service = jsonService["servicio"] as! String
        service.price = jsonService["precio"] as! String
        service.description = jsonService["descripcion"] as! String
        service.latitud = Double(jsonService["latitud"] as! String)
        service.longitud = Double(jsonService["longitud"] as! String)
        service.clientName = jsonService["nombreCliente"] as! String
        service.clientCel = jsonService["celCliente"] as! String
        let format = NSDateFormatter()
        format.dateFormat = "yyy-MM-dd HH:mm:ss"
        if let startedTime = jsonService["fechaEmpezado"] as? String {
            service.startedTime = format.dateFromString(startedTime)
        }
        if let finalTime = jsonService["horaFinalEstimada"] as? String {
            service.finalTime = format.dateFromString(finalTime)
        }

        return service
    }
    
    func sendPopUp(message:String){
        AppData.saveMessage(message)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "alan.VashenCleaner" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("VashenCleaner", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason

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
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
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

