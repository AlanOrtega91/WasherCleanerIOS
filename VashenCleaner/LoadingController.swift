//
//  LoadingController.swift
//  Vashen
//
//  Created by Alan on 8/3/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import Firebase
import FirebaseMessaging

public class LoadingController: UIViewController {

    var email: String!
    var password: String!
    var clickedAlertOK = false

    public override func viewDidLoad() {
        initView()
        FIRMessaging.messaging().connectWithCompletion({ (error) in
            if (error != nil){
                print("Unable to connect with FCM = \(error)")
            } else {
                print("Connected to FCM")
            }
        })
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // do some task
            self.readProfile()
        });
    }
    
    func initView(){
        let backgroundImage = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImage.image = UIImage(named: "loading")
        self.view.insertSubview(backgroundImage, atIndex: 0)
    }
    
    func readProfile(){
        do{
            try ProfileReader.run(email, withPassword: password)
            let token = AppData.readToken()
            let firebaseToken = FIRInstanceID.instanceID().token()
            if firebaseToken == nil {
                throw User.UserError.errorSavingFireBaseToken
            } else {
                try User.saveFirebaseToken(token, pushNotificationToken: firebaseToken!)
                FIRMessaging.messaging().connectWithCompletion({ (error) in
                    if (error != nil){
                        print("Unable to connect with FCM = \(error)")
                    } else {
                        print("Connected to FCM")
                    }
                })
            }
            let storyBoard = UIStoryboard(name: "Map", bundle: nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("map")
            dispatch_async(dispatch_get_main_queue(), {
                self.navigationController?.setViewControllers([nextViewController], animated: true)
                self.navigationController?.popToRootViewControllerAnimated(true)
            })
        } catch User.UserError.errorSavingFireBaseToken{
            ProfileReader.delete()
            createAlertInfo("Error con el sistema de notificaciones")
            while !clickedAlertOK {
                
            }
//            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("login") as! LoginController
//            nextViewController.emailSet = email
//            nextViewController.passwordSet = password
            dispatch_async(dispatch_get_main_queue(), {
                //self.presentViewController(nextViewController, animated: true, completion: nil)
                self.navigationController?.popViewControllerAnimated(true)
            })
        } catch{
//            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
//            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("login") as! LoginController
//            nextViewController.emailSet = email
//            nextViewController.passwordSet = password
            dispatch_async(dispatch_get_main_queue(), {
                //self.presentViewController(nextViewController, animated: true, completion: nil)
                self.navigationController?.popViewControllerAnimated(true)
            })
        }
    }
    
    func createAlertInfo(message:String){
        dispatch_async(dispatch_get_main_queue(), {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: {action in
                self.clickedAlertOK = true
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        })
    }
}
