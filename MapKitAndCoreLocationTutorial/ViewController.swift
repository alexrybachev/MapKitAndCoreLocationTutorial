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
        
    }
    
    @objc fileprivate func startStopButtonTapped() {
        
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
        
    }
    
    fileprivate func getRouteSteps(route: MKRoute) {
        
    }
}

extension ViewController: CLLocationManagerDelegate {
    
}

extension ViewController: MKMapViewDelegate {
    
}
