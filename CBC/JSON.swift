//
//  JSON.swift
//  TWU
//
//  Created by Steve Leeke on 10/4/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

/**

 Handles JSON retrieval and storage
 
 Properties:
    - url to get json from
    - filename for saving json
    - operation queue for managing saving
 */

class JSON
{
    deinit {
        operationQueue.cancelAllOperations()
        debug(self)
    }
    
    var url:String?
    {
        get {
            return Constants.JSON.URL.MEDIA
        }
    }
    
    var filename:String?
    {
        get {
            return Constants.JSON.ARRAY_KEY.MEDIA_ENTRIES + Constants.JSON.FILENAME_EXTENSION
        }
    }

//    var format:String?
//    {
//        get {
//            let defaults = UserDefaults.standard
//            
//            return defaults.string(forKey: Constants.FORMAT)
//        }
//        
//        set {
//            let defaults = UserDefaults.standard
//            if (newValue != nil) {
//                defaults.set(newValue,forKey: Constants.FORMAT)
//            } else {
//                defaults.removeObject(forKey: Constants.FORMAT)
//            }
//            defaults.synchronize()
//        }
//    }
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "JSON"
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    func load(filename:String?, key:String) -> [[String:Any]]?
    {
        guard let json = filename?.fileSystemURL?.data?.json as? [String:Any] else {
            print("could not get json from file, make sure that file contains valid json.")
            return nil
        }
        
        return json[key] as? [[String:Any]]
    }
    
    func get(urlString:String?, filename:String?) -> Any?
    {
        guard Globals.shared.reachability.isReachable else {
            return filename?.fileSystemURL?.data?.json
        }
        
        guard let data = urlString?.url?.data else {
            return filename?.fileSystemURL?.data?.json
        }
        
        if data.json != nil {
            operationQueue.addOperation {
                _ = data.save(to: filename?.fileSystemURL)
            }
        }
        
        return data.json
    }
    
    func load(urlString:String?, key:String, filename:String?) -> [[String:Any]]?
    {
        guard let json = get(urlString: urlString, filename: filename) as? [String:Any] else {
            print("could not get json from url, make sure that url contains valid json.")
            return nil
        }
        
        return json[key] as? [[String:Any]]
    }
}
