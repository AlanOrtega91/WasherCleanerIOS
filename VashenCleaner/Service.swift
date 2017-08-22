//
//  Service.swift
//  Vashen
//
//  Created by Alan on 8/1/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import CoreData

@objc(Service)
public class Service:NSManagedObject {
    
    static var HTTP_LOCATION = "Service/"
    
    @NSManaged var status:String
    @NSManaged var car:String
    @NSManaged var service:String
    @NSManaged var price:String
    @NSManaged var startedTime:Date
    @NSManaged var finalTime:Date
    @NSManaged var serviceDescription:String
    @NSManaged var estimatedTime:String
    
    @NSManaged var latitud:Double
    @NSManaged var longitud:Double
    
    @NSManaged var clientName:String
    @NSManaged var clientCel:String
    @NSManaged var id:String
    @NSManaged var plates:String
    @NSManaged var brand:String
    @NSManaged var color:String
    @NSManaged var type:String
    
    public static let STARTED = 4
    public static let FINISHED = 5

    public static func newService()->Service{
        
        return DataBase.newService()
    }
    
    public static func changeServiceStatus(idService:String, withToken token:String, withStatusId statusId:String)throws {
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "ChangeServiceStatus")
        let params = "serviceId=\(idService)&statusId=\(statusId)&token=\(token)&cancelCode=0"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw ServiceError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw ServiceError.errorChangingStatusRequest
            }

        } catch HttpServerConnection.HttpError.connectionException {
            throw ServiceError.errorChangingStatusRequest
        }
    }
    
    public static func acceptService(idService:String, withToken token:String) throws -> Service?{
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "AcceptService")
        let params = "serviceId=\(idService)&token=\(token)"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw ServiceError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                if response["Status"] as! String == "ERROR faltan productos" {
                    throw ServiceError.errorProducts
                }
                return nil
            }
            let json = response["service info"] as! NSDictionary
            let service = Service.newService()
            
            service.id = json["id"] as! String
            service.car = json["coche"] as! String
            service.service = json["servicio"] as! String
            service.price = json["precio"] as! String
            
            service.latitud = Double(json["latitud"] as! String)!
            service.longitud = Double(json["longitud"] as! String)!
            service.clientName = json["nombreCliente"] as! String
            service.clientCel = json["telCliente"] as! String
            service.status = "Accepted"
            service.estimatedTime = json["tiempoEstimado"] as! String
            service.plates = json["Placas"] as! String
            service.brand = json["Marca"] as! String
            service.color = json["Color"] as! String
            
            return service
        } catch HttpServerConnection.HttpError.connectionException {
            throw ServiceError.errorServiceTaken
        }
    }
    
    public static func getServices(latitud:Double, longitud:Double, withToken token:String) throws -> Array<Service>{
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "GetNearbyServices")
        let params = "latitud=\(latitud)&longitud=\(longitud)&token=\(token)"
        var services = Array<Service>()
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw ServiceError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw ServiceError.errorServiceTaken
            }
            if let json = response["services"] as? Array<NSDictionary> {
                for serviceJson in json {
                    let service = Service.newService()
                    service.id = serviceJson["idServicioPedido"] as! String
                    service.latitud = Double(serviceJson["Latitud"] as! String)!
                    service.longitud = Double(serviceJson["Longitud"] as! String)!
                    services.append(service)
                }
            }
            
            return services
        } catch HttpServerConnection.HttpError.connectionException {
            return services
        }
    }
    
    public static func cancelService(idService:String, withToken token:String) throws {
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "ChangeServiceStatus")
        let params = "serviceId=\(idService)&statusId=6&token=\(token)&cancelCode=\(2)"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw ServiceError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw ServiceError.errorCancelingRequest
            }
            
        } catch HttpServerConnection.HttpError.connectionException {
            throw ServiceError.errorCancelingRequest
        }
    }
    
    enum ServiceError: Error {
        case noSessionFound
        case userBlock
        case errorChangingStatusRequest
        case errorServiceTaken
        case errorCancelingRequest
        case errorProducts
    }
    
}
