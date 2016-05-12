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

class CollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
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
        //print("Flicks length: \(flicks.count)")
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
        flicks = fetchedResultsController.fetchedObjects as! [Flick]
        //print("first flick: \(flicks[0].photoPath)")
        
        FlickrClient.sharedInstance().downloadFlickrImages(flicks) { (success) in
            if success {
                let alert = UIAlertController(title: nil, message: "Image download complete", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        setFlowLayoutParameters()
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Flick")
        
        fetchRequest.sortDescriptors = []
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
        let sectionInfo = self.fetchedResultsController.sections![section]
        //print("Number of cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellIdentifier = "FlickCell"
        
        let flick = fetchedResultsController.objectAtIndexPath(indexPath) as! Flick
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! FlickCollectionViewCell
        
        configureCell(cell, flick: flick)
        
        return cell
        
        // Set the image
//        if let localImage = flick.image {
//            //print("used local image")
//            cell.flickImage.image = localImage
//        } else {
//            //print("downloading image")
//            cell.flickImage?.image = UIImage(named: "Placeholder")
//            
//            let task = FlickrClient.sharedInstance().taskForDownloadImage(flick.imageUrl, completionHandler: { (imageData, error) in
//                if let data = imageData {
//                    dispatch_async(dispatch_get_main_queue(), { 
//                        let image = UIImage(data: data)
//                        flick.image = image
//                        cell.flickImage.image = image
//                    })
//                }
//            })
//            
//            cell.taskToCancelifCellIsReused = task
//        }
//        
//        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        
    }
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
    }
    
    func controller(controller: NSFetchedResultsController,
                    didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
                                     atIndex sectionIndex: Int,
                                             forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
        case .Insert:
            collectionView.insertSections(NSIndexSet(index: sectionIndex))
            
        case .Delete:
            collectionView.deleteSections(NSIndexSet(index: sectionIndex))
            
        default:
            return
        }
    }
    //
    // This is the most interesting method. Take particular note of way the that newIndexPath
    // parameter gets unwrapped and put into an array literal: [newIndexPath!]
    //
    func controller(controller: NSFetchedResultsController,
                    didChangeObject anObject: AnyObject,
                                    atIndexPath indexPath: NSIndexPath?,
                                                forChangeType type: NSFetchedResultsChangeType,
                                                              newIndexPath: NSIndexPath?) {

        
        switch type {
        case .Insert:
            collectionView.insertItemsAtIndexPaths([newIndexPath!])
            
        case .Delete:
            collectionView.deleteItemsAtIndexPaths([indexPath!])
            
        case .Update:
            if let cell = collectionView.cellForItemAtIndexPath(indexPath!) as? FlickCollectionViewCell {
                let flick = controller.objectAtIndexPath(indexPath!) as! Flick
                self.configureCell(cell, flick: flick)
            }
            
            
            
        case .Move:
            collectionView.deleteItemsAtIndexPaths([indexPath!])
            collectionView.insertItemsAtIndexPaths([newIndexPath!])
            
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

    }
    
    func configureCell(cell: FlickCollectionViewCell, flick: Flick) {
        var posterImage = UIImage(named: "Placeholder")
        
        cell.flickImage!.image = nil
        
        if let localImage = flick.image {
            //print("used local image")
            cell.flickImage.image = localImage
        } else {
            //print("downloading image")
            cell.flickImage?.image = posterImage
            
//            let task = FlickrClient.sharedInstance().taskForDownloadImage(flick.imageUrl, completionHandler: { (imageData, error) in
//                if let data = imageData {
//                    let image = UIImage(data: data)
//                    flick.image = image
//                    
//                    dispatch_async(dispatch_get_main_queue(), {
//                        cell.flickImage.image = image
//                    })
//                }
//            })
            
//            cell.taskToCancelifCellIsReused = task
        }
        
    }
}

