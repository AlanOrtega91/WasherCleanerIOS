//
//  User.swift
//  Vashen
//
//  Created by Alan on 8/1/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import CoreData

public class User {
    
    public var name: String!
    public var lastName: String!
    public var email: String!
    public var phone: String!
    public var id: String!
    public var token: String!
    public var rating:Double!
    public var encodedImage:String!
    
    public static let HTTP_LOCATION = "Cleaner/"
    
    public static func updateLocation(token:String, latitud:Double, longitud:Double) throws {
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "UpdateLocation")
        let params = "token=\(token)&latitud=\(latitud)&longitud=\(longitud)"
        do{
            let response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw UserError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw UserError.errorUpdatingLocation
            }
            
        } catch HttpServerConnection.HttpError.connectionException{
            throw UserError.errorUpdatingLocation
        }
    }
    
    public static func saveFirebaseToken(token:String, pushNotificationToken:String) throws {
        let url = HttpServerConnection.buildURL(location: HTTP_LOCATION + "SavePushNotificationToken")
        let params = "token=\(token)&pushNotificationToken=\(pushNotificationToken)"
        do{
            let response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw UserError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw UserError.errorSavingFireBaseToken
            }
            
        } catch HttpServerConnection.HttpError.connectionException{
            throw UserError.errorSavingFireBaseToken
        }
    }
    
    
    public func sendLogout() throws {
        let url = HttpServerConnection.buildURL(location: User.HTTP_LOCATION + "LogOut")
        let params = "email=\(email)"
        do{
            let response = try HttpServerConnection.sendHttpRequestPost(urlPath: url, withParams: params)
            
            if response["Status"] as! String != "OK" {
                throw UserError.errorWithLogOut
            }
            
        } catch HttpServerConnection.HttpError.connectionException{
            throw UserError.errorWithLogOut
        }
    }
    
    public static func getEncodedImageForUser(id:String) -> String? {
        let url = URL(string: "http://imanio.zone/Vashen/images/cleaners/\(id)/profile_image.jpg")!
        do {
            let imageData = try Data.init(contentsOf: url)
            return imageData.base64EncodedString(options: .lineLength64Characters)
        } catch {
            return nil
        }
    }
    
    public enum UserError: Error{
        case noSessionFound
        case errorSavingFireBaseToken
        case errorUpdatingLocation
        case errorWithLogOut
    }
}
