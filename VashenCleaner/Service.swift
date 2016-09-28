//
//  Service.swift
//  Vashen
//
//  Created by Alan on 8/1/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

public class Service {
    
    static var HTTP_LOCATION = "Service/"
    public var status:String!
    public var car:String!
    public var service:String!
    public var price:String!
    public var description:String!
    public var startedTime:Date!
    public var finalTime:Date!
    
    public var estimatedTime:String!
    
    public var latitud:Double!
    public var longitud:Double!
    
    public var clientName:String!
    public var clientCel:String!
    public var id:String!
    public var address:String!
    public var plates:String!
    public var model:String!
    public var brand:String!
    public var color:String!
    public var type:String!
    
    public static let STARTED = 4
    public static let FINISHED = 5

    
    
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
    
    public static func acceptService(idService:String, withToken token:String) throws -> Service{
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "AcceptService")
        let params = "serviceId=\(idService)&token=\(token)"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw ServiceError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw ServiceError.errorServiceTaken
            }
            let json = response["service info"] as! NSDictionary
            let service = Service()
            
            service.id = json["id"] as! String
            service.car = json["coche"] as! String
            service.service = json["servicio"] as! String
            service.price = json["precio"] as! String
            service.description = json["descripcion"] as! String
            
            service.latitud = Double(json["latitud"] as! String)!
            service.longitud = Double(json["longitud"] as! String)!
            service.clientName = json["nombreCliente"] as? String
            service.clientCel = json["telCliente"] as? String
            service.status = "Accepted"
            service.estimatedTime = json["tiempoEstimado"] as! String
            service.plates = json["Placas"] as! String
            service.model = json["Modelo"] as! String
            service.brand = json["Marca"] as! String
            service.color = json["Color"] as! String
            service.type = json["Tipo"] as! String
            
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
                    let service = Service()
                    service.id = serviceJson["idServicioPedido"] as! String
                    service.address = serviceJson["Direccion"] as! String
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
    }
    
}
