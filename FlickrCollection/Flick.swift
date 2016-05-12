//
//  Flick.swift
//  FlickrCollection
//
//  Created by Ian Kennedy on 5/8/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import UIKit
import CoreData

class Flick: NSManagedObject {
    
    @NSManaged var imageUrl: String
    @NSManaged var photoPath: String
    @NSManaged var imageDownloaded: Bool
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(url: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Flick", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageUrl = url
        imageDownloaded = false
        let url = NSURL(fileURLWithPath: url)
        let lastComponent = url.lastPathComponent!
        photoPath = lastComponent
    }
    
    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(photoPath)
        }
        
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: photoPath)
        }
    }
    
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }

}