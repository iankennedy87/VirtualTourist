//
//  MapViewController.swift
//  FlickrCollection
//
//  Created by Ian Kennedy on 5/8/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var pins: [Pin]!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self

        //Add long press recognizer to map
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(gestureRecognizer:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
        
        //Fetches all pins from Core Data and adds them to map
        pins = fetchAllPins()

        addPins(pins)
        
    }
    
    func addAnnotation(gestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) {
        //Check duplicate pin is not added after long press is released
        if (gestureRecognizer.state == .Began) {
            
            //Get coordinates for pin drop on the map
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            
            //Add pin object to pin array and save context
            let newPin = Pin(coordinate: newCoordinates, context: sharedContext)
            pins.insert(newPin, atIndex: 0)
            CoreDataStackManager.sharedInstance().saveContext()
            
            //Drop pin on map at coordinates from long press
            let annotation = PinAnnotation(pin: newPin)
            annotation.coordinate = newCoordinates
            //annotation.title = "dropped pin"
            mapView.addAnnotation(annotation)
        }
        
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func fetchAllPins() -> [Pin] {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Error in fetchAllPins(): \(error)")
            return [Pin]()
        }
    }
    
    
    func addPins(pins: [Pin]) -> Void {
        for pin in pins {
            //let coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
            let annotation = PinAnnotation(pin: pin)
            mapView.addAnnotation(annotation)
        }
    }

    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        //retrieve pin from annotation view and deselect pin
        let annotation = view.annotation! as! PinAnnotation
        let pin = annotation.pin!
        mapView.deselectAnnotation(annotation, animated: true)
        
        
        let collectionView = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbumViewController")  as! PhotoAlbumViewController
        collectionView.pin = pin
        self.navigationController!.pushViewController(collectionView, animated: true)

    }
}