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

        // Bool to know when to center the map
    var mapHasCenteredOnce = false
        // Initializing GeoFire element - With Geofire is easy to retrieve sorrounding location data
    var geoFire: GeoFire!
    var geoFireRef: FIRDatabaseReference!
    
    var locationManager: CLLocationManager!
    var selectedPkmn: Pokemon?

    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        
        mapView.delegate = self
        
            // Setting the mapView to track the user
        mapView.userTrackingMode = MKUserTrackingMode.follow
        mapView.mapType = MKMapType.hybrid
        
            // Creating the Firebase Reference
        geoFireRef = FIRDatabase.database().reference()
            // Initializing GeoFire with that reference
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        guard selectedPkmn?.pokedexId == nil else {
            let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
            createSighting(forLocation: loc, withPokemon: (selectedPkmn?.pokedexId)!)
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
            // Runs when CLLocationManager is instanciated (viewDidLoad)
        switch status {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            break
        default:
                // Other cases: .denied .restricted and .authorizedAlways
                // Not relevant to deal with .authorizedAlways because we won't ask it in this app
            showAlert(title: "Location not found", message: "Please authorize access to your location in order to use the app", buttonText: "Ok")
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
            annotationView.image = anno.pokemonImage
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
                let pkmn = Pokemon(pokedexId: Int(key)!)
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemon: pkmn)
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
    
    func showAlert(title: String, message: String, buttonText: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonText, style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}
