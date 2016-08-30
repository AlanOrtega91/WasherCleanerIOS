//
//  DataBase.swift
//  Vashen
//
//  Created by Alan on 8/9/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import CoreData

public class DataBase {
    
    public static func deleteTable(table:String, context: NSManagedObjectContext) throws{
        let fetchRequest = NSFetchRequest(entityName: table)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do{
            try context.executeRequest(deleteRequest)
        } catch{
            throw errorSavingData
        }
    }
    
    public static func saveUser(user:User){
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        do{
            try deleteTable("User",context: context)
            let newUser = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
            
            newUser.setValue(user.id, forKey: "id")
            newUser.setValue(user.name, forKey: "name")
            newUser.setValue(user.lastName, forKey: "lastName")
            newUser.setValue(user.email, forKey: "email")
            newUser.setValue(user.phone, forKey: "phone")
            newUser.setValue(user.rating, forKey: "rating")
            newUser.setValue(user.encodedImage, forKey: "encodedImage")
            try context.save()
        } catch {
            
        }
    }
    
    public static func readUser() -> User{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "User")
        fetchRequest.returnsObjectsAsFaults = false
        let user: User = User()
        do {
            let results = try context.executeFetchRequest(fetchRequest)[0]
            user.id = results.valueForKey("id") as! String
            user.name = results.valueForKey("name") as! String
            user.lastName = results.valueForKey("lastName") as! String
            user.email = results.valueForKey("email") as! String
            user.phone = results.valueForKey("phone") as! String
            user.encodedImage = results.valueForKey("encodedImage") as! String
            user.rating = results.valueForKey("rating") as! Double
            return user
        } catch {
            return user
        }
    }
    
    
    public static func saveServices(services: Array<Service>) {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        do{
            try deleteTable("Service",context: context)
            for service in services {
                let newService = NSEntityDescription.insertNewObjectForEntityForName("Service", inManagedObjectContext: context)
                newService.setValue(service.id, forKey: "id")
                newService.setValue(service.car, forKey: "car")
                newService.setValue(service.service, forKey: "service")
                newService.setValue(service.price, forKey: "price")
                newService.setValue(service.description, forKey: "serviceDescription")
                newService.setValue(service.startedTime, forKey: "startedTime")
                newService.setValue(service.latitud, forKey: "latitud")
                newService.setValue(service.longitud, forKey: "longitud")
                newService.setValue(service.status, forKey: "status")
                newService.setValue(service.clientName, forKey: "clientName")
                newService.setValue(service.clientCel, forKey: "clientCel")
                newService.setValue(service.finalTime, forKey: "finalTime")
                newService.setValue(service.estimatedTime, forKey: "estimatedTime")
                try context.save()
            }
        } catch {
            //Didnt save
        }
    }
    
    public static func readServices() -> Array<Service>?{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startedTime", ascending: false)]
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            var services: Array<Service> = Array<Service>()
            for serviceResult in results {
                let service: Service = Service()
                service.id = serviceResult.valueForKey("id") as! String
                service.car = serviceResult.valueForKey("car") as! String
                service.service = serviceResult.valueForKey("service") as! String
                service.price = serviceResult.valueForKey("price") as! String
                service.description = serviceResult.valueForKey("serviceDescription") as! String
                service.startedTime = serviceResult.valueForKey("startedTime") as? NSDate
                service.latitud = serviceResult.valueForKey("latitud") as! Double
                service.longitud = serviceResult.valueForKey("longitud") as! Double
                service.status = serviceResult.valueForKey("status") as! String
                service.clientName = serviceResult.valueForKey("clientName") as! String
                service.clientCel = serviceResult.valueForKey("clientCel") as! String
                service.estimatedTime = serviceResult.valueForKey("estimatedTime") as! String
                service.finalTime = serviceResult.valueForKey("finalTime") as? NSDate
                services.append(service)
            }
            return services
        } catch {
            return nil
        }
    }
    
    public static func getActiveService() -> Service?{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        let statusPredicate = NSPredicate(format: "status != %@", "Canceled")
        let ratingPredicate = NSPredicate(format: "status != %@", "Finished")
        fetchRequest.predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [statusPredicate, ratingPredicate])
        
        do {
            if try context.executeFetchRequest(fetchRequest).count > 0 {
                let results = try context.executeFetchRequest(fetchRequest)[0]
                let service: Service = Service()
                service.id = results.valueForKey("id") as! String
                service.car = results.valueForKey("car") as! String
                service.service = results.valueForKey("service") as! String
                service.price = results.valueForKey("price") as! String
                service.description = results.valueForKey("serviceDescription") as! String
                service.startedTime = results.valueForKey("startedTime") as? NSDate
                service.latitud = results.valueForKey("latitud") as! Double
                service.longitud = results.valueForKey("longitud") as! Double
                service.status = results.valueForKey("status") as! String
                service.clientName = results.valueForKey("clientName") as! String
                service.clientCel = results.valueForKey("clientCel") as! String
                service.estimatedTime = results.valueForKey("estimatedTime") as! String
                service.finalTime = results.valueForKey("finalTime") as? NSDate
                return service
            }
            return nil
        } catch {
            return nil
        }
    }
    
    public static func getFinishedServices() -> Array<Service>{
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startedTime", ascending: false)]
        let statusPredicate = NSPredicate(format: "status == %@", "Finished")
        fetchRequest.predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [statusPredicate])
        var services: Array<Service> = Array<Service>()
        do {
            let results = try context.executeFetchRequest(fetchRequest)
            for serviceResult in results {
                let service: Service = Service()
                service.id = serviceResult.valueForKey("id") as! String
                service.car = serviceResult.valueForKey("car") as! String
                service.service = serviceResult.valueForKey("service") as! String
                service.price = serviceResult.valueForKey("price") as! String
                service.description = serviceResult.valueForKey("serviceDescription") as! String
                service.startedTime = serviceResult.valueForKey("startedTime") as! NSDate
                service.latitud = serviceResult.valueForKey("latitud") as! Double
                service.longitud = serviceResult.valueForKey("longitud") as! Double
                service.status = serviceResult.valueForKey("status") as! String
                service.clientName = serviceResult.valueForKey("clientName") as! String
                service.clientCel = serviceResult.valueForKey("clientCel") as! String
                service.estimatedTime = serviceResult.valueForKey("estimatedTime") as! String
                service.finalTime = serviceResult.valueForKey("finalTime") as! NSDate
                services.append(service)
            }
            return services
        } catch {
            return services
        }
    }
    
    public static func deleteAllTables() {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        do{
            try deleteTable("User", context: context)
            try deleteTable("Service", context: context)
        } catch {
            
        }
    }
    
    public static var errorSavingData: ErrorType!
}
