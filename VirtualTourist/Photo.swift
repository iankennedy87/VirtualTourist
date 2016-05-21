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

class Photo: NSManagedObject {
    
    @NSManaged var imageUrl: String
    @NSManaged var photoPath: String
    @NSManaged var imageDownloaded: Bool
    @NSManaged var pin: Pin?
    @NSManaged var image: NSData?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(url: String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        imageUrl = url
        imageDownloaded = false
        let url = NSURL(fileURLWithPath: url)
        let lastComponent = url.lastPathComponent!
        photoPath = lastComponent
    }

}