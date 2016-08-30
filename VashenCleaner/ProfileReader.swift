//
//  ProfileReader.swift
//  Vashen
//
//  Created by Alan on 8/1/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import CoreData

public class ProfileReader {
    
    var managedContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    let HTTP_LOCATION = "Cleaner/"
    var user = User()
    var services = [Service]()
    
    public static func run() throws{
        do{
            let token = AppData.readToken()
            let profile = ProfileReader()
            try profile.initialRead(token)
            DataBase.saveUser(profile.user)
            AppData.saveData(profile.user)
            DataBase.saveServices(profile.services)
            
        } catch{
            print("Error reading profile")
            throw ProfileReaderError.errorReadingProfile
        }
    }
    
    private func initialRead(token:String) throws{
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "InitialRead")
        let params = "token=\(token)"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String != "OK" {
                throw ProfileReaderError.errorReadingData
            }
            
            if let  rating = response["Calificacion"] as? String {
                readUser(response["User Info"] as! NSDictionary, rating: Double(rating)!)
            } else {
                readUser(response["User Info"] as! NSDictionary, rating: 0)
            }
            readHistory(response["History"] as! Array<NSDictionary>)
        } catch (let e) {
            print(e)
            throw ProfileReaderError.errorReadingData
        }
    }
    
    public static func run(email:String, withPassword password:String) throws{
        do{
            let profile = ProfileReader()
            try profile.login(email, withPassword: password)
            DataBase.saveUser(profile.user)
            AppData.saveData(profile.user)
            DataBase.saveServices(profile.services)
        } catch{
            print("Error reading profile")
            throw ProfileReaderError.errorReadingProfile
        }
    }
    
    private func login(email: String, withPassword password: String) throws{
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "LogIn")
        let params = "email=\(email)&password=\(password)"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            print(response)
            if response["Status"] as! String != "OK" {
                throw ProfileReaderError.errorReadingData
            }
            if let  rating = response["Calificacion"] as? String {
                readUser(response["User Info"] as! NSDictionary, rating: Double(rating)!)
            } else {
                readUser(response["User Info"] as! NSDictionary, rating: 0)
            }
            readHistory(response["History"] as! Array<NSDictionary>)
        } catch (let e) {
            print(e)
            throw ProfileReaderError.errorReadingData
        }
    }
    
    private func readUser(parameters: NSDictionary, rating:Double){
        user.name = parameters["Nombre"]! as! String
        user.lastName = parameters["PrimerApellido"]! as! String
        user.email = parameters["Email"]! as! String
        user.id = parameters["idLavador"]! as! String
        user.token = parameters["Token"]! as! String
        user.phone = parameters["Telefono"]! as! String
        if (parameters["FotoURL"] as? String) != nil{
            user.encodedImage = User.getEncodedImageForUser(user.id)
        }
        user.rating = rating
    }
    
    
    private func readHistory(parameters: Array<NSDictionary>){
        for serviceJSON in parameters {
            let service: Service = Service()
            service.id = serviceJSON["id"] as! String
            service.car = serviceJSON["coche"] as! String
            service.status = serviceJSON["status"] as! String
            service.service = serviceJSON["servicio"] as! String
            service.price = serviceJSON["precio"] as! String
            service.description = serviceJSON["descripcion"] as! String
            
            service.latitud = Double(serviceJSON["latitud"] as! String)!
            service.longitud = Double(serviceJSON["longitud"] as! String)!
            service.clientName = serviceJSON["nombreCliente"] as? String
            service.clientCel = serviceJSON["telCliente"] as? String
            service.estimatedTime = serviceJSON["tiempoEstimado"] as? String
            
            let format = NSDateFormatter()
            format.dateFormat = "yyy-MM-dd HH:mm:ss"
            if let finalTime = serviceJSON["horaFinalEstimada"] as? String{
                service.finalTime = format.dateFromString(finalTime)
            }
            if let startedTime = serviceJSON["fechaEmpezado"] as? String {
                service.startedTime = format.dateFromString(startedTime)
            }
            services.append(service)
        }
        
    }
    
    public static func delete() {
        AppData.eliminateData()
        DataBase.deleteAllTables()
    }
    
    public enum ProfileReaderError: ErrorType {
        case errorReadingData
        case errorReadingProfile
    }
    
}