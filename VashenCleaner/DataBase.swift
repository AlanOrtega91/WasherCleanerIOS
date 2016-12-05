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
    
    public static func newUser()->User{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: "User", in: context)
        return User(entity: entity!, insertInto: context)
    }
    
    public static func newService()->Service{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let entity = NSEntityDescription.entity(forEntityName: "Service", in: context)
        return Service(entity: entity!, insertInto: context)
    }
    
    public static func save(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        do {
            try context.save()
        } catch {
            print("Error saving context")
        }
    }
    
    public static func deleteTable(table:String) throws{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: table)
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do{
            try context.execute(deleteRequest)
        } catch{
            throw errorSavingData
        }
    }
    
    public static func readUser() -> User?{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        fetchRequest.returnsObjectsAsFaults = false
        do {
            if let result = try context.fetch(fetchRequest)[0] as? User {
                return result
            }
        } catch {
            return nil
        }
        return nil
    }
    
    public static func readService(id:String)->Service?{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        let idPredicate = NSPredicate(format: "id = %@", id)
        fetchRequest.predicate = idPredicate
        do {
            let results = try context.fetch(fetchRequest) as! [Service]
            if results.count == 1 {
                return results[0]
            } else {
                return nil
            }
        } catch {
            return nil
        }
    }
    
    
    public static func deleteService(service:Service){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        context.delete(service)
    }
    
    public static func readServices() -> Array<Service>?{
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.managedObjectContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Service")
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startedTime", ascending: false)]
        do {
            return try context.fetch(fetchRequest) as? [Service]
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
                return try context.fetch(fetchRequest)[0] as? Service
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
        
        do {
            return try context.fetch(fetchRequest) as! [Service]
        } catch {
            return []
        }
    }
    
    public static func deleteAllTables() {
        do{
            try deleteTable(table: "User")
            try deleteTable(table: "Service")
        } catch {
            print("Error deleting tables")
        }
    }
    
    public static var errorSavingData: Error!
}
