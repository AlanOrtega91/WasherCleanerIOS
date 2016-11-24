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
    @IBOutlet weak var brand: UILabel!
    @IBOutlet weak var color: UILabel!
    @IBOutlet weak var serviceLabel: UILabel!

    
    override func viewDidLoad() {
        let service = DataBase.getActiveService()
        clientName.text = service?.clientName
        clientCel.text = service?.clientCel
        plates.text = service?.plates
        brand.text = service?.brand
        color.text = service?.color
        serviceLabel.text = service?.service
    }
    @IBAction func clickedClose(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
