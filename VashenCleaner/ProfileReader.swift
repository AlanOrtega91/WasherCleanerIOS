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
    
    let HTTP_LOCATION = "Cleaner/"
    var user = User.newUser()
    var services = [Service]()
    
    public static func run() throws{
        do{
            DataBase.deleteAllTables()
            let profile = ProfileReader()
            let token = AppData.readToken()
            try profile.initialRead(token: token!)
            AppData.saveData(user: profile.user)
        } catch{
            throw ProfileReaderError.errorReadingProfile
        }
    }
    
    private func initialRead(token:String) throws{
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "InitialRead")
        let params = "token=\(token)&device=ios"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String != "OK" {
                throw ProfileReaderError.errorReadingData
            }
            
            if let  rating = response["Calificacion"] as? String {
                readUser(parameters: response["User Info"] as! NSDictionary, rating: Int16(Int((Double(rating)?.rounded())!)))
            } else {
                readUser(parameters: response["User Info"] as! NSDictionary, rating: 0)
            }
            readHistory(parameters: response["History"] as! Array<NSDictionary>)
        } catch {
            throw ProfileReaderError.errorReadingData
        }
    }
    
    public static func run(email:String, withPassword password:String) throws{
        do{
            DataBase.deleteAllTables()
            let profile = ProfileReader()
            try profile.login(email: email, withPassword: password)
            AppData.saveData(user: profile.user)
        } catch{
            throw ProfileReaderError.errorReadingProfile
        }
    }
    
    private func login(email: String, withPassword password: String) throws{
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "LogIn")
        let params = "email=\(email)&password=\(password)&device=ios"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String != "OK" {
                throw ProfileReaderError.errorReadingData
            }
            if let  rating = response["Calificacion"] as? String {
                readUser(parameters: response["User Info"] as! NSDictionary, rating: Int16(Int((Double(rating)?.rounded())!)))
            } else {
                readUser(parameters: response["User Info"] as! NSDictionary, rating: 0)
            }
            readHistory(parameters: response["History"] as! Array<NSDictionary>)
        } catch {
            throw ProfileReaderError.errorReadingData
        }
    }
    
    private func readUser(parameters: NSDictionary, rating:Int16){
        user.name = parameters["Nombre"] as! String
        user.lastName = parameters["PrimerApellido"] as! String
        user.email = parameters["Email"] as! String
        user.id = parameters["idLavador"] as! String
        user.token = parameters["Token"] as! String
        user.phone = parameters["Telefono"] as! String
        user.score =  rating
        if let image = User.getEncodedImageForUser(id: user.id) {
            if let encodedImage = User.saveEncodedImageToFileAndGetPath(imageString: image) {
                user.encodedImage = encodedImage
            }
        }
    }
    
    
    private func readHistory(parameters: Array<NSDictionary>){
        for serviceJSON in parameters {
            let service = Service.newService()
            service.id = serviceJSON["id"] as! String
            service.car = serviceJSON["coche"] as! String
            service.status = serviceJSON["status"] as! String
            service.service = serviceJSON["servicio"] as! String
            service.price = serviceJSON["precio"] as! String
            service.serviceDescription = serviceJSON["descripcion"] as! String
            
            service.latitud = Double(serviceJSON["latitud"] as! String)!
            service.longitud = Double(serviceJSON["longitud"] as! String)!
            service.clientName = serviceJSON["nombreCliente"] as! String
            service.clientCel = serviceJSON["telCliente"] as! String
            service.estimatedTime = serviceJSON["tiempoEstimado"] as! String
            if let plates = serviceJSON["Placas"] as? String {
                service.plates = plates
            }
            if let brand = serviceJSON["Placas"] as? String {
                service.brand = brand
            }
            if let color = serviceJSON["Color"] as? String {
                service.color = color
            }
            if let type = serviceJSON["Tipo"] as? String {
                service.type = type
            }
            
            let format = DateFormatter()
            format.dateFormat = "yyy-MM-dd HH:mm:ss"
            format.locale = Locale(identifier: "us")
            if let finalTime = serviceJSON["horaFinalEstimada"] as? String{
                service.finalTime = format.date(from: finalTime)!
            }
            if let startedTime = serviceJSON["fechaEmpezado"] as? String {
                service.startedTime = format.date(from: startedTime)!
            }
            services.append(service)
        }
        
    }
    
    public static func delete() {
        AppData.eliminateData()
        DataBase.deleteAllTables()
    }
    
    public enum ProfileReaderError: Error {
        case errorReadingData
        case errorReadingProfile
    }
    
}
