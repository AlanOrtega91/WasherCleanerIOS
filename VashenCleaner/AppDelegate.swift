//
//  AppDelegate.swift
//  VashenCleaner
//
//  Created by Alan on 8/20/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import CoreData
import Firebase
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var findRequestsNearbyTimer:DispatchSourceTimer!
    var services = [Service]()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FIRApp.configure()
        let notificationType: UIUserNotificationType = [UIUserNotificationType.alert,UIUserNotificationType.badge,UIUserNotificationType.sound]
        let notificationSettings = UIUserNotificationSettings(types: notificationType, categories: nil)
        application.registerForRemoteNotifications()
        application.registerUserNotificationSettings(notificationSettings)
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotificaiton),
                                                       name: NSNotification.Name.firInstanceIDTokenRefresh, object: nil)
        return true
    }


    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        if let state = userInfo["state"] as? String{
            switch state {
            case "-1":
                if let rating = userInfo["rating"] as? String{
                    let user = DataBase.readUser()
                    user.rating = Double(rating)
                    DataBase.saveUser(user: user)
                }
                break
            case "6":
                sendPopUp(message: "Canceled")
                if let serviceJson = userInfo["serviceInfo"] as? String{
                    let data = serviceJson.data(using: String.Encoding.utf8)
                    do {
                        let service = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                        deleteService(serviceJson: service)
                    } catch {}
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
        let i = services?.index(where: {$0.id == id})
        let format = DateFormatter()
        format.dateFormat = "yyy-MM-dd HH:mm:ss"
        format.locale = Locale(identifier: "us")
        if i == nil {
            services?.append(addService(jsonService: serviceJson))
        } else {
            
            let status = serviceJson["status"] as! String
            services![i!].status = status
            if status == "Canceled" {
                sendPopUp(message: "Canceled")
            }
            if let startedTime =  serviceJson["fechaEmpezado"] as? String{
                services![i!].startedTime = format.date(from: startedTime) as Date!
            }
            if let finalTime = serviceJson["horaFinalEstimada"] as? String{
                services![i!].finalTime = format.date(from: finalTime) as Date!
            }
        }
        
        DataBase.saveServices(services: services!)
        AppData.notifyNewData(newData: true)
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
        let format = DateFormatter()
        format.dateFormat = "yyy-MM-dd HH:mm:ss"
        format.locale = Locale(identifier: "us")
        if let startedTime = jsonService["fechaEmpezado"] as? String {
            service.startedTime = format.date(from: startedTime) as Date!
        }
        if let finalTime = jsonService["horaFinalEstimada"] as? String {
            service.finalTime = format.date(from: finalTime) as Date!
        }

        return service
    }
    
    func deleteService(serviceJson:NSDictionary){
        var services = DataBase.readServices()
        let id = serviceJson["id"] as! String
        if let i = services?.index(where: {$0.id == id}) {
            _ = services?.remove(at: i)
            DataBase.saveServices(services: services!)
            AppData.notifyNewData(newData: true)
        }
    }
    
    func sendPopUp(message:String){
        AppData.saveMessage(message: message)
    }
    
    func tokenRefreshNotificaiton(notification: NSNotification) {
        if let refreshedToken = FIRInstanceID.instanceID().token() {
            // Connect to FCM since connection may have failed when attempted before having a token.
            connectToFcm()
            if AppData.readToken() != "" {
                sendTokenToServer(firebaseToken: refreshedToken)
            }
        }
    }
    // [END refresh_token]
    
    // [START connect_to_fcm]
    func connectToFcm() {
        FIRMessaging.messaging().connect { (error) in
            if (error != nil) {
                print("Unable to connect with FCM. \(error)")
            } else {
                print("Connected to FCM.")
            }
        }
    }
    
    func sendTokenToServer(firebaseToken:String){
        do {
            try User.saveFirebaseToken(token: AppData.readToken(),pushNotificationToken: firebaseToken)
        } catch {
            print("Error saving firebase Token")
        }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.unknown)
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
        if findRequestsNearbyTimer != nil {
            findRequestsNearbyTimer.cancel()
        }
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

    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "alan.VashenCleaner" in the application's documents Application Support directory.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "VashenCleaner", withExtension: "momd")!
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

