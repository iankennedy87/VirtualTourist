//
//  FlickrClient.swift
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

class FlickrClient: NSObject {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    var session = NSURLSession.sharedSession()
    
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    private func bboxString(coordinate: CLLocationCoordinate2D) -> String {
        // ensure bbox is bounded by minimum and maximums
        
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
        let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
        let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
        let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    
    func searchByLatLon(coordinate coordinate: CLLocationCoordinate2D, searchCompletionHandler: CompletionHandler) -> Void {
        let methodParameters = [
            Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParameterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
            Constants.FlickrParameterKeys.BoundingBox: bboxString(coordinate),
            Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch,
            Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParameterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback
        ]
        
        flickrPhotoSearch(methodParameters, completionHandler: searchCompletionHandler)
    }
    
    private func flickrPhotoSearch(methodParameters: [String:AnyObject], completionHandler: CompletionHandler) {
        
        // create session and request
        let session = NSURLSession.sharedSession()
        let request = NSURLRequest(URL: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(error: String) {
                print(error)
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[Constants.FlickrResponseKeys.Status] as? String where stat == Constants.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(Constants.FlickrResponseKeys.Photos)' in \(parsedResult)")
                return
            }
            
            //Call completion handler with photos dictionary
            completionHandler(result: photosDictionary, error: nil)

            
        }
        
        // start the task!
        task.resume()
    }
    
    //take a pin and download urls
    func downloadUrlsForPin(pin: Pin, completionHandler: () -> Void) {
        let coordinate = pin.coordinate
        FlickrClient.sharedInstance().searchByLatLon(coordinate: coordinate) { (result, error) in
            guard (error == nil) else {
                print("Encountered error pushing to collection view")
                return
            }
            
            guard let photosDictionary = result as? [String: AnyObject] else {
                print("Result is not a dictionary")
                return
            }
            
            guard let _ = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Total] as? String else {
                print("Didn't find total in photos dictionary")
                return
            }
            
            guard let photosArray = photosDictionary[FlickrClient.Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                return
            }
            
            let group = dispatch_group_create()
            
            if photosArray.count > 0 {
                for index in 0...min(20, photosArray.count-1) {
                    dispatch_group_enter(group)
                    let photo = photosArray[index]
                    let imageUrl = photo[FlickrClient.Constants.FlickrResponseKeys.MediumURL] as! String
                    let newFlick = Photo(url: imageUrl, context: self.sharedContext)
                    newFlick.pin = pin
                    CoreDataStackManager.sharedInstance().saveContext()
                    dispatch_group_leave(group)
                }
            }
            
            dispatch_group_notify(group, dispatch_get_main_queue(), { 
                completionHandler()
            })
        }
    }

    func taskForDownloadImage(url: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
        
        let imageUrl = NSURL(string: url)
        
        let request = NSURLRequest(URL: imageUrl!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            if let newError = error {
                print(error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    func downloadFlickrImages(photos: [Photo], downloadCompletionHandler: (success: Bool) -> Void) -> Void {
        
        let group = dispatch_group_create()
        
        for photo in photos {
            if photo.image == nil {
                dispatch_group_enter(group)
                _ = taskForDownloadImage(photo.imageUrl, completionHandler: { (imageData, error) in
                    if let data = imageData {
                        dispatch_async(dispatch_get_main_queue(), {
                            //let image = UIImage(data: data)
                            photo.image = data
                            photo.imageDownloaded = true
                            CoreDataStackManager.sharedInstance().saveContext()
                        })
                        dispatch_group_leave(group)
                    }
                })
            }
        }
        
        dispatch_group_notify(group, dispatch_get_main_queue()) { 
            downloadCompletionHandler(success: true)
        }
        
    }
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> NSURL {
        
        let components = NSURLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    class func sharedInstance() -> FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        return Singleton.sharedInstance
    }

}