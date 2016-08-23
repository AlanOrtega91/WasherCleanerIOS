//
//  MapController.swift
//  Vashen
//
//  Created by Alan on 7/31/16.
//  Copyright © 2016 Alan. All rights reserved.
//

import UIKit
import GoogleMaps

class MapController: UIViewController,GMSMapViewDelegate,CLLocationManagerDelegate {

    //Map
    @IBOutlet weak var mapView: UIView!
    var map: GMSMapView!
    let serviceMarker = GMSMarker()
    let locationMarker = GMSMarker()
    var locManager = CLLocationManager()
    //Timers
    var clock:NSTimer!
    var findRequestsNearbyTimer:dispatch_source_t!
    var drawPathTimer:dispatch_source_t!
    //Service
    var activeService: Service!
    var idClient:String!
    var services = Array<Service>()
    var token:String!
    var activeServiceCycleThread:NSThread!
    var lastStateSent:Int = -1
    
    @IBOutlet weak var statusDisplay: UIButton!
    var currentLocation: CLLocation!
    
    @IBOutlet weak var informationLayout: UIView!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    var alertSent = true
    @IBOutlet weak var locationText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLocation()
        initView()
        NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MapController.initMap), userInfo: nil, repeats: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        initValues()
        initTimers()
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
        dispatch_source_cancel(findRequestsNearbyTimer)
        dispatch_source_cancel(drawPathTimer)
    }
    
    func initTimers(){
        let  findRequestsNearbyQueue = dispatch_queue_create("com.alan.nearbyCleaners", DISPATCH_QUEUE_CONCURRENT);
        findRequestsNearbyTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, findRequestsNearbyQueue);
        dispatch_source_set_timer(findRequestsNearbyTimer, dispatch_time(DISPATCH_TIME_NOW, 0), NSEC_PER_SEC/50, 2*NSEC_PER_SEC);
        
        dispatch_source_set_event_handler(findRequestsNearbyTimer, {
            self.updateCleanerLocation()
            if self.activeService == nil {
                self.findRequestsNearby()
            }
            dispatch_async(dispatch_get_main_queue(), {
                if self.activeService == nil {
                    self.configureStateLooking()
                }
            })
            
        });
        dispatch_resume(findRequestsNearbyTimer);
        
        
        let  drawPathQueue = dispatch_queue_create("com.alan.reloadAddress", DISPATCH_QUEUE_CONCURRENT);
        drawPathTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, drawPathQueue);
        dispatch_source_set_timer(drawPathTimer, dispatch_time(DISPATCH_TIME_NOW, 0), NSEC_PER_SEC, 2*NSEC_PER_SEC);
        
        dispatch_source_set_event_handler(drawPathTimer, {
            //self.drawPath()
            self.updateLocationMarker()
        });
        dispatch_resume(drawPathTimer);
    }
    
    func updateCleanerLocation(){
        if currentLocation != nil {
            do {
                try User.updateLocation(token, latitud: currentLocation.coordinate.latitude, longitud: currentLocation.coordinate.longitude)
            } catch {
                //TODO: location error
            }
        }
    }
    
    func findRequestsNearby(){
        if activeService == nil {
            do {
                let servicesAmount = services.count
                services = try Service.getServices(currentLocation.coordinate.latitude, longitud: currentLocation.coordinate.longitude, withToken: token)
                if servicesAmount == 0 && services.count > 0 {
                    //SendAlert for services found
                }
            } catch {
                //TODO: check errors
            }
        }
    }
    
    func updateLocationMarker(){
        if currentLocation != nil {
            dispatch_async(dispatch_get_main_queue(), {
                self.locationMarker.position = CLLocationCoordinate2D(latitude: self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude)
            })
        }
    }
    
    func configureStateLooking(){
        serviceMarker.map = nil
        informationLayout.hidden = true
        rightButton.enabled = false
        if services.count > 0 {
            statusDisplay.userInteractionEnabled = true
            statusDisplay.setTitle("Aceptar", forState: .Normal)
        } else {
            statusDisplay.userInteractionEnabled = false
            statusDisplay.setTitle("Buscando Servicios", forState: .Normal)
        }
    }
    
    func startActiveServiceCycle(){
        if activeServiceCycleThread == nil {
            activeServiceCycleThread = NSThread(target: self, selector:#selector(activeServiceCycle), object: nil)
            activeServiceCycleThread.start()
        } else if !activeServiceCycleThread.executing {
            activeServiceCycleThread = NSThread(target: self, selector:#selector(activeServiceCycle), object: nil)
            activeServiceCycleThread.start()
        }
    }
    
    func activeServiceCycle(){
        while DataBase.getActiveService() != nil {
            activeService = DataBase.getActiveService()
            configureActiveServiceView()
            while !AppData.newData(){}
        }
        activeService = nil
        configureServiceForDelete()
    }
    
    func configureActiveServiceView(){
        checkNotification()
        switch activeService.status {
        case "Accepted":
            configureActiveServiceAccepted("Empezar")
            break
        case "Started":
            clock = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(MapController.modifyClock), userInfo: nil, repeats: true)
            let display = "Tiempo restante: -- min"
            configureActiveServiceStarted(display)
            break

        default:
            break
        }
        AppData.notifyNewData(false)
    }
    
    
    func configureActiveServiceAccepted(display:String){
        dispatch_async(dispatch_get_main_queue(), {
            self.serviceMarker.map = self.map
            self.rightButton.enabled = true
            if self.activeService != nil {
                self.serviceMarker.position = CLLocationCoordinate2D(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
            }
            self.statusDisplay.userInteractionEnabled = true
            self.statusDisplay.setTitle(display, forState: .Normal)
            //TODO: implement informationLayout.hidden = false
        })
    }
    
    func configureActiveServiceStarted(display:String){
        dispatch_async(dispatch_get_main_queue(), {
            self.serviceMarker.map = self.map
            self.rightButton.enabled = true
            if self.activeService != nil {
                self.serviceMarker.position = CLLocationCoordinate2D(latitude: self.activeService.latitud, longitude: self.activeService.longitud)
            }
            self.statusDisplay.userInteractionEnabled = true
            self.statusDisplay.setTitle(display, forState: .Normal)
            //TODO: implement informationLayout.hidden = false
        })
    }
    
    func configureServiceForDelete(){
        if AppData.getMessage() == "Canceled" {
            dispatch_async(dispatch_get_main_queue(), {
                //TODO: createAlert("Cancel")
            })
        } else {
            //Change to summary
        }
        AppData.saveMessage("")
        
    }
    
    func checkNotification(){
        //TODO: Notification
    }
    
    
    
    func modifyClock(){
        if activeService != nil || activeService.finalTime != nil {
            //TODO: Get diff in time with sign
            let diff = NSDate().timeIntervalSinceDate(activeService.finalTime)
            let minutes = diff/1000/60
            var display = ""
            if diff < 0 {
                display = "Terminar"
            } else {
                display = "Terminando servicio en: " + String(minutes) + " min"
            }
            configureActiveServiceStarted(display)
        }
    }
    

    
    func initLocation(){
        self.locManager.requestAlwaysAuthorization()
        self.locManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locManager.delegate = self
            locManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locManager.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = manager.location
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        locManager.stopUpdatingLocation()
                print(error)
    }
    
    @IBAction func onClickTravel(sender: AnyObject) {
    }
    func initView(){

    }
    
    func initMap(){
        //Create a GMSCameraPosition that tells the map to display the
        //coordinate -33.86,151.20 at zoom level 6.
        let camera = GMSCameraPosition.cameraWithLatitude(currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: 15.0)
        
        map = GMSMapView.mapWithFrame(self.mapView.bounds, camera: camera)
        map.delegate = self
        map.camera = camera
        map.myLocationEnabled = true
        map.accessibilityElementsHidden = false
        self.mapView.addSubview(map)
        self.view.sendSubviewToBack(mapView)
        
        // Creates a marker in the center of the map.
        locationMarker.position = CLLocationCoordinate2D(latitude: camera.target.latitude, longitude: camera.target.longitude)
        locationMarker.map = map
    }
    
    
    enum Error: ErrorType{
        case invalidVehicle
    }
}
