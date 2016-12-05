//
//  LoadingController.swift
//  Vashen
//
//  Created by Alan on 8/3/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation
import AVFoundation

public class LoadingController: UIViewController {
    
    var email: String!
    var password: String!
    var clickedAlertOK = false
    
    @IBOutlet var videoView: UIView!
    
    public override func viewDidLoad() {
        animateView()
        DispatchQueue.global().async {
            self.readProfile()
        }
    }
    
    
    func animateView() {
        let path = URL(fileURLWithPath: Bundle.main.path(forResource: "Splash", ofType: "mov")!)
        let player = AVPlayer(url: path)
        let newLayer = AVPlayerLayer(player: player)
        newLayer.frame = self.videoView.frame
        self.videoView.layer.addSublayer(newLayer)
        newLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        player.play()
    }
    
    func readProfile(){
        do{
            try ProfileReader.run(email: email, withPassword: password)
            let token = AppData.readToken()
            //TODO: Use APN Token
//            if let firebaseToken = FIRInstanceID.instanceID().token() {
//                try User.saveFirebaseToken(token: token,pushNotificationToken: firebaseToken)
//            }
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
        let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {action in
            self.clickedAlertOK = true
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}
