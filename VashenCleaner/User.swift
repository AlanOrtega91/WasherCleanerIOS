//
//  User.swift
//  Vashen
//
//  Created by Alan on 8/1/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
public class User:NSManagedObject {
    
    @NSManaged var name: String
    @NSManaged var lastName: String
    @NSManaged var email: String
    @NSManaged var phone: String
    @NSManaged var id: String
    @NSManaged var token: String
    @NSManaged var score:Int16
    @NSManaged var encodedImage:String
    
    public static let HTTP_LOCATION = "Cleaner/"
    
    public static func newUser()->User{
        return DataBase.newUser()
    }
    
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
        let url = NSURL(string: "http://washer.mx/Washer/images/cleaner/\(id)/profile_image.jpg")!
        if let imageData = NSData.init(contentsOf: url as URL) {
            return imageData.base64EncodedString(options: .lineLength64Characters)
        } else {
            return nil
        }
    }
    
    public static func saveEncodedImageToFileAndGetPath(imageString:String) -> String? {
        let imageName = "profile.jpg"
        if let dataImage = Data(base64Encoded: imageString, options: .ignoreUnknownCharacters) {
            if let image = UIImage(data: dataImage) {
                let fileName = getDocumentsDirectory().appendingPathComponent(imageName)
                do {
                    if let imageToSave = UIImageJPEGRepresentation(image, 0.5) {
                        try imageToSave.write(to: fileName)
                        return imageName
                    }
                } catch {
                    return nil
                }
            }
        }
        return nil
    }
    
    public static func saveImageToFileAndGetPath(image:UIImage) -> String? {
        let imageName = "profile.jpg"
        let fileName = getDocumentsDirectory().appendingPathComponent(imageName)
        do {
            if let imageToSave = UIImageJPEGRepresentation(image, 0.5) {
                try imageToSave.write(to: fileName)
                return imageName
            }
        } catch {
            return nil
        }
        return nil
    }
    
    public static func readImageDataFromFile(name:String) -> UIImage? {
        let fileName = getDocumentsDirectory().appendingPathComponent(name)
        let image = UIImage(contentsOfFile: fileName.path)
        return image
    }
    
    public static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    public enum UserError: Error{
        case noSessionFound
        case errorSavingFireBaseToken
        case errorUpdatingLocation
        case errorWithLogOut
    }
}
