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
    
    override func viewDidAppear(animated: Bool) {
        initView()
    }
    
    
    func initView(){
        if service != nil {
            let format = NSDateFormatter()
            format.dateFormat = "yyy-MM-dd HH:mm:ss"
            date.text = format.stringFromDate(service.startedTime)
            price.text = service.price
        }
    }
    @IBAction func onClickContinue(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
//        let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
//        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("map") as! MapController
//        self.presentViewController(nextViewController, animated:true, completion:nil)
    }
}
