//  ViewController.swift
//  Mikes Navigation
//
//  Created by Colin Graves on 12/23/15.
//

import UIKit
import MapKit
import AVFoundation
import MediaPlayer



protocol HandleMapSearch: class {
    func dropPinZoomIn(placemark:MKPlacemark)
}

class ViewController: UIViewController {
    
    @IBOutlet weak var cancelButton: UIButton!
    
    @IBOutlet weak var listenButton: UIButton!
    var selectedPin: MKPlacemark?
    var selectedPinTwo: MKPlacemark?
    var findingPin: MKPlacemark?
    var findingHash = [MKPlacemark : NSURL]()
    
    var volume: Float = 0.5
    var pan:Float = 0

    var pinCount = 0
    var distance = 0
    var lastLocation: CLLocation?
    var finding = false
    var resultSearchController: UISearchController!
    let locationManager = CLLocationManager()
    //locationManager.allowsBackgroundLocationUpdates = true
    var heading = CLHeading()
    @IBOutlet weak var mapView: MKMapView!
    
    var audioPlayer: AVAudioPlayer!
    let hotSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "amadeus", ofType: "mp3")!) // If sound not in an assest
    let locateSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "locateSound", ofType: "mp3")!) // If sound not in an assest

    let coldSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "cold", ofType: "mp3")!) // If sound not in an assest
    let beginSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "begin", ofType: "mp3")!) // If sound not in an assest


    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.requestWhenInUseAuthorization() //maybe change
        locationManager.requestLocation()

        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.obscuresBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        mapView.delegate = self
        mapView.isZoomEnabled = true
     
        mapView.sizeToFit()
        let uilpgr = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(gestureRecognized:)))
        
        //long press (2 sec duration)
        uilpgr.minimumPressDuration = 2
        mapView.addGestureRecognizer(uilpgr)
        
        // Instantiate a new music player
 //       let myMediaPlayer = MPMusicPlayerApplicationController.applicationQueuePlayer
  //      // Add a playback queue containing all songs on the device
 //       myMediaPlayer.setQueue(with: MPMediaQuery.songs())
        // Start playing from the beginning of the queue
//        myMediaPlayer.play()
       
        
    }
    @objc func longPressed(gestureRecognized: UIGestureRecognizer){
        
        let touchpoint = gestureRecognized.location(in: self.mapView)
        let location = mapView.convert(touchpoint, toCoordinateFrom: self.mapView)

        let annotation = MKPointAnnotation()
        annotation.title = "Latitude: \(location.latitude)"
        annotation.subtitle = "Longitude: \(location.longitude)"
        annotation.coordinate = location
        mapView.addAnnotation(annotation)
        selectedPin = MKPlacemark(coordinate: location)
        
        
    }
    
    
    func degreesToRadians(degrees: CGFloat) -> CGFloat {
        return degrees * CGFloat(Double.pi) / 180
    }
    
    func radiansToDegress(radians: CGFloat) -> CGFloat {
        return radians * 180 / CGFloat(Double.pi)
    }
    
    @IBAction func cancelPress(_ sender: Any) {
        print("stopDirections")
        //findingPin = selectedPin
        finding = false;
        mapView.userTrackingMode = .none
        locationManager.stopUpdatingLocation()
        mapView.removeAnnotations(mapView.annotations)

        cancelButton.isHidden = true
        audioPlayer.stop()
    }
    
    @IBAction func listenPress(_ sender: Any) {
        print("listen pressed")
        locationManager.stopUpdatingLocation()
        locationManager.startUpdatingLocation()
    }
    
    @objc func getDirections(){
        finding = true;
        print("finding is true")
        sleep(1)
        do{
          print("begin");
          audioPlayer = try AVAudioPlayer(contentsOf: beginSound as URL) //If not in asset
          audioPlayer.pan = pan
          audioPlayer.volume = volume
          audioPlayer.prepareToPlay() // make sure to add this line so audio will play
          audioPlayer.play()
            
        }catch  {
            print("error")
        }
        
        // mapView.userTrackingMode = .followWithHeading
        mapView.setUserTrackingMode(MKUserTrackingMode.followWithHeading, animated: true)
        locationManager.startUpdatingLocation()
       // locationManager.startMonitoringSignificantLocationChanges()
        self.locationManager.distanceFilter = 5.0 // used to be 10
       // self.locationManager.accuracyAuthorization =
        print("before cancel button")
        cancelButton.isHidden = false
        print("after cancel button")

    }
    
    @objc func getDirectionsTwo(){
        
        print("startDirectionsTwo")
        findingHash.updateValue(coldSound, forKey: selectedPinTwo!)
        findingPin = selectedPinTwo
        print("findingPin", findingPin?.name ?? "no name")
        getDirections()
        
    }
    
    @objc func getDirectionsOne(){
        
        print("startDirectionsOne")
        findingPin = selectedPin
        findingHash.updateValue(hotSound, forKey: selectedPin!)
        print("findingPin", findingPin?.name ?? "no name")
        getDirections()

        
    }
    
    func degreesToRadians(degrees: Double) -> Double { return degrees * .pi / 180.0 }
    
    func radiansToDegrees(radians: Double) -> Double { return radians * 180.0 / .pi }

    
    func getBearingBetweenTwoPoints1(point1 : CLLocation, point2 : CLLocation) -> Double {
     //   print("point1 ", point1.coordinate.latitude, " ", point1.coordinate.longitude)
      //  print("point2 ", point2.coordinate.latitude, " ", point2.coordinate.longitude)
        let lat1 = degreesToRadians(degrees: point1.coordinate.latitude)
        let lon1 = degreesToRadians(degrees: point1.coordinate.longitude)
        let lat2 = degreesToRadians(degrees: point2.coordinate.latitude)
        let lon2 = degreesToRadians(degrees: point2.coordinate.longitude)
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let radiansBearing = atan2(y, x)
        if(radiansBearing < 0){
           return (radiansToDegrees(radians: radiansBearing)) + 360
           // return radiansToDegrees(radians: radiansBearing)

        }
        else{
            return radiansToDegrees(radians: radiansBearing)
        }

        //south 0, west 90, north 180, east -90
        
    }
    
    func playSound(dir : Double, bar : Double, hot: Bool) {
      //  let degree = dir - bar
        print("baring ", bar )
        print("direction ", dir)
        
        let firstDegree = (bar - dir).truncatingRemainder(dividingBy: 360)
        let degree = ((firstDegree + 540).truncatingRemainder(dividingBy: 360)) - 180
        
        print("degree", degree)
        //do {
         //  here we can increase or decrease volume
             if(hot){
                if(volume < 1.0)
                {
                    volume += 0.2;
                    print("hot " , volume)
                }
            }
            else{
       
                if(volume > 0.0)
                {
                    volume -= 0.2;
                    print("cold " , volume)
                }
            }
            sleep(3)
            
            
            if(degree > 0)  // if destination on the right?
            {
                if(degree <= 90)
                {
                    pan = Float(degree/90)
                }
                else
                {
                    pan = Float(abs(degree/90-2))
                }
            }
            else // if destination on the left
            {
                if(degree >= -90)
                {
                    pan = Float(degree/90)
                }
                else
                {
                    pan = -(Float(degree/90)+2)
                }
            }
        audioPlayer.pan = pan
        audioPlayer.volume = volume
        audioPlayer.prepareToPlay() // make sure to add this line so audio will play
        audioPlayer.play()
            
            print("pan ", audioPlayer.pan)
            
            /*
             
             
            if(degree>40 && degree<130){
                audioPlayer.pan = 1.0 // right headphone
//                audioPlayer.
                /*
                audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                audioPlayer.play()
                */
            }
            else if(degree<(-40) && degree>(-130)){
                audioPlayer.pan = -1.0 //left headphone
              // audioPlayer.pan = 1.0 // right headphone
                /*
                audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                audioPlayer.play()
            */
            }
            else{
                audioPlayer.pan = 1.0 // right headphone
                /*
                audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                audioPlayer.play()
 */
            }
           
        */
      /*  }
            catch  {
            print("error")
        }*/
    }
    
 
    
}



extension ViewController : CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {

        print("change")
       // print("finding ",findingPin!.location!.coordinate.latitude, " ", findingPin!.location!.coordinate.latitude)
       // print("me ",locations.last!.coordinate.latitude, " ", locations.last!.coordinate.longitude)
        guard let location = locations.first else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
     //   for (pinToFind, soundToFind) in findingHash {
        for (pinToFind, _) in findingHash {
            print("pin", pinToFind.title ?? "no title")
            //  do {
            sleep(4)
                
                /*
            audioPlayer = try AVAudioPlayer(contentsOf: soundToFind as URL) //If not in asset
            audioPlayer.pan = 0
         
            audioPlayer.prepareToPlay() // make sure to add this line so audio will play
        
            audioPlayer.play()
 */
            /*  } catch{
                print("error")
            }*/
        }
        if(finding){
            
            if(lastLocation != nil){
                guard locations.last != nil else { return }
                if let findingLocation = findingPin?.location {
                   // var newDistance = location.distance(from: lastLocation!)
                    let coords = findingLocation.coordinate
              
                   // print("last ",lastLocation!.coordinate.latitude, " ", lastLocation!.coordinate.longitude)
                    let finder = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
                    let direction = getBearingBetweenTwoPoints1(point1: lastLocation!, point2: location)
                    let baring = getBearingBetweenTwoPoints1(point1: location, point2: finder)
                 //**   print("baring ", baring)
                 //***   print("direction ", direction)
                    
                    let distanceInMeters = location.distance(from: finder) // result is in meters
                   // *** print("distance ", distanceInMeters)
                    if(distance > 0){
                        if(distance < Int(distanceInMeters)){
                            playSound(dir: direction,bar: baring, hot: false)
                        }
                        else{
                            playSound(dir: direction,bar: baring, hot: true)
                        }
                        
                    }
                    else{ //can move
                       /* do {
                            sleep(1)
                            print("begin");
                            audioPlayer = try AVAudioPlayer(contentsOf: beginSound as URL) //If not in asset
                            audioPlayer.pan = pan
                            audioPlayer.volume = volume
                            audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                            audioPlayer.play()
                            print("can move")
                        } catch  {
                            print("error")
                        } */
                    }
                        distance = Int(distanceInMeters)
                }
            }
            else
            {
                do{
                audioPlayer = try AVAudioPlayer(contentsOf: locateSound as URL) //If not in asset
                }
                catch
                {
                        print("error playing begin")
                    
                }
            }
          
            lastLocation = location
        }
       

    }
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
    
}

extension ViewController: HandleMapSearch {
    
    func dropPinZoomIn(placemark: MKPlacemark){
        // cache the pin
        print("slected pin", pinCount )
        if(pinCount == 0){

            selectedPin = placemark
        }
      /*  else{
            selectedPinTwo = placemark
        } */
        // clear existing pins
      //  mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        
        if let city = placemark.locality,
            let state = placemark.administrativeArea {
            annotation.subtitle = "\(city) \(state)"
        }
        
        mapView.addAnnotation(annotation);
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
        mapView.setRegion(region, animated: true)
       
 
    }
    
}

extension ViewController : MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?{

      //  exit(0);
      
        guard !(annotation is MKUserLocation) else { return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinCount+=1
            print("pinCount is " , pinCount)
        }
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        // could throw a counter up top to change image.
        //if(pinCount == 1){
            button.setBackgroundImage(UIImage(named: "sound"), for: .normal)
            button.addTarget(self, action: #selector(ViewController.getDirectionsOne), for: .touchUpInside)

       // }
        /*
        else{
            button.setBackgroundImage(UIImage(named: "sound"), for: .normal)
            button.addTarget(self, action: #selector(ViewController.getDirectionsTwo), for: .touchUpInside)

        }
 */

        pinView?.leftCalloutAccessoryView = button
        
        return pinView
 /*
        let reuseId = "pin"
        guard let pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView else {
            let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            return pinView
        }
        pinView.annotation = annotation
        return pinView
 */
    }

}

