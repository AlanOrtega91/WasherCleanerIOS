//
//  HistoryController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import Foundation

class HistoryController: UIViewController,UITableViewDataSource,UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    var idClient:String!
    var services: Array<Service> = Array<Service>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(frame: UIScreen.mainScreen().bounds)
        backgroundImage.image = UIImage(named: "background")
        self.view.insertSubview(backgroundImage, atIndex: 0)
        initValues()
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func initValues() {
        services = DataBase.getFinishedServices()
    }
    
    
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let service = self.services[indexPath.row]
        let cell = self.tableView.dequeueReusableCellWithIdentifier("historyCell") as! HistoryRowTableViewCell
        let format = NSDateFormatter()
        format.dateFormat = "yyy-MM-dd HH:mm:ss"
        cell.date.text = format.stringFromDate(service.startedTime)
        cell.serviceType.text = service.service + " $" + service.price
        //setCleanerImage(cell.cleanerImage, withId: service.cleanerId)
        setMapImage(cell.locationImage, withService: service)
        return cell
    }
    
    func setMapImage(map: UIImageView, withService service:Service){
        let url = NSURL(string: "https://maps.googleapis.com/maps/api/staticmap?center=\(service.latitud),\(service.longitud)&markers=color:red%7Clabel:S%7C\(service.latitud),\(service.longitud)&zoom=15&size=1000x400&key=")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let data = NSData(contentsOfURL: url!){
                dispatch_async(dispatch_get_main_queue(), {
                    map.image = UIImage(data: data)
                });
            }
        }
    }
    
    func setCleanerImage(image:UIImageView, withId id: String){
        let url = NSURL(string: "http://imanio.zone/Vashen/images/cleaners/" + id + "/profile_image.jpg")
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            if let data = NSData(contentsOfURL: url!){
                dispatch_async(dispatch_get_main_queue(), {
                    image.image = UIImage(data: data)
                });
            }
        }
    }
    
    
    @IBAction func clickedCancel(sender: AnyObject) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
        let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("menu") as! MenuController
        self.presentViewController(nextViewController, animated:true, completion:nil)
    }

}
