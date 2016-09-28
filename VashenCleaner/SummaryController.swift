//
//  SummaryController.swift
//  Vashen
//
//  Created by Alan on 8/18/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class SummaryController: UIViewController {

    @IBOutlet weak var date: UILabel!
    @IBOutlet weak var price: UILabel!
    
    var service:Service!
    
    override func viewDidLoad() {
        initView()
    }
    
    func initView(){
        if service != nil {
            let format = DateFormatter()
            format.dateFormat = "yyy-MM-dd HH:mm:ss"
            format.locale = Locale(identifier: "us")
            date.text = format.string(from: service.startedTime)
            price.text = "$ " + service.price
        }
    }
    @IBAction func onClickContinue(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }
}
