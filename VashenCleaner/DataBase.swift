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
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do{
            try context.execute(deleteRequest)
        } catch{
            throw errorSavingData
        }
    }
    
    public static func saveUser(user:User){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        do{
            try deleteTable(table: "User",context: context)
            let newUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
            
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
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.returnsObjectsAsFaults = false
        let user: User = User()
        do {
            let results = try context.fetch(fetchRequest)[0] as! NSManagedObject
            user.id = results.value(forKey: "id") as! String
            user.name = results.value(forKey: "name") as! String
            user.lastName = results.value(forKey: "lastName") as! String
            user.email = results.value(forKey: "email") as! String
            user.phone = results.value(forKey: "phone") as! String
            user.encodedImage = results.value(forKey: "encodedImage") as! String
            user.rating = results.value(forKey: "rating") as! Double
            return user
        } catch {
            return user
        }
    }
    
    
    public static func saveServices(services: Array<Service>) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        
        do{
            try deleteTable(table: "Service",context: context)
            for service in services {
                let newService = NSEntityDescription.insertNewObject(forEntityName: "Service", into: context)
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
                
                newService.setValue(service.plates, forKey: "plates")
                newService.setValue(service.model, forKey: "model")
                newService.setValue(service.brand, forKey: "brand")
                newService.setValue(service.color, forKey: "color")
                newService.setValue(service.type, forKey: "type")
                
                try context.save()
            }
        } catch {
            //Didnt save
        }
    }
    
    public static func readServices() -> Array<Service>?{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startedTime", ascending: false)]
        do {
            let results = try context.fetch(fetchRequest) as! [NSManagedObject]
            var services: Array<Service> = Array<Service>()
            for serviceResult in results {
                let service: Service = Service()
                service.id = serviceResult.value(forKey: "id") as! String
                service.car = serviceResult.value(forKey: "car") as! String
                service.service = serviceResult.value(forKey: "service") as! String
                service.price = serviceResult.value(forKey: "price") as! String
                service.description = serviceResult.value(forKey: "serviceDescription") as! String
                service.startedTime = serviceResult.value(forKey: "startedTime") as? Date
                service.latitud = serviceResult.value(forKey: "latitud") as! Double
                service.longitud = serviceResult.value(forKey: "longitud") as! Double
                service.status = serviceResult.value(forKey: "status") as! String
                service.clientName = serviceResult.value(forKey: "clientName") as! String
                service.clientCel = serviceResult.value(forKey: "clientCel") as! String
                service.estimatedTime = serviceResult.value(forKey: "estimatedTime") as! String
                service.finalTime = serviceResult.value(forKey: "finalTime") as? Date
                
                service.plates = serviceResult.value(forKey: "plates") as! String
                service.model = serviceResult.value(forKey: "model") as! String
                service.brand = serviceResult.value(forKey: "brand") as! String
                service.color = serviceResult.value(forKey: "color") as! String
                service.type = serviceResult.value(forKey: "type") as! String
                
                service.plates = serviceResult.value(forKey: "plates") as! String
                service.model = serviceResult.value(forKey: "model") as! String
                service.brand = serviceResult.value(forKey: "brand") as! String
                service.color = serviceResult.value(forKey: "color") as! String
                service.type = serviceResult.value(forKey: "type") as! String
                
                services.append(service)
            }
            return services
        } catch {
            return nil
        }
    }
    
    public static func getActiveService() -> Service?{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        let statusPredicate = NSPredicate(format: "status != %@", "Canceled")
        let ratingPredicate = NSPredicate(format: "status != %@", "Finished")
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [statusPredicate, ratingPredicate])
        
        do {
            if try context.fetch(fetchRequest).count > 0 {
                let results = try context.fetch(fetchRequest)[0] as! NSManagedObject
                let service: Service = Service()
                service.id = results.value(forKey: "id") as! String
                service.car = results.value(forKey: "car") as! String
                service.service = results.value(forKey: "service") as! String
                service.price = results.value(forKey: "price") as! String
                service.description = results.value(forKey: "serviceDescription") as! String
                service.startedTime = results.value(forKey: "startedTime") as? Date
                service.latitud = results.value(forKey: "latitud") as! Double
                service.longitud = results.value(forKey: "longitud") as! Double
                service.status = results.value(forKey: "status") as! String
                service.clientName = results.value(forKey: "clientName") as! String
                service.clientCel = results.value(forKey: "clientCel") as! String
                service.estimatedTime = results.value(forKey: "estimatedTime") as! String
                service.finalTime = results.value(forKey: "finalTime") as? Date
                
                service.plates = results.value(forKey: "plates") as! String
                service.model = results.value(forKey: "model") as! String
                service.brand = results.value(forKey: "brand") as! String
                service.color = results.value(forKey: "color") as! String
                service.type = results.value(forKey: "type") as! String
                return service
            }
            return nil
        } catch {
            return nil
        }
    }
    
    public static func getFinishedServices() -> Array<Service>{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startedTime", ascending: false)]
        let statusPredicate = NSPredicate(format: "status == %@", "Finished")
        fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: [statusPredicate])
        var services: Array<Service> = Array<Service>()
        do {
            let results = try context.fetch(fetchRequest) as! [NSManagedObject]
            for serviceResult in results {
                let service: Service = Service()
                service.id = serviceResult.value(forKey: "id") as! String
                service.car = serviceResult.value(forKey: "car") as! String
                service.service = serviceResult.value(forKey: "service") as! String
                service.price = serviceResult.value(forKey: "price") as! String
                service.description = serviceResult.value(forKey: "serviceDescription") as! String
                service.startedTime = serviceResult.value(forKey: "startedTime") as! Date
                service.latitud = serviceResult.value(forKey: "latitud") as! Double
                service.longitud = serviceResult.value(forKey: "longitud") as! Double
                service.status = serviceResult.value(forKey: "status") as! String
                service.clientName = serviceResult.value(forKey: "clientName") as! String
                service.clientCel = serviceResult.value(forKey: "clientCel") as! String
                service.estimatedTime = serviceResult.value(forKey: "estimatedTime") as! String
                service.finalTime = serviceResult.value(forKey: "finalTime") as! Date
                service.plates = serviceResult.value(forKey: "plates") as! String
                service.model = serviceResult.value(forKey: "model") as! String
                service.brand = serviceResult.value(forKey: "brand") as! String
                service.color = serviceResult.value(forKey: "color") as! String
                service.type = serviceResult.value(forKey: "type") as! String
                
                services.append(service)
            }
            return services
        } catch {
            return services
        }
    }
    
    public static func deleteAllTables() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        do{
            try deleteTable(table: "User", context: context)
            try deleteTable(table: "Service", context: context)
        } catch {
            
        }
    }
    
    public static var errorSavingData: Error!
}
