//
//  VoiceBase.swift
//  CBC
//
//  Created by Steve Leeke on 6/27/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import Speech

extension NSMutableData
{
    func appendString(_ string: String)
    {
        // why not utf16?
        if let data = string.data(using: String.Encoding.utf8, allowLossyConversion: false) {
            append(data)
        }
    }
}

extension VoiceBase // Class Methods
{
    static func url(mediaID:String?,path:String?,query:String?) -> String
    {
        if mediaID == nil, path == nil, query == nil {
            return Constants.URL.VOICE_BASE_ROOT + "?limit=1000"
        } else {
            return Constants.URL.VOICE_BASE_ROOT + (mediaID != nil ? "/" + mediaID! : "") + (path != nil ? "/" + path! : "") + (query != nil ? "?" + query! : "")
        }
    }
    
    static func html(_ json:[String:Any]?) -> String?
    {
        guard json != nil else {
            return nil
        }
        
        var htmlString = "<!DOCTYPE html><html><body>"
        
        if let media = json?["media"] as? [String:Any] {
            if let mediaID = media["mediaId"] as? String {
                htmlString = htmlString + "MediaID: \(mediaID)\n"
            }
            
            if let status = media["status"] as? String {
                htmlString = htmlString + "Status: \(status)\n"
            }
            
            if let dateCreated = media["dateCreated"] as? String {
                htmlString = htmlString + "Date Created: \(dateCreated)\n"
            }
            
            if let job = media["job"] as? [String:Any] {
                htmlString = htmlString + "\nJob\n"
                
                if let jobProgress = job["progress"] as? [String:Any] {
                    if let jobStatus = jobProgress["status"] as? String {
                        htmlString = htmlString + "Job Status: \(jobStatus)\n"
                    }
                    if let jobTasks = jobProgress["tasks"] as? [String:Any] {
                        htmlString = htmlString + "Job Tasks: \(jobTasks.count)\n"
                        
                        var stats = [String:Int]()
                        
                        for task in jobTasks.keys {
                            if let status = (jobTasks[task] as? [String:Any])?["status"] as? String {
                                if let count = stats[status] {
                                    stats[status] = count + 1
                                } else {
                                    stats[status] = 1
                                }
                            }
                        }
                        
                        for key in stats.keys {
                            if let value = stats[key] {
                                htmlString = htmlString + "\(key): \(value)\n"
                            }
                        }
                    }
                }
            }
            
            if let metadata = media["metadata"] as? [String:Any] {
                htmlString = htmlString + "\nMetadata\n"
                
                if let length = metadata["length"] as? [String:Any] {
                    if let length = length["milliseconds"] as? Int, let hms = (Double(length) / 1000.0).secondsToHMS {
                        htmlString = htmlString + "Length: \(hms)\n"
                    }
                }
                
                if let metadataTitle = metadata["title"] as? String {
                    htmlString = htmlString + "Title: \(metadataTitle)\n"
                }
                
                if let device = metadata["device"] as? [String:String] {
                    htmlString = htmlString + "\nDevice Information:\n"
                    
                    if let model = device["model"] {
                        htmlString = htmlString + "Model: \(model)\n"
                    }
                    
                    if let modelName = device["modelName"] {
                        htmlString = htmlString + "Model Name: \(modelName)\n"
                    }
                    
                    if let name = device["name"] {
                        htmlString = htmlString + "Name: \(name)\n"
                    }
                    
                    if let deviceUUID = device["UUID"] {
                        htmlString = htmlString + "UUID: \(deviceUUID)\n"
                    }
                }
                
                if let mediaItem = metadata["mediaItem"] as? [String:String] {
                    htmlString = htmlString + "\nMediaItem\n"
                    
                    if let category = mediaItem["category"] {
                        htmlString = htmlString + "Category: \(category)\n"
                    }
                    
                    if let id = mediaItem["id"] {
                        htmlString = htmlString + "id: \(id)\n"
                    }
                    
                    if let title = mediaItem["title"] {
                        htmlString = htmlString + "Title: \(title)\n"
                    }
                    
                    if let date = mediaItem["date"] {
                        htmlString = htmlString + "Date: \(date)\n"
                    }
                    
                    if let service = mediaItem["service"] {
                        htmlString = htmlString + "Service: \(service)\n"
                    }
                    
                    if let speaker = mediaItem["speaker"] {
                        htmlString = htmlString + "Speaker: \(speaker)\n"
                    }
                    
                    if let scripture = mediaItem["scripture"] {
                        htmlString = htmlString + "Scripture: \(scripture)\n"
                    }
                    
                    if let purpose = mediaItem["purpose"] {
                        htmlString = htmlString + "Purpose: \(purpose)\n"
                    }
                }
            }
            
            if let transcripts = media["transcripts"] as? [String:Any] {
                htmlString = htmlString + "\nTranscripts\n"
                
                if let latest = transcripts["latest"] as? [String:Any] {
                    htmlString = htmlString + "Latest\n"
                    
                    if let engine = latest["engine"] as? String {
                        htmlString = htmlString + "Engine: \(engine)\n"
                    }
                    
                    if let confidence = latest["confidence"] as? String {
                        htmlString = htmlString + "Confidence: \(confidence)\n"
                    }
                    
                    if let words = latest["words"] as? [[String:Any]] {
                        htmlString = htmlString + "Words: \(words.count)\n"
                    }
                }
            }
            
            if let keywords = media["keywords"] as? [String:Any] {
                htmlString = htmlString + "\nKeywords\n"
                
                if let keywordsLatest = keywords["latest"] as? [String:Any] {
                    if let words = keywordsLatest["words"] as? [[String:Any]] {
                        htmlString = htmlString + "Keywords: \(words.count)\n"
                    }
                }
            }
            
            if let topics = media["topics"] as? [String:Any] {
                htmlString = htmlString + "\nTopics\n"
                
                if let topicsLatest = topics["latest"] as? [String:Any] {
                    if let topics = topicsLatest["topics"] as? [[String:Any]] {
                        htmlString = htmlString + "Topics: \(topics.count)\n"
                    }
                }
            }
        }
        
        htmlString = htmlString.replacingOccurrences(of: "\n", with: "<br/>") + "</body></html>"

        return htmlString
    }
    
    static func get(accept:String?,mediaID:String?,path:String?,query:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        if !Globals.shared.checkingAvailability {
            if !Globals.shared.isVoiceBaseAvailable {
                return
            }
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(mediaID:mediaID, path:path, query:query)) else {
            return
        }

        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        if let accept = accept {
            request.addValue(accept, forHTTPHeaderField: "Accept")
        }
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: mediaID ?? UUID().uuidString)
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("post HTTP response: ",httpResponse.description)
                    print("post HTTP response: ",httpResponse.allHeaderFields)
                    print("post HTTP response: ",httpResponse.statusCode)
                    print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, data.count > 0 {
                let string = String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?

                if let acceptText = accept?.contains("text"), acceptText {
                    json = ["text":string as Any]
                } else {
                    json = data.json as? [String:Any]
                    
                    if let errors = json?["errors"] {
                        print(errors)
                        errorOccured = true
                    }

//                    do {
//                        json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//
//                        if let errors = json?["errors"] {
//                            print(errors)
//                            errorOccured = true
//                        }
//                    } catch let error {
//                        // JSONSerialization failed
//                        print("JSONSerialization error: ",error.localizedDescription)
//                    }
                }
            } else {
                // no data
                errorOccured = true
            }
            
            if errorOccured {
                onError?(json)
            } else {
                completion?(json)
            }
        })
        
        task.resume()
    }
    
    static func metadata(mediaID: String?, completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept: nil, mediaID: mediaID, path: "metadata", query: nil, completion: completion, onError: onError)
    }

    static func progress(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: mediaID, path: "progress", query: nil, completion: completion, onError: onError)
    }
    
    static func details(mediaID:String?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: mediaID, path: nil, query: nil, completion: completion, onError: onError)
    }

    static func all(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        get(accept:nil, mediaID: nil, path: nil, query: nil, completion: completion, onError: onError)
    }
    
    static func delete(mediaID:String?)
    {
        print("VoiceBase.delete")

        guard Globals.shared.isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(mediaID:mediaID, path:nil, query:nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default // background(withIdentifier: mediaID)
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("post HTTP response: ",httpResponse.description)
                    print("post HTTP response: ",httpResponse.allHeaderFields)
                    print("post HTTP response: ",httpResponse.statusCode)
                    print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, data.count > 0 {
                let string = String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)
                
                json = data.json as? [String:Any]
                print(json as Any)

                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }
                
//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                Thread.onMainThread {
                    
                }
            } else {
                Thread.onMainThread {
                    
                }
            }
        })
        
        task.resume()
    }
    
    @objc static func deleteAll()
    {
        print("VoiceBase.deleteAllMedia")
        
        get(accept: nil, mediaID: nil, path: nil, query: nil, completion: { (json:[String : Any]?) -> (Void) in
            if let mediaItems = json?["media"] as? [[String:Any]] {
                if mediaItems.count > 0 {
                    if mediaItems.count > 1 {
                        Alerts.shared.alert(title: "Deleting \(mediaItems.count) Items from VoiceBase Media Library", message: nil)
                    } else {
                        Alerts.shared.alert(title: "Deleting \(mediaItems.count) Item from VoiceBase Media Library", message: nil)
                    }
                    
                    for mediaItem in mediaItems {
                        delete(mediaID:mediaItem["mediaId"] as? String)
                    }
                } else {
                    Alerts.shared.alert(title: "No Items to Delete in VoiceBase Media Library", message: nil)
                }
            } else {
                // No mediaItems
                Alerts.shared.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
            }
        }, onError:  { (json:[String : Any]?) -> (Void) in
            Alerts.shared.alert(title: "No Items Deleted from VoiceBase Media Library", message: nil)
        })
    }
}

class VoiceBase {
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// VoiceBase API for Speech Recognition
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    weak var mediaItem:MediaItem?
    
    static let separator = "------------"
    
    static let configuration:String? = "{\"configuration\":{\"executor\":\"v2\"}}"
    
    var purpose:String?
    
    var transcriptPurpose:String
    {
        get {
            var transcriptPurpose = "ERROR"
            
            if let purpose = self.purpose {
                switch purpose {
                case Purpose.audio:
                    transcriptPurpose = Constants.Strings.Audio
                    break
                    
                case Purpose.video:
                    transcriptPurpose = Constants.Strings.Video
                    break

                default:
                    break
                }
            }
            
            return transcriptPurpose // .lowercased() NO
        }
    }

    var metadata : String
    {
        guard let mediaItem = mediaItem else {
            return "ERROR no mediaItem"
        }
        
        guard mediaItem.id != nil else {
            return "ERROR no mediaItem.id"
        }

        var mediaItemString = "{"
        
            mediaItemString += "\"metadata\":{"
        
                if let text = mediaItem.text {
                    if let mediaID = mediaID {
                        mediaItemString += "\"title\":\"\(text) (\(transcriptPurpose))\n\(mediaID)\","
                    } else {
                        mediaItemString += "\"title\":\"\(text) (\(transcriptPurpose))\","
                    }
                }
        
                mediaItemString += "\"mediaItem\":{"
                
                    if let category = mediaItem.category {
                        mediaItemString += "\"category\":\"\(category)\","
                    }
                    
                    if let id = mediaItem.id {
                        mediaItemString += "\"id\":\"\(id)\","
                    }
                    
                    if let date = mediaItem.date {
                        mediaItemString += "\"date\":\"\(date)\","
                    }
                    
                    if let service = mediaItem.service {
                        mediaItemString += "\"service\":\"\(service)\","
                    }
                    
                    if let title = mediaItem.title {
                        mediaItemString += "\"title\":\"\(title)\","
                    }
            
                    if let text = mediaItem.text {
                        mediaItemString += "\"text\":\"\(text) (\(transcriptPurpose))\","
                    }
                    
                    if let scripture = mediaItem.scripture {
                        mediaItemString += "\"scripture\":\"\(scripture.description)\","
                    }
                    
                    if let speaker = mediaItem.speaker {
                        mediaItemString += "\"speaker\":\"\(speaker)\","
                    }
                    
                    mediaItemString += "\"purpose\":\"\(transcriptPurpose)\""
            
                mediaItemString += "},"
            
                mediaItemString += "\"device\":{"
                
                    mediaItemString += "\"name\":\"\(UIDevice.current.deviceName)\","
                    
                    mediaItemString += "\"model\":\"\(UIDevice.current.localizedModel)\","
                    
                    mediaItemString += "\"modelName\":\"\(UIDevice.current.modelName)\","
        
                    if let uuid = UIDevice.current.identifierForVendor?.description {
                        mediaItemString += "\"UUID\":\"\(uuid)\""
                    }
        
                mediaItemString += "}"
        
            mediaItemString += "}"
        
        mediaItemString += "}"
        
        return mediaItemString
    }
    
    var mediaID:String?
    {
        didSet {
            guard mediaID != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["mediaID."+purpose] = mediaID
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }
    }
    
    var completed = false
    {
        didSet {
            guard completed != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["completed."+purpose] = completed ? "YES" : "NO"

            Thread.onMainThread {
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        }
    }
    
    var transcribing = false
    {
        didSet {
            guard transcribing != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["transcribing."+purpose] = transcribing ? "YES" : "NO"
            
            if transcribing {
                mediaItem?.addTag(Constants.Strings.Transcribing + " - " + transcriptPurpose)
            } else {
                mediaItem?.removeTag(Constants.Strings.Transcribing + " - " + transcriptPurpose)
            }
        }
    }
    
    var alignmentSource : String?
    
    var aligning = false
    {
        didSet {
            guard aligning != oldValue else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            mediaItem?.mediaItemSettings?["aligning."+purpose] = aligning ? "YES" : "NO"
        }
    }
    
    var percentComplete:String?
    {
        didSet {

        }
    }
    
    var uploadJSON:[String:Any]?
    
    var resultsTimer:Timer?
    {
        didSet {
            
        }
    }
    
    var url:String?
    {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            switch purpose {
            case Purpose.video:
                var mp4 = mediaItem?.mp4
                
                if let range = mp4?.range(of: "&profile_id="), let root = mp4?[..<range.upperBound] {
                    mp4 = root.description + "174"
                }
                
                return mp4
                
            case Purpose.audio:
                return mediaItem?.audio
                
            default:
                return nil
            }
        }
    }
    
    var fileSystemURL:URL?
    {
        get {
            guard let purpose = purpose else {
                return nil
            }
            
            switch purpose {
            case Purpose.video:
                return mediaItem?.videoDownload?.fileSystemURL
                
            case Purpose.audio:
                return mediaItem?.audioDownload?.fileSystemURL
                
            default:
                return nil
            }
        }
    }
    
    var headerHTML : String {
        if  var headerHTML = self.mediaItem?.headerHTML,
            let purpose = self.purpose {
            headerHTML = headerHTML +
                "<br/>" +
                "<center>MACHINE GENERATED TRANSCRIPT<br/>(\(purpose))</center>" +
                "<br/>"
            return headerHTML
        }
        
        return "NO MEDIAITEM HEADER"
    }
    
    var fullHTML : String {
        return "<!DOCTYPE html><html><body>" + headerHTML + bodyHTML + "</body></html>"
    }
    
    var bodyHTML : String {
        get {
            var htmlString = String()
            
            if  let transcript = self.transcript {
                htmlString = transcript.replacingOccurrences(of: "\n", with: "<br/>")
            }

            return htmlString
        }
    }
    
    // Prevents a background thread from creating multiple timers accidentally
    // by accessing transcript before the timer creation on the main thread is complete.
    var settingTimer = false
    
    var transcript:String?
    {
        get {
            guard (_transcript == nil) else {
                return _transcript
            }
            
            guard mediaID != nil else {
                return nil
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard let id = mediaItem.id else {
                return nil
            }
            
            guard let purpose = purpose else {
                return nil
            }
            
            if completed {
                if let destinationURL = (id+".\(purpose)").fileSystemURL {
                    do {
                        try _transcript = String(contentsOfFile: destinationURL.path, encoding: String.Encoding.utf8) // why not utf16?
                        // This will cause an error.  The tag is created in the constantTags getter while loading.
                        //                    mediaItem.addTag("Machine Generated Transcript")
                        
                        // Also, the tag would normally be added or removed in the didSet for transcript but didSet's are not
                        // called during init()'s which is fortunate.
                    } catch let error {
                        print("failed to load machine generated transcript for \(mediaItem.description): \(error.localizedDescription)")
                        completed = false
                        // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
                        //                        if !aligning {
                        //                            remove()
                        //                        }
                    }
                } else {
                    completed = false
                }
            }

            if !completed && transcribing && !aligning && (self.resultsTimer == nil) && !settingTimer {
                settingTimer = true
                Thread.onMainThread {
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    self.settingTimer = false
                }
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()
                // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
                if self.resultsTimer != nil {
                    print("TIMER NOT NIL!")
                }
            }

            if completed && !transcribing && aligning && (self.resultsTimer == nil) && !settingTimer {
                settingTimer = true
                Thread.onMainThread {
                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    self.settingTimer = false
                }
            } else {
                // Overkill to make sure the cloud storage is cleaned-up?
                //                mediaItem.voicebase?.delete()
                // Actually it causes recurive access to voicebase when voicebase is being lazily instantiated and causes a crash!
                if self.resultsTimer != nil {
                    print("TIMER NOT NIL!")
                }
            }

            return _transcript
        }
        
        set {
            _transcript = newValue
            
            let fileManager = FileManager.default
            
            guard let mediaItem = mediaItem else {
                return
            }

            guard let id = mediaItem.id else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            if _transcript != nil {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    if let destinationURL = (id+".\(purpose)").fileSystemURL {
                        destinationURL.delete()
                        
                        do {
                            try self?._transcript?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8) // why not utf16?
                        } catch let error {
                            print("failed to write transcript to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            } else {
                DispatchQueue.global(qos: .background).async { [weak self] in
                    if let destinationURL = (id+".\(purpose)").fileSystemURL {
                        destinationURL.delete()
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var _transcript:String?
    {
        didSet {
            guard let mediaItem = mediaItem else {
                return
            }
            
            if mediaItem.transcripts.values.filter({ (transcript:VoiceBase) -> Bool in
                return transcript._transcript != nil // self._
            }).count == 0 {
                // This blocks this thread until it finishes.
                Globals.shared.queue.sync {
                    mediaItem.removeTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
                }
            } else {
                // This blocks this thread until it finishes.
                Globals.shared.queue.sync {
                    mediaItem.addTag(Constants.Strings.Transcript + " - " + Constants.Strings.Machine_Generated + " - " + transcriptPurpose)
                }
            }
        }
    }
    
    var wordRangeTiming : [[String:Any]]?
    {
        get {
            guard let transcript = transcript?.lowercased() else {
                return nil
            }
            
            guard var words = words, words.count > 0 else {
                return nil
            }
            
            var wordRangeTiming = [[String:Any]]()
            
            var offset : String.Index?
        
            var lastEnd : Int?
        
            while words.count > 0 {
                let word = words.removeFirst()
                
                guard let text = (word["w"] as? String)?.lowercased().trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: Constants.Strings.TokenDelimiters + Constants.Strings.TrimChars)), !text.isEmpty else {
                    continue
                }
                
                guard let start = word["s"] as? Int else {
                    continue
                }
                
                guard let end = word["e"] as? Int else {
                    continue
                }
                
                var dict:[String:Any] = ["start":Double(start) / 1000.0, "end":Double(end) / 1000.0, "text":text]
            
                if let lastEnd = lastEnd {
                    dict["gap"] = (Double(start) - Double(lastEnd)) / 1000.0
                }
                    
                lastEnd = end

                if offset == nil {
                    offset = transcript.range(of: text)?.lowerBound
                }
                
                if offset != nil {
                    let startingRange = Range(uncheckedBounds: (lower: offset!, upper: transcript.endIndex))
                    if let range = transcript.range(of: text, options: [], range: startingRange, locale: nil) {
                        dict["range"] = range
                        dict["lowerBound"] = range.lowerBound.encodedOffset
                        dict["upperBound"] = range.upperBound.encodedOffset
                        offset = range.upperBound
                    }
                }

                if let metadata = word["m"] as? String { // , metadata == "punc"
                    print(word["w"],metadata)
                } else {
                    wordRangeTiming.append(dict)
                }
            }
            
            return wordRangeTiming.count > 0 ? wordRangeTiming : nil
        }
    }
    
    var mediaJSON: [String:Any]?
    {
        get {
            guard completed else {
                return nil
            }
            
            guard _mediaJSON == nil else {
                return _mediaJSON
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard let id = mediaItem.id else {
                return nil
            }
            
            guard let purpose = purpose else {
                return nil
            }
            
            if let url = ("\(id).\(purpose).media").fileSystemURL, let data = url.data {
                do {
                    _mediaJSON = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String : Any]
                } catch let error {
                    print("failed to load machine generated media for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
//                    if completed && !aligning {
//                        remove()
//                    }
                }
            } else {
                print("failed to open machine generated media for \(mediaItem.description)")
                // Not sure I want to do this since it only removes keywords
//                remove()
            }
            
            return _mediaJSON
        }
        set {
            _mediaJSON = newValue
            
            guard let mediaItem = mediaItem else {
                return
            }
            
            guard let id = mediaItem.id else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                let fileManager = FileManager.default
                
                if self?._mediaJSON != nil {
                    let mediaPropertyList = try? PropertyListSerialization.data(fromPropertyList: self?._mediaJSON as Any, format: .xml, options: 0)
                    
                    if let destinationURL = "\(id).\(purpose).media".fileSystemURL {
                        destinationURL.delete()
//                        if destinationURL.exists {
//                            do {
//                                try fileManager.removeItem(at: destinationURL)
//                            } catch let error {
//                                print("failed to remove machine generated transcript media: \(error.localizedDescription)")
//                            }
//                        }
                        
                        do {
                            try mediaPropertyList?.write(to: destinationURL)
                        } catch let error {
                            print("failed to write machine generated transcript media to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("destinationURL nil!")
                    }
                } else {
                    if let destinationURL = "\(id).\(purpose).media".fileSystemURL {
                        destinationURL.delete()
//                        if destinationURL.exists {
//                            do {
//                                try fileManager.removeItem(at: destinationURL)
//                            } catch let error {
//                                print("failed to remove machine generated transcript media: \(error.localizedDescription)")
//                            }
//                        } else {
//                            print("machine generated transcript media file doesn't exist")
//                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var _mediaJSON : [String:Any]?
    {
        didSet {

        }
    }

    var keywordsJSON: [String:Any]?
    {
        get {
            return mediaJSON?["keywords"] as? [String:Any]
        }
    }
    
    var keywordTimes : [String:[String]]?
    {
        get {
            guard let keywordDictionaries = keywordDictionaries else {
                return nil
            }
            
            var keywordTimes = [String:[String]]()
            
            for name in keywordDictionaries.keys {
                if let dict = keywordDictionaries[name], let speakers = dict["t"] as? [String:Any], let times = speakers["unknown"] as? [String] {
                    keywordTimes[name] = times.map({ (time) -> String in
                        return time.secondsToHMS!
                    })
                }
            }
            
            return keywordTimes.count > 0 ? keywordTimes : nil
        }
    }
    
    var keywordDictionaries : [String:[String:Any]]?
    {
        get {
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
    }
    
    var keywords : [String]?
    {
        get {
            if let keywords = keywordDictionaries?.filter({ (key: String, value: [String : Any]) -> Bool in
                if let speakerTimes = value["t"] as? [String:[String]] {
                    if let times = speakerTimes["unknown"] {
                        return times.count > 0
                    }
                }
                return false
            }).map({ (key: String, value: [String : Any]) -> String in
                return key.uppercased()
            }) {
                return keywords
            } else {
                return nil
            }
        }
    }
    
    // Make thread safe?
    var transcriptsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["transcripts"] as? [String:Any]
        }
    }
    
    // Make thread safe?
    var transcriptLatest : [String:Any]?
    {
        get {
            return transcriptsJSON?["latest"] as? [String:Any]
        }
    }
    
    // Make thread safe?
    var tokens : [String:Int]?
    {
        get {
            guard let words = words else {
                return nil
            }
            
            var tokens = [String:Int]()
            
            for word in words {
                if let text = (word["w"] as? String)?.uppercased(), !text.isEmpty, (Int(text) == nil) && !CharacterSet(charactersIn:text).intersection(CharacterSet(charactersIn:"ABCDEFGHIJKLMNOPQRSTUVWXYZ")).isEmpty && CharacterSet(charactersIn:text).intersection(CharacterSet(charactersIn:".")).isEmpty {
                    if let count = tokens[text] {
                        tokens[text] = count + 1
                    } else {
                        tokens[text] = 1
                    }
                }
            }
            
            return tokens.count > 0 ? tokens : nil
        }
    }
    
    // Make thread safe?
    var words : [[String:Any]]?
    {
        get {
            return transcriptLatest?["words"] as? [[String:Any]]
        }
    }
    
    var transcriptFromWords : String?
    {
        get {
            var transcript:String?
            
            if let words = words {
                var index = 0
                
                for word in words {
                    if let string = word["w"] as? String {
                        if let metadata = word["m"] as? String, metadata == "punc" {
                            var spacing = String()
                            
                            switch string {
                            case ".":
                                spacing = " "
                                
                            default:
                                spacing = ""
                                break
                            }
                            
                            transcript = (transcript != nil ? transcript! : "") + string + (index < (words.count - 1) ? spacing : " ")
                        } else {
                            transcript = (transcript != nil ? transcript! + (!transcript!.isEmpty ? " " : "") : "") + string
                        }
                    }
                    index += 1
                }
            }
            
            return transcript?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) //?.replacingOccurrences(of: ".   ", with: ".  ")
        }
    }
    
    // Make thread safe?
    var topicsJSON : [String:Any]?
    {
        get {
            return mediaJSON?["topics"] as? [String:Any]
        }
    }
    
    // Make thread safe?
    var topicsDictionaries : [String:[String:Any]]?
    {
        get {
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
    }
    
    // Make thread safe?
    var topics : [String]?
    {
        get {
            if let topics = topicsDictionaries?.map({ (key: String, value: [String : Any]) -> String in
                return key
            }) {
                return topics
            } else {
                return nil
            }
        }
    }
    
    init(mediaItem:MediaItem,purpose:String)
    {
        self.mediaItem = mediaItem
        
        self.purpose = purpose

        if let mediaID = mediaItem.mediaItemSettings?["mediaID."+purpose] {
            self.mediaID = mediaID
            
            if let completed = mediaItem.mediaItemSettings?["completed."+purpose] {
                self.completed = (completed == "YES") // && (mediaID != nil)
            }
            
            if let transcribing = mediaItem.mediaItemSettings?["transcribing."+purpose] {
                self.transcribing = (transcribing == "YES") // && (mediaID != nil)
            }
            
            if let aligning = mediaItem.mediaItemSettings?["aligning."+purpose] {
                self.aligning = (aligning == "YES") // && (mediaID != nil)
            }
            
            if !completed {
                if transcribing || aligning {
                    // We need to check and see if it is really on VB and if not, clean things up.
                    
                }
            } else {
                if transcribing || aligning {
                    // This seems wrong.
                    
                }
            }
        }
    }
    
    deinit {
        
    }
    
    func createBody(parameters: [String: String],boundary: String) -> NSData
    {
        let body = NSMutableData()
        
        let boundaryPrefix = "--\(boundary)\r\n"
        
        for (key, value) in parameters {
            switch key {
                // This works? But isn't necessary?
//            case "transcript":
//                if let id = mediaItem?.id { // , let data = value.data(using: String.Encoding.utf8) // why not utf16?
//                    let mimeType = "text/plain"
//                    body.appendString(boundaryPrefix)
//                    body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(id)\"\r\n")
//                    body.appendString("Content-Type: \(mimeType)\r\n\r\n")
//                    body.appendString(value)
//                    body.appendString("\r\n")
//                }
//                break
                
                // This works, but uploading the file takes A LOT longer than the URL!
//            case "media":
//                if let purpose = purpose, let id = mediaItem?.id {
//                    var mimeType : String?
//
//                    switch purpose {
//                    case Purpose.audio:
//                        mimeType = "audio/mpeg"
//                        break
//
//                    case Purpose.video:
//                        mimeType = "video/mp4"
//                        break
//
//                    default:
//                        break
//                    }
//
//                    if let mimeType = mimeType, let url = URL(string: value), let audioData = try? Data(contentsOf: url) {
//                        body.appendString(boundaryPrefix)
//                        body.appendString("Content-Disposition: form-data; name=\"\(key)\"; filename=\"\(id)\"\r\n")
//                        body.appendString("Content-Type: \(mimeType)\r\n\r\n")
//                        body.append(audioData)
//                        body.appendString("\r\n")
//                    }
//                }
//                break
                
            default:
                body.appendString(boundaryPrefix)
                body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString("\(value)\r\n")
                break
            }
        }
        
        body.appendString("--".appending(boundary.appending("--\r\n")))

        return body //as Data
    }
    
    func post(path:String?,parameters:[String:String]?,completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        guard Globals.shared.isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
            return
        }
        
        guard let parameters = parameters else {
            return
        }
        
        guard let url = URL(string:VoiceBase.url(mediaID:mediaID, path:path, query:nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let body = createBody(parameters: parameters,boundary: boundary)
        
        request.httpBody = body as Data
        request.setValue(String(body.length), forHTTPHeaderField: "Content-Length")
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = 30.0 * 60.0
        let session = URLSession(configuration: sessionConfig)

        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("post response: ",response.description)

                if let httpResponse = response as? HTTPURLResponse {
                    print("post HTTP response: ",httpResponse.description)
                    print("post HTTP response: ",httpResponse.allHeaderFields)
                    print("post HTTP response: ",httpResponse.statusCode)
                    print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))

                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }

            var json : [String:Any]?

            if let data = data, data.count > 0 {
                let string = String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)
                
                json = data.json as? [String:Any]
                print(json as Any)
                
                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }

//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }

            if errorOccured {
                Thread.onMainThread {
                    onError?(json)
                }
            } else {
                Thread.onMainThread {
                    completion?(json)
                }
            }
        })
        
        task.resume()
    }
    
    func userInfo(alert:Bool,detailedAlerts:Bool,
                  finishedTitle:String?,finishedMessage:String?,onFinished:(()->(Void))?,
                  errorTitle:String?,errorMessage:String?,onError:(()->(Void))?) -> [String:Any]?
    {
        var userInfo = [String:Any]()
        
        userInfo["completion"] = { (json:[String : Any]?) -> (Void) in
            guard let status = json?["status"] as? String else {
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: errorMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onError?()
                return
            }

            guard let title = self.mediaItem?.title else {
                return
            }
            
            switch status {
            case "finished":
                if alert, let finishedTitle = finishedTitle {
                    Alerts.shared.alert(title: finishedTitle,message: finishedMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onFinished?()
                break
                
            case "failed":
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: errorMessage)
                }
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.percentComplete = nil
                
                onError?()
                break
                
            default:
                guard let progress = json?["progress"] as? [String:Any] else {
                    print("\(title) (\(self.transcriptPurpose)) no progress")
                    break
                }
                
                guard let tasks = progress["tasks"] as? [String:Any] else {
                    print("\(title) (\(self.transcriptPurpose)) no tasks")
                    break
                }
                
                let count = tasks.count
                let finished = tasks.filter({ (key: String, value: Any) -> Bool in
                    if let dict = value as? [String:Any] {
                        if let status = dict["status"] as? String {
                            return (status == "finished") || (status == "completed")
                        }
                    }
                    
                    return false
                }).count
                
                if count > 0 {
                    self.percentComplete = String(format: "%0.0f",Double(finished)/Double(count) * 100.0)
                } else {
                    self.percentComplete = "0"
                }
                
                if let percentComplete = self.percentComplete {
                    print("\(title) (\(self.transcriptPurpose)) is \(percentComplete)% finished")
                }
                break
            }
        }
        
        userInfo["onError"] = { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            if let error = error {
                if alert, let errorTitle = errorTitle {
                    Alerts.shared.alert(title: errorTitle,message: (errorMessage ?? "") + "\n\nError: \(error)")
                }
            } else {
                if let text = self.mediaItem?.text {
                    print("An unknown error occured while monitoring the transcription of \n\n\(text).")
                } else {
                    print("An unknown error occured while monitoring a transcription.")
                }
            }
            
            onError?()
        }
        
        return userInfo.count > 0 ? userInfo : nil
    }
    
    func uploadUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }
        
        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcription Completed", finishedMessage: "The transcription process for\n\n\(text) (\(self.transcriptPurpose))\n\nhas completed.", onFinished: {
                            self.getTranscript(alert:detailedAlerts) {
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {
                                        self.transcribing = false
                                        self.completed = true
                                        
                                        // This is where we MIGHT ask the user if they want to view/edit the transcript but I'm not
                                        // sure I can predict the context in which this (i.e. that) would happen.
                                    }
                                }
                            }
                        },
                        errorTitle: "Transcription Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not completed.  Please try again.", onError: {
                            self.remove()
                            
                            Thread.onMainThread {
                                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_COMPLETE), object: self)
                                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
                            }
                        })
    }
    
    func uploadNotAccepted(_ json:[String:Any]?)
    {
        var error : String?
        
        if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
            error = message
        }
        
        if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
            error = message
        }
        
        var message : String?
        
        if let text = self.mediaItem?.text {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            } else {
                message = "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            }
        } else {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript failed to start.  Please try again."
            } else {
                message = "The transcript failed to start.  Please try again."
            }
        }
        
        if let message = message {
            Alerts.shared.alert(title: "Transcription Failed",message: message)
        }
    }
    
    func upload()
    {
        guard let url = url else {
            return
        }
        
        transcribing = true

        var parameters:[String:String] = ["mediaUrl":url,"metadata":self.metadata] //
        
        if let configuration = VoiceBase.configuration {
            parameters["configuration"] = configuration
        }
        
        post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            self.uploadJSON = json
            
            guard let status = json?["status"] as? String else {
                // Not accepted.
                self.transcribing = false
                
                self.uploadNotAccepted(json)
                return
            }
            
            switch status {
            case "accepted":
                guard let mediaID = json?["mediaId"] as? String else {
                    // Not accepted.
                    self.transcribing = false
                    
                    self.uploadNotAccepted(json)
                    break
                }
                
                self.mediaID = mediaID
                
                if let text = self.mediaItem?.text {
                    Alerts.shared.alert(title:"Machine Generated Transcript Started", message:"The machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been started.  You will be notified when it is complete.")
                }
                
                if self.resultsTimer == nil {
                    Thread.onMainThread {
                        self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.uploadUserInfo(alert:true,detailedAlerts:false), repeats: true)
                    }
                } else {
                    print("TIMER NOT NIL!")
                }
                break
                
            default:
                // Not accepted.
                self.transcribing = false
                
                self.uploadNotAccepted(json)
                break
            }
        }, onError: { (json:[String : Any]?) -> (Void) in
            self.transcribing = false
            
            self.uploadNotAccepted(json)
            
            Thread.onMainThread {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.FAILED_TO_UPLOAD), object: self)
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_FAILED_TO_START), object: self)
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_STOP_EDITING_CELL), object: self.mediaItem)
            }
        })
    }
    
    func progress(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.get(accept:nil, mediaID: mediaID, path: "progress", query: nil, completion: completion, onError: onError)
    }
    
    @objc func monitor(_ timer:Timer?)
    {
        // Expected to be on the main thread
        guard   let dict = timer?.userInfo as? [String:Any],
            let completion = dict["completion"] as? (([String:Any]?)->(Void)),
            let onError = dict["onError"] as? (([String:Any]?)->(Void)) else {
            return
        }
        
        progress(completion: completion, onError: onError)
    }
    
    func delete()
    {
        guard Globals.shared.isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
            return
        }
        
        guard let mediaID = mediaID else {
            return
        }

        guard let url = URL(string: VoiceBase.url(mediaID:mediaID, path:nil, query: nil)) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "DELETE"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("post HTTP response: ",httpResponse.description)
                    print("post HTTP response: ",httpResponse.allHeaderFields)
                    print("post HTTP response: ",httpResponse.statusCode)
                    print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                    
                    if (httpResponse.statusCode == 204) || (httpResponse.statusCode == 404) {
                        // It eithber completed w/o error (204) so it is now gone and we should set mediaID to nil
                        // OR it couldn't be found (404) in which case it should also be set to nil.

                        // WE DO NOT HAVE TO SET THIS TO NIL.
                        // self.mediaID = nil
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, data.count > 0 {
                let string = String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)

                json = data.json as? [String:Any]
                print(json as Any)
                
                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }

//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }
            
            if errorOccured {

            } else {
            
            }
        })
        
        task.resume()
    }
    
    func remove()
    {
        delete()

        // Must retain purpose and mediaItem.
        
        mediaID = nil
        
        transcribing = false
        completed = false
        aligning = false

        percentComplete = nil
        
        uploadJSON = nil
        mediaJSON = nil
        
        resultsTimer?.invalidate()
        resultsTimer = nil
        
        transcript = nil
        transcriptSegments = nil
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
    
    // Make thread safe?
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
    
    // Make thread safe?
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
    
    func details(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.details(mediaID: mediaID, completion: completion, onError: onError)
    }

    func details(alert:Bool, atEnd:(()->())?)
    {
        details(completion: { (json:[String : Any]?) -> (Void) in
            if let json = json?["media"] as? [String:Any] {
                self.mediaJSON = json
                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Keywords Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare available.")
                }
            } else {
                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
                }
            }

            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert, let text = self.mediaItem?.text {
                Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords for\n\n\(text) (\(self.transcriptPurpose))\n\nare not available.")
            } else {
                Alerts.shared.alert(title: "Keywords Not Available",message: "The keywords are not available.")
            }

            atEnd?()
        })
    }
    
    func metadata(completion:(([String:Any]?)->(Void))?,onError:(([String:Any]?)->(Void))?)
    {
        VoiceBase.get(accept: nil, mediaID: mediaID, path: "metadata", query: nil, completion: completion, onError: onError)
    }
    
    func addMetaData()
    {
        var parameters:[String:String] = ["metadata":metadata]
        
        if let configuration = VoiceBase.configuration {
            parameters["configuration"] = configuration
        }

        post(path: "metadata", parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
            
        }, onError: { (json:[String : Any]?) -> (Void) in
            
        })
    }
    
    // Not possible.  VB introduces errors in capitalization and extraneous spaces
    // Even if we took a sample before or after the string to match to try and put
    // the string in the right place I doubt it could be done as we never know where
    // VB might introduce an error which would cause the match to fail.
    //
    // All a successful relaignment does is make the timing index match the audio.
    // That's it.  The whole transcript from VB will never match the alignment source.
    //
//    func correctAlignedTranscript()
//    {
//        guard let alignmentSource = alignmentSource else {
//            return
//        }
//
//        let string = "\n\n"
//
//        var ranges = [Range<String.Index>]()
//
//        var startingRange = Range(uncheckedBounds: (lower: alignmentSource.startIndex, upper: alignmentSource.endIndex))
//
//        while let range = alignmentSource.range(of: string, options: [], range: startingRange, locale: nil) {
//            ranges.append(range)
//            startingRange = Range(uncheckedBounds: (lower: range.upperBound, upper: alignmentSource.endIndex))
//        }
//
//        if var newTranscript = transcript {
//            for range in ranges {
//                let before = String(newTranscript[..<range.lowerBound]).trimmingCharacters(in: CharacterSet(charactersIn: " "))
//                let after = String(newTranscript[range.lowerBound...]).trimmingCharacters(in: CharacterSet(charactersIn: " "))
//                newTranscript = before + string + after
//            }
//            transcript = newTranscript
//        }
//    }
    
    func alignUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }

        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Alignment Complete", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been realigned.", onFinished: {
                            // Get the new versions.
                            self.getTranscript(alert:detailedAlerts) {
//                                self.correctAlignedTranscript()
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {
                                        self.aligning = false
                                    }
                                }
                            }
                        },
                        errorTitle: "Transcript Alignment Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not realigned.  Please try again.", onError: {
                            // WHY would we remove when an alignment fails?
//                            self.remove()
                            self.aligning = false
                        })
    }

    func alignmentNotAccepted(_ json:[String:Any]?)
    {
        var error : String?
        
        if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
            error = message
        }
        
        if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
            error = message
        }
        
        var message : String?
        
        if let text = self.mediaItem?.text {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript alignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            } else {
                message = "The transcript alignment for\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
            }
        } else {
            if let error = error {
                message = "Error: \(error)\n\n" + "The transcript alignment failed to start.  Please try again."
            } else {
                message = "The transcript alignment failed to start.  Please try again."
            }
        }

        if let message = message {
            Alerts.shared.alert(title: "Transcript Alignment Failed",message: message)
        }
    }
    
    func align(_ transcript:String?)
    {
        guard let transcript = transcript else {
            return
        }
        
        guard completed else {
            // Should never happen.
            return
        }
        
        guard !aligning else {
            if let text = self.mediaItem?.text {
                Alerts.shared.alert(title:"Transcript Alignment in Progress", message:"The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis already being aligned.  You will be notified when it is completed.")
            }
            return
        }
        
        aligning = true

        // WHY are we calling progress?  To see if the media is on VB.
        progress(completion: { (json:[String : Any]?) -> (Void) in
            var parameters:[String:String] = ["transcript":transcript]
            
            if let configuration = VoiceBase.configuration {
                parameters["configuration"] = configuration
            }
            
            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json

                guard let status = json?["status"] as? String else {
                    // Not accepted
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.alignmentNotAccepted(json)
                    return
                }
                
                switch status {
                // If it is on VB, upload the transcript for alignment
                case "accepted":
                    guard let mediaID = json?["mediaId"] as? String else {
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.alignmentNotAccepted(json)
                        
                        break
                    }
                    
                    guard self.mediaID == mediaID else {
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.alignmentNotAccepted(json)
                        
                        return
                    }
                    
                    self.alignmentSource = transcript
                    
                    // Don't set transcribing to true and completed to false because we're just re-aligning.
                    
                    let title =  "Machine Generated Transcript Alignment Started"
                    
                    var message = "Realigning the machine generated transcript"
                    
                    if let text = self.mediaItem?.text {
                        message += " for\n\n\(text) (\(self.transcriptPurpose))"
                    }
                    
                    message += "\n\nhas started.  You will be notified when it is complete."
                    
                    Alerts.shared.alert(title:title, message:message)
                    
                    if self.resultsTimer == nil {
                        Thread.onMainThread {
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                        }
                    } else {
                        print("TIMER NOT NIL!")
                    }
                    break
                    
                default:
                    break
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false

                self.resultsTimer?.invalidate()
                self.resultsTimer = nil

                self.alignmentNotAccepted(json)
            })
        }, onError: { (json:[String : Any]?) -> (Void) in
            guard let url = self.url else {
                // Alert?
                return
            }
            
            // Not on VoiceBase
            
            if let text = self.mediaItem?.text {
                Alerts.shared.alert(title:"Media Not on VoiceBase", message:"The media for\n\n\(text) (\(self.transcriptPurpose))\n\nis not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript alignment is started.")
            } else {
                Alerts.shared.alert(title:"Media Not on VoiceBase", message:"The media is not on VoiceBase. The media will have to be uploaded again.  You will be notified once that is completed and the transcript alignment is started.")
            }
            
            // Upload then align
            self.mediaID = nil
            
            var parameters:[String:String] = ["media":url,"metadata":self.metadata]
            
            if let configuration = VoiceBase.configuration {
                parameters["configuration"] = configuration
            }

            self.post(path:nil,parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                self.uploadJSON = json
                
                guard let status = json?["status"] as? String else {
                    // Not accepted.
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.alignmentNotAccepted(json)
                    return
                }
            
                switch status {
                case "accepted":
                    guard let mediaID = json?["mediaId"] as? String else {
                        // No media ID???
                        self.aligning = false
                        
                        self.resultsTimer?.invalidate()
                        self.resultsTimer = nil
                        
                        self.alignmentNotAccepted(json)
                        break
                    }
                    
                    // We do get a new mediaID
                    self.mediaID = mediaID
                    
                    if let text = self.mediaItem?.text {
                        Alerts.shared.alert(title:"Media Upload Started", message:"The transcript alignment for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be started once the media upload has completed.")
                    }
                    
                    if self.resultsTimer == nil {
                        let newUserInfo = self.userInfo(alert: false, detailedAlerts: false,
                                                        finishedTitle: nil, finishedMessage: nil, onFinished: {
                                                            // Now do the relignment
                                                            var parameters:[String:String] = ["transcript":transcript]
                                                            
                                                            if let configuration = VoiceBase.configuration {
                                                                parameters["configuration"] = configuration
                                                            }
                                                            
                                                            self.post(path:nil, parameters: parameters, completion: { (json:[String : Any]?) -> (Void) in
                                                                self.uploadJSON = json

                                                                guard let status = json?["status"] as? String else {
                                                                    // Not accepted.
                                                                    self.aligning = false
                                                                    
                                                                    self.resultsTimer?.invalidate()
                                                                    self.resultsTimer = nil
                                                                    
                                                                    self.alignmentNotAccepted(json)
                                                                    return
                                                                }
                                                                
                                                                switch status {
                                                                // If it is on VB, upload the transcript for alignment
                                                                case "accepted":
                                                                    guard let mediaID = json?["mediaId"] as? String else {
                                                                        // Not accepted.
                                                                        self.aligning = false
                                                                        
                                                                        self.resultsTimer?.invalidate()
                                                                        self.resultsTimer = nil
                                                                        
                                                                        self.alignmentNotAccepted(json)
                                                                        
                                                                        break
                                                                    }
                                                                    
                                                                    guard self.mediaID == mediaID else {
                                                                        // Not accepted.
                                                                        self.aligning = false
                                                                        
                                                                        self.resultsTimer?.invalidate()
                                                                        self.resultsTimer = nil
                                                                        
                                                                        self.alignmentNotAccepted(json)
                                                                        
                                                                        return
                                                                    }
                                                                    
                                                                    // Don't set transcribing to true and completed to false because we're just re-aligning.
                                                                    
                                                                    self.aligning = true
                                                                    
                                                                    if let text = self.mediaItem?.text {
                                                                        Alerts.shared.alert(title:"Machine Generated Transcript Alignment Started", message:"Realigning the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas started.  You will be notified when it is complete.")
                                                                    }
                                                                    
                                                                    if self.resultsTimer == nil {
                                                                        Thread.onMainThread {
                                                                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.alignUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                                                        }
                                                                    } else {
                                                                        print("TIMER NOT NIL!")
                                                                    }
                                                                    break
                                                                    
                                                                default:
                                                                    // Not accepted.
                                                                    self.aligning = false
                                                                    
                                                                    self.resultsTimer?.invalidate()
                                                                    self.resultsTimer = nil
                                                                    
                                                                    self.alignmentNotAccepted(json)
                                                                    break
                                                                }
                                                            }, onError: { (json:[String : Any]?) -> (Void) in
                                                                self.aligning = false
                                                                
                                                                self.resultsTimer?.invalidate()
                                                                self.resultsTimer = nil
                                                                
                                                                self.alignmentNotAccepted(json)
                                                            })
                        },
                                                        errorTitle: nil, errorMessage: nil, onError: {
                                                            self.aligning = false
                                                            self.alignmentNotAccepted(json)
                        })
                        
                        Thread.onMainThread {
                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 10.0, target: self, selector: #selector(self.monitor(_:)), userInfo: newUserInfo, repeats: true)
                        }
                    } else {
                        print("TIMER NOT NIL!")
                    }
                    break
                    
                default:
                    // Not accepted.
                    self.aligning = false
                    
                    self.resultsTimer?.invalidate()
                    self.resultsTimer = nil
                    
                    self.alignmentNotAccepted(json)
                    break
                }
            }, onError: { (json:[String : Any]?) -> (Void) in
                self.aligning = false
                
                self.resultsTimer?.invalidate()
                self.resultsTimer = nil
                
                self.alignmentNotAccepted(json)
            })
        })
    }
    
    func getTranscript(alert:Bool, atEnd:(()->())?)
    {
        guard let mediaID = mediaID else {
            upload()
            return
        }
        
        VoiceBase.get(accept:"text/plain",mediaID: mediaID, path: "transcripts/latest", query: nil, completion: { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            if let error = error {
                print(error)
            }
            
            if let text = json?["text"] as? String {
                self.transcript = text

                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Transcript Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis available.")
                }
                
                Thread.onMainThread {
                    NotificationCenter.default.post(name: NSNotification.Name(rawValue: Constants.NOTIFICATION.TRANSCRIPT_COMPLETED), object: self)
                }
            } else {
                if let error = error {
                    if alert, let text = self.mediaItem?.text {
                        Alerts.shared.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.\n\nError: \(error)")
                    }
                } else {
                    if alert, let text = self.mediaItem?.text {
                        Alerts.shared.alert(title: "Transcript Not Available",message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
                    }
                }
            }
            
            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            var error : String?
            
            if error == nil, let message = (json?["errors"] as? [String:Any])?["error"] as? String {
                error = message
            }
            
            if error == nil, let message =  (json?["errors"] as? [[String:Any]])?[0]["error"] as? String {
                error = message
            }
            
            var message : String?
            
            if let text = self.mediaItem?.text {
                if let error = error {
                    message = "Error: \(error)\n\n" + "The transcription of\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
                } else {
                    message = "The transcription of\n\n\(text) (\(self.transcriptPurpose))\n\nfailed to start.  Please try again."
                }
            } else {
                if let error = error {
                    message = "Error: \(error)\n\n" + "The transcription failed to start.  Please try again."
                } else {
                    message = "The transcription failed to start.  Please try again."
                }
            }
            
            if let message = message {
                Alerts.shared.alert(title: "Transcription Failed",message: message)
            }
            
            atEnd?()
        })
    }
    
    // Make thread safe?
    var transcriptSegmentArrays:[[String]]?
    {
        get {
            guard _transcriptSegmentArrays == nil else {
                return _transcriptSegmentArrays
            }
            
            let _ = transcriptSegments
            
            return _transcriptSegmentArrays
        }
        set {
            _transcriptSegmentArrays = newValue
        }
    }
    
    // Make thread safe?
    var _transcriptSegmentArrays:[[String]]?
    {
        didSet {
            guard let transcriptSegmentArrays = _transcriptSegmentArrays else {
                return
            }
            
            var tokenTimes = [String:[String]]()
            
            for transcriptSegmentArray in transcriptSegmentArrays {
                if let times = transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray), let startTime = times.first {
                    if let tokens = tokensFromString(transcriptSegmentArrayText(transcriptSegmentArray: transcriptSegmentArray)) {
                        for token in tokens {
                            let key = token
                            
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
            
            transcriptSegmentTokensTimes = tokenTimes.count > 0 ? tokenTimes : nil
        }
    }
    
    // Make thread safe?
    var transcriptSegmentTokens : [String]?
    {
        return transcriptSegmentTokensTimes?.keys.sorted()
    }
    
    func transcriptSegmentTokenTimes(token:String) -> [String]?
    {
        return transcriptSegmentTokensTimes?[token]
    }
    
    // Make thread safe?
    var transcriptSegmentTokensTimes : [String:[String]]?
    {
        get {
            guard _transcriptSegmentTokensTimes == nil else {
                return _transcriptSegmentTokensTimes
            }
            
            let _ = transcriptSegments
            
            return _transcriptSegmentTokensTimes
        }
        set {
            _transcriptSegmentTokensTimes = newValue
        }
    }
    
    // Make thread safe?
    var _transcriptSegmentTokensTimes : [String:[String]]?
    {
        didSet {
            
        }
    }
    
    func transcriptSegmentArrayStartTime(transcriptSegmentArray:[String]?) -> Double?
    {
        return transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray)?.first?.hmsToSeconds
    }
    
    func transcriptSegmentArrayEndTime(transcriptSegmentArray:[String]?) -> Double?
    {
        return transcriptSegmentArrayTimes(transcriptSegmentArray: transcriptSegmentArray)?.last?.hmsToSeconds
    }
    
    func transcriptSegmentArrayIndex(transcriptSegmentArray:[String]?) -> String?
    {
        return transcriptSegmentArray?.first
    }
    
    func transcriptSegmentArrayTimes(transcriptSegmentArray:[String]?) -> [String]?
    {
        guard let transcriptSegmentArray = transcriptSegmentArray else {
            return nil
        }
        
        guard transcriptSegmentArray.count > 1 else {
            return nil
        }
        
        var array = transcriptSegmentArray
        
        if let count = array.first, !count.isEmpty {
            array.remove(at: 0)
        } else {
            return nil
        }
        
        if let timeWindow = array.first, !timeWindow.isEmpty {
            array.remove(at: 0)
            let times = timeWindow.components(separatedBy: " --> ")
            
            return times
        } else {
            return nil
        }
    }
    
    func transcriptSegmentArrayText(transcriptSegmentArray:[String]?) -> String?
    {
        guard let transcriptSegmentArray = transcriptSegmentArray else {
            return nil
        }
        
        guard transcriptSegmentArray.count > 1 else {
            return nil
        }
        
        var string = String()
        
        var array = transcriptSegmentArray
        
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
    
    func searchTranscriptSegmentArrays(string:String) -> [[String]]?
    {
        guard let transcriptSegmentArrays = transcriptSegmentArrays else {
            return nil
        }
        
        var results = [[String]]()
        
        for transcriptSegmentArray in transcriptSegmentArrays {
            if let contains = transcriptSegmentArrayText(transcriptSegmentArray: transcriptSegmentArray)?.contains(string.lowercased()), contains {
                results.append(transcriptSegmentArray)
            }
        }
        
        return results.count > 0 ? results : nil
    }
    
    // Make thread safe?
    var transcriptSegmentComponents:[String]?
    {
        get {
            guard _transcriptSegmentComponents == nil else {
                return _transcriptSegmentComponents
            }
            
            let _ = transcriptSegments
            
            return _transcriptSegmentComponents
        }
        set {
            _transcriptSegmentComponents = newValue
        }
    }
    
    // Make thread safe?
    var _transcriptSegmentComponents:[String]?
    {
        didSet {
            guard let transcriptSegmentComponents = _transcriptSegmentComponents else {
                return
            }
            
            var transcriptSegmentArrays = [[String]]()
            
            for transcriptSegmentComponent in transcriptSegmentComponents {
                transcriptSegmentArrays.append(transcriptSegmentComponent.components(separatedBy: "\n"))
            }
            
            self.transcriptSegmentArrays = transcriptSegmentArrays.count > 0 ? transcriptSegmentArrays : nil
        }
    }
    
    var transcriptSegments:String?
    {
        get {
            guard completed else {
                return nil
            }
            
            guard _transcriptSegments == nil else {
                return _transcriptSegments
            }
            
            guard let mediaItem = mediaItem else {
                return nil
            }
            
            guard let id = mediaItem.id else {
                return nil
            }
            
            guard let purpose = purpose else {
                return nil
            }
            
            //Legacy
            if let url = "\(id).\(purpose).srt".fileSystemURL {
                do {
                    try _transcriptSegments = String(contentsOfFile: url.path, encoding: String.Encoding.utf8) // why not utf16
                } catch let error {
                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
                    //                    if completed && !aligning {
                    //                        remove()
                    //                    }
                }
            }
            
            if let url = "\(id).\(purpose).segments".fileSystemURL {
                do {
                    try _transcriptSegments = String(contentsOfFile: url.path, encoding: String.Encoding.utf8) // why not utf16?
                } catch let error {
                    print("failed to load machine generated transcriptSegments for \(mediaItem.description): \(error.localizedDescription)")
                    
                    // this doesn't work because these flags are set too quickly so aligning is false by the time it gets here!
                    //                    if completed && !aligning {
                    //                        remove()
                    //                    }
                }
            }
            
            return _transcriptSegments
        }
        
        set {
            guard let mediaItem = mediaItem else {
                return
            }
            
            guard let id = mediaItem.id else {
                return
            }
            
            guard let purpose = purpose else {
                return
            }
            
            var changed = false
            
            var value = newValue
            
            if _transcriptSegments == nil {
                // Why do we do this?  To strip any header like SRT or WebVTT and remove newlines and add separator
                if var transcriptSegmentComponents = value?.components(separatedBy: "\n\n") {
                    for transcriptSegmentComponent in transcriptSegmentComponents {
                        var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                        if transcriptSegmentArray.count > 2 {
                            let count = transcriptSegmentArray.removeFirst()
                            let timeWindow = transcriptSegmentArray.removeFirst()
                            
                            if let range = transcriptSegmentComponent.range(of: timeWindow + "\n") {
                                let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                
                                if let index = transcriptSegmentComponents.index(of: transcriptSegmentComponent) {
                                    transcriptSegmentComponents[index] = "\(count)\n\(timeWindow)\n" + text
                                    changed = true
                                }
                            }
                        }
                    }
                    if changed { // Essentially guaranteed to happen.
                        value = nil
                        for transcriptSegmentComponent in transcriptSegmentComponents {
                            let transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            if transcriptSegmentArray.count > 2 { // This removes anything w/o text, i.e. only count and timeWindow - or less, like a header, e.g. WebVTT (a nice side effect)
                                value = (value != nil ? value! + VoiceBase.separator : "") + transcriptSegmentComponent
                            }
                        }
                    }
                }
            }
            
            _transcriptSegments = value
            
            DispatchQueue.global(qos: .background).async { [weak self] in
                let fileManager = FileManager.default
                
                if self?._transcriptSegments != nil {
                    if let destinationURL = (id+".\(purpose).segments").fileSystemURL {
                        destinationURL.delete()
//                        // Check if file exist
//                        if (fileManager.fileExists(atPath: destinationURL.path)){
//                            do {
//                                try fileManager.removeItem(at: destinationURL)
//                            } catch let error {
//                                print("failed to remove machine generated segment transcript: \(error.localizedDescription)")
//                            }
//                        }
                        
                        do {
                            try self?._transcriptSegments?.write(toFile: destinationURL.path, atomically: false, encoding: String.Encoding.utf8) // why not utf16?
                        } catch let error {
                            print("failed to write segment transcript to cache directory: \(error.localizedDescription)")
                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                    
                    //Legacy clean-up
                    if let destinationURL = (id+".\(purpose).srt").fileSystemURL {
                        destinationURL.delete()
//                        // Check if file exist
//                        if (fileManager.fileExists(atPath: destinationURL.path)){
//                            do {
//                                try fileManager.removeItem(at: destinationURL)
//                            } catch let error {
//                                print("failed to remove machine generated segment transcript: \(error.localizedDescription)")
//                            }
//                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                } else {
                    if let destinationURL = (id+".\(purpose).segments").fileSystemURL {
                        destinationURL.delete()
//                        // Check if file exist
//                        if (fileManager.fileExists(atPath: destinationURL.path)){
//                            do {
//                                try fileManager.removeItem(at: destinationURL)
//                            } catch let error {
//                                print("failed to remove machine generated transcript: \(error.localizedDescription)")
//                            }
//                        } else {
//                            print("machine generated transcript file doesn't exist")
//                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                    
                    //Legacy clean-up
                    if let destinationURL = (id+".\(purpose).srt").fileSystemURL {
                        destinationURL.delete()
//                        // Check if file exist
//                        if (fileManager.fileExists(atPath: destinationURL.path)){
//                            do {
//                                try fileManager.removeItem(at: destinationURL)
//                            } catch let error {
//                                print("failed to remove machine generated transcript: \(error.localizedDescription)")
//                            }
//                        } else {
//                            print("machine generated transcript file doesn't exist")
//                        }
                    } else {
                        print("failed to get destinationURL")
                    }
                }
            }
        }
    }
    
    var _transcriptSegments:String?
    {
        didSet {
            transcriptSegmentComponents = _transcriptSegments?.components(separatedBy: VoiceBase.separator)
        }
    }
    
    var transcriptSegmentsFromWords:String?
    {
        get {
            var str : String?
            
            if let wordRangeTiming = wordRangeTiming {
                var count = 1
                var transcriptSegmentComponents = [String]()
                
                for element in wordRangeTiming {
                    if  let start = element["start"] as? Double,
                        let startSeconds = start.secondsToHMS,
                        let end = element["end"] as? Double,
                        let endSeconds = end.secondsToHMS,
                        let text = element["text"] as? String {
                        transcriptSegmentComponents.append("\(count)\n\(startSeconds) --> \(endSeconds)\n\(text)")
                    }
                    count += 1
                }

                for transcriptSegmentComponent in transcriptSegmentComponents {
                    str = (str != nil ? str! + VoiceBase.separator : "") + transcriptSegmentComponent
                }
            }
            
            return str
        }
    }
    
    var transcriptSegmentsFromTranscriptSegments:String?
    {
        get {
            var str : String?
            
            if let transcriptSegmentComponents = transcriptSegmentComponents {
                for transcriptSegmentComponent in transcriptSegmentComponents {
                    str = (str != nil ? str! + VoiceBase.separator : "") + transcriptSegmentComponent
                }
            }
            
            return str
        }
    }
    
    var transcriptFromTranscriptSegments:String?
    {
        get {
            var str : String?
            
            if let transcriptSegmentComponents = transcriptSegmentComponents {
                for transcriptSegmentComponent in transcriptSegmentComponents {
                    var strings = transcriptSegmentComponent.components(separatedBy: "\n")
                    
                    if strings.count > 2 {
                        _ = strings.removeFirst() // count
                        let timing = strings.removeFirst() // time
                        
                        if let range = transcriptSegmentComponent.range(of:timing+"\n") {
                            let string = transcriptSegmentComponent[range.upperBound...] // .substring(from:range.upperBound)
                            str = (str != nil ? str! + " " : "") + string
                        }
                    }
                }
            }
            
            return str
        }
    }
    
    func getTranscriptSegments(alert:Bool, atEnd:(()->())?)
    {
        VoiceBase.get(accept: "text/vtt", mediaID: mediaID, path: "transcripts/latest", query: nil, completion: { (json:[String : Any]?) -> (Void) in
            if let transcriptSegments = json?["text"] as? String {
                self._transcriptSegments = nil // Without this the new transcript segments will not be processed correctly.

                self.transcriptSegments = transcriptSegments

                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Transcript Segments Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis available.")
                }
            } else {
                if alert, let text = self.mediaItem?.text {
                    Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
                }
            }
            
            atEnd?()
        }, onError: { (json:[String : Any]?) -> (Void) in
            if alert, let text = self.mediaItem?.text {
                Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments for\n\n\(text) (\(self.transcriptPurpose))\n\nis not available.")
            } else {
                Alerts.shared.alert(title: "Transcript Segments Not Available",message: "The transcript segments is not available.")
            }
            
            atEnd?()
        })
    }
    
    func search(string:String?)
    {
        guard Globals.shared.isVoiceBaseAvailable else {
            return
        }
        
        guard let voiceBaseAPIKey = Globals.shared.voiceBaseAPIKey else {
            return
        }
        
        guard let string = string else {
            return
        }
        
        var service = VoiceBase.url(mediaID: nil, path: nil, query: nil)
        service = service + "?query=" + string
        
        guard let url = URL(string:service) else {
            return
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = "GET"
        
        request.addValue("Bearer \(voiceBaseAPIKey)", forHTTPHeaderField: "Authorization")
        
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        
        // URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { (data:Data?, response:URLResponse?, error:Error?) in
            var errorOccured = false
            
            if let error = error {
                print("post error: ",error.localizedDescription)
                errorOccured = true
            }
            
            if let response = response {
                print("post response: ",response.description)
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("post HTTP response: ",httpResponse.description)
                    print("post HTTP response: ",httpResponse.allHeaderFields)
                    print("post HTTP response: ",httpResponse.statusCode)
                    print("post HTTP response: ",HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
                    
                    if (httpResponse.statusCode < 200) || (httpResponse.statusCode > 299) {
                        errorOccured = true
                    }
                }
            } else {
                errorOccured = true
            }
            
            var json : [String:Any]?
            
            if let data = data, data.count > 0 {
                let string = String.init(data: data, encoding: String.Encoding.utf8) // why not utf16?
                print(string as Any)
                
                json = data.json as? [String:Any]
                print(json as Any)
                
                if let errors = json?["errors"] {
                    print(errors)
                    errorOccured = true
                }

//                do {
//                    json = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any]
//                    print(json as Any)
//
//                    if let errors = json?["errors"] {
//                        print(errors)
//                        errorOccured = true
//                    }
//                } catch let error {
//                    // JSONSerialization failed
//                    print("JSONSerialization error: ",error.localizedDescription)
//                }
            } else {
                // no data
                
            }
            
            if errorOccured {
                Thread.onMainThread {
                    
                }
            } else {
                Thread.onMainThread {
                    
                }
            }
        })
        
        task.resume()
    }

    func relaodUserInfo(alert:Bool,detailedAlerts:Bool) -> [String:Any]?
    {
        guard let text = self.mediaItem?.text else {
            return nil
        }
        
        return userInfo(alert: alert, detailedAlerts: detailedAlerts,
                        finishedTitle: "Transcript Reload Completed", finishedMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nhas been reloaded.", onFinished: {
                            self.getTranscript(alert:detailedAlerts) {
                                self.getTranscriptSegments(alert:detailedAlerts) {
                                    self.details(alert:detailedAlerts) {

                                    }
                                }
                            }
                        },
                        errorTitle: "Transcript Reload Failed", errorMessage: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwas not reloaded.  Please try again.", onError: {

                        })
    }
    
    func alert(viewController:UIViewController)
    {
        let completion = " (\(transcriptPurpose))" + (percentComplete != nil ? "\n(\(percentComplete!)% complete)" : "")
        
        var title = "Machine Generated Transcript "
        
        var message = "You will be notified when the machine generated transcript"
        
        if let text = self.mediaItem?.text {
            message += " for\n\n\(text)\(completion) "
        }
        
        if (mediaID != nil) {
            title += "in Progress"
            message += "\n\nis available."
            
            var actions = [AlertAction]()
            
            actions.append(AlertAction(title: "Media ID", style: .default, handler: {
                var message : String?
                
                if let text = self.mediaItem?.text {
                    message = text + " (\(self.transcriptPurpose))"
                }

                let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                message: message,
                    preferredStyle: .alert)
                alert.makeOpaque()
                
                alert.addTextField(configurationHandler: { (textField:UITextField) in
                    textField.text = self.mediaID
                })
                
                let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                    (action : UIAlertAction) -> Void in
                })
                alert.addAction(okayAction)
                
                viewController.present(alert, animated: true, completion: nil)
            }))
            
            actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
            
            Alerts.shared.alert(title:title, message:message, actions:actions)
        } else {
            title += "Requested"
            message += "\n\nhas started."
            
            Alerts.shared.alert(title:title, message:message)
        }
    }

    func confirmAlignment(viewController:UIViewController, action:(()->())?)
    {
        guard let text = self.mediaItem?.text else {
            return
        }
        
        yesOrNo(viewController: viewController, title: "Confirm Alignment of Machine Generated Transcript", message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.",
            yesAction: { () -> (Void) in
                action?()
        },
            yesStyle: .destructive,
            noAction: nil, noStyle: .default)
    }
    
    func selectAlignmentSource(viewController:UIViewController)
    {
        guard let text = self.mediaItem?.text else {
            return
        }
        
        var alertActions = [AlertAction]()
        
        if (self.mediaItem?.hasNotesText == true) {
            alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
                self.confirmAlignment(viewController:viewController) {
                    process(viewController: viewController, work: { [weak self] () -> (Any?) in
                        return self?.mediaItem?.notesText // self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
                    }, completion: { [weak self] (data:Any?) in
                        self?.align(data as? String) // stripHTML(self?.mediaItem?.notesHTML.result)
                    })
                }
            }))
        }
        
//        alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
//            self.confirmAlignment(viewController:viewController) {
//                self.align(self.transcript)
//            }
//        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .destructive, handler: {
            self.confirmAlignment(viewController:viewController) {
                self.align(self.transcriptFromTranscriptSegments)
            }
        }))
        
        alertActions.append(AlertAction(title: Constants.Strings.Words, style: .destructive, handler: {
            self.confirmAlignment(viewController:viewController) {
                self.align(self.transcriptFromWords)
            }
        }))
        
        alertActionsCancel( viewController: viewController,
                            title: "Select Source for Alignment",
                            message: text,
                            alertActions: alertActions,
                            cancelAction: nil)
        
        //                            alertActionsCancel( viewController: viewController,
        //                                                title: "Confirm Alignment of Machine Generated Transcript",
        //                                                message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.",
        //                                alertActions: alertActions,
        //                                cancelAction: nil)
    }
    
    func alertActions(viewController:UIViewController) -> AlertAction?
    {
        guard let purpose = purpose else {
            return nil
        }
        
        guard let text = mediaItem?.text else {
            return nil
        }
        
        var prefix:String!
        
        switch purpose {
        case Purpose.audio:
            prefix = Constants.Strings.Audio
            
        case Purpose.video:
            prefix = Constants.Strings.Video
            
        default:
            return nil // prefix = ""
//            break
        }
        
        var action : AlertAction!

        action = AlertAction(title: prefix + " " + Constants.Strings.Transcript, style: .default) {
            if self.transcript == nil {
                guard Globals.shared.isVoiceBaseAvailable else {
                    if Globals.shared.voiceBaseAPIKey == nil {
                        let alert = UIAlertController(  title: "Please add an API Key to use VoiceBase",
                                                        message: nil,
                                                        preferredStyle: .alert)
                        alert.makeOpaque()
                        
                        alert.addTextField(configurationHandler: { (textField:UITextField) in
                            textField.text = Globals.shared.voiceBaseAPIKey
                        })
                        
                        let okayAction = UIAlertAction(title: Constants.Strings.Okay, style: UIAlertActionStyle.default, handler: {
                            (action : UIAlertAction) -> Void in
                            Globals.shared.voiceBaseAPIKey = alert.textFields?[0].text
                            
                            // If this is a valid API key then should pass a completion block to start the transcript!
                            if Globals.shared.voiceBaseAPIKey != nil {
                                Globals.shared.checkVoiceBaseAvailability {
                                    if !self.transcribing {
                                        if Globals.shared.reachability.isReachable {
//                                            var alertActions = [AlertAction]()
//
//                                            alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: {
//                                                self.getTranscript(alert: true) {}
//                                                mgtUpdate()
//                                            }))
//
//                                            alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                                            
                                            yesOrNo(viewController: viewController,
                                                    title: "Begin Creating\nMachine Generated Transcript?",
                                                    message: "\(text) (\(self.transcriptPurpose))",
                                                    yesAction: { () -> (Void) in
                                                        self.getTranscript(alert: true) {}
                                                        self.alert(viewController:viewController)
                                                    },
                                                    yesStyle: .default,
                                                    noAction: nil,
                                                    noStyle: .default)
                                            
//                                                alertActionsCancel( viewController: viewController,
//                                                                    title: "Begin Creating\nMachine Generated Transcript?",
//                                                                    message: "\(text) (\(self.transcriptPurpose))",
//                                                    alertActions: alertActions,
//                                                    cancelAction: nil)
                                        } else {
                                            networkUnavailable(viewController, "Machine Generated Transcript Unavailable.")
                                        }
                                    } else {
                                        self.alert(viewController:viewController)
                                    }
                                }
                            }
                        })
                        alert.addAction(okayAction)
                        
                        let cancel = UIAlertAction(title: Constants.Strings.Cancel, style: .default, handler: {
                            (action : UIAlertAction) -> Void in
                        })
                        alert.addAction(cancel)
                        
                        viewController.present(alert, animated: true, completion: nil)
                    } else {
                        networkUnavailable(viewController,"VoiceBase unavailable.")
                    }
                    return
                }
                
                guard Globals.shared.reachability.isReachable else {
                    networkUnavailable(viewController,"VoiceBase unavailable.")
                    return
                }
                
                if !self.transcribing {
                    if Globals.shared.reachability.isReachable {
//                        var alertActions = [AlertAction]()
//
//                        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .default, handler: {
//                            self.getTranscript(alert: true) {}
//                            mgtUpdate()
//                        }))
//
//                        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                        
                        yesOrNo(viewController: viewController,
                                title: "Begin Creating\nMachine Generated Transcript?",
                                message: "\(text) (\(self.transcriptPurpose))",
                            yesAction: { () -> (Void) in
                                self.getTranscript(alert: true) {}
                                self.alert(viewController:viewController)
                            },
                            yesStyle: .default,
                            noAction: nil,
                            noStyle: .default)
                        
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Begin Creating\nMachine Generated Transcript?",
//                                                message: "\(text) (\(self.transcriptPurpose))",
//                                alertActions: alertActions,
//                                cancelAction: nil)
                    } else {
                        networkUnavailable(viewController, "Machine Generated Transcript Unavailable.")
                    }
                } else {
                    self.alert(viewController:viewController)
                }
            } else {
                var alertActions = [AlertAction]()
                
                alertActions.append(AlertAction(title: "View", style: .default, handler: {
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Transcript", style: .default, handler: {
                        if self.transcript == self.transcriptFromWords {
                            print("THEY ARE THE SAME!")
                        }

                        popoverHTML(viewController, title:self.mediaItem?.title, bodyHTML:self.bodyHTML, headerHTML:self.headerHTML, search:true)
                    }))
                    
                    alertActions.append(AlertAction(title: "Transcript with Timing", style: .default, handler: {
                        process(viewController: viewController, work: { [weak self] () -> (Any?) in
                            var htmlString = "<!DOCTYPE html><html><body>"
                            
                            var transcriptSegmentHTML = String()
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "<table>"
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "<tr style=\"vertical-align:bottom;\"><td><b>#</b></td><td><b>Gap</b></td><td><b>Start Time</b></td><td><b>End Time</b></td><td><b>Span</b></td><td><b>Recognized Speech</b></td></tr>"
                            
                            if let transcriptSegmentComponents = self?.transcriptSegmentComponents {
                                var priorEndTime : Double?
                                
                                for transcriptSegmentComponent in transcriptSegmentComponents {
                                    var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                                    
                                    if transcriptSegmentArray.count > 2  {
                                        let count = transcriptSegmentArray.removeFirst()
                                        let timeWindow = transcriptSegmentArray.removeFirst()
                                        let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") //
                                        
                                        if  let start = times.first,
                                            let end = times.last,
                                            let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                            let text = String(transcriptSegmentComponent[range.upperBound...])
                                            
                                            var gap = String()
                                            var duration = String()

                                            if let startTime = start.hmsToSeconds, let endTime = end.hmsToSeconds {
                                                let durationTime = endTime - startTime
                                                duration = String(format:"%.3f",durationTime)

                                                if let peTime = priorEndTime {
                                                    let gapTime = startTime - peTime
                                                    gap = String(format:"%.3f",gapTime)
                                                }
                                            }

                                            priorEndTime = end.hmsToSeconds

                                            let row = "<tr style=\"vertical-align:top;\"><td>\(count)</td><td>\(gap)</td><td>\(start)</td><td>\(end)</td><td>\(duration)</td><td>\(text.replacingOccurrences(of: "\n", with: " "))</td></tr>"
                                            transcriptSegmentHTML = transcriptSegmentHTML + row
                                        }
                                    }
                                }
                            }
                            
                            transcriptSegmentHTML = transcriptSegmentHTML + "</table>"

                            htmlString = htmlString + (self?.headerHTML ?? "") + transcriptSegmentHTML + "</body></html>"

                            return htmlString as Any
                        }, completion: { [weak self] (data:Any?) in
                            if let htmlString = data as? String {
                                popoverHTML(viewController,title:self?.mediaItem?.title,htmlString:htmlString, search:true)
                            }
                        })
                    }))

                    alertActionsCancel( viewController: viewController,
                                        title: "View",
                                        message: "This is a machine generated transcript for \n\n\(text) (\(self.transcriptPurpose))\n\nIt may lack proper formatting and have signifcant errors.",
                                        alertActions: alertActions,
                                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Edit", style: .default, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
                        let textPopover = navigationController.viewControllers[0] as? TextViewController {

                        navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                        
                        if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                            navigationController.popoverPresentationController?.permittedArrowDirections = .any
                            navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                        }

                        textPopover.navigationController?.isNavigationBarHidden = false
                        
                        textPopover.navigationItem.title = (self.mediaItem?.title ?? "") + " (\(self.transcriptPurpose))"
                        
                        let text = self.transcript
                        
                        textPopover.transcript = self // Must come before track
                        textPopover.track = true
                        
                        textPopover.text = text
                        
                        textPopover.assist = true
                        textPopover.search = true
                        
                        textPopover.onSave = { (text:String) -> Void in
                            guard text != textPopover.text else {
                                return
                            }
                            
                            self.transcript = text
                        }
                        
                        viewController.present(navigationController, animated: true, completion: nil)
                    } else {
                        print("ERROR")
                    }
                }))
                
                alertActions.append(AlertAction(title: "Media ID", style: .default, handler: {
                    let alert = UIAlertController(  title: "VoiceBase Media ID",
                                                    message: text + " (\(self.transcriptPurpose))",
                                                    preferredStyle: .alert)
                    alert.makeOpaque()
                    
                    alert.addTextField(configurationHandler: { (textField:UITextField) in
                        textField.text = self.mediaID
                    })
                    
                    let okayAction = UIAlertAction(title: Constants.Strings.Cancel, style: UIAlertActionStyle.default, handler: {
                        (action : UIAlertAction) -> Void in
                    })
                    alert.addAction(okayAction)
                    
                    viewController.present(alert, animated: true, completion: nil)
                }))
                
                if Globals.shared.isVoiceBaseAvailable {
                    alertActions.append(AlertAction(title: "Check VoiceBase", style: .default, handler: {
                        self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                                    var actions = [AlertAction]()
                                    
                                    actions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
                                        VoiceBase.delete(mediaID: self.mediaID)
                                    }))
                                    
                                    actions.append(AlertAction(title: Constants.Strings.No, style: .default, handler:nil))
                                    
                                    Alerts.shared.alert(title:"Confirm Removal From VoiceBase", message:text + "\nMedia ID: " + mediaID, actions:actions)
                                }))
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"On VoiceBase", message:"A transcript for\n\n" + text + " (\(self.transcriptPurpose))\n\nwith mediaID\n\n\(mediaID)\n\nis on VoiceBase.", actions:actions)
                            }
                        }, onError:  { (dict:[String:Any]?)->(Void) in
                            if let mediaID = self.mediaID {
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"Not on VoiceBase", message:"A transcript for\n\n" + text + " (\(self.transcriptPurpose))\n\nwith mediaID\n\n\(mediaID)\n\nis not on VoiceBase.", actions:actions)
                            }
                        })
                    }))
                    
                    alertActions.append(AlertAction(title: "Align", style: .destructive, handler: {
                        guard !self.aligning else {
                            if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                                alertActionsCancel( viewController: viewController,
                                                    title: "Alignment Underway",
                                                    message: "There is an alignment already underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                    alertActions: nil,
                                    cancelAction: nil)
                            } else {
                                alertActionsCancel( viewController: viewController,
                                                    title: "Alignment Underway",
                                                    message: "There is an alignment already underway.\n\nPlease try again later.",
                                    alertActions: nil,
                                    cancelAction: nil)
                            }
                            return
                        }
                        
//                        var alertActions = [AlertAction]()
//
//                        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                            var alertActions = [AlertAction]()
//
//                            if self.mediaItem?.hasNotesHTML == true {
//                                alertActions.append(AlertAction(title: Constants.Strings.HTML_Transcript, style: .default, handler: {
//                                    process(viewController: viewController, work: { [weak self] () -> (Any?) in
//                                        self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
//                                    }, completion: { [weak self] (data:Any?) in
//                                        self?.align(stripHTML(self?.mediaItem?.notesHTML.result))
//                                    })
//                                }))
//                            }
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .default, handler: {
//                                self.align(self.transcript)
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .default, handler: {
//                                self.align(self.transcriptFromTranscriptSegments)
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Words, style: .default, handler: {
//                                self.align(self.transcriptFromWords)
//                            }))
//
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Select Source for Alignment",
//                                                message: text,
//                                                alertActions: alertActions,
//                                                cancelAction: nil)
//                        }))
//
//                        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                        
                        self.selectAlignmentSource(viewController:viewController)
                        
//                        if let text = self.mediaItem?.text {
//                            var alertActions = [AlertAction]()
//
//                            if (self.mediaItem?.hasNotes == true) || (self.mediaItem?.hasNotesHTML == true) {
//                                alertActions.append(AlertAction(title: Constants.Strings.HTML_Transcript, style: .destructive, handler: {
//                                    confirmAlignment {
//                                        process(viewController: viewController, work: { [weak self] () -> (Any?) in
//                                            self?.mediaItem?.notesHTML.load() // Do this in case there is delay.
//                                            }, completion: { [weak self] (data:Any?) in
//                                                self?.align(self?.mediaItem?.notesText) // stripHTML(self?.mediaItem?.notesHTML.result)
//                                        })
//                                    }
//                                }))
//                            }
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Transcript, style: .destructive, handler: {
//                                confirmAlignment {
//                                    self.align(self.transcript)
//                                }
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Segments, style: .destructive, handler: {
//                                confirmAlignment {
//                                    self.align(self.transcriptFromTranscriptSegments)
//                                }
//                            }))
//
//                            alertActions.append(AlertAction(title: Constants.Strings.Words, style: .destructive, handler: {
//                                confirmAlignment {
//                                    self.align(self.transcriptFromWords)
//                                }
//                            }))
//
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Select Source for Alignment",
//                                                message: text,
//                                                alertActions: alertActions,
//                                                cancelAction: nil)
//
////                            alertActionsCancel( viewController: viewController,
////                                                title: "Confirm Alignment of Machine Generated Transcript",
////                                                message: "Depending on the source selected, this may change both the transcript and timing for\n\n\(text) (\(self.transcriptPurpose))\n\nPlease note that new lines and blank lines (e.g. paragraph breaks) may not survive the alignment process.",
////                                alertActions: alertActions,
////                                cancelAction: nil)
//                        }
                    }))
                }
                
                alertActions.append(AlertAction(title: "Restore", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
                    var alertActions = [AlertAction]()
                    
                    alertActions.append(AlertAction(title: "Regenerate Transcript", style: .destructive, handler: {
                        yesOrNo(viewController: viewController,
                                title: "Confirm Regeneration of Transcript",
                                message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
                                yesAction: { () -> (Void) in
                                    self.transcript = self.transcriptFromWords
                                }, yesStyle: .destructive,
                                noAction: nil, noStyle: .default)
                        
//                        var alertActions = [AlertAction]()
//                        
//                        alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                            self.transcript = self.transcriptFromWords
//                        }))
//                        
//                        alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
//                        
//                        if let text = self.mediaItem?.text {
//                            alertActionsCancel( viewController: viewController,
//                                                title: "Confirm Regeneration of Transcript",
//                                                message: "The transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be regenerated from the individually recognized words.",
//                                alertActions: alertActions,
//                                cancelAction: nil)
//                        }
                    }))
                    
                    if Globals.shared.isVoiceBaseAvailable {
                        alertActions.append(AlertAction(title: "Reload from VoiceBase", style: .destructive, handler: {
                            self.metadata(completion: { (dict:[String:Any]?)->(Void) in
                                var alertActions = [AlertAction]()
                                
                                alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
                                    Alerts.shared.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
                                    
                                    if self.resultsTimer != nil {
                                        print("TIMER NOT NIL!")
                                        
                                        var actions = [AlertAction]()
                                        
                                        actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                        
                                        Alerts.shared.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
                                    } else {
                                        Thread.onMainThread {
                                            self.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.relaodUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                        }
                                    }
                                }))
                                
                                alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                                
                                yesOrNo(viewController: viewController,
                                        title: "Confirm Reloading",
                                        message: "The results of speech recognition for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
                                        yesAction: { () -> (Void) in
                                            Alerts.shared.alert(title:"Reloading Machine Generated Transcript", message:"Reloading the machine generated transcript for\n\n\(text) (\(self.transcriptPurpose))\n\nYou will be notified when it has been completed.")
                                            
                                            if self.resultsTimer != nil {
                                                print("TIMER NOT NIL!")
                                                
                                                var actions = [AlertAction]()
                                                
                                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                                
                                                Alerts.shared.alert(title:"Processing Not Complete", message:text + "\nPlease try again later.", actions:actions)
                                            } else {
                                                Thread.onMainThread {
                                                    self.resultsTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.monitor(_:)), userInfo: self.relaodUserInfo(alert:true,detailedAlerts:false), repeats: true)
                                                }
                                            }
                                        }, yesStyle: .destructive,
                                        noAction: nil, noStyle: .default)
                                
//                                        alertActionsCancel( viewController: viewController,
//                                                            title: "Confirm Reloading",
//                                                            message: "The results of speech recognition for\n\n\(text) (\(self.transcriptPurpose))\n\nwill be reloaded from VoiceBase.",
//                                            alertActions: alertActions,
//                                            cancelAction: nil)
                            }, onError:  { (dict:[String:Any]?)->(Void) in
                                var actions = [AlertAction]()
                                
                                actions.append(AlertAction(title: Constants.Strings.Okay, style: .default, handler: nil))
                                
                                Alerts.shared.alert(title:"Not on VoiceBase", message:text + "\nis not on VoiceBase.", actions:actions)
                            })
                        }))
                    }
                    
                    alertActionsCancel( viewController: viewController,
                                        title: "Restore Options",
                                        message: "\(text) (\(self.transcriptPurpose))",
                        alertActions: alertActions,
                        cancelAction: nil)
                }))
                
                alertActions.append(AlertAction(title: "Delete", style: .destructive, handler: {
                    guard !self.aligning else {
                        if let percentComplete = self.percentComplete { // , let text = self.mediaItem?.text
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway (\(percentComplete)% complete) for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        } else {
                            alertActionsCancel( viewController: viewController,
                                                title: "Alignment Underway",
                                                message: "There is an alignment underway for:\n\n\(text) (\(self.transcriptPurpose))\n\nPlease try again later.",
                                alertActions: nil,
                                cancelAction: nil)
                        }
                        return
                    }
                    
//                    var alertActions = [AlertAction]()
//
//                    alertActions.append(AlertAction(title: Constants.Strings.Yes, style: .destructive, handler: {
//                        self.remove()
//                    }))
//
//                    alertActions.append(AlertAction(title: Constants.Strings.No, style: .default, handler: nil))
                    
                    yesOrNo(viewController: viewController,
                            title: "Confirm Deletion of Machine Generated Transcript",
                            message: "\(text) (\(self.transcriptPurpose))",
                            yesAction: { () -> (Void) in
                                self.remove()
                            },
                            yesStyle: .destructive,
                            noAction: nil,
                            noStyle: .default)

//                        alertActionsCancel( viewController: viewController,
//                                            title: "Confirm Deletion of Machine Generated Transcript",
//                                            message: "\(text) (\(self.transcriptPurpose))",
//                            alertActions: alertActions,
//                            cancelAction: nil)
                }))
                
                alertActionsCancel(  viewController: viewController,
                                     title: Constants.Strings.Machine_Generated + " " + Constants.Strings.Transcript,
                    message: text + " (\(self.transcriptPurpose))",
                    alertActions: alertActions,
                    cancelAction: nil)
            }
        }
        
        return action
    }
    
//    func editTranscriptSegment(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath)
//    {
//        editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath,automatic:false,automaticVisible:false,automaticInteractive:false,automaticCompletion:nil)
//    }
    
    func editTranscriptSegment(popover:PopoverTableViewController, tableView:UITableView, indexPath:IndexPath, automatic:Bool = false, automaticVisible:Bool = false, automaticInteractive:Bool = false, automaticCompletion:(()->(Void))? = nil)
    {
        let stringIndex = popover.section.index(indexPath)
        
        guard let string = popover.section.strings?[stringIndex] else {
            return
        }

        let playing = Globals.shared.mediaPlayer.isPlaying
        
        Globals.shared.mediaPlayer.pause()
        
        var transcriptSegmentArray = string.components(separatedBy: "\n")
        let count = transcriptSegmentArray.removeFirst() // Count
        let timing = transcriptSegmentArray.removeFirst() // Timing
        let transcriptSegmentTiming = timing.replacingOccurrences(of: "to", with: "-->")
        
        if  let first = transcriptSegmentComponents?.filter({ (string:String) -> Bool in
            return string.contains(transcriptSegmentTiming)
        }).first,
            let navigationController = popover.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.TEXT_VIEW) as? UINavigationController,
            let textPopover = navigationController.viewControllers[0] as? TextViewController,
            let transcriptSegmentIndex = self.transcriptSegmentComponents?.index(of: first),
            let range = string.range(of:timing+"\n") {
            navigationController.modalPresentationStyle = .overCurrentContext
            
            navigationController.popoverPresentationController?.delegate = popover
            
            Thread.onMainThread {
                textPopover.navigationController?.isNavigationBarHidden = false
                textPopover.navigationItem.title = count // "Edit Text"
            }
            
            let text = String(string[range.upperBound...])
            
            textPopover.text = text
            textPopover.assist = true
            
            textPopover.automatic = automatic
            textPopover.automaticVisible = automaticVisible
            textPopover.automaticInteractive = automaticInteractive
            textPopover.automaticCompletion = automaticCompletion
 
            textPopover.onCancel = {
                if playing {
                    Globals.shared.mediaPlayer.play()
                }
            }
            
            textPopover.onSave = { (text:String) -> Void in
                // This guard condition will be false after save
                guard text != textPopover.text else {
                    if playing {
                        Globals.shared.mediaPlayer.play()
                    }
                    return
                }
                
                // I.e. THIS SHOULD NEVER HAPPEN WHEN CALLED FROM onDone UNLESS
                // It is called during automatic.
                self.transcriptSegmentComponents?[transcriptSegmentIndex] = "\(count)\n\(transcriptSegmentTiming)\n\(text)"
                if popover.searchActive {
                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
                }
                popover.unfilteredSection.strings?[transcriptSegmentIndex] = "\(count)\n\(timing)\n\(text)"
            }
            
            textPopover.onDone = { (text:String) -> Void in
                textPopover.onSave?(text)
//                self.transcriptSegmentComponents?[transcriptSegmentIndex] = "\(count)\n\(transcriptSegmentTiming)\n\(text)"
//                if popover.searchActive {
//                    popover.filteredSection.strings?[stringIndex] = "\(count)\n\(timing)\n\(text)"
//                }
//                popover.unfilteredSection.strings?[transcriptSegmentIndex] = "\(count)\n\(timing)\n\(text)"
                
                DispatchQueue.global(qos: .background).async { [weak self] in
                    self?.transcriptSegments = self?.transcriptSegmentsFromTranscriptSegments
                }
                
                Thread.onMainThread {
                    popover.tableView.isEditing = false
                    popover.tableView.reloadData()
                    popover.tableView.reloadData()
                }
                
                if indexPath.section >= popover.tableView.numberOfSections {
                    print("ERROR: bad indexPath.section")
                }
                
                if indexPath.row >= popover.tableView.numberOfRows(inSection: indexPath.section) {
                    print("ERROR: bad indexPath.row")
                }
                
                Thread.onMainThread {
                    popover.tableView.scrollToRow(at: indexPath, at: UITableViewScrollPosition.middle, animated: true)
                }
                
                if playing {
                    Globals.shared.mediaPlayer.play()
                }
            }
            
            popover.present(navigationController, animated: true, completion: nil)
        } else {
            print("ERROR")
        }
    }
    
    func rowActions(popover:PopoverTableViewController,tableView:UITableView,indexPath:IndexPath) -> [AlertAction]? // popover:PopoverTableViewController,
    {
        var actions = [AlertAction]()
        
        var edit:AlertAction!
        
        edit = AlertAction(title: "Edit", style: .default) {
            self.editTranscriptSegment(popover:popover,tableView:tableView,indexPath:indexPath)
        }
        
        actions.append(edit)
        
        return actions.count > 0 ? actions : nil
    }

    func timingIndexAlertActions(viewController:UIViewController,completion:((PopoverTableViewController)->(Void))?) -> AlertAction?
    {
        var action : AlertAction!
        
        action = AlertAction(title: "Timing Index", style: .default) {
            var alertActions = [AlertAction]()

            alertActions.append(AlertAction(title: "By Word", style: .default, handler: {
                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTimingIndexWord
                    
                    popover.section.showIndex = true

                    popover.stringsFunction = { () -> [String]? in
                        guard let transcriptSegmentTokens = self.transcriptSegmentTokens else {
                            return nil
                        }
                        
                        return Array(transcriptSegmentTokens).sorted()
                    }

                    viewController.present(navigationController, animated: true, completion:  {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Phrase", style: .default, handler: {
                if  let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController,
                    let popover = navigationController.viewControllers[0] as? PopoverTableViewController {

                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))"
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTimingIndexPhrase
                    
                    popover.section.showIndex = true
                    
                    popover.stringsFunction = { () -> [String]? in
                        guard let keywordDictionaries = self.keywordDictionaries?.keys else {
                            return nil
                        }
                        
                        return Array(keywordDictionaries).sorted()
                    }
                    
                    viewController.present(navigationController, animated: true, completion:  {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Segment", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))"
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self

                    popover.search = true
                    
                    popover.editActionsAtIndexPath = self.rowActions
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTime
                    
                    popover.parser = { (string:String) -> [String] in
                        var strings = string.components(separatedBy: "\n")
                        while strings.count > 2 {
                            strings.removeLast()
                        }
                        return strings
                    }
                    
                    popover.section.showIndex = true
                    popover.section.indexStringsTransform = century
                    popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                        return string
                    }
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { () -> [String]? in
                        return self.transcriptSegmentComponents?.filter({ (string:String) -> Bool in
                            return string.components(separatedBy: "\n").count > 1
                        }).map({ (transcriptSegmentComponent:String) -> String in
                            var transcriptSegmentArray = transcriptSegmentComponent.components(separatedBy: "\n")
                            
                            if transcriptSegmentArray.count > 2  {
                                let count = transcriptSegmentArray.removeFirst()
                                let timeWindow = transcriptSegmentArray.removeFirst()
                                let times = timeWindow.replacingOccurrences(of: ",", with: ".").components(separatedBy: " --> ") // 
                                
                                if  let start = times.first,
                                    let end = times.last,
                                    let range = transcriptSegmentComponent.range(of: timeWindow+"\n") {
                                    let text = String(transcriptSegmentComponent[range.upperBound...]).replacingOccurrences(of: "\n", with: " ")
                                    let string = "\(count)\n\(start) to \(end)\n" + text
                                    
                                    return string
                                }
                            }
                            
                            return "ERROR"
                        })
                    }
                        
                    popover.track = true
                    popover.assist = true
                    
                    viewController.present(navigationController, animated: true, completion: {
                        completion?(popover)
                    })
                }
            }))
            
            alertActions.append(AlertAction(title: "By Timed Word", style: .default, handler: {
                if let navigationController = viewController.storyboard?.instantiateViewController(withIdentifier: Constants.IDENTIFIER.POPOVER_TABLEVIEW) as? UINavigationController, let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    
                    navigationController.modalPresentationStyle = preferredModalPresentationStyle(viewController: viewController)
                    
                    if navigationController.modalPresentationStyle == .popover {// MUST OCCUR BEFORE PPC DELEGATE IS SET.
                        navigationController.popoverPresentationController?.permittedArrowDirections = .any
                        navigationController.popoverPresentationController?.delegate = viewController as? UIPopoverPresentationControllerDelegate
                    }
                    
                    popover.navigationController?.isNavigationBarHidden = false
                    
                    popover.navigationItem.title = "Timing Index (\(self.transcriptPurpose))" //
                    
                    popover.selectedMediaItem = self.mediaItem
                    popover.transcript = self
                    
                    popover.search = true
                    
                    popover.delegate = viewController as? PopoverTableViewControllerDelegate
                    popover.purpose = .selectingTime
                    
                    popover.section.showIndex = true
                    popover.section.indexStringsTransform = century
                    popover.section.indexSort = { (first:String?,second:String?) -> Bool in
                        guard let first = first else {
                            return false
                        }
                        guard let second = second else {
                            return true
                        }
                        return Int(first) < Int(second)
                    }
                    popover.section.indexHeadersTransform = { (string:String?)->(String?) in
                        return string
                    }
                    
                    // Must use stringsFunction with .selectingTime.
                    popover.stringsFunction = { () -> [String]? in
                        var strings = [String]()
                        
                        if let words = self.words?.filter({ (dict:[String:Any]) -> Bool in
                            return dict["w"] != nil
                        }) {
                            var lastEnd : Int?
                            
                            for i in 0..<words.count {
                                if  let position = words[i]["p"] as? Int,
                                    let start = words[i]["s"] as? Int,
                                    let end = words[i]["e"] as? Int,
                                    let word = words[i]["w"] as? String,
                                    let startHMS = (Double(start)/1000.0).secondsToHMS,
                                    let endHMS = (Double(end)/1000.0).secondsToHMS {
                                    strings.append("\(position+1)\n")
                                    
                                    if let lastEnd = lastEnd {
                                        strings[i] += String(format:"%.3f ",Double(start - lastEnd)/1000.0)
                                    }

                                    strings[i] += "\(startHMS) to \(endHMS)\n\(word)"

                                    lastEnd = end
                                }
                            }
                        }
                    
                        return strings.count > 0 ? strings : nil
                    }
                    
                    viewController.present(navigationController, animated: true, completion: {
                        completion?(popover)
                    })
                }
            }))
            
            alertActionsCancel( viewController: viewController,
                                title: "Show Timing Index",
                                message: nil,
                                alertActions: alertActions,
                                cancelAction: nil)
        }
        
        return action
    }
}
