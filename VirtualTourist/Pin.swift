//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Ian Kennedy on 5/3/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Pin: NSManagedObject {
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
    }
    
    @NSManaged var longitude: CLLocationDegrees
    @NSManaged var latitude: CLLocationDegrees
    @NSManaged var photosDownloaded: Bool
    @NSManaged var photos: [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        longitude = coordinate.longitude
        latitude = coordinate.latitude
        photosDownloaded = false
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
}