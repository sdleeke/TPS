//
//  MediaItem.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit
import AVKit

                            //Group//String//Sort
typealias MediaGroupSort = [String:[String:[String:[MediaItem]]]]

                             //Group//String//Name
typealias MediaGroupNames = [String:[String:String]]

class MediaListGroupSort {
    var list:[MediaItem]? { //Not in any specific order
        didSet {
            if (list != nil) {
                index = [String:MediaItem]()
                
                for mediaItem in list! {
                    index![mediaItem.id!] = mediaItem
                }
            }
        }
    }
    var index:[String:MediaItem]? //MediaItems indexed by ID.
    
    var searches:[String:MediaListGroupSort]? // Hierarchical means we could search within searches - but not right now.
    
    var scriptureIndex:ScriptureIndex?

    var groupSort:MediaGroupSort?
    var groupNames:MediaGroupNames?
    
    var tagMediaItems:[String:[MediaItem]]?//sortTag:MediaItem
    var tagNames:[String:String]?//sortTag:tag
    
    var mediaItemTags:[String]? {
        get {
            return tagMediaItems?.keys.sorted(by: { $0 < $1 }).map({ (string:String) -> String in
                return self.tagNames![string]!
            })
        }
    }
    
    var mediaItems:[MediaItem]? {
        get {
            return mediaItems(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sortGroup(_ grouping:String?)
    {
        if (list == nil) {
            return
        }
        
//        var strings:[String]?
//        var names:[String]?
        
        var groupedMediaItems = [String:[String:[MediaItem]]]()
        
        globals.finished += list!.count
        
        for mediaItem in list! {
            var entries:[(string:String,name:String)]?
            
            switch grouping! {
            case Grouping.YEAR:
                entries = [(mediaItem.yearString,mediaItem.yearString)]
                break
                
            case Grouping.TITLE:
                entries = [(mediaItem.multiPartSectionSort,mediaItem.multiPartSection)]
                break
                
            case Grouping.BOOK:
                // Need to update this for the fact that mediaItems can have more than one book.
                if let books = mediaItem.books {
                    for book in books {
                        if entries == nil {
                            entries = [(book,book)]
                        } else {
                            entries?.append((book,book))
                        }
                    }
                }
                if entries == nil {
                    if mediaItem.scripture == Constants.Selected_Scriptures {
                        entries = [(Constants.Selected_Scriptures,Constants.Selected_Scriptures)]
                    } else {
                        entries = [(Constants.None,Constants.None)]
                    }
                }
//                if entries?.count > 1 {
//                    print(mediaItem,entries!)
//                }
                break
                
            case Grouping.SPEAKER:
                entries = [(mediaItem.speakerSectionSort,mediaItem.speakerSection)]
                break
                
            default:
                break
            }
            
            if (groupNames?[grouping!] == nil) {
                groupNames?[grouping!] = [String:String]()
            }
            
            if entries != nil {
                for entry in entries! {
                    groupNames?[grouping!]?[entry.string] = entry.name
                    
                    if (groupedMediaItems[grouping!] == nil) {
                        groupedMediaItems[grouping!] = [String:[MediaItem]]()
                    }
                    
                    if groupedMediaItems[grouping!]?[entry.string] == nil {
                        groupedMediaItems[grouping!]?[entry.string] = [mediaItem]
                    } else {
                        groupedMediaItems[grouping!]?[entry.string]?.append(mediaItem)
                    }
                    
                    globals.progress += 1
                }
            }
        }
        
        if (groupedMediaItems[grouping!] != nil) {
            globals.finished += groupedMediaItems[grouping!]!.keys.count
        }
        
        if (groupSort?[grouping!] == nil) {
            groupSort?[grouping!] = [String:[String:[MediaItem]]]()
        }
        if (groupedMediaItems[grouping!] != nil) {
            for string in groupedMediaItems[grouping!]!.keys {
                if (groupSort?[grouping!]?[string] == nil) {
                    groupSort?[grouping!]?[string] = [String:[MediaItem]]()
                }
                for sort in Constants.sortings {
                    let array = sortMediaItemsChronologically(groupedMediaItems[grouping!]?[string])
                    
                    switch sort {
                    case Constants.CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array
                        break
                        
                    case Constants.REVERSE_CHRONOLOGICAL:
                        groupSort?[grouping!]?[string]?[sort] = array?.reversed()
                        break
                        
                    default:
                        break
                    }
                    
                    globals.progress += 1
                }
            }
        }
    }
    
    func mediaItems(grouping:String?,sorting:String?) -> [MediaItem]?
    {
        var groupedSortedMediaItems:[MediaItem]?
        
        if (groupSort == nil) {
            return nil
        }
        
        if (groupSort?[grouping!] == nil) {
            sortGroup(grouping)
        }
        
        //        print("\(groupSort)")
        if (groupSort![grouping!] != nil) {
            for key in groupSort![grouping!]!.keys.sorted(
                by: {
                    switch grouping! {
                    case Grouping.YEAR:
                        switch sorting! {
                        case Constants.CHRONOLOGICAL:
                            return $0 < $1
                            
                        case Constants.REVERSE_CHRONOLOGICAL:
                            return $1 < $0
                            
                        default:
                            break
                        }
                        break
                        
                    case Grouping.BOOK:
                        if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                            return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                        } else {
                            return bookNumberInBible($0) < bookNumberInBible($1)
                        }
                        
                    case Grouping.SPEAKER:
                        return $0 < $1
                        
                    case Grouping.TITLE:
                        return $0.lowercased() < $1.lowercased()
                        
                    default:
                        break
                    }

                    return $0 < $1
            }) {
                let mediaItems = groupSort?[grouping!]?[key]?[sorting!]
                
                if (groupedSortedMediaItems == nil) {
                    groupedSortedMediaItems = mediaItems
                } else {
                    groupedSortedMediaItems?.append(contentsOf: mediaItems!)
                }
            }
        }
        
        return groupedSortedMediaItems
    }
    
    var sectionIndexTitles:[String]? {
        get {
            return sectionIndexTitles(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    var sectionTitles:[String]? {
        get {
            return sectionTitles(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionIndexTitles(grouping:String?,sorting:String?) -> [String]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        })
    }
    
    func sectionTitles(grouping:String?,sorting:String?) -> [String]?
    {
//        return groupSort?[grouping!]?.keys.sorted(by: {
//            switch grouping! {
//            case Grouping.YEAR:
//                switch sorting! {
//                case Constants.CHRONOLOGICAL:
//                    return $0 < $1
//                    
//                case Constants.REVERSE_CHRONOLOGICAL:
//                    return $1 < $0
//                    
//                default:
//                    break
//                }
//                break
//                
//            case Grouping.BOOK:
//                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
//                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
//                } else {
//                    return bookNumberInBible($0) < bookNumberInBible($1)
//                }
//                
//            default:
//                break
//            }
//            
//            return $0 < $1
//        }).map({ (string:String) -> String in
//            return groupNames![grouping!]![string]!
//        })
        
        return sectionIndexTitles(grouping: grouping,sorting: sorting)?.map({ (string:String) -> String in
            return groupNames![grouping!]![string]!
        })
    }
    
    var sectionCounts:[Int]? {
        get {
            return sectionCounts(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionCounts(grouping:String?,sorting:String?) -> [Int]?
    {
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            return groupSort![grouping!]![string]![sorting!]!.count
        })
    }
    
    var sectionIndexes:[Int]? {
        get {
            return sectionIndexes(grouping: globals.grouping,sorting: globals.sorting)
        }
    }
    
    func sectionIndexes(grouping:String?,sorting:String?) -> [Int]?
    {
        var cumulative = 0
        
        return groupSort?[grouping!]?.keys.sorted(by: {
            switch grouping! {
            case Grouping.YEAR:
                switch sorting! {
                case Constants.CHRONOLOGICAL:
                    return $0 < $1
                    
                case Constants.REVERSE_CHRONOLOGICAL:
                    return $1 < $0
                    
                default:
                    break
                }
                break
                
            case Grouping.BOOK:
                if (bookNumberInBible($0) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) && (bookNumberInBible($1) == Constants.NOT_IN_THE_BOOKS_OF_THE_BIBLE) {
                    return stringWithoutPrefixes($0) < stringWithoutPrefixes($1)
                } else {
                    return bookNumberInBible($0) < bookNumberInBible($1)
                }
                
            default:
                break
            }
            
            return $0 < $1
        }).map({ (string:String) -> Int in
            let prior = cumulative
            
            cumulative += groupSort![grouping!]![string]![sorting!]!.count
            
            return prior
        })
    }
    
    init(mediaItems:[MediaItem]?)
    {
        if (mediaItems != nil) {
            globals.finished = 0
            globals.progress = 0
            
            list = mediaItems
            
            groupNames = MediaGroupNames()
            groupSort = MediaGroupSort()
            tagMediaItems = [String:[MediaItem]]()
            tagNames = [String:String]()
            
            sortGroup(globals.grouping)

            globals.finished += list!.count
            
            for mediaItem in list! {
                if let tags =  mediaItem.tagsSet {
                    for tag in tags {
                        let sortTag = stringWithoutPrefixes(tag)
                        if tagMediaItems?[sortTag!] == nil {
                            tagMediaItems?[sortTag!] = [mediaItem]
                        } else {
                            tagMediaItems?[sortTag!]?.append(mediaItem)
                        }
                        tagNames?[sortTag!] = tag
                    }
                }
                globals.progress += 1
            }
        } else {
            globals.finished = 1
            globals.progress = 1
        }
    }
}

enum State {
    case downloading
    case downloaded
    case none
}

class Download {
    weak var mediaItem:MediaItem?
    
    var purpose:String?
    
    var downloadURL:URL?
    var fileSystemURL:URL? {
        didSet {
            state = isDownloaded() ? .downloaded : .none
        }
    }
    
    var totalBytesWritten:Int64 = 0
    
    var totalBytesExpectedToWrite:Int64 = 0
    
    var session:URLSession? // We're using a session for each download.  Not sure is the best but it works for TWU.
    
    var task:URLSessionDownloadTask?
    
    var active:Bool {
        get {
            return state == .downloading
        }
    }
    
    var state:State = .none {
        didSet {
            if state != oldValue {
                switch purpose! {
                case Purpose.audio:
                    switch state {
                    case .downloading:
                        break
                        
                    case .downloaded:
                        mediaItem?.addTag(Constants.Downloaded)
                        break
                        
                    case .none:
                        mediaItem?.removeTag(Constants.Downloaded)
                        break
                    }
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        // The following must appear AFTER we change the state
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.mediaItem)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    })
                    break
                    
                default:
                    DispatchQueue.main.async(execute: { () -> Void in
                        // The following must appear AFTER we change the state
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self.mediaItem)
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_CELL), object: self.mediaItem)
                    })
                    break
                }
            }
        }
    }
    
    var completionHandler: ((Void) -> (Void))?
    
    func isDownloaded() -> Bool
    {
        if fileSystemURL != nil {
//            print(fileSystemURL!.path!)
//            print(FileManager.default.fileExists(atPath: fileSystemURL!.path!))
            return FileManager.default.fileExists(atPath: fileSystemURL!.path)
        } else {
            return false
        }
    }
    
    var fileSize:Int
    {
        var size = 0
        
        if fileSystemURL != nil {
            do {
                let fileAttributes = try FileManager.default.attributesOfItem(atPath: fileSystemURL!.path)
                size = fileAttributes[FileAttributeKey.size] as! Int
            } catch _ {
                print("failed to get file attributes for \(fileSystemURL!)")
            }
        }
        
        return size
    }
    
    func download()
    {
        if (state == .none) {
            state = .downloading
            
            if (downloadURL == nil) {
                print("\(mediaItem?.title)")
                print("\(purpose)")
                print("\(fileSystemURL)")
            }
            
            let downloadRequest = URLRequest(url: downloadURL!)
            
            // This allows the downloading to continue even if the app goes into the background or terminates.
            let configuration = URLSessionConfiguration.background(withIdentifier: Constants.DOWNLOAD_IDENTIFIER + fileSystemURL!.lastPathComponent)
            configuration.sessionSendsLaunchEvents = true
            
            //        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            
            session = URLSession(configuration: configuration, delegate: mediaItem, delegateQueue: nil)
            
            session?.sessionDescription = self.fileSystemURL!.lastPathComponent
            
            task = session?.downloadTask(with: downloadRequest)
            task?.taskDescription = fileSystemURL?.lastPathComponent
            
            task?.resume()
            
            DispatchQueue.main.async(execute: { () -> Void in
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            })
        }
    }
    
    func deleteDownload()
    {
        if (state == .downloaded) {
            // Check if file exists and if so, delete it.
            if (FileManager.default.fileExists(atPath: fileSystemURL!.path)){
                do {
                    try FileManager.default.removeItem(at: fileSystemURL!)
                } catch _ {
                    print("failed to delete download")
                }
            }
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }

    func cancelOrDeleteDownload()
    {
        switch state {
        case .downloading:
            cancelDownload()
            break
            
        case .downloaded:
            deleteDownload()
            break
            
        default:
            break
        }
    }
    
    func cancelDownload()
    {
        if (active) {
            //            download.task?.cancelByProducingResumeData({ (data: NSData?) -> Void in
            //            })
            task?.cancel()
            task = nil
            
            totalBytesWritten = 0
            totalBytesExpectedToWrite = 0
            
            state = .none
        }
    }
}

class MediaItem : NSObject, URLSessionDownloadDelegate {
    var dict:[String:String]?
    
    var bcv:[String:[Int:[Int]]]?
    
    var singleLoaded = false

    init(dict:[String:String]?)
    {
        super.init()
//        print("\(dict)")
        self.dict = dict
    }
    
    var downloads = [String:Download]()
    
    //    lazy var downloads:[String:Download]? = {
    //        return [String:Download]()
    //    }()
    
    lazy var audioDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.audio
        download.downloadURL = self.audioURL
        download.fileSystemURL = self.audioFileSystemURL
        self.downloads[Purpose.audio] = download
        return download
        }()
    
    lazy var videoDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.video
        download.downloadURL = self.videoURL
        download.fileSystemURL = self.videoFileSystemURL
        self.downloads[Purpose.video] = download
        return download
        }()
    
    lazy var slidesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.slides
        download.downloadURL = self.slidesURL
        download.fileSystemURL = self.slidesFileSystemURL
        self.downloads[Purpose.slides] = download
        return download
        }()
    
    lazy var notesDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.notes
        download.downloadURL = self.notesURL
        download.fileSystemURL = self.notesFileSystemURL
        self.downloads[Purpose.notes] = download
        return download
        }()
    
    lazy var outlineDownload:Download? = {
        [unowned self] in
        var download = Download()
        download.mediaItem = self
        download.purpose = Purpose.outline
        download.downloadURL = self.outlineURL
        download.fileSystemURL = self.outlineFileSystemURL
        self.downloads[Purpose.outline] = download
        return download
        }()
    
//    required convenience init?(coder decoder: NSCoder)
//    {
//        guard
//            
//            let dict = decoder.decodeObjectForKey(Constants.DICT) as? [String:String]
//            
//            else {
//                return nil
//            }
//        
//        self.init(dict: dict)
//    }
//    
//    func encodeWithCoder(coder: NSCoder) {
//        coder.encodeObject(self.dict, forKey: Constants.DICT)
//    }
    
    var id:String! {
        get {
            // This should be constructed from the speaker (first and last initial), date, and service. E.g. tp160501a
            // BUT it doesn't work for gs == Guest Speaker
//            if speaker != nil {
//                let firstName = speaker!.substringToIndex(speaker!.rangeOfString(Constants.SINGLE_SPACE)!.startIndex)
//                let lastName = speaker!.substringFromIndex(speaker!.rangeOfString(Constants.SINGLE_SPACE)!.endIndex)
//                
//                let firstInitial = firstName.lowercaseString.substringToIndex("a".endIndex)
//                let lastInitial = lastName.lowercaseString.substringToIndex("a".endIndex)
//                
//                let calendar = NSCalendar.currentCalendar()
//                
//                let year = String(format: "%02d",calendar.components(.Year, fromDate: fullDate!).year % 1000)
//                let month = String(format: "%02d",calendar.components(.Month, fromDate: fullDate!).month)
//                let day = String(format: "%02d",calendar.components(.Day, fromDate: fullDate!).day)
//
//                let service = self.service!.lowercaseString.substringToIndex("a".endIndex)
//                
//                let idString = firstInitial + lastInitial + year + month + day + service
//                
////                print(idString)
//            }
            
            return dict![Field.id]
            
//            if dict?[Constants.ID] != nil {
//                return dict?[Constants.ID]
//            } else {
//                if let cd = audio?.range(of: "CD") {
//                    return audio?.substring(to: cd.lowerBound)
//                } else {
//                    return audio?.substring(to: audio!.range(of: Constants.MP3_FILENAME_EXTENSION)!.lowerBound)
//                }
//            }
        }
    }
    
    var classCode:String {
        var chars = Constants.EMPTY_STRING
        
        for char in id.characters {
            if Int(String(char)) != nil {
                break
            }
            chars.append(char)
        }
        
        return chars
    }
    
    var serviceCode:String {
        let afterClassCode = id.substring(from: classCode.endIndex)
        
        let ymd = "YYMMDD"
        
        let afterDate = afterClassCode.substring(from: ymd.endIndex)
        
        let code = afterDate.substring(to: "x".endIndex)
        
//        print(code)
        
        return code
    }
    
    var conferenceCode:String? {
        if serviceCode == "s" {
            let afterClassCode = id.substring(from: classCode.endIndex)
            
            var string = id.substring(to: classCode.endIndex)
            
            let ymd = "YYMMDD"
            
            string = string + afterClassCode.substring(to: ymd.endIndex)
            
            let s = "s"
            
            let code = string + s
            
//            print(code)
            
            return code
        }
        
        return nil
    }
    
    var repeatCode:String? {
        let afterClassCode = id.substring(from: classCode.endIndex)
        
        var string = id.substring(to: classCode.endIndex)
        
        let ymd = "YYMMDD"
        
        string = string + afterClassCode.substring(to: ymd.endIndex) + serviceCode
        
        let code = id.substring(from: string.endIndex)

        if code != Constants.EMPTY_STRING  {
//            print(code)
            return code
        } else {
            return nil
        }
    }
    
    var multiPartMediaItems:[MediaItem]? {
        get {
            if (hasMultipleParts) {
                var mediaItemParts:[MediaItem]?
//                print(multiPartSort)
                if (globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Constants.CHRONOLOGICAL] == nil) {
                    mediaItemParts = globals.mediaRepository.list?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })

                } else {
                    mediaItemParts = globals.media.all?.groupSort?[Grouping.TITLE]?[multiPartSort!]?[Constants.CHRONOLOGICAL]?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return (testMediaItem.multiPartName == multiPartName) && (testMediaItem.category == category)
                    })
                }

//                print(id)
//                print(id.range(of: "s")?.lowerBound)
//                print("flYYMMDD".endIndex)
                
                // Filter for conference series
                if conferenceCode != nil {
                    return sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        return testMediaItem.conferenceCode == conferenceCode
                    }),sorting: Constants.CHRONOLOGICAL)
                } else {
                    return sortMediaItemsByYear(mediaItemParts?.filter({ (testMediaItem:MediaItem) -> Bool in
                        //                        print(classCode,testMediaItem.classCode)
                        return testMediaItem.classCode == classCode
                    }),sorting: Constants.CHRONOLOGICAL)
                }
            } else {
                return [self]
            }
        }
    }
    
    func searchStrings() -> [String]?
    {
        var array = [String]()
        //        var set = Set<String>()
        
        //        if tagsArray != nil {
        //            tokens = tokens.union(Set(tagsArray!))
        //        }
        
        if hasSpeaker {
            array.append(speaker!)
            //
            //            if let firstname = firstNameFromName(speaker) {
            //                array.append(firstname)
            //            }
            //
            //            if let lastname = lastNameFromName(speaker) {
            //                array.append(lastname)
            //            }
        }
        
        if hasMultipleParts {
            array.append(multiPartName!)
        } else {
            array.append(title!)
        }
        
        if books != nil {
            array.append(contentsOf: books!)
        }
        
        if let titleTokens = tokensFromString(title) {
            array.append(contentsOf: titleTokens)
        }
        
        return array.count > 0 ? array : nil
    }
    
    func searchTokens() -> [String]?
    {
        var set = Set<String>()

        if tagsArray != nil {
            for tag in tagsArray! {
                if let tokens = tokensFromString(tag) {
                    set = set.union(Set(tokens))
                }
            }
        }
        
        if hasSpeaker {
            if let firstname = firstNameFromName(speaker) {
                set.insert(firstname)
            }

            if let lastname = lastNameFromName(speaker) {
                set.insert(lastname)
            }
        }
        
        if books != nil {
            set = set.union(Set(books!))
        }
        
        if let titleTokens = tokensFromString(title) {
            set = set.union(Set(titleTokens))
        }
        
        return set.count > 0 ? Array(set).map({ (string:String) -> String in
                return string.uppercased()
            }).sorted() : nil
    }
    
    func search(searchText:String?) -> Bool
    {
        if searchText != nil {
            return  ((title?.range(of:      searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((date?.range(of:       searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((speaker?.range(of:    searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((scripture?.range(of:  searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
                    ((tags?.range(of:       searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil)

//            ((id?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||
//            ((multiPartName?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)) != nil) ||

        } else {
            return false
        }
    }
    
    func searchNotesHTML(searchText:String?) -> Bool
    {
        if searchText != nil {
            if hasNotesHTML {
                if notesHTML == nil {
                    loadNotesHTML()
                }
                return notesHTML?.range(of: searchText!, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil
            } else {
                return false
            }
        } else {
            return false
        }
    }

    func mediaItemsInCollection(_ tag:String) -> [MediaItem]?
    {
        var mediaItems:[MediaItem]?
        
        if (tagsSet != nil) && tagsSet!.contains(tag) {
            mediaItems = globals.media.all?.tagMediaItems?[tag]
        }
        
        return mediaItems
    }

    var playingURL:URL? {
        get {
            var url:URL?
            
            switch playing! {
            case Playing.audio:
                url = audioFileSystemURL
                if (!FileManager.default.fileExists(atPath: url!.path)){
                    url = audioURL
                }
                break
                
            case Playing.video:
                url = videoFileSystemURL
                if (!FileManager.default.fileExists(atPath: url!.path)){
                    url = videoURL
                }
                break
                
            default:
                break
            }
            
            return url
        }
    }
    
    var isPlaying:Bool {
        get {
            return globals.mediaPlayer.url == playingURL
        }
    }
    
    // this supports settings values that are saved in defaults between sessions
    var playing:String? {
        get {
            if (dict![Field.playing] == nil) {
                if let playing = mediaItemSettings?[Field.playing] {
                    dict![Field.playing] = playing
                } else {
                    dict![Field.playing] = Playing.audio
                }
            }
            return dict![Field.playing]
        }
        
        set {
            if newValue != dict![Field.playing] {
                //Changing audio to video or vice versa resets the state and time.
                if globals.mediaPlayer.mediaItem == self {
                    globals.mediaPlayer.stop()
                }
                
                dict![Field.playing] = newValue
                mediaItemSettings?[Field.playing] = newValue
            }
        }
    }
    
    var wasShowing:String? = Showing.slides //This is an arbitrary choice
    
    // this supports settings values that are saved in defaults between sessions
    var showing:String? {
        get {
            if (dict![Field.showing] == nil) {
                if let showing = mediaItemSettings?[Field.showing] {
                    dict![Field.showing] = showing
                } else {
                    if (hasSlides && hasNotes) {
                        dict![Field.showing] = Showing.slides
                    }
                    if (!hasSlides && hasNotes) {
                        dict![Field.showing] = Showing.notes
                    }
                    if (hasSlides && !hasNotes) {
                        dict![Field.showing] = Showing.slides
                    }
                    if (!hasSlides && !hasNotes) {
                        dict![Field.showing] = Showing.none
                    }
                }
            }
            return dict![Field.showing]
        }
        
        set {
            if newValue != Showing.video {
                wasShowing = newValue
            }
            dict![Field.showing] = newValue
            mediaItemSettings?[Field.showing] = newValue
        }
    }
    
    var download:Download? {
        get {
            if showing != nil {
                return downloads[showing!]
            } else {
                return nil
            }
        }
    }
    
    var atEnd:Bool {
        get {
            if let atEnd = mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] {
                dict![Constants.SETTINGS.AT_END+playing!] = atEnd
            } else {
                dict![Constants.SETTINGS.AT_END+playing!] = "NO"
            }
            return dict![Constants.SETTINGS.AT_END+playing!] == "YES"
        }
        
        set {
            dict![Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
            mediaItemSettings?[Constants.SETTINGS.AT_END+playing!] = newValue ? "YES" : "NO"
        }
    }
    
    var websiteURL:URL? {
        get {
            return URL(string: Constants.CBC.SINGLE_WEBSITE + id)
        }
    }
    
    var downloadURL:URL? {
        get {
            return download?.downloadURL
        }
    }
    
    var fileSystemURL:URL? {
        get {
            return download?.fileSystemURL
        }
    }
    
    func hasCurrentTime() -> Bool
    {
        return (currentTime != nil) && (Float(currentTime!) != nil)
    }
    
    var currentTime:String? {
        get {
            if let current_time = mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = current_time
            } else {
                dict![Constants.SETTINGS.CURRENT_TIME+playing!] = "\(0)"
            }
//            print(dict![Constants.SETTINGS.CURRENT_TIME+playing!])
            return dict![Constants.SETTINGS.CURRENT_TIME+playing!]
        }
        
        set {
            dict![Constants.SETTINGS.CURRENT_TIME+playing!] = newValue
            
            if mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] != newValue {
               mediaItemSettings?[Constants.SETTINGS.CURRENT_TIME+playing!] = newValue 
            }
        }
    }
    
    var seriesID:String! {
        get {
            if hasMultipleParts {
                return (conferenceCode != nil ? conferenceCode! : classCode) + multiPartName!
            } else {
                return id!
            }
        }
    }
    
    var year:Int? {
        get {
            if (fullDate != nil) {
                return (Calendar.current as NSCalendar).components(.year, from: fullDate!).year
            }
            return nil
        }
    }
    
    var yearSection:String!
    {
        return yearString
    }
    
    var yearString:String! {
        if (year != nil) {
            return "\(year!)"
        } else {
            return "None"
        }
    }

    func singleJSONFromURL() -> JSON
    {
        do {
            let data = try Data(contentsOf: URL(string: Constants.JSON.URL.SINGLE + self.id!)!) // , options: NSData.ReadingOptions.mappedIfSafe
            
            let json = JSON(data: data)
            if json != JSON.null {
                
                print(json)
                return json
            }
        } catch let error as NSError {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    func loadSingleDict() -> [String:String]?
    {
        var mediaItemDicts = [[String:String]]()
        
        let json = singleJSONFromURL() // jsonDataFromDocumentsDirectory()
        
        if json != JSON.null {
            print("single json:\(json)")
            
            let mediaItems = json[Constants.JSON.ARRAY_KEY.SINGLE_ENTRY]
            
            for i in 0..<mediaItems.count {
                
                var dict = [String:String]()
                
                for (key,value) in mediaItems[i] {
                    dict["\(key)"] = "\(value)"
                }
                
                mediaItemDicts.append(dict)
            }
            
            print(mediaItemDicts)
            
            return mediaItemDicts.count > 0 ? mediaItemDicts[0] : nil
        } else {
            print("could not get json from file, make sure that file contains valid json.")
        }
        
        return nil
    }
    
    func loadNotesHTML()
    {
        if let mediaItemDict = self.loadSingleDict() {
            self.dict![Field.notes_HTML] = mediaItemDict[Field.notes_HTML]
        } else {
            print("loadSingle failure")
        }
    }
    
    var formattedDate:String? {
        get {
            let dateStringFormatter = DateFormatter()
            dateStringFormatter.dateFormat = "MMMM d, yyyy"
            dateStringFormatter.locale = Locale(identifier: "en_US_POSIX")
            return dateStringFormatter.string(for: fullDate)
        }
    }
    
    var date:String? {
        get {
            return dict![Field.date]?.substring(to: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.lowerBound) // last two characters // dict![Field.title]
        }
    }
    
    var service:String? {
        get {
            return dict![Field.date]?.substring(from: dict![Field.date]!.range(of: Constants.SINGLE_SPACE)!.upperBound) // last two characters // dict![Field.title]
        }
    }
    
    var title:String? {
        get {
            return dict![Field.title]
        }
    }
    
    var category:String? {
        get {
            return dict![Field.category]
        }
    }
    
    var scripture:String? {
        get {
            return dict![Field.scripture]
        }
    }
    
    var speakerSectionSort:String! {
        get {
            return hasSpeaker ? speakerSort! : Constants.None
        }
    }
    
    var speakerSection:String! {
        get {
            return hasSpeaker ? speaker! : Constants.None
        }
    }
    
    var speaker:String? {
        get {
            return dict![Field.speaker]?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
    }
    
    // this saves calculated values in defaults between sessions
    var speakerSort:String? {
        get {
            if dict![Field.speaker_sort] == nil {
                if let speakerSort = mediaItemSettings?[Field.speaker_sort] {
                    dict![Field.speaker_sort] = speakerSort
                } else {
                    //Sort on last names.  This assumes the speaker names are all fo the form "... <last name>" with one or more spaces before the last name and no spaces IN the last name, e.g. "Van Kirk"

                    var speakerSort:String?
                    
                    if (speaker != nil) {
                        if !speaker!.contains("Ministry Panel") {
                            if let lastName = lastNameFromName(speaker) {
                                speakerSort = lastName
                            }
                            if let firstName = firstNameFromName(speaker) {
                                speakerSort = speakerSort! + "," + firstName
                            }
                        } else {
                            speakerSort = speaker
                        }
                    }
                        
//                    print(speaker)
//                    print(speakerSort)
                    
                    dict![Field.speaker_sort] = speakerSort != nil ? speakerSort : Constants.None

//                    if var speakerSort = speaker {
//                        while (speakerSort.range(of: Constants.SINGLE_SPACE) != nil) {
//                            speakerSort = speakerSort.substring(from: speakerSort.range(of: Constants.SINGLE_SPACE)!.upperBound)
//                        }
//                        dict![Field.speaker_sort] = speakerSort
////                        settings?[Field.speaker_sort] = speakerSort
//                    } else {
//                        print("NO SPEAKER")
//                    }
                }
            }
            if dict![Field.speaker_sort] == nil {
                print("Speaker sort is NIL")
            }
            return dict![Field.speaker_sort]
        }
    }
    
    var multiPartSectionSort:String! {
        get {
            return hasMultipleParts ? multiPartSort!.lowercased() : stringWithoutPrefixes(title)!.lowercased() // Constants.Individual_Media
        }
    }
    
    var multiPartSection:String! {
        get {
            return hasMultipleParts ? multiPartName! : title! // Constants.Individual_Media
        }
    }
    
    // this saves calculated values in defaults between sessions
    var multiPartSort:String? {
        get {
            if dict![Field.multi_part_name_sort] == nil {
                if let multiPartSort = mediaItemSettings?[Field.multi_part_name_sort] {
                    dict![Field.multi_part_name_sort] = multiPartSort
                } else {
                    if let multiPartSort = stringWithoutPrefixes(multiPartName) {
                        dict![Field.multi_part_name_sort] = multiPartSort
//                        settings?[Field.series_sort] = multiPartSort
                    } else {
//                        print("multiPartSort is nil")
                    }
                }
            }
            return dict![Field.multi_part_name_sort]
        }
    }
    
    var multiPartName:String? {
        //        get {
        //            return dict![Field.series]
        //        }
        get {
            if (dict![Field.multi_part_name] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let seriesString = title!.substring(to: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.lowerBound)!).trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

                    dict![Field.multi_part_name] = seriesString
                }
            }
            
            return dict![Field.multi_part_name]
        }
    }
    
    var part:String? {
        //        get {
        //            return dict![Field.series]
        //        }
        get {
            if hasMultipleParts && (dict![Field.part] == nil) {
                if (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil) != nil) {
                    let partString = title!.substring(from: (title?.range(of: Constants.PART_INDICATOR_SINGULAR, options: NSString.CompareOptions.caseInsensitive, range: nil, locale: nil)!.upperBound)!)
//                    print(partString)
                    dict![Field.part] = partString.substring(to: partString.range(of: ")")!.lowerBound)
                }
            }
            
//            print(dict![Field.part])
            return dict![Field.part]
        }
    }
    
    // nil better be okay for these or expect a crash
    var tags:String? {
        get {
            if let tags = mediaItemSettings?[Field.tags] {
                if dict![Field.tags] != nil {
                    return dict![Field.tags]! + Constants.TAGS_SEPARATOR + tags
                } else {
                    return tags
                }
            } else {
                var tags:String?
                
                if hasSlides {
                    tags = tags != nil ? tags! + "|Slides" : "Slides"
                }
                if hasNotes {
                    tags = tags != nil ? tags! + "|Transcript" : "Transcript"
                }
                if hasVideo {
                    tags = tags != nil ? tags! + "|Video" : "Video"
                }
                
//                if let books = self.books {
//                    for book in books {
//                        tags = tags != nil ? tags! + "|Book:" + book : "Book:" + book
//                    }
//                }
                
                return dict![Field.tags] != nil ? dict![Field.tags]! + (tags != nil ? "|" + tags! : "") : tags
            }
        }
//        set {
//            var tag:String
//            var tags = newValue
//            var tagsSet = Set<String>()
//            
//            while (tags?.rangeOfString(Constants.TAGS_SEPARATOR) != nil) {
//                tag = tags!.substringToIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.startIndex)
//                tagsSet.insert(tag)
//                tags = tags!.substringFromIndex(tags!.rangeOfString(Constants.TAGS_SEPARATOR)!.endIndex)
//            }
//            
//            if (tags != nil) {
//                tagsSet.insert(tags!)
//            }

//            settings?[Field.tags] = newValue
//            dict![Field.tags] = newValue
//        }
    }
    
    func addTag(_ tag:String)
    {
        let tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
        
        if tags?.index(of: tag) == nil {
            if (mediaItemSettings?[Field.tags] == nil) {
                mediaItemSettings?[Field.tags] = tag
            } else {
                mediaItemSettings?[Field.tags] = mediaItemSettings![Field.tags]! + Constants.TAGS_SEPARATOR + tag
            }
            
            let sortTag = stringWithoutPrefixes(tag)
            
            if globals.media.all!.tagMediaItems![sortTag!] != nil {
                if globals.media.all!.tagMediaItems![sortTag!]!.index(of: self) == nil {
                    globals.media.all!.tagMediaItems![sortTag!]!.append(self)
                    globals.media.all!.tagNames![sortTag!] = tag
                }
            } else {
                globals.media.all!.tagMediaItems![sortTag!] = [self]
                globals.media.all!.tagNames![sortTag!] = tag
            }
            
            if (globals.tags.selected == tag) {
                globals.media.tagged = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: globals.media.tagged)
                })
            }
            
            DispatchQueue.main.async(execute: { () -> Void in
                NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
            })
        }
    }
    
    func removeTag(_ tag:String)
    {
        if (mediaItemSettings?[Field.tags] != nil) {
            var tags = tagsArrayFromTagsString(mediaItemSettings![Field.tags])
            
            if tags?.index(of: tag) != nil {
                tags?.remove(at: tags!.index(of: tag)!)
                mediaItemSettings?[Field.tags] = tagsArrayToTagsString(tags)
                
                let sortTag = stringWithoutPrefixes(tag)
                
                if let index = globals.media.all?.tagMediaItems?[sortTag!]?.index(of: self) {
                    globals.media.all?.tagMediaItems?[sortTag!]?.remove(at: index)
                }
                
                if globals.media.all?.tagMediaItems?[sortTag!]?.count == 0 {
                    _ = globals.media.all?.tagMediaItems?.removeValue(forKey: sortTag!)
                }
                
                if (globals.tags.selected == tag) {
                    globals.media.tagged = MediaListGroupSort(mediaItems: globals.media.all?.tagMediaItems?[sortTag!])
                    
                    DispatchQueue.main.async(execute: { () -> Void in
                        NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_MEDIA_LIST), object: globals.media.tagged)
                    })
                }
                
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_UPDATE_UI), object: self)
                })
            }
        }
    }
    
    func tagsSetToString(_ tagsSet:Set<String>?) -> String?
    {
        var tags:String?
        
        if tagsSet != nil {
            for tag in tagsSet! {
                if tags == nil {
                    tags = tag
                } else {
                    tags = tags! + Constants.TAGS_SEPARATOR + tag
                }
            }
        }
        
        return tags
    }
    
    var tagsSet:Set<String>? {
        get {
            var tag:String
            var tags = self.tags
            var tagsSet = Set<String>()
            
            while (tags?.range(of: Constants.TAGS_SEPARATOR) != nil) {
                tag = tags!.substring(to: tags!.range(of: Constants.TAGS_SEPARATOR)!.lowerBound)
                tagsSet.insert(tag)
                tags = tags!.substring(from: tags!.range(of: Constants.TAGS_SEPARATOR)!.upperBound)
            }
            
            if (tags != nil) {
                tagsSet.insert(tags!)
            }
            
            return tagsSet.count == 0 ? nil : tagsSet
        }
    }
    
    var tagsArray:[String]? {
        get {
            return tagsSet == nil ? nil : Array(tagsSet!).sorted() {
//                let range0 = $0.range(of: "Book:")
//                let range1 = $1.range(of: "Book:")
//                
//                if (range0 != nil) && (range1 != nil) {
//                    return bookNumberInBible($0.substring(from: range0!.upperBound)) < bookNumberInBible($1.substring(from: range1!.upperBound))
//                } else {
                    return $0 < $1
//                }
            }
        }
    }
    
    //    Slides: Constants.BASE_MEDIA_URL+{year}/{mediacode}slides.pdf
    //    Outline: Constants.BASE_MEDIA_URL+{year}/{mediacode}outline.pdf
    //    Transcript: Constants.BASE_MEDIA_URL+{year}/{mediacode}transcript.pdf

    var audio:String? {
        
        get {
            if (dict?[Field.audio] == nil) && hasAudio {
                dict![Field.audio] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Constants.FILENAME_EXTENSION.MP3
            }
            
//            print(dict![Field.audio])
            
            return dict![Field.audio]
        }
    }
    
    var mp4:String? {
        get {
            return dict![Field.mp4]
        }
    }
    
    var m3u8:String? {
        get {
            return dict![Field.m3u8]
        }
    }
    
    var video:String? {
        get {
            return m3u8
        }
    }
    
    var videoID:String? {
        get {
//            print(video)
            
            guard video != nil else {
                return nil
            }
            
            guard video!.contains(Constants.BASE_URL.VIDEO_PREFIX) else {
                return nil
            }
            
            let tail = video?.substring(from: Constants.BASE_URL.VIDEO_PREFIX.endIndex)
//            print(tail)
            
            let id = tail?.substring(to: tail!.range(of: ".m")!.lowerBound)
//            print(id)

            return id
        }
    }
    
    var externalVideo:String? {
        get {
            return videoID != nil ? Constants.BASE_URL.EXTERNAL_VIDEO_PREFIX + videoID! : nil
        }
    }
    
    var notes:String? {
        get {
            if (dict![Field.notes] == nil) && hasNotes { // \(year!)
                dict![Field.notes] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.notes + Constants.FILENAME_EXTENSION.PDF
            }

            //            print(dict![Field.notes])
            return dict![Field.notes]
        }
    }
    
    var searchMarkedNotesHTML:String? {
        get {
            guard (notesHTML != nil) else {
                return nil
            }
            
            guard globals.searchActive && (globals.searchText != nil) && (globals.searchText != Constants.EMPTY_STRING) else {
                return nil
            }
            
            var stringBefore:String = Constants.EMPTY_STRING
            var stringAfter:String = Constants.EMPTY_STRING
            var foundString:String = Constants.EMPTY_STRING
            var string:String = notesHTML!
            var newString:String = Constants.EMPTY_STRING
            
            repeat {
                //                            print(string)
                
                if let range = string.lowercased().range(of: globals.searchText!.lowercased()) {
                    stringBefore = string.substring(to: range.lowerBound)
                    stringAfter = string.substring(from: range.upperBound)
                    
                    foundString = string.substring(from: range.lowerBound)
                    let newRange = foundString.lowercased().range(of: globals.searchText!.lowercased())
                    foundString = foundString.substring(to: newRange!.upperBound)
                    
                    foundString = "<mark style=\"background-color:yellow;\">" + foundString + "</mark>"
                    
                    newString = newString + stringBefore + foundString
                    
                    stringBefore = stringBefore + foundString
                    
                    string = stringAfter
                }
            } while (string.lowercased().range(of: globals.searchText!.lowercased()) != nil)
            
            newString = newString + stringAfter
            
            var header = "<center><b>"
            
            if let string = title {
                header = header + string + "</br>"
            }
            
            if let string = scripture {
                header = header + string + "</br>"
            }
            
            if let string = formattedDate {
                header = header + string + "</br>"
            }
            
            if let string = speaker {
                header = header + "<i>by " + string + "</i></br>"
            }
            
            header = header + "<i>Countryside Bible Church</i></br>"
            
            header = header + "</br>"
            header = header + "Available online at <a href=\"\(websiteURL!)\">www.countrysidebible.org</a></br>"
            
            if let string = yearString {
                header = header + "Copyright \(string).  All rights reserved.</br>"
            } else {
                header = header + "Copyright, all rights reserved.</br>"
            }
            
            header = header + "<i>Unedited transcript for personal use only.</i>"
            
            header = header + "</b></center>"
            
            newString = header + newString
            
            return newString
        }
    }
    
    var notesHTML:String? {
        get {
            //            print(dict![Field.notes])
            return dict![Field.notes_HTML]
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var slides:String? {
        get {
            if (dict![Field.slides] == nil) && hasSlides { // \(year!)
                dict![Field.slides] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.slides + Constants.FILENAME_EXTENSION.PDF
            }

            return dict![Field.slides]
        }
    }
    
    // this supports set values that are saved in defaults between sessions
    var outline:String? {
        get {
            if (dict![Field.outline] == nil) && hasSlides { // \(year!)
                dict![Field.outline] = Constants.BASE_URL.MEDIA + "\(year!)/\(id!)" + Field.outline + Constants.FILENAME_EXTENSION.PDF
            }
            
            return dict![Field.outline]
        }
    }
    
    // A=Audio, V=Video, O=Outline, S=Slides, T=Transcript, H=HTML Transcript

    var files:String? {
        get {
            return dict![Field.files]
        }
    }
    
    var hasAudio:Bool {
        get {
            return files != nil ? files!.contains("A") : false
        }
    }
    
    var hasVideo:Bool {
        get {
            return files != nil ? files!.contains("V") : false
        }
    }
    
    var hasSlides:Bool {
        get {
            return files != nil ? files!.contains("S") : false
        }
    }
    
    var hasNotes:Bool {
        get {
            return files != nil ? files!.contains("T") : false
        }
    }
    
    var hasNotesHTML:Bool {
        get {
//            print(files)
            return files != nil ? files!.contains("H") : false
        }
    }
    
    var hasOutline:Bool {
        get {
            return files != nil ? files!.contains("O") : false
        }
    }
    
    var audioURL:URL? {
        get {
//            print(audio)
            return audio != nil ? URL(string: audio!) : nil
        }
    }
    
    var videoURL:URL? {
        get {
            return video != nil ? URL(string: video!) : nil
        }
    }
    
    var notesURL:URL? {
        get {
//            print(notes)
            return notes != nil ? URL(string: notes!) : nil
        }
    }
    
    var slidesURL:URL? {
        get {
//            print(slides)
            return slides != nil ? URL(string: slides!) : nil
        }
    }
    
    var outlineURL:URL? {
        get {
//            print(outline)
            return outline != nil ? URL(string: outline!) : nil
        }
    }
    
    var audioFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.MP3)
        }
    }
    
    var mp4FileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.MP4)
        }
    }
    
    var m3u8FileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + Constants.FILENAME_EXTENSION.M3U8)
        }
    }
    
    var videoFileSystemURL:URL? {
        get {
            return m3u8FileSystemURL
        }
    }
    
    var slidesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.slides + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var notesFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.notes + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var outlineFileSystemURL:URL? {
        get {
            return cachesURL()?.appendingPathComponent(id! + "." + Field.outline + Constants.FILENAME_EXTENSION.PDF)
        }
    }
    
    var bookSection:String! {
        get {
            return hasBook ? book! : hasScripture ? scripture! : Constants.None
        }
    }
    
    var testament:String? {
        if (hasBook) {
            if (Constants.OLD_TESTAMENT_BOOKS.contains(book!)) {
                return Constants.Old_Testament
            }
            if (Constants.NEW_TESTAMENT_BOOKS.contains(book!)) {
                return Constants.New_Testament
            }
        } else {
            return nil
        }
        
        return nil
    }
    
    func verses(book:String,chapter:Int) -> [Int]
    {
        var versesForChapter = [Int]()
        
        if let bacv = booksAndChaptersAndVerses() {
            if let verses = bacv[book]?[chapter] {
                versesForChapter = verses
            }
        }
        
        return versesForChapter
    }
    
    func chaptersAndVerses(book:String) -> [Int:[Int]]
    {
        var chaptersAndVerses = [Int:[Int]]()
        
        if let bacv = booksAndChaptersAndVerses() {
            if let cav = bacv[book] {
                chaptersAndVerses = cav
            }
        }
        
        return chaptersAndVerses
    }
    
    func booksAndChaptersAndVerses() -> [String:[Int:[Int]]]?
    {
        if self.bcv != nil {
            return self.bcv
        }
        
        guard (scripture != nil) else {
            return nil
        }
        
//        print(scripture!)
        
        var booksAndChaptersAndVerses = [String:[Int:[Int]]]()
        
        let books = booksFromScripture(scripture)
        
        var scriptures = [String]()
        
        var string = scripture!
        
        let separator = ";"
        
        repeat {
            if string.range(of: separator) != nil {
                scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
                string = string.substring(from: string.range(of: separator)!.upperBound)
            }
        } while (string.range(of: separator) != nil)
        
        scriptures.append(string)
        
        for scripture in scriptures {
            for book in books {
                if (scripture.range(of: book) != nil) {
                    booksAndChaptersAndVerses[book] = chaptersAndVersesFromScripture(book:book,reference:scripture.substring(from: scripture.range(of: book)!.upperBound))
                    if let chapters = booksAndChaptersAndVerses[book]?.keys {
                        for chapter in chapters {
                            if booksAndChaptersAndVerses[book]?[chapter] == nil {
                                print(description,book,chapter)
                            }
                        }
                    }
                }
            }
        }
        
//        print(scripture!)
//        print(booksAndChaptersAndVerses)
        
        self.bcv = booksAndChaptersAndVerses.count > 0 ? booksAndChaptersAndVerses : nil
        
        return self.bcv
    }
    
    func chapters(_ thisBook:String) -> [Int]?
    {
        guard !Constants.NO_CHAPTER_BOOKS.contains(thisBook) else {
            return [1]
        }
        
        var chaptersForBook:[Int]?
        
        let books = booksFromScripture(scripture)
        
        switch books.count {
        case 0:
            break
            
        case 1:
            if book == books.first {
                if Constants.NO_CHAPTER_BOOKS.contains(thisBook) {
                    chaptersForBook = [1]
                } else {
                    var string = scripture!
                    
                    if (string.range(of: ";") == nil) {
                        chaptersForBook = chaptersFromScripture(string.substring(from: scripture!.range(of: thisBook)!.upperBound))
                    } else {
                        repeat {
                            var subString = string.substring(to: string.range(of: ";")!.lowerBound)
                            
                            if (subString.range(of: thisBook) != nil) {
                                subString = subString.substring(from: subString.range(of: thisBook)!.upperBound)
                            }
                            if let chapters = chaptersFromScripture(subString) {
                                chaptersForBook?.append(contentsOf: chapters)
                            }
                            
                            string = string.substring(from: string.range(of: ";")!.upperBound)
                        } while (string.range(of: ";") != nil)
                        
                        //                        print(string)
                        if (string.range(of: thisBook) != nil) {
                            string = string.substring(from: string.range(of: thisBook)!.upperBound)
                        }
                        if let chapters = chaptersFromScripture(string) {
                            chaptersForBook?.append(contentsOf: chapters)
                        }
                    }
                }
            }
            break
            
        default:
            var scriptures = [String]()
            
            var string = scripture!
            
            let separator = ";"
            
            repeat {
                if string.range(of: separator) != nil {
                    scriptures.append(string.substring(to: string.range(of: separator)!.lowerBound))
                    string = string.substring(from: string.range(of: separator)!.upperBound)
                }
            } while (string.range(of: separator) != nil)
            
            scriptures.append(string)
            
            for scripture in scriptures {
                if (scripture.range(of: thisBook) != nil) {
                    if let chapters = chaptersFromScripture(scripture.substring(from: scripture.range(of: thisBook)!.upperBound)) {
                        if chaptersForBook == nil {
                            chaptersForBook = chapters
                        } else {
                            chaptersForBook?.append(contentsOf: chapters)
                        }
                    }
                }
            }
            break
        }
        
//        if chaptersForBook.count > 1 {
//            print("\(scripture)")
//            print("\(chaptersForBook)")
//        }
        
        return chaptersForBook
    }
    
    var books:[String]? {
        get {
            return booksFromScripture(scripture)
        }
    } //Derived from scripture
    
    var book:String? {
        get {
            if (dict![Field.book] == nil) {
                if let bookTitle = mediaItemSettings?[Field.book] {
                    dict![Field.book] = bookTitle
                } else {
                    if (scripture == Constants.Selected_Scriptures) {
//                        dict![Field.book] = Constants.Selected_Scriptures
                    } else {
                        if scripture != nil {
                            if (dict![Field.book] == nil) {
                                for bookTitle in Constants.OLD_TESTAMENT_BOOKS {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
                                            dict![Field.book] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Field.book] == nil) {
                                for bookTitle in Constants.NEW_TESTAMENT_BOOKS {
                                    if (scripture!.endIndex >= bookTitle.endIndex) &&
                                        (scripture!.substring(to: bookTitle.endIndex) == bookTitle) {
                                            dict![Field.book] = bookTitle
                                            break
                                    }
                                }
                            }
                            if (dict![Field.book] != nil) {
//                                settings?[Field.book] = dict![Field.book]
                            }
                        }
                    }
                }
            }
            
            return dict![Field.book]
        }
    }//Derived from scripture
    
    lazy var fullDate:Date?  = {
        [unowned self] in
        if (self.hasDate()) {
            return Date(dateString:self.date!)
        } else {
            return nil
        }
    }()//Derived from date
    
    var text : String? {
        get {
            var string:String?
            
            if hasDate() {
                string = date
            } else {
                string = "No Date"
            }
            
            if hasSpeaker {
                string = string! + " \(speaker!)"
            }
            
            if hasTitle() {
                if (title!.range(of: ", Part ") != nil) {
                    let first = title!.substring(to: (title!.range(of: " (Part")?.upperBound)!)
                    let second = title!.substring(from: (title!.range(of: " (Part ")?.upperBound)!)
                    let combined = first + "\u{00a0}" + second // replace the space with an unbreakable one
                    string = string! + "\n\(combined)"
                } else {
                    string = string! + "\n\(title!)"
                }
            }
            
            if hasScripture {
                string = string! + "\n\(scripture!)"
            }
            
            return string
        }
    }
    
    override var description : String {
        //This requires that date, service, title, and speaker fields all be non-nil
        
        var mediaItemString = "MediaItem: "
        
        if (category != nil) {
            mediaItemString = "\(mediaItemString) \(category!)"
        }
        
        if (id != nil) {
            mediaItemString = "\(mediaItemString) \(id!)"
        }
        
        if (date != nil) {
            mediaItemString = "\(mediaItemString) \(date!)"
        }
        
        if (service != nil) {
            mediaItemString = "\(mediaItemString) \(service!)"
        }
        
        if (title != nil) {
            mediaItemString = "\(mediaItemString) \(title!)"
        }
        
        if (scripture != nil) {
            mediaItemString = "\(mediaItemString) \(scripture!)"
        }
        
        if (speaker != nil) {
            mediaItemString = "\(mediaItemString) \(speaker!)"
        }
        
        return mediaItemString
    }
    
    struct MediaItemSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.mediaItemSettings?[mediaItem!.id]?[key]
            }
            set {
                if (mediaItem != nil) {
                    if globals.mediaItemSettings == nil {
                        globals.mediaItemSettings = [String:[String:String]]()
                    }
                    if (globals.mediaItemSettings != nil) {
                        if (globals.mediaItemSettings?[mediaItem!.id] == nil) {
                            globals.mediaItemSettings?[mediaItem!.id] = [String:String]()
                        }
                        if (globals.mediaItemSettings?[mediaItem!.id]?[key] != newValue) {
                            //                        print("\(mediaItem)")
                            globals.mediaItemSettings?[mediaItem!.id]?[key] = newValue
                            
                            // For a high volume of activity this can be very expensive.
                            globals.saveSettingsBackground()
                        }
                    } else {
                        print("globals.settings == nil in Settings!")
                    }
                } else {
                    print("mediaItem == nil in Settings!")
                }
            }
        }
    }
    
    lazy var mediaItemSettings:MediaItemSettings? = {
        return MediaItemSettings(mediaItem:self)
    }()
    
    struct MultiPartSettings {
        weak var mediaItem:MediaItem?
        
        init(mediaItem:MediaItem?) {
            if (mediaItem == nil) {
                print("nil mediaItem in Settings init!")
            }
            self.mediaItem = mediaItem
        }
        
        subscript(key:String) -> String? {
            get {
                return globals.multiPartSettings?[mediaItem!.seriesID]?[key]
            }
            set {
                guard (mediaItem != nil) else {
                    print("mediaItem == nil in SeriesSettings!")
                    return
                }

                if globals.multiPartSettings == nil {
                    globals.multiPartSettings = [String:[String:String]]()
                }
                
                guard (globals.multiPartSettings != nil) else {
                    print("globals.viewSplits == nil in SeriesSettings!")
                    return
                }
                
                if (globals.multiPartSettings?[mediaItem!.seriesID] == nil) {
                    globals.multiPartSettings?[mediaItem!.seriesID] = [String:String]()
                }
                if (globals.multiPartSettings?[mediaItem!.seriesID]?[key] != newValue) {
                    //                        print("\(mediaItem)")
                    globals.multiPartSettings?[mediaItem!.seriesID]?[key] = newValue
                    
                    // For a high volume of activity this can be very expensive.
                    globals.saveSettingsBackground()
                }
            }
        }
    }
    
    lazy var multiPartSettings:MultiPartSettings? = {
        return MultiPartSettings(mediaItem:self)
    }()
    
    var viewSplit:String? {
        get {
            return multiPartSettings?[Constants.VIEW_SPLIT]
        }
        set {
            multiPartSettings?[Constants.VIEW_SPLIT] = newValue
        }
    }
    
    var slideSplit:String? {
        get {
            return multiPartSettings?[Constants.SLIDE_SPLIT]
        }
        set {
            multiPartSettings?[Constants.SLIDE_SPLIT] = newValue
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }

        if (download != nil) {
            debug("URLSession:downloadTask:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:")
            
            debug("session: \(session.sessionDescription)")
            debug("downloadTask: \(downloadTask.taskDescription)")
            
            if (download?.fileSystemURL != nil) {
                debug("path: \(download!.fileSystemURL!.path)")
                debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
                
                if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                    debug("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
                }
            } else {
                debug("No fileSystemURL")
            }
            
            debug("bytes written: \(totalBytesWritten)")
            debug("bytes expected to write: \(totalBytesExpectedToWrite)")
            
            if (download?.state == .downloading) {
                download?.totalBytesWritten = totalBytesWritten
                download?.totalBytesExpectedToWrite = totalBytesExpectedToWrite
            } else {
                print("ERROR NOT DOWNLOADING")
            }
        } else {
            print("ERROR NO DOWNLOAD")
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        })
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.task == downloadTask) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        guard (download!.fileSystemURL != nil) else {
            print("NO FILE SYSTEM URL!")
            return
        }

        debug("URLSession:downloadTask:didFinishDownloadingToURL:")
        
        debug("session: \(session.sessionDescription)")
        debug("downloadTask: \(downloadTask.taskDescription)")
        
        debug("purpose: \(download!.purpose!)")
        
        debug("path: \(download!.fileSystemURL!.path)")
        debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
        
        if (downloadTask.taskDescription != download!.fileSystemURL!.lastPathComponent) {
            debug("downloadTask.taskDescription != download!.fileSystemURL.lastPathComponent")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        let fileManager = FileManager.default
        
        // Check if file exists
        //            print("location: \(location) \n\ndestinationURL: \(destinationURL)\n\n")
        
        do {
            if (download?.state == .downloading) && (download!.totalBytesExpectedToWrite != -1) {
                if (fileManager.fileExists(atPath: download!.fileSystemURL!.path)){
                    do {
                        try fileManager.removeItem(at: download!.fileSystemURL!)
                    } catch _ {
                        print("failed to remove duplicate download")
                    }
                }
                
                debug("\(location)")
                
                try fileManager.copyItem(at: location, to: download!.fileSystemURL!)
                try fileManager.removeItem(at: location)
                download?.state = .downloaded
            } else {
                // Nothing was downloaded
                download?.state = .none
                DispatchQueue.main.async(execute: { () -> Void in
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.MEDIA_DOWNLOAD_FAILED), object: self)
                })
            }
        } catch _ {
            print("failed to copy temp download file")
            download?.state = .none
        }
    
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }

        debug("URLSession:task:didCompleteWithError:")
        
        debug("session: \(session.sessionDescription)")
        debug("task: \(task.taskDescription)")
        
        debug("purpose: \(download!.purpose!)")
        
        if (download?.fileSystemURL != nil) {
            debug("path: \(download!.fileSystemURL!.path)")
            debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
            
            if (task.taskDescription != download!.fileSystemURL!.lastPathComponent) {
                debug("task.taskDescription != download!.fileSystemURL.lastPathComponent")
            }
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
            download?.state = .none
        }
        
        //        print("Download error: \(error)")
        //
        //        if (download?.totalBytesExpectedToWrite == 0) {
        //            download?.state = .none
        //        } else {
        //            print("Download succeeded for: \(session.description)")
        ////            download?.state = .downloaded // <- This caused a very spurious error.  Let this state chagne happen in didFinishDownloadingToURL!
        //        }
        
        // This may delete temp files other than the one we just downloaded, so don't do it.
        //        removeTempFiles()
        
        session.invalidateAndCancel()
        
        DispatchQueue.main.async(execute: { () -> Void in
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        })
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?)
    {
        var download:Download?
        
        for key in downloads.keys {
            if (downloads[key]?.session == session) {
                download = downloads[key]
                break
            }
        }
        
        guard (download != nil) else {
            print("NO DOWNLOAD FOUND!")
            return
        }
        
        debug("URLSession:didBecomeInvalidWithError:")
        
        debug("session: \(session.sessionDescription)")
        
        debug("purpose: \(download!.purpose!)")
        
        if (download?.fileSystemURL != nil) {
            debug("path: \(download!.fileSystemURL!.path)")
            debug("filename: \(download!.fileSystemURL!.lastPathComponent)")
        } else {
            debug("No fileSystemURL")
        }
        
        debug("bytes written: \(download!.totalBytesWritten)")
        debug("bytes expected to write: \(download!.totalBytesExpectedToWrite)")
        
        if (error != nil) {
            print("with error: \(error!.localizedDescription)")
        }

        download?.session = nil
    }
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession)
    {
        print("URLSessionDidFinishEventsForBackgroundURLSession")
        
        var filename:String?
        
        filename = session.configuration.identifier!.substring(from: Constants.DOWNLOAD_IDENTIFIER.endIndex)
        
        if let download = downloads.filter({ (key:String, value:Download) -> Bool in
            //                print("\(filename) \(key)")
            return value.task?.taskDescription == filename
        }).first?.1 {
            download.completionHandler?()
        }
    }
    
    func hasDate() -> Bool
    {
        return (date != nil) && (date != Constants.EMPTY_STRING)
    }
    
    func hasTitle() -> Bool
    {
        return (title != nil) && (title != Constants.EMPTY_STRING)
    }
    
//    func hasAudio() -> Bool
//    {
//        return (audio != nil) && (audio != Constants.EMPTY_STRING)
//    }
    
    func playingAudio() -> Bool
    {
        return (playing == Playing.audio)
    }
    
//    func hasVideo() -> Bool
//    {
//        return (video != nil) && (video != Constants.EMPTY_STRING)
//    }
    
    var playingVideo:Bool
    {
        get {
            return (playing == Playing.video)
        }
    }
    
    var showingVideo:Bool
    {
        get {
            return (showing == Showing.video)
        }
    }
    
    var hasScripture:Bool
    {
        get {
            return (self.scripture != nil) && (self.scripture != Constants.EMPTY_STRING)
        }
    }
    
    var hasMultipleParts:Bool
        {
        get {
            return (self.multiPartName != nil) && (self.multiPartName != Constants.EMPTY_STRING)
        }
    }
    
    var hasCategory:Bool
        {
        get {
            return (self.category != nil) && (self.category != Constants.EMPTY_STRING)
        }
    }
    
    var hasBook:Bool
    {
        get {
            return (self.book != nil) && (self.book != Constants.EMPTY_STRING)
        }
    }
    
    var hasSpeaker:Bool
    {
        get {
            return (self.speaker != nil) && (self.speaker != Constants.EMPTY_STRING)
        }
    }
    
//    func hasNotesOrSlides() -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(),hasSlides())
//    }
    
//    func hasNotes() -> Bool
//    {
//        return (self.notes != nil) && (self.notes != Constants.EMPTY_STRING)
//    }
    
    var showingNotes:Bool
    {
        get {
            return (showing == Showing.notes)
        }
    }
    
//    func hasSlides() -> Bool
//    {
//        return (self.slides != nil) && (self.slides != Constants.EMPTY_STRING)
//    }
    
    var showingSlides:Bool
    {
        get {
            return (showing == Showing.slides)
        }
    }
    
//    func hasNotesOrSlides(check:Bool) -> (hasNotes:Bool,hasSlides:Bool)
//    {
//        return (hasNotes(check),hasSlides(check))
//    }
    
    func checkNotes() -> Bool
    {
        if !hasNotes { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: notesURL!)) != nil) {
//                notes = testNotes
                print("Transcript DOES exist for: \(title!)")
            }
        }
        
        return hasNotes
    }
    
    func hasNotes(_ check:Bool) -> Bool
    {
        return check ? checkNotes() : hasNotes
    }
    
    func checkSlides() -> Bool
    {
        if !hasSlides { //  && Reachability.isConnectedToNetwork()
            if ((try? Data(contentsOf: slidesURL!)) != nil) {
//                slides = testSlides
                print("Slides DO exist for: \(title!)")
            } else {
                
            }
        }
        
        return hasSlides
    }
    
    func hasSlides(_ check:Bool) -> Bool
    {
        return check ? checkSlides() : hasSlides
    }
    
    var hasTags:Bool
    {
        get {
            return (self.tags != nil) && (self.tags != Constants.EMPTY_STRING)
        }
    }
    
    var hasFavoritesTag:Bool
    {
        get {
            return hasTags ? tagsSet!.contains(Constants.Favorites) : false
        }
    }
}