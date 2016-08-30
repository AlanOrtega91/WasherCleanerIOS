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
        rating.text = String(user.rating)
        let imageData = NSData(base64EncodedString: user.encodedImage, options: .IgnoreUnknownCharacters)
        image.image = UIImage(data: imageData!)
    }
    

    @IBAction func clickClose(sender: AnyObject) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("map") as! MapController
        self.presentViewController(nextViewController, animated:true, completion:nil)
    }
    
    
    @IBAction func logoutClick(sender: AnyObject) {
        do{
            ProfileReader.delete()
            try user.sendLogout()
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main") as! MainController
            self.presentViewController(nextViewController, animated:true, completion:nil)
        } catch {
            let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main") as! MainController
            self.presentViewController(nextViewController, animated:true, completion:nil)
        }
    }

}
