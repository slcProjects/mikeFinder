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
    var selectedPin: MKPlacemark?
    var findingPin: MKPlacemark?
    var distance = 0
    var lastLocation: CLLocation?
    var finding = false
    var resultSearchController: UISearchController!
    let locationManager = CLLocationManager()
    var heading = CLHeading()
    @IBOutlet weak var mapView: MKMapView!
    var audioPlayer = AVAudioPlayer()
    let hotSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "hot", ofType: "mp3")!) // If sound not in an assest
    let coldSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "cold", ofType: "mp3")!) // If sound not in an assest
    let beginSound = NSURL(fileURLWithPath: Bundle.main.path(forResource: "begin", ofType: "mp3")!) // If sound not in an assest

  //  let alertSound = NSDataAsset(name: "intro") // If sound is in an Asset


    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController.searchResultsUpdater = locationSearchTable
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "Search for places"
        navigationItem.titleView = resultSearchController?.searchBar
        resultSearchController.hidesNavigationBarDuringPresentation = false
        resultSearchController.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
        mapView.delegate = self
       /* let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(addWaypoint(longGesture:)))
        mapView.addGestureRecognizer(longGesture)
*/
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
        
        
    }
    /*
    @objc func addWaypoint(longGesture: UIGestureRecognizer) {
        
        let touchPoint = longGesture.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        mapView.addAnnotation(annotation)
    }
 */
    
    
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
        cancelButton.isHidden = true
    }
    @objc func getDirections(){

        print("startDirections")
        findingPin = selectedPin
        finding = true;
        mapView.userTrackingMode = .followWithHeading
        locationManager.startUpdatingLocation()
        cancelButton.isHidden = false

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
        let firstDegree = (bar - dir).truncatingRemainder(dividingBy: 360)
        let degree = ((firstDegree + 540).truncatingRemainder(dividingBy: 360)) - 180
        
        print("degree", degree)
        do {
            if(hot){
                audioPlayer = try AVAudioPlayer(contentsOf: hotSound as URL) //If not in asset
            }
            else{
                audioPlayer = try AVAudioPlayer(contentsOf: coldSound as URL) //If not in asset
            }
            if(degree>40 && degree<130){
                audioPlayer.pan = 1.0 // right headphone
                audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                audioPlayer.play()
            }
            else if(degree<(-40) && degree>(-130)){
                audioPlayer.pan = -1.0 //left headphone
              // audioPlayer.pan = 1.0 // right headphone
                audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                audioPlayer.play()
            }
            else{
                audioPlayer.pan = 1.0 // right headphone
                audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                audioPlayer.play()
            }
            
        } catch  {
            print("error")
        }
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
        guard let location = locations.first else { return }
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: location.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        if(finding){
            if(lastLocation != nil){
                guard locations.last != nil else { return }
                if let findingLocation = findingPin?.location {
                   // var newDistance = location.distance(from: lastLocation!)
                    let coords = findingLocation.coordinate
                   // print("finding ",coords.latitude, " ", coords.longitude)
                    //print("me ",location.coordinate.latitude, " ", location.coordinate.longitude)
                    print("last ",lastLocation!.coordinate.latitude, " ", lastLocation!.coordinate.longitude)
                    let finder = CLLocation(latitude: coords.latitude, longitude: coords.longitude)
                    let direction = getBearingBetweenTwoPoints1(point1: lastLocation!, point2: location)
                    let baring = getBearingBetweenTwoPoints1(point1: location, point2: finder)
                    print("baring ", baring)
                    print("direction ", direction)
                    
                    let distanceInMeters = location.distance(from: finder) // result is in meters
                    print("distance ", distanceInMeters)
                    if(distance > 0){
                        if(distance < Int(distanceInMeters)){
                            playSound(dir: direction,bar: baring, hot: false)
                        }
                        else{
                            playSound(dir: direction,bar: baring, hot: true)
                        }
                    }
                    else{
                        do {
                            audioPlayer = try AVAudioPlayer(contentsOf: beginSound as URL) //If not in asset
                            audioPlayer.pan = 0 // right headphone
                            audioPlayer.prepareToPlay() // make sure to add this line so audio will play
                            audioPlayer.play()
                        } catch  {
                            print("error")
                        }
                    }
                        distance = Int(distanceInMeters)
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
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
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
        }
        pinView?.pinTintColor = UIColor.orange
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), for: .normal)
        button.addTarget(self, action: #selector(ViewController.getDirections), for: .touchUpInside)
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

