//
//  ForgotPasswordController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit

class ForgotPasswordController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImage.image = UIImage(named: "background")
        self.view.insertSubview(backgroundImage, atIndex: 0)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clickedCancel(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
//        let nextViewController = self.storyboard!.instantiateViewControllerWithIdentifier("login") as! LoginController
//        self.presentViewController(nextViewController, animated:true, completion:nil)
    }

    @IBAction func clickedRecover(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
//        let nextViewController = self.storyboard!.instantiateViewControllerWithIdentifier("login") as! LoginController
//        self.presentViewController(nextViewController, animated:true, completion:nil)
    }
}
