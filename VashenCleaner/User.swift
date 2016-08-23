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
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "UpdateLocation")
        let params = "token=\(token)&latitud=\(latitud)&longitud=\(longitud)"
        do{
            let response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw UserError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw UserError.errorUpdatingLocation
            }
            
        } catch {
            throw UserError.errorUpdatingLocation
        }
    }
    
    public static func saveFirebaseToken(token:String, pushNotificationToken:String) throws {
        let url = HttpServerConnection.buildURL(HTTP_LOCATION + "SavePushNotificationToken")
        let params = "token=\(token)&pushNotificationToken=\(pushNotificationToken)"
        do{
            let response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            if response["Status"] as! String == "SESSION ERROR" {
                throw UserError.noSessionFound
            }
            if response["Status"] as! String != "OK" {
                throw UserError.errorSavingFireBaseToken
            }
            
        } catch {
            throw UserError.errorSavingFireBaseToken
        }
    }
    
    
    public func sendLogout() throws {
        let url = HttpServerConnection.buildURL(User.HTTP_LOCATION + "LogOut")
        let params = "email=\(email)"
        do{
            let response = try HttpServerConnection.sendHttpRequestPost(url, withParams: params)
            
            if response["Status"] as! String != "OK" {
                throw UserError.errorWithLogOut
            }
            
        } catch {
            throw UserError.errorWithLogOut
        }
    }
    
    public static func getEncodedImageForUser(id:String) -> String {
        let url = NSURL(string: "http://imanio.zone/Vashen/images/cleaners/\(id)/profile_image.jpg")!
        let imageData = NSData.init(contentsOfURL: url)
        return imageData!.base64EncodedStringWithOptions(.Encoding64CharacterLineLength)
    }
    
    public enum UserError: ErrorType{
        case noSessionFound
        case errorSavingFireBaseToken
        case errorUpdatingLocation
        case errorWithLogOut
    }
}