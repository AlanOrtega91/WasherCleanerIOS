//
//  MapController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import GoogleMaps

class MapController: UIViewController,GMSMapViewDelegate,CLLocationManagerDelegate,SWRevealViewControllerDelegate {

    //Map
    @IBOutlet weak var mapView: UIView!
    var map: GMSMapView!
    let serviceMarker = GMSMarker()
    let locationMarker = GMSMarker()
    var locManager = CLLocationManager()
    //Timers
    var clock:DispatchSourceTimer!
    var findRequestsNearbyTimer:DispatchSourceTimer!
    var drawPathTimer:DispatchSourceTimer!
    //Service
    var activeService: Service!
    var idClient:String!
    var services = Array<Service>()
    var token:String!
    var activeServiceCycleThread:Thread!
    var lastStateSent:Int = -1
    
    @IBOutlet weak var statusDisplay: UIButton!
    @IBOutlet weak var cancelDisplay: UIButton!
    var currentLocation: CLLocation!
    
    @IBOutlet weak var informationLayout: UIView!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    var alertSent = true
    @IBOutlet weak var locationText: UILabel!
    @IBOutlet weak var menuOpenButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        menuOpenButton.target = self.revealViewController()
        menuOpenButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        self.revealViewController().delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        initLocation()
        initTimers()
        initValues()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
            self.initMap()
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cancelTimers()
        print("cancel timers")
        self.locManager.stopUpdatingLocation()
    }
    
    func initValues(){
        idClient = AppData.readUserId()
        token = AppData.readToken()
        activeService = DataBase.getActiveService()
        if activeService != nil {
            startActiveServiceCycle()
        }
    }
    
    func cancelTimers(){
        findRequestsNearbyTimer.cancel()
        drawPathTimer.cancel()
    }
    
    func initTimers(){
        let findRequestsNearbyQueue = DispatchQueue(label: "com.alan.nearbyRequests", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        findRequestsNearbyTimer = DispatchSource.makeTimerSource(flags: .strict, queue: findRequestsNearbyQueue)
        findRequestsNearbyTimer.scheduleRepeating(deadline: .now(), interval: .seconds(1), leeway: .seconds(2))
        findRequestsNearbyTimer.setEventHandler(handler: {
            self.updateCleanerLocation()
            if self.activeService == nil {
                self.findRequestsNearby()
            }
            DispatchQueue.main.async {
                if self.activeService == nil {
                    self.configureStateLooking()
                }
            }
        })
        findRequestsNearbyTimer.resume()
        
        let drawPathQueue = DispatchQueue(label: "com.alan.reloadAddress", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
        drawPathTimer = DispatchSource.makeTimerSource(flags: .strict, queue: drawPathQueue)
        drawPathTimer.scheduleRepeating(deadline: .now(), interval: .seconds(1), leeway: .seconds(2))
        drawPathTimer.setEventHandler(handler: {
            //self.drawPath()
            self.updateLocationMarker()
        })
        drawPathTimer.resume()
    }
    
    func updateCleanerLocation(){
        if self.currentLocation != nil {
            do {
                try User.updateLocation(token: self.token, latitud: self.currentLocation.coordinate.latitude, longitud: self.currentLocation.coordinate.longitude)
            } catch User.UserError.noSessionFound{
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
                DispatchQueue.main.async {
                    self.present(nextViewController, animated: true, completion: nil)
                }
            } catch {
                print("Error updating location")
            }
        }
    }
    
    func findRequestsNearby(){
        if activeService == nil && currentLocation != nil{
            do {
                let servicesAmount = services.count
                services = try Service.getServices(latitud: currentLocation.coordinate.latitude, longitud: currentLocation.coordinate.longitude, withToken: token)
                if servicesAmount == 0 && services.count > 0 {
                    //SendAlert for services found
                }
            } catch Service.ServiceError.noSessionFound{
                //TODO: check errors
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
                DispatchQueue.main.async {
                    self.present(nextViewController, animated: true, completion: nil)
                }
            } catch {
                print("Error getting services")
            }
        }
    }
    
    func updateLocationMarker(){
        if self.currentLocation != nil {
            DispatchQueue.main.async {
                self.locationMarker.position = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
            }
        }
    }
    
    func configureStateLooking(){
        serviceMarker.map = nil
        informationLayout.isHidden = true
        rightButton.isEnabled = false
        if services.count > 0 {
            statusDisplay.isUserInteractionEnabled = true
            statusDisplay.setTitle("Aceptar", for: .normal)
            cancelDisplay.isHidden = true
        } else {
            statusDisplay.isUserInteractionEnabled = false
            statusDisplay.setTitle("Buscando Servicios", for: .normal)
            cancelDisplay.isHidden = true
        }
    }
    
    func startActiveServiceCycle(){
        if activeServiceCycleThread == nil {
            activeServiceCycleThread = Thread(target: self, selector:#selector(activeServiceCycle), object: nil)
            activeServiceCycleThread.start()
        } else if !activeServiceCycleThread.isExecuting {
            activeServiceCycleThread = Thread(target: self, selector:#selector(activeServiceCycle), object: nil)
            activeServiceCycleThread.start()
        }
    }
    
    func activeServiceCycle(){
        while DataBase.getActiveService() != nil {
            activeService = DataBase.getActiveService()
            configureActiveServiceView()
            while !AppData.newData(){}
        }
        configureServiceForDelete()
        activeService = nil
    }
    
    func configureActiveServiceView(){
        checkNotification()
        switch activeService.status {
        case "Accepted":
            configureActiveServiceAccepted(display: "Empezar")
            break
        case "Started":
            let clockQueue = DispatchQueue(label: "com.alan.reloadAddress", qos: .background, attributes: .concurrent, autoreleaseFrequency: .inherit, target: nil)
            clock = DispatchSource.makeTimerSource(flags: .strict, queue: clockQueue)
            clock.scheduleRepeating(deadline: .now(), interval: .seconds(1))
            clock.setEventHandler(handler: {
                print("Modify Clock")
                self.modifyClock()
            })
            clock.resume()
            let display = "Tiempo restante: -- min"
            configureActiveServiceStarted(display: display)
            break

        default:
            break
        }
        AppData.notifyNewData(newData: false)
    }
    
    
    func configureActiveServiceAccepted(display:String){
        DispatchQueue.main.async {
            self.serviceMarker.map = self.map
            self.rightButton.isEnabled = true
            if self.activeService != nil {
                self.serviceMarker.position = CLLocationCoordinate2D(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
            }
            self.statusDisplay.isUserInteractionEnabled = true
            self.statusDisplay.setTitle(display, for: .normal)
            self.informationLayout.isHidden = false
            self.cancelDisplay.isHidden = false
        }
        getGeoLocation()
    }
    
    func configureActiveServiceStarted(display:String){
        DispatchQueue.main.async {
            self.serviceMarker.map = self.map
            self.rightButton.isEnabled = true
            if self.activeService != nil {
                self.serviceMarker.position = CLLocationCoordinate2D(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
            }
            self.statusDisplay.isUserInteractionEnabled = true
            self.statusDisplay.setTitle(display, for: .normal)
            self.informationLayout.isHidden = false
            self.cancelDisplay.isHidden = false
        }
    }
    
    func configureServiceForDelete(){
        if AppData.getMessage() == "Canceled" {
            DispatchQueue.main.async {
                self.createAlertInfo(message: "Servicio cancelado")
            }
        } else {
            let auxService = activeService
            DispatchQueue.main.async {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "summary") as! SummaryController
                nextViewController.service = auxService
                self.navigationController?.pushViewController(nextViewController, animated: true)
            }
        }
        AppData.saveMessage(message: "")
        
    }
    
    func checkNotification(){
        //TODO: Notification
    }
    
    func getGeoLocation(){
        let location = CLLocation(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: {(placemarks, error) -> Void in
            //print(location)
            
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                self.locationText.text = ""
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0] //as! CLPlacemark
                //self.locationText.text = pm.thoroughfare! + " " + pm.subThoroughfare! + ", " + pm.subLocality! + ", " + pm.locality! + ", " + pm.administrativeArea! + ", " + pm.country!
                print(self.locationText.text)
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func modifyClock(){
        if activeService != nil {
            if activeService.finalTime != nil {
                let diff = activeService.finalTime.timeIntervalSinceNow
                let minutes = diff/1000/60 + 1
                var display = ""
                if diff < 0 {
                    display = "Terminar"
                    self.clock.cancel()
                } else {
                    display = "Terminando servicio en: " + String(Int(minutes)) + " min"
                }
                self.configureActiveServiceStarted(display: display)
            }
        }
    }
    

    @IBAction func onClickChangeStatus(_ sender: AnyObject) {
        if activeService == nil {
            tryAcceptService()
        } else if activeService.status == "Accepted" {
            changeServiceStatus(status: Service.STARTED,statusString: "Started")
        } else if activeService.status == "Started" {
            changeServiceStatus(status: Service.FINISHED,statusString: "Finished")
        }
    }
    @IBAction func onClickCancel(_ sender: AnyObject) {
        DispatchQueue.global().async {
            self.cancelService()
        }
    }
    
    func cancelService(){
        do {
            try Service.cancelService(idService: activeService.id, withToken: token)
            var auxServices = DataBase.readServices()
            let index = auxServices?.index(where: {$0.id == activeService.id})
            auxServices![index!].status = "Canceled"
            auxServices?.remove(at: index!)
            DataBase.saveServices(services: auxServices!)
            AppData.saveIdService(id: activeService.id)
            AppData.notifyNewData(newData: true)
            AppData.saveMessage(message: "Canceled")
        } catch Service.ServiceError.noSessionFound {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            DispatchQueue.main.async {
                self.present(nextViewController, animated: true, completion: nil)
            }
        } catch {
            createAlertInfo(message: "Error cancelando servicio")
            print("Error canceling service")
        }
    }
    
    func tryAcceptService(){
        DispatchQueue.global().async {
            for service in self.services {
                do {
                    let acceptedService = try Service.acceptService(idService: service.id, withToken: self.token)
                    var auxServices = DataBase.readServices()
                    auxServices?.append(acceptedService)
                    DataBase.saveServices(services: auxServices!)
                    DispatchQueue.main.async {
                        self.statusDisplay.setTitle("Aceptando", for: .normal)
                    }
                    AppData.saveIdService(id: acceptedService.id)
                    AppData.notifyNewData(newData: true)
                    self.startActiveServiceCycle()
                    return
                } catch Service.ServiceError.noSessionFound{
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
                    DispatchQueue.main.async {
                        self.present(nextViewController, animated: true, completion: nil)
                    }
                } catch {
                    self.createAlertInfo(message: "Error acceptando servicio...checha tus productos")
                    print("Error accepting service")
                }
            }
        }
    }
    
    func changeServiceStatus(status: Int, statusString:String){
        do {
            if lastStateSent != status {
                lastStateSent = status
                try Service.changeServiceStatus(idService: activeService.id, withToken: token, withStatusId: String(status))
                var auxServices = DataBase.readServices()
                let index = auxServices?.index(where: {$0.id == activeService.id})
                auxServices![index!].status = statusString
                if statusString == "Started" {
                    let format = DateFormatter()
                    format.dateFormat = "yyy-MM-dd HH:mm:ss"
                    format.locale = Locale(identifier: "us")
                    auxServices![index!].startedTime = Date()
                    auxServices![index!].finalTime = Date().addingTimeInterval(Double(auxServices![index!].estimatedTime)! * 60)
                }
                DataBase.saveServices(services: auxServices!)
                AppData.saveIdService(id: activeService.id)
                AppData.notifyNewData(newData: true)
            }
            
        } catch Service.ServiceError.noSessionFound{
            createAlertInfo(message: "Error con la session")
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            DispatchQueue.main.async {
                self.present(nextViewController, animated: true, completion: nil)
            }
        } catch {
            createAlertInfo(message: "Error al cambiar el estado")
            print("Error changing status")
        }
    }
    
    func initLocation(){
        locManager.delegate = self
        self.locManager.requestAlwaysAuthorization()
        self.locManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if CLLocationManager.locationServicesEnabled() {
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.startUpdatingLocation()
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 1.0, execute: {
                self.myLocationClicked("" as AnyObject)
            })
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locManager.stopUpdatingLocation()
                print(error)
    }
    
    func revealController(_ revealController: SWRevealViewController!, didMoveTo position: FrontViewPosition) {
        if(position == .left) {
            self.mapView.isUserInteractionEnabled = true;
        } else {
            self.mapView.isUserInteractionEnabled = false;
        }
    }
    
    @IBAction func onClickTravel(_ sender: AnyObject) {
        let url = URL(string: "comgooglemaps://?saddr=&daddr=\(activeService.latitud),\(activeService.longitud)&directionsmode=driving")!
        UIApplication.shared.openURL(url)
    }
    
    func initMap(){
            var camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 15.0)
            self.map = GMSMapView.map(withFrame: self.mapView.bounds, camera: camera)
            self.map.delegate = self
            self.map.isMyLocationEnabled = true
            self.map.accessibilityElementsHidden = false
            self.mapView.addSubview(self.map)
            
            if self.currentLocation != nil {
                camera = GMSCameraPosition.camera(withLatitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude, zoom: 15.0)
            } else if self.map.myLocation != nil{
                camera = GMSCameraPosition.camera(withLatitude: self.map.myLocation!.coordinate.latitude, longitude: self.map.myLocation!.coordinate.longitude, zoom: 15.0)
            }
            
            
            // Creates a marker in the center of the map.
            self.locationMarker.position = CLLocationCoordinate2D(latitude: camera.target.latitude, longitude: camera.target.longitude)
            self.locationMarker.map = self.map
            self.locationMarker.icon = UIImage(named: "washer")
            self.map.camera = camera
    }
    
    @IBAction func myLocationClicked(_ sender: AnyObject) {
        var camera:GMSCameraPosition
        if self.currentLocation != nil {
            camera = GMSCameraPosition.camera(withLatitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude, zoom: 15.0)
        } else if self.map.myLocation != nil{
            camera = GMSCameraPosition.camera(withLatitude: self.map.myLocation!.coordinate.latitude, longitude: self.map.myLocation!.coordinate.longitude, zoom: 15.0)
        } else {
            camera = GMSCameraPosition.camera(withLatitude: 0, longitude: 0, zoom: 15.0)
        }
        self.map.animate(to: camera)
    }
    
    @IBAction func infoClick(_ sender: AnyObject) {
        let nextViewController = self.storyboard!.instantiateViewController(withIdentifier: "information") as! InformationController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    
    func createAlertInfo(message:String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    enum MapError: Error{
        case invalidVehicle
    }
}
