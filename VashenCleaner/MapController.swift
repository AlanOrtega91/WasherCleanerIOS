//
//  MapController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import MapKit

class MapController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate,SWRevealViewControllerDelegate {

    //Map
    @IBOutlet weak var mapViewIOS: MKMapView!
    let serviceMarker = CustomServiceMarker()
    let locationMarker = CustomCleanerMarker()
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
    var activeServiceCycleThread = DispatchQueue(label: "com.washer.activeServiceCycle", attributes: .concurrent)
    var running = false
    var lastStateSent:Int = -1
    
    @IBOutlet weak var statusDisplay: UIButton!
    @IBOutlet weak var cancelDisplay: UIButton!
    var currentLocation: CLLocation!
    
    @IBOutlet weak var informationLayout: UIView!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    var alertSent = true
    @IBOutlet weak var locationText: UILabel!
    @IBOutlet weak var menuOpenButton: UIBarButtonItem!
    
    var acceptSent = false
    var cancelSent = false
    var changingStatus = false
    
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
                self.locationMarker.coordinate = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
            }
        }
    }
    
    func configureStateLooking(){
        self.mapViewIOS.removeAnnotation(serviceMarker)
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
        //TODO: change to Dispatch
        if !running {
            activeServiceCycleThread.async {
                self.running = true
                self.activeServiceCycle()
                self.running = false
            }
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
            self.mapViewIOS.addAnnotation(self.serviceMarker)
            self.rightButton.isEnabled = true
            if self.activeService != nil {
                self.serviceMarker.coordinate = CLLocationCoordinate2D(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
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
            self.mapViewIOS.addAnnotation(self.serviceMarker)
            self.rightButton.isEnabled = true
            if self.activeService != nil {
                self.serviceMarker.coordinate = CLLocationCoordinate2D(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
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
            print(location)
            
            if error != nil {
                print("Reverse geocoder failed with error" + error!.localizedDescription)
                self.locationText.text = ""
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                DispatchQueue.main.async {
                    if pm.thoroughfare != nil && pm.subThoroughfare != nil && pm.subLocality != nil && pm.locality != nil && pm.administrativeArea != nil {
                        self.locationText.text = "\(pm.thoroughfare!) \(pm.subThoroughfare!), \(pm.subLocality!), \(pm.locality!), \(pm.administrativeArea!)"
                    }
                }
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
        if activeService == nil && !acceptSent{
            tryAcceptService()
        } else if activeService.status == "Accepted" && !changingStatus {
            changeServiceStatus(status: Service.STARTED,statusString: "Started", statusName: "Empezando...")
        } else if activeService.status == "Started" && !changingStatus {
            changeServiceStatus(status: Service.FINISHED,statusString: "Finished", statusName: "Terminando...")
        }
    }
    @IBAction func onClickCancel(_ sender: AnyObject) {
        if !cancelSent {
        DispatchQueue.global().async {
            self.cancelService()
        }
        }
    }
    
    func cancelService(){
        do {
            cancelSent = true
            try Service.cancelService(idService: activeService.id, withToken: token)
            var auxServices = DataBase.readServices()
            if activeService != nil {
                if let index = auxServices?.index(where: {$0.id == activeService.id}) {
                    auxServices![index].status = "Canceled"
                    auxServices?.remove(at: index)
                    DataBase.saveServices(services: auxServices!)
                    AppData.saveIdService(id: activeService.id)
                    AppData.saveMessage(message: "Canceled")
                    AppData.notifyNewData(newData: true)
                }
            }
            cancelSent = false
        } catch Service.ServiceError.noSessionFound {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
            DispatchQueue.main.async {
                self.present(nextViewController, animated: true, completion: nil)
            }
            cancelSent = false
        } catch {
            createAlertInfo(message: "Error cancelando servicio")
            cancelSent = false
        }
    }
    
    func tryAcceptService(){
        acceptSent = true
        self.statusDisplay.setTitle("Aceptando...", for: .normal)
        DispatchQueue.global().async {
            for service in self.services {
                do {
                    if let acceptedService = try Service.acceptService(idService: service.id, withToken: self.token) {
                        var auxServices = DataBase.readServices()
                        auxServices?.append(acceptedService)
                        DataBase.saveServices(services: auxServices!)
                        AppData.saveIdService(id: acceptedService.id)
                        AppData.notifyNewData(newData: true)
                        self.startActiveServiceCycle()
                        self.acceptSent = false
                        return
                    }
                } catch Service.ServiceError.noSessionFound{
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
                    DispatchQueue.main.async {
                        self.present(nextViewController, animated: true, completion: nil)
                    }
                    self.acceptSent = false
                    return
                } catch Service.ServiceError.errorProducts {
                    self.createAlertInfo(message: "Error acceptando servicio...checha tus productos")
                    self.acceptSent = false
                    return
                } catch {
                    self.acceptSent = false
                }
            }
            self.createAlertInfo(message: "Error acceptando servicio...checha tus productos")
            self.acceptSent = false
        }
    }
    
    func changeServiceStatus(status: Int, statusString:String, statusName:String){
        self.statusDisplay.setTitle(statusName, for: .normal)
        DispatchQueue.global().async {
            do {
                self.changingStatus = true
                if self.lastStateSent != status {
                    self.lastStateSent = status
                    try Service.changeServiceStatus(idService: self.activeService.id, withToken: self.token, withStatusId: String(status))
                    var auxServices = DataBase.readServices()
                    let index = auxServices?.index(where: {$0.id == self.activeService.id})
                    auxServices![index!].status = statusString
                    if statusString == "Started" {
                        let format = DateFormatter()
                        format.dateFormat = "yyy-MM-dd HH:mm:ss"
                        format.locale = Locale(identifier: "us")
                        auxServices![index!].startedTime = Date()
                        auxServices![index!].finalTime = Date().addingTimeInterval(Double(auxServices![index!].estimatedTime)! * 60)
                    }
                    DataBase.saveServices(services: auxServices!)
                    AppData.saveIdService(id: self.activeService.id)
                    AppData.notifyNewData(newData: true)
                }
                self.changingStatus = false
                
            } catch Service.ServiceError.noSessionFound{
                self.createAlertInfo(message: "Error con la session")
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewController(withIdentifier: "main")
                DispatchQueue.main.async {
                    self.present(nextViewController, animated: true, completion: nil)
                }
                self.changingStatus = false
            } catch {
                self.createAlertInfo(message: "Error al cambiar el estado")
                self.changingStatus = false
            }
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
    }
    
    func revealController(_ revealController: SWRevealViewController!, didMoveTo position: FrontViewPosition) {
        if(position == .left) {
            self.mapViewIOS.isUserInteractionEnabled = true;
        } else {
            self.mapViewIOS.isUserInteractionEnabled = false;
        }
    }
    
    @IBAction func onClickTravel(_ sender: AnyObject) {
        let latitude:CLLocationDegrees =  activeService.latitud
        let longitude:CLLocationDegrees =  activeService.longitud
        let coordinates = CLLocationCoordinate2DMake(latitude, longitude)
        let span = MKCoordinateSpanMake(0.02, 0.02)
        let options = [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinates),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: span)
        ]
        let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = "Servicio"
        mapItem.openInMaps(launchOptions: options)
    }
    
    func initMap(){
        self.mapViewIOS.showsUserLocation = true
        self.mapViewIOS.userTrackingMode = .follow
        let span = MKCoordinateSpanMake(0.02, 0.02)
        var location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        self.mapViewIOS.delegate = self
        
        if self.currentLocation != nil {
            location = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
        } else if self.mapViewIOS.userLocation.location != nil{
            location = CLLocationCoordinate2D(latitude: (self.mapViewIOS.userLocation.location?.coordinate.latitude)!, longitude: (self.mapViewIOS.userLocation.location?.coordinate.longitude)!)
        }
        let region = MKCoordinateRegionMake(location, span)
        mapViewIOS.setRegion(region, animated: true)
        self.locationMarker.coordinate = location
        mapViewIOS.addAnnotation(locationMarker)
        
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if !(annotation is MKPointAnnotation) {
            return nil
        }
        if annotation is CustomCleanerMarker {
            var anView = mapView.dequeueReusableAnnotationView(withIdentifier: "washer")
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: "washer")
            }
            anView?.image = UIImage(named: "washer")
            
            return anView
        } else if annotation is CustomServiceMarker {
            var anView = mapView.dequeueReusableAnnotationView(withIdentifier: "central")
            if anView == nil {
                anView = MKAnnotationView(annotation: annotation, reuseIdentifier: "central")
            }
            anView?.image = UIImage(named: "Location")
            
            return anView
        }
        else {
            return MKAnnotationView()
        }
    }
    
    @IBAction func myLocationClicked(_ sender: AnyObject) {
        var location = CLLocationCoordinate2D(latitude: 0, longitude: 0)
        if self.currentLocation != nil {
            location = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
        }
        let span = MKCoordinateSpanMake(0.02, 0.02)
        let region = MKCoordinateRegionMake(location, span)
        self.mapViewIOS.setRegion(region, animated: true)
    }
    
    @IBAction func infoClick(_ sender: AnyObject) {
        let nextViewController = self.storyboard!.instantiateViewController(withIdentifier: "information") as! InformationController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
    
    
    func createAlertInfo(message:String){
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "", message: message, preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    class CustomServiceMarker: MKPointAnnotation {
        let image = UIImage(named: "default_marker")
    }
    class CustomCleanerMarker: MKPointAnnotation {
        let image = UIImage(named: "washer")
    }
    
    enum MapError: Error{
        case invalidVehicle
    }
}
