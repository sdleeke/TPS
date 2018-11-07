//
//  Display.swift
//  CBC
//
//  Created by Steve Leeke on 10/15/18.
//  Copyright © 2018 Steve Leeke. All rights reserved.
//

import Foundation

class Display
{
    var mediaItems:[MediaItem]?
    var section = Section(stringsAction: nil)
    
    func setup(_ active:MediaListGroupSort? = nil)
    {
        mediaItems = active?.mediaItems
        
        Globals.shared.groupings = Constants.groupings
        Globals.shared.groupingTitles = Constants.GroupingTitles
        
        if active?.classes?.count > 0 {
            Globals.shared.groupings.append(GROUPING.CLASS)
            Globals.shared.groupingTitles.append(Grouping.Class)
        }
        
        if active?.events?.count > 0 {
            Globals.shared.groupings.append(GROUPING.EVENT)
            Globals.shared.groupingTitles.append(Grouping.Event)
        }
        
        if let grouping = Globals.shared.grouping, !Globals.shared.groupings.contains(grouping) {
            Globals.shared.grouping = GROUPING.YEAR
        }

        section.showHeaders = true
        
        section.headerStrings = active?.section?.headerStrings
        section.indexStrings = active?.section?.indexStrings
        section.indexes = active?.section?.indexes
        section.counts = active?.section?.counts
    }
    
    func clear()
    {
        mediaItems = nil
        
        section.clear()
    }
}
