//
//  InitController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import Firebase
import FirebaseMessaging

class InitController: UIViewController {
    
    var settings : NSUserDefaults = NSUserDefaults.standardUserDefaults()
    var token : String = ""
    var clickedAlertOK = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func initValues() {
        token = AppData.readToken()
    }
    
    func initView() {
        let backgroundImage = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImage.image = UIImage(named: "loading")
        self.view.insertSubview(backgroundImage, atIndex: 0)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            self.decideNextView()
            });
    }
    
    func decideNextView(){
        if token == "" {
            changeView("Main", controllerName: "main")
        } else{
            tryReadUser()
        }
    }
    
    func tryReadUser() {
        do{
            try ProfileReader.run()
            let user = DataBase.readUser()
            user.token = token
            AppData.saveData(user)
            
            let firebaseToken = FIRInstanceID.instanceID().token()
            if firebaseToken == nil {
                throw User.UserError.errorSavingFireBaseToken
            } else {
                try User.saveFirebaseToken(token,pushNotificationToken: firebaseToken!)
                FIRMessaging.messaging().connectWithCompletion({ (error) in
                    if (error != nil){
                        print("Unable to connect with FCM = \(error)")
                    } else {
                        print("Connected to FCM")
                    }
                })
            }

            changeView("Map", controllerName: "map")
        } catch User.UserError.errorSavingFireBaseToken{
            createAlertInfo("Error con FB")
            ProfileReader.delete()
            while !clickedAlertOK{
                
            }
            changeView("Main", controllerName: "main")
        } catch {
            createAlertInfo("Error")
            ProfileReader.delete()
            while !clickedAlertOK{
                
            }
            let nextViewController = self.storyboard!.instantiateViewControllerWithIdentifier("main") as! MainController
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(nextViewController, animated: true, completion: nil)
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
    
    private func changeView(storyBoardName:String, controllerName:String){
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: nil)
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier(controllerName)
        dispatch_async(dispatch_get_main_queue(), {
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            self.navigationController?.popToRootViewControllerAnimated(true)
        })
        
    }
    
    override func viewDidAppear(animated: Bool) {
        initValues()
        initView()
    }

}
