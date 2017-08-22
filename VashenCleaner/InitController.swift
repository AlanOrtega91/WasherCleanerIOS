//
//  InitController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import AVFoundation

class InitController: UIViewController {
    
    var settings : UserDefaults = UserDefaults.standard
    var clickedAlertOK = false

    @IBOutlet var videoView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        animateView()
        if AppData.firstTime() {
            self.createAlertTerms()
        } else {
            DispatchQueue.global().async {
                self.decideNextView()
            }
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
    
    
    func decideNextView(){
        if AppData.readToken() == nil {
            changeView(storyBoardName: "Main", controllerName: "main")
        } else{
            tryReadUser()
        }
    }
    
    func tryReadUser() {
        do{
            try ProfileReader.run()
            if let user = DataBase.readUser() {
                if let token = AppData.readToken() {
                    user.token = token
                    //TODO: Implement APNS Token
                    if let notificationToken = AppData.readNotificationToken() {
                        try User.saveFirebaseToken(token: token,pushNotificationToken: notificationToken)
                    }
                }
                AppData.saveData(user: user)
            } else {
                createAlertInfo(message: "Error")
                ProfileReader.delete()
                while !clickedAlertOK{
                    
                }
                let nextViewController = self.storyboard!.instantiateViewController(withIdentifier: "main") as! MainController
                DispatchQueue.main.async {
                    self.present(nextViewController, animated: true, completion: nil)
                }
                return
            }

            changeView(storyBoardName: "Map", controllerName: "reveal_controller")
        } catch User.UserError.errorSavingFireBaseToken{
            createAlertInfo(message: "Error con FB")
            ProfileReader.delete()
            while !clickedAlertOK{
                
            }
            changeView(storyBoardName: "Main", controllerName: "main")
        } catch {
            createAlertInfo(message: "Error")
            ProfileReader.delete()
            while !clickedAlertOK{
                
            }
            let nextViewController = self.storyboard!.instantiateViewController(withIdentifier: "main") as! MainController
            DispatchQueue.main.async {
                self.present(nextViewController, animated: true, completion: nil)
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
    
    func createAlertTerms(){
        let alert = UIAlertController(title: "", message: "Al utilizar esta aplicacion aceptas los terminos y condiciones de uso en la pagina http://www.washer.mx", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {action in
            AppData.used()
            DispatchQueue.global().async {
                self.decideNextView()
            }
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    private func changeView(storyBoardName:String, controllerName:String){
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: controllerName)
        DispatchQueue.main.async {
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
}
