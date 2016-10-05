//
//  ViewController.swift
//  PokeFinder
//
//  Created by Sandro Simes on 05/10/2016.
//  Copyright © 2016 smbss. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
        // Bool to know when to center the map
    var mapHasCenteredOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
            // Setting the mapView to track the user
        mapView.userTrackingMode = MKUserTrackingMode.follow
        mapView.mapType = MKMapType.hybrid
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
        
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        }
        
        return annotationView
    }
    
    @IBAction func spotRandomPokemon(_ sender: UIButton) {
    }
    
}

