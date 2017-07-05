//
//  VoiceBase.swift
//  CBC
//
//  Created by Steve Leeke on 6/27/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

extension NSMutableData {
    func appendString(_ string: String) {
        let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false)
        append(data!)
    }
}

extension VoiceBase // Class Methods
{
    static func delete(mediaID:String?)
    {
        print("VoiceBase.delete")

        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media/\(mediaID)"
        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode as Any)
            if let data = data {
                //                let string = String.init(data: data!, encoding: String.Encoding.utf8)
                //                print(string as Any) // object name
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String : Any] {
                    print(json)
                } else {
                    // JSONSerialization.jsonObject call failed
                    
                }
            } else {
                // No data
                
            }
            
            if let response = response {
                print("class delete response: ",response.description)
            }
            
            if let error = error {
                print("class delete error: ",error.localizedDescription)
            }
        })
        
        task.resume()
    }
    
    static func getAllMedia(completion:((Void)->(Void))?)
    {
        print("VoiceBase.getAllMedia")
        
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media"
        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode as Any)
            if let data = data {
                let string = String.init(data: data, encoding: String.Encoding.utf8)
                print(string as Any) // object name

                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String : Any] {
                    print(json)
                    
                    if let mediaItems = json["media"] as? [[String:Any]] {
                        if mediaItems.count > 0 {
                            let deleteAllAction = AlertAction(title: "Delete All", style: .destructive, action: completion)
                            let cancelAction = AlertAction(title: "Cancel", style: .default, action: nil)
                            
                            if mediaItems.count > 1 {
                                globals.alert(title: "Your VoiceBase Media Library contains \(mediaItems.count) items.", message: nil, actions:[deleteAllAction,cancelAction])
                            } else {
                                globals.alert(title: "Your VoiceBase Media Library contains \(mediaItems.count) item.", message: nil, actions:[deleteAllAction,cancelAction])
                            }
                        } else {
                            globals.alert(title: "Your VoiceBase Media Library does not contain any items.", message: nil)
                        }
                    } else {
                        globals.alert(title: "Unable to Determine the number of items in your VoiceBase Media Library.", message: nil)
                    }
                } else {
                    // JSONSerialization.jsonObject call failed
                    globals.alert(title: "Unable to Determine the number of items in your VoiceBase Media Library.", message: nil)
                }
            } else {
                // No data
                globals.alert(title: "Unable to Determine the number of items in your VoiceBase Media Library.", message: nil)
            }
            
            if let response = response {
                print("class getAllMedia response: ",response.description)
            }
            
            if let error = error {
                print("class getAllMedia error: ",error.localizedDescription)
            }
        })
        
        task.resume()
    }
    
    static func deleteAllMedia()
    {
        print("VoiceBase.deleteAllMedia")
        
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media"
        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode as Any)
            if data != nil {
                //                let string = String.init(data: data!, encoding: String.Encoding.utf8)
                //                print(string as Any) // object name
                
                if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any] {
                    print(json)
                    
                    if let mediaItems = json["media"] as? [[String:Any]] {
                        if mediaItems.count > 0 {
                            if mediaItems.count > 1 {
                                globals.alert(title: "Deleting \(mediaItems.count) Items from VoiceBase Media Library", message: nil)
                            } else {
                                globals.alert(title: "Deleting \(mediaItems.count) Item from VoiceBase Media Library", message: nil)
                            }
                            
                            for mediaItem in mediaItems {
                                delete(mediaID:mediaItem["mediaId"] as? String)
                            }
                        } else {
                            globals.alert(title: "No Items to Delete in VoiceBase Media Library", message: nil)
                        }
                    } else {
                        // No mediaItems
                        globals.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
                    }
                } else {
                    // JSONSerialization.jsonObject call failed
                    globals.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
                }
            } else {
                // No data
                globals.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
            }
            
            if let response = response {
                print("class deleteAllMedia response: ",response.description)
            }
            
            if let error = error {
                print("class deleteAllMedia error: ",error.localizedDescription)
            }
        })
        
        task.resume()
    }
}

class VoiceBase {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// VoiceBase API for Speech Recognition
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    weak var mediaItem:MediaItem!
    
    var purpose:String?
    
    var mediaID:String?
    {
        didSet {
            mediaItem.mediaItemSettings?["mediaID."+purpose!] = mediaID
        }
    }
    
    init(mediaItem:MediaItem,purpose:String)
    {
        self.mediaItem = mediaItem
        
        self.purpose = purpose
        
        if let mediaID = mediaItem.mediaItemSettings?["mediaID."+self.purpose!] {
            self.mediaID = mediaID
        }
    }
    
    var transcribing = false
    var upload:[String:Any]?
    
    var resultsTimer:Timer?
    
    func createBody(parameters: [String: String],boundary: String) -> Data {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            body.appendString(boundaryPrefix)
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString("--".appending(boundary.appending("--")))
        
        return body as Data
    }
    
    var url:String? {
        switch purpose! {
        case Purpose.video:
            return mediaItem.mp4
            
        case Purpose.audio:
            return mediaItem.audio
            
        default:
            return nil
        }
    }
    
    func uploadMedia()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard !transcribing && (upload == nil) else {
            return
        }
        
        guard let url = url else {
            return
        }
        
        //        print(url)
        
        transcribing = true
        
        let service = "https://apis.voicebase.com/v2-beta/media"
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "POST"
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let body = createBody(parameters: ["media":url],boundary: boundary)
        
        request.httpBody = body
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            
            var failed = true
            
            if let data = data {
                //                let string = String.init(data: data, encoding: String.Encoding.utf8)
                //                print(string)
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String : Any] {
                    //                    print(json)
                    
                    if json["errors"] == nil {
                        self.upload = json
                        self.mediaID = json["mediaId"] as? String
                        
                        //                        if #available(iOS 10.0, *) {
                        //                            notification(title: "Machine Generated Transcript Started", message: "The machine generated transcript for \(self.mediaItem.title!) (\(self.purpose!.lowercased())) has been started.  You will be notified when it is complete.")
                        //                        } else {
                        //                            alert(viewController:nil,title: "Machine Generated Transcript Started", message: "The machine generated transcript for \(self.mediaItem.title!) (\(self.purpose!.lowercased())) has been started.  You will be notified when it is complete.",completion: nil)
                        //                        }
                        
                        //                        alert(viewController:nil,title: "Machine Generated Transcript Started", message: "The machine generated transcript for \(self.mediaItem.title!) (\(self.purpose!.lowercased())) has been started.  You will be notified when it is complete.",completion: nil)
                        
                        var transcriptPurpose:String!
                        
                        if let purpose = self.purpose {
                            switch purpose {
                            case Purpose.audio:
                                transcriptPurpose = Constants.Strings.Audio
                                break
                                
                            case Purpose.video:
                                transcriptPurpose = Constants.Strings.Video
                                break
                                
                            case Purpose.slides:
                                transcriptPurpose = Constants.Strings.Slides
                                break
                                
                            case Purpose.notes:
                                transcriptPurpose = Constants.Strings.Transcript
                                break
                                
                            default:
                                transcriptPurpose = "ERROR"
                                break
                            }
                        }
                        
                        globals.alert(title:"Machine Generated Transcript Started", message:"The machine generated transcript for \(self.mediaItem.title!) (\(transcriptPurpose.lowercased())) has been started.  You will be notified when it is complete.")
                        //                        DispatchQueue.main.async(execute: { () -> Void in
                        //                        })
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_UPLOAD), object: self)
                        })
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(VoiceBase.getProgress), userInfo: nil, repeats: true)
                        })
                        failed = false
                    }
                } else {
                    // JSONSerialization.jsonObject call failed
                    
                }
            } else {
                // No data
                
            }
            
            if let response = response {
                print("uploadMedia response: ",response.description)
            }
            
            if let error = error {
                print("uploadMedia error: ",error.localizedDescription)
            }
            
            if failed {
                // FAIL
                var transcriptPurpose:String!
                
                if let purpose = self.purpose {
                    switch purpose {
                    case Purpose.audio:
                        transcriptPurpose = Constants.Strings.Audio
                        break
                        
                    case Purpose.video:
                        transcriptPurpose = Constants.Strings.Video
                        break
                        
                    case Purpose.slides:
                        transcriptPurpose = Constants.Strings.Slides
                        break
                        
                    case Purpose.notes:
                        transcriptPurpose = Constants.Strings.Transcript
                        break
                        
                    default:
                        transcriptPurpose = "ERROR"
                        break
                    }
                }
                
                globals.alert(title: "Transcript Failed",message: "The transcript for \(self.mediaItem.title!) (\(transcriptPurpose.lowercased())) failed to start.  Please try again.")
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_START), object: self)
                })
                
                self.transcribing = false
            }
        })
        
        task.resume()
    }
    
    var percentComplete:String?
    
    @objc func getProgress()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        guard let mediaID = mediaID else {
            uploadMedia()
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media/\(mediaID)/progress"
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            if let data = data {
//                let string = String.init(data: data!, encoding: String.Encoding.utf8)
//                print(string) // object name
                
                if let json = try? JSONSerialization.jsonObject(with: data, options: []) as! [String : Any] {
                    print(json)
                    
                    if let errors = json["errors"] {
                        print(errors)
                        
                        self.remove()
                        
                        var transcriptPurpose:String!
                        
                        if let purpose = self.purpose {
                            switch purpose {
                            case Purpose.audio:
                                transcriptPurpose = Constants.Strings.Audio
                                break
                                
                            case Purpose.video:
                                transcriptPurpose = Constants.Strings.Video
                                break
                                
                            case Purpose.slides:
                                transcriptPurpose = Constants.Strings.Slides
                                break
                                
                            case Purpose.notes:
                                transcriptPurpose = Constants.Strings.Transcript
                                break
                                
                            default:
                                transcriptPurpose = "ERROR"
                                break
                            }
                        }
                        
                        globals.alert(title: "Transcript Failed",message: "The transcript for \(self.mediaItem.title!) (\(transcriptPurpose.lowercased())) was not completed.  Please try again.")
                        
                        DispatchQueue.main.async(execute: { () -> Void in
                            NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                        })
                    } else {
                        if let status = json["status"] as? String, status == "finished" {
                            self.percentComplete = nil
                            self.resultsTimer?.invalidate()
                            self.resultsTimer = nil
                            self.getTranscript()
                        } else {
                            if let progress = json["progress"] as? [String:Any] {
                                if let tasks = progress["tasks"] as? [String:Any] {
                                    let count = tasks.count
                                    let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                                        if let dict = value as? [String:Any] {
                                            if let status = dict["status"] as? String {
                                                return status == "finished"
                                            }
                                        }
                                        
                                        return false
                                    }).count
                                    
                                    self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                                    
                                    var transcriptPurpose:String!
                                    
                                    if let purpose = self.purpose {
                                        switch purpose {
                                        case Purpose.audio:
                                            transcriptPurpose = Constants.Strings.Audio
                                            break
                                            
                                        case Purpose.video:
                                            transcriptPurpose = Constants.Strings.Video
                                            break
                                            
                                        case Purpose.slides:
                                            transcriptPurpose = Constants.Strings.Slides
                                            break
                                            
                                        case Purpose.notes:
                                            transcriptPurpose = Constants.Strings.Transcript
                                            break
                                            
                                        default:
                                            transcriptPurpose = "ERROR"
                                            break
                                        }
                                    }
                                    
                                    print("\(self.mediaItem.title!) is \(self.percentComplete!)% finished (\(transcriptPurpose.lowercased()))")
                                }
                            }
                        }
                    }
                } else {
                    // JSONSerialization.jsonObject call failed
                    
                }
            } else {
                // No data
                
            }
            
            if let response = response {
                print("getProgress response: ",response.description)
            }
            
            if let error = error {
                print("getProgress error: ",error.localizedDescription)
            }
        })
        
        task.resume()
    }
    
    func delete()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media/\(mediaID)"
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            
            // Once we know the object is deleted we should set mediaID to "Completed" (or some other agreed upon string) so we aren't hitting the
            // file system everytime we want to see if some mediaItem has a transcript and so we don't keep trying to delete it.
            
            if data != nil {
                let string = String.init(data: data!, encoding: String.Encoding.utf8)
                print(string as Any) // object name

                if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any] {
                    print(json)
                    
                    if let errors = json["errors"] as? [String:String] {
                        if (errors["error"] == "Requested resource not found") {
                            self.mediaID = self._transcript != nil ? "Completed" : nil
                        }
                    }
                } else {
                    // JSONSerialization.jsonObject call failed
                    
                }
            } else {
                // No data
                
            }
            
            if let response = response {
                print("delete response: ",response.description)
            }
            
            if let error = error {
                print("delete error: ",error.localizedDescription)
            }
        })
        
        task.resume()
    }
    
    func remove()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        delete()
        
        mediaID = nil
        
        transcript = nil
        transcribing = false
        
        upload = nil
        
        resultsTimer?.invalidate()
        resultsTimer = nil
        
        topicsJSON = nil
        keywordsJSON = nil
        
//        DispatchQueue(label: "CBC").sync(execute: { () -> Void in
//            self.mediaItem.removeTag("Machine Generated Transcript")
//        })
        
//        let fileManager = FileManager.default
        
//        if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).keywords") {
//            if (fileManager.fileExists(atPath: destinationURL.path)){
//                do {
//                    try fileManager.removeItem(at: destinationURL)
//                } catch _ {
//                    print("failed to remove machine generated transcript keywords")
//                }
//            } else {
//                print("machine generated transcript keywords file doesn't exist")
//            }
//        } else {
//            print("failed to get destinationURL")
//        }
        
//        if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).topics") {
//            if (fileManager.fileExists(atPath: destinationURL.path)){
//                do {
//                    try fileManager.removeItem(at: destinationURL)
//                } catch _ {
//                    print("failed to remove machine generated transcript topics")
//                }
//            } else {
//                print("machine generated transcript topics file doesn't exist")
//            }
//        } else {
//            print("failed to get destinationURL")
//        }
        
//        if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(purpose!)") {
//            // Check if file exist
//            if (fileManager.fileExists(atPath: destinationURL.path)){
//                do {
//                    try fileManager.removeItem(at: destinationURL)
//                } catch _ {
//                    print("failed to remove machine generated transcript")
//                }
//            } else {
//                print("machine generated transcript file doesn't exist")
//            }
//        } else {
//            print("failed to get destinationURL")
//        }
    }
    
    var topicsJSON : [String:Any]?
    {
        get {
            guard _topicsJSON == nil else {
                return _topicsJSON
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(self.mediaItem.id!).\(self.purpose!).topics"), let data = try? Data(contentsOf: url) {
                do {
                    _topicsJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
                    //                            print(self.topicsJSON)
                    //                            print(self.topics)
                } catch let error as NSError {
                    print("failed to load machine generated topics for \(mediaItem.description): \(error.localizedDescription)")
                }
            }

            return _topicsJSON
        }
        set {
            _topicsJSON = newValue
        }
    }
    var _topicsJSON : [String:Any]?
    {
        didSet {
            let fileManager = FileManager.default
            
            if topicsJSON != nil {
                let topicsPropertyList = try? PropertyListSerialization.data(fromPropertyList: self.topicsJSON as Any, format: .xml, options: 0)
                
                if let destinationURL = cachesURL()?.appendingPathComponent("\(self.mediaItem.id!).\(self.purpose!).topics") {
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated transcript topics: \(error.localizedDescription)")
                        }
                    }
                    
                    do {
                        try topicsPropertyList?.write(to: destinationURL)
                    } catch let error as NSError {
                        print("failed to write machine generated transcript topics to cache directory: \(error.localizedDescription)")
                    }
                }
            } else {
                if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).topics") {
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated transcript topics: \(error.localizedDescription)")
                        }
                    } else {
                        print("machine generated transcript topics file doesn't exist")
                    }
                } else {
                    print("failed to get destinationURL")
                }
            }
        }
    }
    
    var topicsDictionaries : [String:[String:Any]]?
    {
        if let latest = topicsJSON?["latest"] as? [String:Any] {
            if let words = latest["topics"] as? [[String:Any]] {
                var tdd = [String:[String:Any]]()
                
                for dict in words {
                    if let name = dict["name"] as? String {
                        tdd[name] = dict
                    }
                }
                
                return tdd.count > 0 ? tdd : nil
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    var topics : [String]?
    {
        if let topics = topicsDictionaries?.map({ (key: String, value: [String : Any]) -> String in
            return key
        }) {
            return topics
        } else {
            return nil
        }
    }
    
    func topicKeywordDictionaries(topic:String?) -> [String:[String:Any]]?
    {
        guard let topic = topic else {
            return nil
        }
        
        if let topicDictionary = topicsDictionaries?[topic] {
            if let keywordsDictionaries = topicDictionary["keywords"] as? [[String:Any]] {
                var kwdd = [String:[String:Any]]()
                
                for dict in keywordsDictionaries {
                    if let name = dict["name"] as? String {
                        kwdd[name.lowercased()] = dict
                    }
                }
                
                return kwdd.count > 0 ? kwdd : nil
            }
        }
        
        return nil
    }
    
    func topicKeywords(topic:String?) -> [String]?
    {
        guard let topic = topic else {
            return nil
        }
        
        if let topicKeywordDictionaries = topicKeywordDictionaries(topic: topic) {
            let topicKeywords = topicKeywordDictionaries.map({ (key: String, value: [String : Any]) -> String in
                return key
            })
            
            return topicKeywords.count > 0 ? topicKeywords : nil
        }
        
        return nil
    }
    
    func topicKeywordTimes(topic:String?,keyword:String?) -> [String]?
    {
        guard let topic = topic else {
            return nil
        }
        
        guard let keyword = keyword else {
            return nil
        }
        
        if let keywordDictionaries = topicKeywordDictionaries(topic:topic) {
            if let keywordDictionary = keywordDictionaries[keyword] {
                if let speakerTimes = keywordDictionary["t"] as? [String:[String]] {
                    if let times = speakerTimes["unknown"] {
                        return times
                    }
                }
            }
        }
        
        return nil
    }
    
    var allTopicKeywords : [String]?
    {
        guard let topics = topics else {
            return nil
        }
        
        var keywords = Set<String>()
        
        for topic in topics {
            if let topicsKeywords = topicKeywords(topic: topic) {
                keywords = keywords.union(Set(topicsKeywords))
            }
        }
        
        return keywords.count > 0 ? Array(keywords) : nil
    }
    
    var allTopicKeywordDictionaries : [String:[String:Any]]?
    {
        guard let topics = topics else {
            return nil
        }
        
        var allTopicKeywordDictionaries = [String:[String:Any]]()
        
        for topic in topics {
            if let topicKeywordDictionaries = topicKeywordDictionaries(topic: topic) {
                for topicKeywordDictionary in topicKeywordDictionaries {
                    if allTopicKeywordDictionaries[topicKeywordDictionary.key] == nil {
                        allTopicKeywordDictionaries[topicKeywordDictionary.key.lowercased()] = topicKeywordDictionary.value
                    } else {
                        print("allTopicKeywordDictionaries key occupied")
                    }
                }
            }
        }
        
        return allTopicKeywordDictionaries.count > 0 ? allTopicKeywordDictionaries : nil
    }
    
    func allTopicKeywordTimes(keyword:String?) -> [String]?
    {
        guard let keyword = keyword else {
            return nil
        }
        
        if let keywordDictionary = allTopicKeywordDictionaries?[keyword] {
            if let speakerTimes = keywordDictionary["t"] as? [String:[String]] {
                if let times = speakerTimes["unknown"] {
                    return times
                }
            }
        }
        
        return nil
    }
    
    var keywordsJSON: [String:Any]?
    {
        get {
            guard _keywordsJSON == nil else {
                return _keywordsJSON
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(self.mediaItem.id!).\(self.purpose!).keywords"), let data = try? Data(contentsOf: url) {
                do {
                    _keywordsJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
                    //                            print(self.keywordsJSON)
                    //                            print(self.keywords)
                } catch let error as NSError {
                    print("failed to load machine generated keywords for \(mediaItem.description): \(error.localizedDescription)")
                }
            }
            
            return _keywordsJSON
        }
        set {
            _keywordsJSON = newValue
        }
    }
    var _keywordsJSON : [String:Any]?
    {
        didSet {
            guard mediaItem != nil else {
                return
            }
            
            guard mediaItem?.id != nil else {
                return
            }
            
            guard purpose != nil else {
                return
            }
            
            let fileManager = FileManager.default
            
            if _keywordsJSON != nil {
                let keywordsPropertyList = try? PropertyListSerialization.data(fromPropertyList: self.keywordsJSON as Any, format: .xml, options: 0)
                
                if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).keywords") {
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated transcript keywords: \(error.localizedDescription)")
                        }
                    }
                    
                    do {
                        try keywordsPropertyList?.write(to: destinationURL)
                    } catch let error as NSError {
                        print("failed to write machine generated transcript keywords to cache directory: \(error.localizedDescription)")
                    }
                }
            } else {
                if let destinationURL = cachesURL()?.appendingPathComponent("\(mediaItem.id!).\(purpose!).keywords") {
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated transcript keywords: \(error.localizedDescription)")
                        }
                    } else {
                        print("machine generated transcript keywords file doesn't exist")
                    }
                } else {
                    print("failed to get destinationURL")
                }
            }
        }
    }
    
    var keywordDictionaries : [String:[String:Any]]?
    {
        if let latest = keywordsJSON?["latest"] as? [String:Any] {
            if let wordDictionaries = latest["words"] as? [[String:Any]] {
                var kwdd = [String:[String:Any]]()
                
                for dict in wordDictionaries {
                    if let name = dict["name"] as? String {
                        kwdd[name.lowercased()] = dict
                    }
                }
                
                return kwdd.count > 0 ? kwdd : nil
            }
        }
        
        return nil
    }
    
    var keywords : [String]?
    {
        if let keywords = keywordDictionaries?.filter({ (key: String, value: [String : Any]) -> Bool in
            if let speakerTimes = value["t"] as? [String:[String]] {
                if let times = speakerTimes["unknown"] {
                    return times.count > 0
                }
            }
            return false
        }).map({ (key: String, value: [String : Any]) -> String in
            return key
        }) {
            return keywords
        } else {
            return nil
        }
    }
    
    func keywordTimes(keyword:String?) -> [String]?
    {
        guard let keyword = keyword else {
            return nil
        }
        
        if let keywordDictionary = keywordDictionaries?[keyword] {
            if let speakerTimes = keywordDictionary["t"] as? [String:[String]] {
                if let times = speakerTimes["unknown"] {
                    return times
                }
            }
        }
        
        return nil
    }
    
    func getDetails()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            uploadMedia()
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media/\(mediaID)"
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            if data != nil {
                //                let string = String.init(data: data!, encoding: String.Encoding.utf8)
                //                print(string) // object name
                
                if let json = try? JSONSerialization.jsonObject(with: data!, options: []) as! [String : Any] {
                    //                    print(json)
                    
                    let media = json["media"] as? [String:Any]
                    
                    self.keywordsJSON = media?["keywords"] as? [String : Any]
                    self.topicsJSON = media?["topics"] as? [String : Any]
                }
            }
            
            self.delete()
        })
        
        task.resume()
    }
    
    var transcript:String?
    {
        get {
            guard (_transcript == nil) else {
                return _transcript
            }
            
            guard (mediaID == "Completed") || (mediaID != nil) else {
                return nil
            }
            
            if let destinationURL = cachesURL()?.appendingPathComponent(self.mediaItem.id!+".\(self.purpose!)") {
                do {
                    try _transcript = String(contentsOfFile: destinationURL.path, encoding: String.Encoding.utf8)
                    // This will cause an error.  The tag is created in the constantTags getter while loading.
                    //                    mediaItem.addTag("Machine Generated Transcript")
                    
                    // Also, the tag would normally be added or removed in teh didSet for transcript but didSet's are not
                    // called during init()'s which is fortunate.
                } catch let error as NSError {
                    if mediaID == "Completed" {
                        mediaID = nil
                        print("failed to load machine generated transcript for \(mediaItem.description): \(error.localizedDescription)")
                    }
                }
            }
            
            if (_transcript == nil) && (mediaID != "Completed") && (mediaID != nil) && (self.resultsTimer == nil) {
                DispatchQueue(label: "CBC").sync(execute: { () -> Void in
                    self.mediaItem.removeTag("Machine Generated Transcript")
                })
                
                self.transcribing = true
                
                DispatchQueue.main.async(execute: { () -> Void in
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(VoiceBase.getProgress), userInfo: nil, repeats: true)
                })
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()  // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
            }
        
            return _transcript
        }
        set {
            _transcript = newValue
        }
    }
    var _transcript:String?
    {
        didSet {
            guard mediaItem != nil else {
                return
            }
            
            let fileManager = FileManager.default
            
            if _transcript != nil {
                DispatchQueue(label: "CBC").sync(execute: { () -> Void in
                    self.mediaItem.addTag("Machine Generated Transcript")
                })
                
                if let destinationURL = cachesURL()?.appendingPathComponent(self.mediaItem.id!+".\(self.purpose!)") {
                    // Check if file exist
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated transcript: \(error.localizedDescription)")
                        }
                    }
                    
                    do {
                        try _transcript?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8);
                    } catch let error as NSError {
                        print("failed to write transcript to cache directory: \(error.localizedDescription)")
                    }
                } else {
                    print("failed to get destinationURL")
                }
            } else {
                DispatchQueue(label: "CBC").sync(execute: { () -> Void in
                    self.mediaItem.removeTag("Machine Generated Transcript")
                })
                
                if let destinationURL = cachesURL()?.appendingPathComponent(mediaItem.id!+".\(purpose!)") {
                    // Check if file exist
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated transcript: \(error.localizedDescription)")
                        }
                    } else {
                        print("machine generated transcript file doesn't exist")
                    }
                } else {
                    print("failed to get destinationURL")
                }
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
            })
        }
    }
    
    func getTranscript()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            globals.alert(title: "Transcript Unavailable",message: "The transcript for \(self.mediaItem.title!) can not be created.  Please check your network connection and try again.")
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard mediaItem != nil else {
            return
        }
        
        guard let mediaID = mediaID else {
            uploadMedia()
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media/\(mediaID)/transcripts/latest"
//        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        request.addValue("text/plain", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            if data != nil {
                let string = String.init(data: data!, encoding: String.Encoding.utf8)
                
//                print(string)
                
                self.transcript = string
                self.transcribing = false
                
                var transcriptPurpose:String!
                
                if let purpose = self.purpose {
                    switch purpose {
                    case Purpose.audio:
                        transcriptPurpose = Constants.Strings.Audio
                        break
                        
                    case Purpose.video:
                        transcriptPurpose = Constants.Strings.Video
                        break
                        
                    case Purpose.slides:
                        transcriptPurpose = Constants.Strings.Slides
                        break
                        
                    case Purpose.notes:
                        transcriptPurpose = Constants.Strings.Transcript
                        break
                        
                    default:
                        transcriptPurpose = "ERROR"
                        break
                    }
                }
                
                globals.alert(title: "Transcript Ready",message: "The transcript for \(self.mediaItem.title!) (\(transcriptPurpose.lowercased())) is available.")

                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
                })
            } else {
                // Now what?
            }
            
            self.getTranscriptSRT()
        })
        
        task.resume()
    }
    
    var srtArrays:[[String]]?
    {
        get {
            guard _srtArrays == nil else {
                return _srtArrays
            }
            
            let _ = transcriptSRT
            
            return _srtArrays
        }
        set {
            _srtArrays = newValue
        }
    }
    var _srtArrays:[[String]]?
    {
        didSet {
            guard let srtArrays = _srtArrays else {
                return
            }
            
            var tokenTimes = [String:[String]]()
            
            for srtArray in srtArrays {
                if let times = srtArrayTimes(srtArray: srtArray), let startTime = times.first {
                    if let tokens = tokensFromString(srtArrayText(srtArray: srtArray)) {
                        for token in tokens {
                            let key = token.lowercased()
                            
                            if tokenTimes[key] == nil {
                                tokenTimes[key] = [startTime]
                            } else {
                                if var times = tokenTimes[key] {
                                    times.append(startTime)
                                    tokenTimes[key] = Array(Set(times)).sorted()
                                }
                            }
                        }
                    }
                }
            }
            
            srtTokensTimes = tokenTimes.count > 0 ? tokenTimes : nil
        }
    }
    
    var srtTokens : [String]?
    {
        return srtTokensTimes?.keys.sorted()
    }
    
    func srtTokenTimes(token:String) -> [String]?
    {
        return srtTokensTimes?[token]
    }
    
    var srtTokensTimes : [String:[String]]?
    {
        get {
            guard _srtTokensTimes == nil else {
                return _srtTokensTimes
            }
            
            let _ = transcriptSRT
            
            return _srtTokensTimes
        }
        set {
            _srtTokensTimes = newValue
        }
    }
    var _srtTokensTimes : [String:[String]]?
    {
        didSet {
            
        }
    }
    
    func srtArrayStartTime(srtArray:[String]?) -> Double?
    {
        return hmsToSeconds(string: srtArrayTimes(srtArray: srtArray)?.first)
    }
    
    func srtArrayEndTime(srtArray:[String]?) -> Double?
    {
        return hmsToSeconds(string: srtArrayTimes(srtArray: srtArray)?.last)
    }
    
    func srtArrayIndex(srtArray:[String]?) -> String?
    {
        if let count = srtArray?.first {
            return count
        } else {
            return nil
        }
    }
    
    func srtArrayTimes(srtArray:[String]?) -> [String]?
    {
        guard srtArray?.count > 1 else {
            return nil
        }
        
        var array = srtArray!
        
        if let count = array.first, !count.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        if let timeWindow = array.first, !timeWindow.isEmpty {
            array.remove(at: 0)
            let times = timeWindow.components(separatedBy: " --> ")
            //            print(times)
            
            return times
        } else {
            return nil
        }
    }
    
    func srtArrayText(srtArray:[String]?) -> String?
    {
        guard srtArray?.count > 1 else {
            return nil
        }
        
        var string = String()
        
        var array = srtArray!
        
        if let count = array.first, !count.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        if let timeWindow = array.first, !timeWindow.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        for element in array {
            string = string + " " + element.lowercased()
        }
        
        return !string.isEmpty ? string : nil
    }
    
    func searchSRTArrays(string:String) -> [[String]]?
    {
        var results = [[String]]()
        
        for srtArray in srtArrays! {
            if let contains = srtArrayText(srtArray: srtArray)?.contains(string.lowercased()), contains {
                results.append(srtArray)
            }
        }
        
        return results.count > 0 ? results : nil
    }
    
    var srtComponents:[String]?
    {
        get {
            guard _srtComponents == nil else {
                return _srtComponents
            }
            
            let _ = transcriptSRT
            
            return _srtComponents
        }
        set {
            _srtComponents = newValue
        }
    }
    var _srtComponents:[String]?
    {
        didSet {
            guard srtComponents != nil else {
                return
            }
            
            var srtArrays = [[String]]()
            
            for srtComponent in srtComponents! {
                srtArrays.append(srtComponent.components(separatedBy: "\n"))
            }
            
            self.srtArrays = srtArrays.count > 0 ? srtArrays : nil
        }
    }
    
    var transcriptSRT:String?
    {
        get {
            guard _transcriptSRT == nil else {
                return _transcriptSRT
            }
            
            if let url = cachesURL()?.appendingPathComponent("\(self.mediaItem.id!).\(self.purpose!).srt") {
                do {
                    try _transcriptSRT = String(contentsOfFile: url.path, encoding: String.Encoding.utf8)
                } catch let error as NSError {
                    print("failed to load machine generated topics for \(mediaItem.description): \(error.localizedDescription)")
                }
            }
            
            return _transcriptSRT
        }
        set {
            _transcriptSRT = newValue
        }
    }
    var _transcriptSRT:String?
    {
        didSet {
            srtComponents = transcriptSRT?.components(separatedBy: "\n\n")
            //            print(srtComponents)
            
            if _transcriptSRT != nil {
                if let destinationURL = cachesURL()?.appendingPathComponent(self.mediaItem.id!+".\(self.purpose!).srt") {
                    // Check if file exist
                    let fileManager = FileManager.default
                    
                    if (fileManager.fileExists(atPath: destinationURL.path)){
                        do {
                            try fileManager.removeItem(at: destinationURL)
                        } catch let error as NSError {
                            print("failed to remove machine generated SRT transcript: \(error.localizedDescription)")
                        }
                    }
                    
                    do {
                        try _transcriptSRT?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8);
                    } catch let error as NSError {
                        print("failed to write SRT transcript to cache directory: \(error.localizedDescription)")
                    }
                } else {
                    print("failed to get destinationURL")
                }
            }
        }
    }
    
    func getTranscriptSRT()
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            uploadMedia()
            return
        }
        
        let service = "https://apis.voicebase.com/v2-beta/media/\(mediaID)/transcripts/latest"
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        request.addValue("text/srt", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            if data != nil {
                let string = String.init(data: data!, encoding: String.Encoding.utf8)

                self.transcriptSRT = string
                
                //                print(string)
            } else {
                // Now what?
            }
            
            self.getDetails()
        })
        
        task.resume()
    }
    
    func search(string:String?)
    {
        guard globals.reachability.currentReachabilityStatus != .notReachable else {
            return
        }
        
        guard let voiceBaseAPIKey = globals.voiceBaseAPIKey else {
            return
        }
        
        guard let string = string else {
            return
        }
        
        //        guard let mediaID = mediaID else {
        //            return
        //        }
        
        var service = "https://apis.voicebase.com/v2-beta/media"
        
        service = service + "q=" + string
        
        //        print(service)
        
        var request = URLRequest(url: URL(string:service)!)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        //        request.addValue("text/plain", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            //            print((response as? HTTPURLResponse)?.statusCode)
            if data != nil {
                //                let string = String.init(data: data!, encoding: String.Encoding.utf8)
                //                print(string)
                
                // No idea what this produces, but I'm guessing it is like the keywords dictionary.
            } else {
                // Now what?
            }
        })
        
        task.resume()
    }
}
