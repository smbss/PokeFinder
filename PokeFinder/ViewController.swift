//
//  ViewController.swift
//  PokeFinder
//
//  Created by smbss on 05/10/2016.
//  Copyright © 2016 smbss. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
        // Bool to know when to center the map
    var mapHasCenteredOnce = false
        // Initializing GeoFire element - With Geofire is easy to retrieve sorrounding location data
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
            // Setting the mapView to track the user
        mapView.userTrackingMode = MKUserTrackingMode.follow
        mapView.mapType = MKMapType.hybrid
        
            // Creating the Firebase Reference
        geoFireRef = FIRDatabase.database().reference()
            // Initializing GeoFire with that reference
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    
    override func viewDidAppear(_ animated: Bool) {
            // This will run everytime the view appears
        
        locationAuthStatus()
    }
    
        // Checking if the user already gave permission to access location
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        
    }

        // Centering the map on the location
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
            // (geoPoint, xZoom, yZoom)
        
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
        // Acting when location is updated
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location {
            
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
        }
        
    }
    
        // Creating the sprite for the user location
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Whenever mapView.addAnnotation() is called, this will be executed
            // This is where the annotation is customized
        
        let annoIdentifier = "Pokemon"
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
                // Creating user location sprite
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
                // Reusing annotations
            annotationView = deqAnno
            annotationView?.annotation = annotation
        } else {
                // Creating a new annotation if we can't deque one
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }
        
            // Customizing the annotation
            // Making sure that annotationView is not nil and anno is a PokeAnnotation
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation {
            
                // Making the annotation display a callout [!] The annotation needs to have a title
            annotationView.canShowCallout = true
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
                // Creating the little button for the map
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
        }
        
        return annotationView
    }
    
    func createSighting(forLocation location: CLLocation, withPokemon pokeId: Int) {
        
        geoFire.setLocation(location, forKey: "\(pokeId)")
    }
    
    func showSightingsOnMap(location: CLLocation) {
        
            // Making a circle query with 2.5 km radius - rectangle query also available
        let circleQuery = geoFire.query(at: location, withRadius: 2.5)
        
            // Observe sightings - if we had 50 pkm in that 2.5 radius this would be called 50 times
        _ = circleQuery?.observe(GFEventType.keyEntered, with: { (key, location) in
            
                // Making sure that key and location exist
            if let key = key, let location = location {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                    // Adding that annotation to the mapView
                self.mapView.addAnnotation(anno)
            }
            
        })
    }
    
        // Updating the mapView when the region changes
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
        showSightingsOnMap(location: loc)
    }
    
        // Acting when the map callout button is pressed
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnnotation {
                // Create a place for the Apple map
            var place: MKPlacemark!
            if #available(iOS 10.0, *) {
                place = MKPlacemark(coordinate: anno.coordinate)
            } else {
                place = MKPlacemark(coordinate: anno.coordinate, addressDictionary: nil)
            }
            let destination = MKMapItem(placemark: place)
            destination.name = "Pokemon Sighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
                // Configuring options like center, span and directions method (walking, driving...)
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
        }
        
    }
    
    @IBAction func spotRandomPokemon(_ sender: UIButton) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        
            // Choosing a random pokemon
        let rand = arc4random_uniform(151) + 1
            // (upper boundary) + lower boundary
        createSighting(forLocation: loc, withPokemon: Int(rand))
    }
    
}

