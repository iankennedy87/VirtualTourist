//
//  ViewController.swift
//  FlickrCollection
//
//  Created by Ian Kennedy on 5/8/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit
import MapKit
import CoreData

class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var numberOfCells: Int?
    
    var flicks: [Flick]!
    
    var imageUrls: [String]!

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        
        setFlowLayoutParameters()
        
//        do {
//            try fetchedResultsController.performFetch()
//        } catch {}
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        setFlowLayoutParameters()
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Flick")
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    func setFlowLayoutParameters() {
        var dimension: CGFloat
        let space: CGFloat = 3.0
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space
//        dimension = (view.frame.size.width - (2 * space)) / 3.0
        switch UIDevice.currentDevice().orientation {
        case .Portrait, .PortraitUpsideDown:
            
            dimension = (view.frame.size.width - (2 * space)) / 3.0
        case .LandscapeLeft, .LandscapeRight:
            dimension = (view.frame.size.width - (4 * space)) / 5.0
        default:
            dimension = 1.0
        }
        flowLayout.itemSize = CGSizeMake(dimension, dimension)
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfCells!
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let flick = flicks[indexPath.row]
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickCell", forIndexPath: indexPath) as! FlickCollectionViewCell
        
        // Set the image
        if let localImage = flick.image {
            //print("used local image")
            cell.flickImage.image = localImage
        } else {
            //print("downloading image")
            cell.flickImage?.image = UIImage(named: "Placeholder")
            
            let task = FlickrClient.sharedInstance().taskForDownloadImage(flick.imageUrl, completionHandler: { (imageData, error) in
                if let data = imageData {
                    dispatch_async(dispatch_get_main_queue(), { 
                        let image = UIImage(data: data)
                        flick.image = image
                        cell.flickImage.image = image
                    })
                }
            })
            
            cell.taskToCancelifCellIsReused = task
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        
    }
}

