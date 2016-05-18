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
    
    var numCells: Int?
    
    var imageUrls = [String]()
    
    var flicks = [Flick]()
    
    var pins: [Pin]!
    
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self

//        let coordinate = CLLocationCoordinate2DMake(FlickrClient.Constants.Flickr.DefaultSearchLatitude, FlickrClient.Constants.Flickr.DefaultSearchLongitude)
//        self.mapView.centerCoordinate = coordinate
//        let span = MKCoordinateSpanMake(0.1,0.1)
//        let region = MKCoordinateRegionMake(coordinate, span)
//        self.mapView.region = region
        //Add long press recognizer to map
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(MapViewController.addAnnotation(gestureRecognizer:)))
        longPressRecognizer.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressRecognizer)
        
        //Fetches all pins from Core Data and adds them to map
        pins = fetchAllPins()
        //Test: print("Pin count: \(pins.count)")
        addPins(pins)
        
    }
    
    func addAnnotation(gestureRecognizer gestureRecognizer: UILongPressGestureRecognizer) {
        //Check duplicate pin is not added after long press is released
        if (gestureRecognizer.state == .Began) {
            //Get coordinates for pin drop on the map
            let touchPoint = gestureRecognizer.locationInView(mapView)
            let newCoordinates = mapView.convertPoint(touchPoint, toCoordinateFromView: mapView)
            print("Coordinates: \(newCoordinates)")
            //Add pin object to pin array and save context
            pins.insert(Pin(coordinate: newCoordinates, context: sharedContext), atIndex: 0)
            //Test: print("Pin added. Pin count: \(pins.count)")
            CoreDataStackManager.sharedInstance().saveContext()
            
            //Drop pin on map at coordinates from long press
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            annotation.title = "dropped pin"
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
    
    func fetchAllFlicks() -> [Flick] {
        let fetchRequest = NSFetchRequest(entityName: "Flick")
        
        do {
            return try sharedContext.executeFetchRequest(fetchRequest) as! [Flick]
        } catch {
            print("Error in fetchAllFlicks: \(error)")
            return [Flick]()
        }
    }
    
    func addPins(pins: [Pin]) -> Void {
        for pin in pins {
            let annotation = MKPointAnnotation()
            let coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
            annotation.coordinate = coordinate
            annotation.title = "title"
            mapView.addAnnotation(annotation)
        }
    }
    
    func mapView(mapView: MKMapView, didAddAnnotationViews views: [MKAnnotationView]) {
        print("annotation view added")
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        
        let annotation = view.annotation!
        mapView.deselectAnnotation(annotation, animated: true)

        let coordinate = annotation.coordinate
        print("Clicked coordinates: \(coordinate)")
        
        flicks = fetchAllFlicks()
        
        if flicks.isEmpty {
            print("No flicks")
            button.enabled = false
            FlickrClient.sharedInstance().searchByLatLon(coordinate: coordinate) { (result, error) in
                guard (error == nil) else {
                    print("Encountered error pushing to collection view")
                    return
                }
                
                guard let photosDictionary = result as? [String: AnyObject] else {
                    print("Result is not a dictionary")
                    return
                }
                
                
                guard let numberOfPhotos = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Total] as? String else {
                    print("Didn't find total in photos dictionary")
                    return
                }
                
                //self.numCells = Int(numberOfPhotos)
                
                guard let photosArray = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    return
                }
                
                
//                if photosArray.count > 21 {
//                    for photo in photosArray[0...21] {
//                        print("more than 21 pics")
//                        let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
//                        _ = Flick(url: imageUrl, context: self.sharedContext)
//                        CoreDataStackManager.sharedInstance().saveContext()
//                    }
//                } else {
//                    for photo in photosArray {
//                        let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
//                        _ = Flick(url: imageUrl, context: self.sharedContext)
//                        CoreDataStackManager.sharedInstance().saveContext()
//                    }
//                }
                
                if photosArray.count > 0 {
                    for index in 0...min(20, photosArray.count) {
                        let photo = photosArray[index] 
                        let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
                        _ = Flick(url: imageUrl, context: self.sharedContext)
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                } else {
                    print("no photos")
                }
                
//                for index in 0...21 {
//                    print(index)
//                    print(photosArray[index])
//                    let photo = photosArray[index] as! [String: AnyObject]
//                    let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
//                    _ = Flick(url: imageUrl, context: self.sharedContext)
//                    CoreDataStackManager.sharedInstance().saveContext()
//                }
                
//                for photo in photosArray {
//                    let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
//                    _ = Flick(url: imageUrl, context: self.sharedContext)
//                    CoreDataStackManager.sharedInstance().saveContext()
//                }
                
                dispatch_async(dispatch_get_main_queue(), {
                    
                    self.button.enabled = true
                    let collectionView = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController") as! CollectionViewController
                    self.navigationController?.pushViewController(collectionView, animated: true)
                    
                })
            }
        } else {
            let collectionView = self.storyboard!.instantiateViewControllerWithIdentifier("CollectionViewController") as! CollectionViewController
            navigationController?.pushViewController(collectionView, animated: true)
        }
        
    }

    
}