//
//  PinAnnotation.swift
//  FlickrCollection
//
//  Created by Ian Kennedy on 5/18/16.
//  Copyright © 2016 Udacity. All rights reserved.
//

import Foundation
import MapKit

class PinAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var pin: Pin?
    
    init(pin: Pin) {
        self.coordinate = pin.coordinate
        self.pin = pin
        title = "Dropped Pin"
    }
    
}
