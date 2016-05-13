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

class MapViewController: UIViewController {
    
    var numCells: Int?
    
    var imageUrls = [String]()
    
    var flicks = [Flick]()
    
    @IBOutlet weak var button: UIButton!
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let coordinate = CLLocationCoordinate2DMake(FlickrClient.Constants.Flickr.DefaultSearchLatitude, FlickrClient.Constants.Flickr.DefaultSearchLongitude)
        self.mapView.centerCoordinate = coordinate
        let span = MKCoordinateSpanMake(0.1,0.1)
        let region = MKCoordinateRegionMake(coordinate, span)
        self.mapView.region = region
        
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
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    @IBAction func push(sender: AnyObject) {
        
        flicks = fetchAllFlicks()
        
        if flicks.isEmpty {
            print("No flicks")
            button.enabled = false
            FlickrClient.sharedInstance().searchByLatLon(FlickrClient.Constants.Flickr.DefaultSearchLatitude, longitude: FlickrClient.Constants.Flickr.DefaultSearchLongitude) { (result, error) in
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
                
                self.numCells = Int(numberOfPhotos)
                
                guard let photosArray = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                    return
                }
                
                
                for photo in photosArray {
                    let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
                    let newFlick = Flick(url: imageUrl, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
                
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