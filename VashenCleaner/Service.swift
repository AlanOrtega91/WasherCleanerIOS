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
    public var startedTime:NSDate!
    public var finalTime:NSDate!
    
    public var estimatedTime:String!
    
    public var latitud:Double!
    public var longitud:Double!
    
    public var clientName:String!
    public var clientCel:String!
    public var id:String!
    public var address:String!
    
    public static let STARTED = 4
    public static let FINISHED = 5

    
    
    public static func changeServiceStatus(idService:String, withToken token:String, withStatusId statusId:String)throws {
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "ChangeServiceStatus")
        let params = "serviceId=\(idService)&statusId=\(statusId)&token=\(token)&cancelCode=0"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw Error.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw Error.errorChangingStatusRequest
            }

        } catch HttpServerConnection.Error.connectionException {
            throw Error.errorChangingStatusRequest
        }
    }
    
    public static func acceptService(idService:String, withToken token:String) throws -> Service{
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "AcceptService")
        let params = "serviceId=\(idService)&token=\(token)"
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw Error.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw Error.errorServiceTaken
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
            
            return service
        } catch HttpServerConnection.Error.connectionException {
            throw Error.errorServiceTaken
        }
    }
    
    public static func getServices(latitud:Double, longitud:Double, withToken token:String) throws -> Array<Service>{
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "GetNearbyServices")
        let params = "latitud=\(latitud)&longitud=\(longitud)&token=\(token)"
        var services = Array<Service>()
        do{
            var response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw Error.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw Error.errorServiceTaken
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
        } catch HttpServerConnection.Error.connectionException {
            return services
        }
    }
    
    enum Error: ErrorType {
        case noSessionFound
        case userBlock
        case errorChangingStatusRequest
        case errorServiceTaken
    }
    
}