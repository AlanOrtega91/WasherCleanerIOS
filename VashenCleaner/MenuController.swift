//
//  MenuController.swift
//  VashenCleaner
//
//  Created by Alan on 8/23/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class MenuController: UIViewController {
    
    
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var rating: UILabel!
    var user:User!
    
    
    override func viewDidLoad() {
        initValues()
        initView()
    }
    
    func initValues(){
        user = DataBase.readUser()
    }
    
    func initView(){
        name.text = user.name + user.lastName
        rating.text = String(describing: user.score)
        let imageData = Data(base64Encoded: user.encodedImage, options: .ignoreUnknownCharacters)
        image.image = UIImage(data: imageData! as Data)
    }
    

    @IBAction func clickClose(sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func logoutClick(sender: AnyObject) {
        do{
            ProfileReader.delete()
            try user.sendLogout()
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        } catch {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            self.navigationController?.setViewControllers([nextViewController], animated: true)
            _ = self.navigationController?.popToRootViewController(animated: true)
        }
    }

}
