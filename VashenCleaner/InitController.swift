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
    
    var settings : UserDefaults = UserDefaults.standard
    var token : String = ""
    var clickedAlertOK = false

    @IBOutlet weak var loading: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        initValues()
        DispatchQueue.global().async {
            self.decideNextView()
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
        imgList.removeAll()
    }
    
    public override func didReceiveMemoryWarning() {
        self.loading.stopAnimating()
        self.loading.animationImages = []
        self.loading.image = UIImage(named: "frame_199_delay-0.04s")
    }
    
    func initValues() {
        token = AppData.readToken()
    }
    
    func decideNextView(){
        if token == "" {
            changeView(storyBoardName: "Main", controllerName: "main")
        } else{
            tryReadUser()
        }
    }
    
    func tryReadUser() {
        do{
            try ProfileReader.run()
            let user = DataBase.readUser()
            user.token = token
            AppData.saveData(user: user)
            
            if let firebaseToken = FIRInstanceID.instanceID().token() {
                try User.saveFirebaseToken(token: token,pushNotificationToken: firebaseToken)
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
    
    private func changeView(storyBoardName:String, controllerName:String){
        let storyBoard = UIStoryboard(name: storyBoardName, bundle: nil)
        let nextViewController = storyBoard.instantiateViewController(withIdentifier: controllerName)
        DispatchQueue.main.async {
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
        
    }
}
