//
//  ViewController.swift
//  MapKitAndCoreLocationTutorial
//
//  Created by Aleksandr Rybachev on 06.05.2022.
//

/*
 Проект сделан по уроку https://youtu.be/5fWG5ofhHsY
 */

import UIKit
import MapKit
import CoreLocation
import AVFoundation
import Layoutless

class ViewController: UIViewController {
    
    var steps: [MKRoute.Step] = []
    var stepCounter = 0
    var route: MKRoute?
    var showMapRoute = false
    var navigationStarted = false
    let locationDistance = 500.0
    
    var speechSynthesizer = AVSpeechSynthesizer()
    
    lazy var locationManager: CLLocationManager = {
        let locationManager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            handleAuthorizationStatus(locationManager: locationManager, status: CLLocationManager.authorizationStatus())
        } else {
            print("Location services are not enabled")
        }
        
        return locationManager
    }()
    
    lazy var directionLabel: UILabel = {
        let label = UILabel()
        label.text = "Where do you want to go?"
        label.font = .boldSystemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    lazy var textfield: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter your destination"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    lazy var getDirectionButton: UIButton = {
        let button = UIButton()
        button.setTitle("Get Direction", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(getDirectionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var startStopButton: UIButton = {
        let button = UIButton()
        button.setTitle("Start Navigation", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.addTarget(self, action: #selector(startStopButtonTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.delegate = self
        mapView.showsUserLocation = true
        return mapView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.overrideUserInterfaceStyle = .light
        setupViews()
        locationManager.startUpdatingLocation()
    }
    
    @objc fileprivate func getDirectionButtonTapped() {
        guard let text = textfield.text else { return }
        showMapRoute = true
        textfield.endEditing(true)
        
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(text) { placemarks, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let placemarks = placemarks,
                  let placemark = placemarks.first,
                  let location = placemark.location
            else { return }
            
            let destinationCoordinate = location.coordinate
            
            self.mapRoute(destinationCoordinate: destinationCoordinate)
        }
    }
    
    @objc fileprivate func startStopButtonTapped() {
        if !navigationStarted {
            showMapRoute = true
            if let location = locationManager.location {
                let center = location.coordinate
                centerViewToUserLocation(center: center)
            }
        } else {
            if let route = route {
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                               edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                               animated: true)
                self.steps.removeAll()
                self.stepCounter = 0
            }
        }
        
        navigationStarted.toggle()
        
        startStopButton.setTitle(navigationStarted ? "Stop Navigation" : "Start Navigation", for: .normal)
    }
    
    fileprivate func setupViews() {
        view.backgroundColor = .systemBackground
        
        stack(.vertical) (
            directionLabel.insetting(by: 16),
            stack(.horizontal, spacing: 16)(
                textfield,
                getDirectionButton
            ).insetting(by: 16),
            startStopButton.insetting(by: 16),
            mapView
        ).fillingParent(relativeToSafeArea: true).layout(in: view)
    }
    
    fileprivate func centerViewToUserLocation(center: CLLocationCoordinate2D) {
        let region = MKCoordinateRegion(center: center,
                                        latitudinalMeters: locationDistance,
                                        longitudinalMeters: locationDistance)
        mapView.setRegion(region, animated: true)
    }
    
    fileprivate func handleAuthorizationStatus(locationManager: CLLocationManager, status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted:
            //
            break
        case .denied:
            //
            break
        case .authorizedAlways:
            //
            break
        case .authorizedWhenInUse:
            if let center = locationManager.location?.coordinate {
                centerViewToUserLocation(center: center)
            }
            break
        case .authorized:
            //
            break
        @unknown default:
            print("new case")
            break
        }
    }
    
    fileprivate func mapRoute(destinationCoordinate: CLLocationCoordinate2D) {
        guard let sourceCoordinate = locationManager.location?.coordinate else { return }
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
        let destinationPlacemark = MKPlacemark(coordinate: destinationCoordinate)
        
        let sourceItem = MKMapItem(placemark: sourcePlacemark)
        let destinationItem = MKMapItem(placemark: destinationPlacemark)
        
        let routeRequest = MKDirections.Request()
        routeRequest.source = sourceItem
        routeRequest.destination = destinationItem
        routeRequest.transportType = .walking
        
        let directions = MKDirections(request: routeRequest)
        
        directions.calculate { response, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            guard let response = response, let route = response.routes.first else { return }
            
            self.route = route
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect,
                                           edgePadding: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16),
                                           animated: true)
           
            self.getRouteSteps(route: route)
        }
    }
    
    fileprivate func getRouteSteps(route: MKRoute) {
        for monitoredRegions in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: monitoredRegions)
        }
        
        let steps = route.steps
        self.steps = steps
        
        for i in 0..<steps.count {
            let step = steps[i]
            print(step.instructions)
            print(step.distance)
            
            let region = CLCircularRegion(center: step.polyline.coordinate, radius: 20, identifier: "\(i)")
            locationManager.startMonitoring(for: region)
        }
        
        stepCounter += 1
        let initialMessage = "In \(steps[stepCounter].distance) meters \(steps[stepCounter].instructions), then in \(steps[stepCounter + 1].distance) meters \(steps[stepCounter + 1].instructions)"
        directionLabel.text = initialMessage
        
        let speechUtterance = AVSpeechUtterance(string: initialMessage)
        speechSynthesizer.speak(speechUtterance)
    }
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !showMapRoute {
            if let location = locations.last {
                let center = location.coordinate
                centerViewToUserLocation(center: center)
            }
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        handleAuthorizationStatus(locationManager: manager, status: CLLocationManager.authorizationStatus())
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        stepCounter += 1
        if stepCounter < steps.count {
            let message = "In \(steps[stepCounter].distance) meters \(steps[stepCounter].instructions), then in \(steps[stepCounter + 1].distance) meters \(steps[stepCounter + 1].instructions)"
            directionLabel.text = message
            
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            speechSynthesizer.speak(speechUtterance)
        } else {
            let message = "You have arrived at your destination"
            directionLabel.text = message
            stepCounter = 0
            navigationStarted = false
            
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            
            for monitoredRegion in locationManager.monitoredRegions {
                locationManager.stopMonitoring(for: monitoredRegion)
            }
        }
    }
}

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .blue
        return renderer
    }
}
