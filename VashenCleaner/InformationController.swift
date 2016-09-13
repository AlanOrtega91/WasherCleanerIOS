//
//  InformationController.swift
//  VashenCleaner
//
//  Created by Alan on 8/23/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class InformationController: UIViewController {

    @IBOutlet weak var clientName: UILabel!
    @IBOutlet weak var clientCel: UILabel!
    @IBOutlet weak var plates: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var type: UILabel!
    
    override func viewDidLoad() {
        let service = DataBase.getActiveService()
        clientName.text = service?.clientName
        clientCel.text = service?.clientCel
        plates.text = service?.plates
        serviceLabel.text = service?.service
        type.text = service?.type
    }
    @IBAction func clickedClose(sender: AnyObject) {
//        let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
//        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("map") as! MapController
//        self.presentViewController(nextViewController, animated:true, completion:nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
}
