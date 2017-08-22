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
        static var NOTIFICATION_TOKEN  = "notificationToken"
        static var MESSAGE  = "notificationMessage"
        static var SERVICE_CHANGED  = "serviceChanged"
        static var IDSERVICE = "idService"
    static var USED = "used"
    
    public static func saveData(user: User){
        let settings : UserDefaults = UserDefaults.standard
        settings.set(user.token, forKey: TOKEN)
        settings.set(user.id, forKey: IDCLIENT)
    }
    
    public static func saveIdService(id:String) {
        let settings : UserDefaults = UserDefaults.standard
        settings.set(id, forKey: IDSERVICE)
    }
    
    public static func readToken() -> String? {
        let settings : UserDefaults = UserDefaults.standard
        if let token = settings.string(forKey: TOKEN) {
            return token
        } else {
            return nil
        }
    }
    
    public static func readUserId() -> String?{
        let settings : UserDefaults = UserDefaults.standard
        if let idClient = settings.string(forKey: IDCLIENT) {
            return idClient
        } else {
            return nil
        }
    }
    
    public static func savePaymentToken(paymentToken:String){
        let settings : UserDefaults = UserDefaults.standard
        settings.set(paymentToken, forKey: PAYMENT_TOKEN)
    }
    
    public static func readPaymentToken() -> String? {
        let settings : UserDefaults = UserDefaults.standard
        if let paymentToken = settings.string(forKey: PAYMENT_TOKEN) {
            return paymentToken
        } else {
            return nil
        }
    }
    
    public static func saveNotificationToken(notificationToken:String){
        let settings : UserDefaults = UserDefaults.standard
        settings.set(notificationToken, forKey: NOTIFICATION_TOKEN)
    }
    
    public static func readNotificationToken() -> String? {
        let settings : UserDefaults = UserDefaults.standard
        if let notificationToken = settings.string(forKey: NOTIFICATION_TOKEN) {
            return notificationToken
        } else {
            return nil
        }
    }
    
    public static func newData() -> Bool{
        let settings : UserDefaults = UserDefaults.standard
        let newData = settings.bool(forKey: SERVICE_CHANGED)
        return newData
    }
    public static func notifyNewData(newData:Bool){
        let settings : UserDefaults = UserDefaults.standard
        settings.set(newData, forKey: SERVICE_CHANGED)
    }
    
    public static func saveMessage(message:String){
        let settings : UserDefaults = UserDefaults.standard
        settings.set(message, forKey: MESSAGE)
    }
    
    public static func getMessage() -> String? {
        let settings : UserDefaults = UserDefaults.standard
        if let message = settings.string(forKey: MESSAGE) {
            return message
        } else {
            return nil
        }
    }
    
    public static func deleteMessage() {
        let settings : UserDefaults = UserDefaults.standard
        settings.removeObject(forKey: MESSAGE)
    }
    
    public static func used(){
        let setting : UserDefaults = UserDefaults.standard
        setting.set(true, forKey: USED)
    }
    
    public static func firstTime()->Bool{
        let settings: UserDefaults = UserDefaults.standard
        if settings.bool(forKey: USED){
            return false
        } else {
            return true
        }
    }
    
    public static func eliminateData() {
        let settings : UserDefaults = UserDefaults.standard
        settings.removeObject(forKey: TOKEN)
        settings.removeObject(forKey: IDCLIENT)
        settings.removeObject(forKey: SENT_ALERT)
        settings.removeObject(forKey: PAYMENT_TOKEN)
        settings.removeObject(forKey: SERVICE_CHANGED)
        settings.removeObject(forKey: IDSERVICE)
    }
}
