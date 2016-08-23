//
//  AppData.swift
//  Vashen
//
//  Created by Alan on 8/1/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

public class AppData {
    
    
        static var TOKEN  = "token"
        static var IDCLIENT  = "idClient"
        static var SENT_ALERT  = "alert"
        static var IN_BACKGROUND  = "inBackground"
        static var PAYMENT_TOKEN  = "paymentToken"
        static var FB_TOKEN  = "fireBase"
        static var MESSAGE  = "notificationMessage"
        static var SERVICE_CHANGED  = "serviceChanged"
    static var IDSERVICE = "idService"
    
    public static func saveData(user: User){
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        settings.setObject(user.token, forKey: TOKEN)
        settings.setObject(user.id, forKey: IDCLIENT)
    }
    
    public static func saveIdService(id:String) {
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        settings.setObject(id, forKey: IDSERVICE)
    }
    
    public static func readToken() -> String{
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let token = settings.stringForKey(TOKEN) {
            return token
        } else {
            return ""
        }
    }
    
    public static func readUserId() -> String{
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let idClient = settings.stringForKey(IDCLIENT) {
            return idClient
        } else {
            return ""
        }
    }
    
    public static func savePaymentToken(paymentToken:String){
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        settings.setObject(paymentToken, forKey: PAYMENT_TOKEN)
    }
    
    public static func readPaymentToken() -> String{
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let paymentToken = settings.stringForKey(PAYMENT_TOKEN) {
            return paymentToken
        } else {
            return ""
        }
    }
    
    public static func readFirebaseToken() -> String{
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let firebaseToken = settings.stringForKey(FB_TOKEN) {
            return firebaseToken
        } else {
            return ""
        }
    }
    
    public static func newData() -> Bool{
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        let newData = settings.boolForKey(SERVICE_CHANGED)
        return newData
    }
    public static func notifyNewData(newData:Bool){
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        settings.setObject(newData, forKey: SERVICE_CHANGED)
    }
    
    public static func saveMessage(message:String){
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        settings.setObject(message, forKey: SERVICE_CHANGED)
    }
    
    public static func getMessage() -> String {
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        if let message = settings.stringForKey(MESSAGE) {
            return message
        } else {
            return ""
        }
    }
    
    public static func eliminateData() {
        let settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
        settings.removeObjectForKey(TOKEN)
        settings.removeObjectForKey(SENT_ALERT)
        settings.removeObjectForKey(IDCLIENT)
        settings.removeObjectForKey(PAYMENT_TOKEN)
    }
}
