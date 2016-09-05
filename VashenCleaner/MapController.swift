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
    @IBOutlet weak var cancelDisplay: UIButton!
    var currentLocation: CLLocation!
    
    @IBOutlet weak var informationLayout: UIView!
    @IBOutlet weak var rightButton: UIBarButtonItem!
    var alertSent = true
    @IBOutlet weak var locationText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLocation()
        initTimers()
        initValues()
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: #selector(MapController.initMap), userInfo: nil, repeats: false)
    }
    
    override func viewDidDisappear(animated: Bool) {
        cancelTimers()
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
            } catch User.UserError.noSessionFound{
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(nextViewController, animated: true, completion: nil)
                })
            } catch {
                print("Error updating location")
            }
        }
    }
    
    func findRequestsNearby(){
        if activeService == nil && currentLocation != nil{
            do {
                let servicesAmount = services.count
                services = try Service.getServices(currentLocation.coordinate.latitude, longitud: currentLocation.coordinate.longitude, withToken: token)
                if servicesAmount == 0 && services.count > 0 {
                    //SendAlert for services found
                }
            } catch Service.Error.noSessionFound{
                //TODO: check errors
                let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
                dispatch_async(dispatch_get_main_queue(), {
                    self.presentViewController(nextViewController, animated: true, completion: nil)
                })
            } catch {
                print("Error getting services")
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
            cancelDisplay.hidden = true
        } else {
            statusDisplay.userInteractionEnabled = false
            statusDisplay.setTitle("Buscando Servicios", forState: .Normal)
            cancelDisplay.hidden = true
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
        configureServiceForDelete()
        activeService = nil
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
            self.informationLayout.hidden = false
            self.cancelDisplay.hidden = false
        })
        getGeoLocation()
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
            self.informationLayout.hidden = false
            self.cancelDisplay.hidden = false
        })
    }
    
    func configureServiceForDelete(){
        if AppData.getMessage() == "Canceled" {
            dispatch_async(dispatch_get_main_queue(), {
                //TODO: createAlert("Cancel")
            })
        } else {
            let auxService = activeService
            dispatch_async(dispatch_get_main_queue(), {
                let storyBoard: UIStoryboard = UIStoryboard(name: "Map", bundle:nil)
                let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("summary") as! SummaryController
                nextViewController.service = auxService
                self.presentViewController(nextViewController, animated:true, completion:nil)
            })
        }
        AppData.saveMessage("")
        
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
                self.locationText.text = pm.thoroughfare! + " " + pm.subThoroughfare! + ", " + pm.subLocality! + ", " + pm.locality! + ", " + pm.administrativeArea! + ", " + pm.country!
                print(self.locationText.text)
            }
            else {
                print("Problem with the data received from geocoder")
            }
        })
    }
    
    func modifyClock(){
        if activeService != nil || activeService.finalTime != nil {
            //TODO: Get diff in time with sign
            let diff = activeService.finalTime.timeIntervalSinceNow
            let minutes = diff/1000/60 + 1
            var display = ""
            if diff < 0 {
                display = "Terminar"
            } else {
                display = "Terminando servicio en: " + String(minutes) + " min"
            }
            configureActiveServiceStarted(display)
        }
    }
    

    @IBAction func onClickChangeStatus(sender: AnyObject) {
        if activeService == nil {
            tryAcceptService()
        } else if activeService.status == "Accepted" {
            changeServiceStatus(Service.STARTED,statusString: "Started")
        } else if activeService.status == "Started" {
            changeServiceStatus(Service.FINISHED,statusString: "Finished")
        }
    }
    @IBAction func onClickCancel(sender: AnyObject) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            // do some task
            self.cancelService()
        });
    }
    
    func cancelService(){
        do {
            try Service.cancelService(activeService.id, withToken: token)
            var auxServices = DataBase.readServices()
            let index = auxServices?.indexOf({$0.id == activeService.id})
            auxServices![index!].status = "Canceled"
            auxServices?.removeAtIndex(index!)
            DataBase.saveServices(auxServices!)
            AppData.saveIdService(activeService.id)
            AppData.notifyNewData(true)
            AppData.saveMessage("Canceled")
        } catch Service.Error.noSessionFound {
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(nextViewController, animated: true, completion: nil)
            })
        } catch {
            createAlertInfo("Error cancelando servicio")
            print("Error canceling service")
        }
    }
    
    func tryAcceptService(){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            for service in self.services {
                do {
                    let acceptedService = try Service.acceptService(service.id, withToken: self.token)
                    var auxServices = DataBase.readServices()
                    auxServices?.append(acceptedService)
                    DataBase.saveServices(auxServices!)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.statusDisplay.setTitle("Aceptando", forState: .Normal)
                    })
                    AppData.saveIdService(acceptedService.id)
                    AppData.notifyNewData(true)
                    self.startActiveServiceCycle()
                    return
                } catch Service.Error.noSessionFound{
                    let storyBoard = UIStoryboard(name: "Main", bundle: nil)
                    let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
                    dispatch_async(dispatch_get_main_queue(), {
                        self.presentViewController(nextViewController, animated: true, completion: nil)
                    })
                } catch {
                    self.createAlertInfo("Error acceptando servicio...checha tus productos")
                    print("Error accepting service")
                }
            }
        })
    }
    
    func changeServiceStatus(status: Int, statusString:String){
        do {
            if lastStateSent != status {
                lastStateSent = status
                try Service.changeServiceStatus(activeService.id, withToken: token, withStatusId: String(status))
                var auxServices = DataBase.readServices()
                let index = auxServices?.indexOf({$0.id == activeService.id})
                auxServices![index!].status = statusString
                if statusString == "Started" {
                    let format = NSDateFormatter()
                    format.dateFormat = "yyy-MM-dd HH:mm:ss"
                    auxServices![index!].startedTime = NSDate()
                    auxServices![index!].finalTime = NSDate().dateByAddingTimeInterval(Double(auxServices![index!].estimatedTime)! * 60)
                }
                DataBase.saveServices(auxServices!)
                AppData.saveIdService(activeService.id)
                AppData.notifyNewData(true)
            }
            
        } catch Service.Error.noSessionFound{
            createAlertInfo("Error con la session")
            let storyBoard = UIStoryboard(name: "Main", bundle: nil)
            let nextViewController = storyBoard.instantiateViewControllerWithIdentifier("main")
            dispatch_async(dispatch_get_main_queue(), {
                self.presentViewController(nextViewController, animated: true, completion: nil)
            })
        } catch {
            createAlertInfo("Error al cambiar el estado")
            print("Error changing status")
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
        let url = NSURL(string: "comgooglemaps://?saddr=&daddr=\(activeService.latitud),\(activeService.longitud)&directionsmode=driving")!
        UIApplication.sharedApplication().openURL(url)
    }
    
    func initMap(){
        //Create a GMSCameraPosition that tells the map to display the
        //coordinate -33.86,151.20 at zoom level 6.
        var camera: GMSCameraPosition!
        if currentLocation == nil {
            camera = GMSCameraPosition.cameraWithLatitude(0, longitude: 0, zoom: 15.0)
        } else {
            camera = GMSCameraPosition.cameraWithLatitude(currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude, zoom: 15.0)
        }
        
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
    
    @IBAction func myLocationClicked(sender: AnyObject) {
        var camera:GMSCameraPosition
        if self.currentLocation == nil {
            camera = GMSCameraPosition.cameraWithLatitude(0, longitude: 0, zoom: 15.0)
        } else {
            camera = GMSCameraPosition.cameraWithLatitude(self.currentLocation.coordinate.latitude, longitude: self.currentLocation.coordinate.longitude, zoom: 15.0)
        }
        self.map.animateToCameraPosition(camera)
    }
    
    func createAlertInfo(message:String){
        dispatch_async(dispatch_get_main_queue(), {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        })
    }
    
    
    enum Error: ErrorType{
        case invalidVehicle
    }
}
