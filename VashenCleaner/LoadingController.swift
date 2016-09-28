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
    @IBOutlet weak var loading: UIImageView!
    
    public override func viewDidLoad() {
        initView()
        FIRMessaging.messaging().connect(completion: { (error) in
            if (error != nil){
                print("Unable to connect with FCM = \(error)")
            } else {
                print("Connected to FCM")
            }
        })
        DispatchQueue.global().async {
            self.readProfile()
        }
    }
    
    func initView(){
        var imgList = [UIImage]()
        for countValue in 0...119{
            let strImageName = "frame_\(countValue)_delay-0.04s"
            let image = UIImage(named: strImageName)
            if image != nil {
                imgList.append(image!)
            }
        }
        self.loading.animationImages = imgList
        self.loading.animationDuration = 5.0
        self.loading.startAnimating()
    }
    
    func readProfile(){
        do{
            try ProfileReader.run(email: email, withPassword: password)
            let token = AppData.readToken()
            if let firebaseToken = FIRInstanceID.instanceID().token() {
                try User.saveFirebaseToken(token: token,pushNotificationToken: firebaseToken)
            }
            let storyBoard = UIStoryboard(name: "Map", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "reveal_controller")
            DispatchQueue.main.async {
                self.navigationController?.setViewControllers([nextViewController], animated: true)
                _ = self.navigationController?.popToRootViewController(animated: true)
            }
        } catch User.UserError.errorSavingFireBaseToken{
            ProfileReader.delete()
            createAlertInfo(message: "Error con el sistema de notificaciones")
            while !clickedAlertOK {
                
            }
            DispatchQueue.main.async {
                _ = self.navigationController?.popViewController(animated: true)
            }
        } catch{
            createAlertInfo(message: "Error con el inicio de sesion")
            while !clickedAlertOK {
                
            }
            DispatchQueue.main.async {
                _ = self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func createAlertInfo(message:String){
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {action in
                self.clickedAlertOK = true
            }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
