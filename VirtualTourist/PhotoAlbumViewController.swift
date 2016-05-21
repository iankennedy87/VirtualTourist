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

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var newCollection: UIBarButtonItem!
    
    var photos: [Photo]!
    
    var pin: Pin!
    
    var imagesDownloaded: Bool = false

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        newCollection.enabled = false
        
        setFlowLayoutParameters()
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        fetchedResultsController.delegate = self

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        mapView.centerCoordinate = pin.coordinate
        mapView.addAnnotation(PinAnnotation(pin: pin))
        
        let mapWidth = mapView.frame.width
        let mapHeight = mapView.frame.height
        let ratio = Double(mapWidth/mapHeight)
        
        let span = MKCoordinateSpanMake(0.1,0.1 * ratio)
        let region = MKCoordinateRegionMake(pin.coordinate, span)
        self.mapView.region = region
        
        if pin.photosDownloaded {
            newCollection.enabled = true
        }
        
        if pin.photos.isEmpty {
            downloadPhotos()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
    }
    
    
    @IBAction func newCollection(sender: AnyObject) {
        //retrieve all photos assigned to pin
        let photos = fetchedResultsController.fetchedObjects as! [Photo]
        
        //remove image to delete from storage and delete from context
        for photo in photos {
            photo.image = nil
            photo.pin = nil
            sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }
        
        pin.photosDownloaded = false
        newCollection.enabled = false
        downloadPhotos()

    }
    
    func downloadPhotos() {
        FlickrClient.sharedInstance().downloadUrlsForPin(pin, completionHandler: {
            if !self.pin.photosDownloaded {
                
                FlickrClient.sharedInstance().downloadFlickrImages(self.pin.photos) { (success) in
                    if success {
                        self.pin.photosDownloaded  = true
                        CoreDataStackManager.sharedInstance().saveContext()
                        self.newCollection.enabled = true
                        
                        dispatch_async(dispatch_get_main_queue(), {
                            if (self.isViewLoaded() && (self.view.window != nil)) {
                                let alert = UIAlertController(title: nil, message: "Image download complete", preferredStyle: .Alert)
                                alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                                self.presentViewController(alert, animated: true, completion: nil)
                            }
                        })
                    }
                }
            } else {
                self.newCollection.enabled = true
            }
        })
    }
    
    //Reset flow layout if phone is rotated
    override func didRotateFromInterfaceOrientation(fromInterfaceOrientation: UIInterfaceOrientation) {
        setFlowLayoutParameters()
    }
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    func setFlowLayoutParameters() {
        var dimension: CGFloat
        let space: CGFloat = 3.0
        flowLayout.minimumLineSpacing = space
        flowLayout.minimumInteritemSpacing = space

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
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cellIdentifier = "PhotoCell"
        
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellIdentifier, forIndexPath: indexPath) as! PhotoCollectionViewCell
        
        configureCell(cell, photo: photo)
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        if pin.photosDownloaded {
            let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            
            //Set image to nil to delete image from cache and hard drive using storeImage function in ImageCache
            photo.image = nil
            
            photo.pin = nil
            
            //Delete photo from context and save context to update collection view
            sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        }

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
            if let cell = collectionView.cellForItemAtIndexPath(indexPath!) as? PhotoCollectionViewCell {
                let photo = controller.objectAtIndexPath(indexPath!) as! Photo
                self.configureCell(cell, photo: photo)
            }
            
        case .Move:
            collectionView.deleteItemsAtIndexPaths([indexPath!])
            collectionView.insertItemsAtIndexPaths([newIndexPath!])
            
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {

    }
    
    func configureCell(cell: PhotoCollectionViewCell, photo: Photo) {
        let placeholderImage = UIImage(named: "Placeholder")
        
        cell.photoImage!.image = nil
        
        //If photo already has an image assigned, make it the cell image
        if let localImage = photo.image {
            cell.photoImage.image = UIImage(data: localImage)
        } else {
            //if not, set the cell image to the placeholder while the image downloads
            cell.photoImage?.image = placeholderImage
            
        }
        
    }
}

