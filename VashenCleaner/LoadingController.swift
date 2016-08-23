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

    public override func viewDidLoad() {
        initView()
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
            let firebaseToken = AppData.readFirebaseToken()
            try User.saveFirebaseToken(token, pushNotificationToken: firebaseToken)
            
            let storyBoard = UIStoryboard(name: "Map", bundle: nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("map")
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(nextViewController, animated: true, completion: nil)
            })
        } catch{
            let storyBoard = UIStoryboard(name: "main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(nextViewController, animated: true, completion: nil)
            })
        }
    }
}
