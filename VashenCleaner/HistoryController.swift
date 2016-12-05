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
    var services: [Service] = []
    var images:[UIImage] = []
    var imageSet:[Int] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "background")
        initValues()
        self.view.insertSubview(backgroundImage, at: 0)
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
    
    func initValues(){
        services = DataBase.getFinishedServices()
        for _ in services {
            images.append(UIImage())
            imageSet.append(0)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let service = self.services[indexPath.row]
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "historyCell") as! HistoryRowTableViewCell
        let format = DateFormatter()
        format.dateFormat = "yyy-MM-dd HH:mm:ss"
        format.locale = Locale(identifier: "us")
        cell.date.text = format.string(from: service.startedTime)
        cell.serviceType.text = service.service + " $" + service.price
        if imageSet[indexPath.row] == 0 {
            cell.locationImage.image = nil
            DispatchQueue.global().async {
                self.setMapImage(map: cell.locationImage, withService: service, withPosition: indexPath.row)
            }
        } else {
            cell.locationImage.image = images[indexPath.row]
        }
        return cell
    }
    
    func setMapImage(map: UIImageView, withService service:Service, withPosition position:Int){
        let primer = "https://maps.googleapis.com/maps/api/staticmap?center=" + String(service.latitud) + ","
        let segundo = String(service.longitud) + "&markers=color:red%7Clabel:S%7C" + String(service.latitud) + "," + String(service.longitud) + "&zoom=15&size=1000x400&key="
        if let url = URL(string: primer + segundo) {
        do {
            let data = try Data(contentsOf: url)
            map.image = UIImage(data: data as Data)
            images[position] = map.image!
            imageSet[position] = 1
        } catch {}
        }
    }
    
    @IBAction func clickedCancel(_ sender: AnyObject) {
        _ = self.navigationController?.popViewController(animated: true)
    }

}
