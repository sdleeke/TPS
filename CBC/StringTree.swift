//
//  StringTree.swift
//  CBC
//
//  Created by Steve Leeke on 6/17/17.
//  Copyright © 2017 Steve Leeke. All rights reserved.
//

import Foundation

// Crucial for Word Picker that this be a struct so that it is passed by value, not reference; i.e. a copy is made.
// That means all of the stringNodes are frozen when it is passed by value so that Expanded Views are always complete as of that moment and
// are not affected by changes to the tree while the expanded view is being prepared.
////////////
// So why is it a class?
////////////

class StringTree
{
    lazy var root:StringNode! = { [weak self] in
        return StringNode(nil)
    }()
    
    var incremental = false
    var building = false
//    {
//        get {
//            return operationQueue.operationCount > 0
//        }
//    }
    var completed = false
    
    convenience init(incremental: Bool)
    {
        self.init()
        self.incremental = incremental
    }
    
    var html : String?
    {
        get {
            var bodyHTML = "<!DOCTYPE html>"
            
            bodyHTML += "<html><body>"
            
            guard let roots = root?.stringNodes else {
                bodyHTML += "</body></html>"
                return bodyHTML
            }
            
            var total = 0
            for root in roots {
                if let count = root.htmlWords(nil)?.count {
                    total += count
                }
            }
            bodyHTML += "<p>Index to \(total) Words</p>"
            
            bodyHTML += "<table><tr>"
            
            for root in roots {
                if let string = root.string {
                    bodyHTML += "<td>" + "<a id=\"index\(string)\" name=\"index\(string)\" href=#\(string)>" + string + "</a>" + "</td>"
                }
            }
            
            bodyHTML += "</tr></table>"
            
            bodyHTML += "<table>"
            
            for root in roots {
                if let rows = root.htmlWords(nil) {
                    if let string = root.string {
                        bodyHTML += "<tr><td>" + "<br/>" +  "<a id=\"\(string)\" name=\"\(string)\" href=#index\(string)>" + string + "</a>" + " (\(rows.count))" + "</td></tr>"
                    }
                    
                    for row in rows {
                        bodyHTML += "<tr>" + row + "</tr>"
                    }
                }
            }
            
            bodyHTML += "</table>"

            bodyHTML += "</body></html>"
            
            return bodyHTML.insertHead(fontSize: Constants.FONT_SIZE)
        }
    }
    
    lazy var operationQueue:OperationQueue! = {
        let operationQueue = OperationQueue()
        operationQueue.name = "StringTree" + UUID().uuidString
        operationQueue.qualityOfService = .background
        operationQueue.maxConcurrentOperationCount = 1
        return operationQueue
    }()
    
    deinit {
        operationQueue.cancelAllOperations()
    }
    
    func build(strings:[String]?)
    {
        guard !building else {
            return
        }
        
        guard let strings = strings?.sorted(), strings.count > 0 else {
            return
        }
        
        building = true

        if incremental {
//            DispatchQueue.global(qos: .background).async { [weak self] in
            operationQueue.addOperation { [weak self] in
                self?.root = StringNode(nil)

                var date : Date?
                
                for string in strings {
                    self?.root.addString(string)
                    
                    if (date == nil) || (date?.timeIntervalSinceNow <= -1) { // Any more frequent and the UI becomes unresponsive.
                        Globals.shared.queue.async {
                            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self)
                        }
                        
                        date = Date()
                    }
                }
                
                self?.building = false
                self?.completed = true
                
                Globals.shared.queue.async {
                    NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.STRING_TREE_UPDATED), object: self)
                }
            }
        } else {
            // This blocks
            self.root = StringNode(nil)
            
            self.root.addStrings(strings)
            
            self.building = false
            self.completed = true
        }
    }
}

