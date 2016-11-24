//
//  ForgotPasswordController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit

class ForgotPasswordController: UIViewController {
    
    @IBAction func clickedCancel(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }

    @IBAction func clickedRecover(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
