//
//  LoginController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit

public class LoginController: UIViewController {

    @IBOutlet weak var email: UITextField!
    public var emailSet:String = ""
    @IBOutlet weak var password: UITextField!
    public var passwordSet:String = ""
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "background")
        self.view.insertSubview(backgroundImage, at: 0)
        if emailSet != "" {
            email.text = emailSet
        }
        if passwordSet != "" {
            password.text = passwordSet
        }
    }

    override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancelClicked(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
    
  

    @IBAction func sendLogin(_ sender: AnyObject) {
        let nextViewController = self.storyboard!.instantiateViewController(withIdentifier: "loading") as! LoadingController
        nextViewController.email = email.text!
        nextViewController.password = password.text!
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
