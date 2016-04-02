//
//  MyTableViewController.swift
//  TWU
//
//  Created by Steve Leeke on 7/28/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

enum PopoverPurpose {
    case selectingShow

    case selectingSorting
    case selectingGrouping
    case selectingSection
    
    case selectingHistory
    
    case selectingCellAction
    
    case selectingAction
    
    case selectingTags

    case showingTags
    case editingTags
}

class MyTableViewController: UIViewController, UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate, UIPopoverPresentationControllerDelegate, PopoverTableViewControllerDelegate, NSURLSessionDownloadDelegate {

    override func canBecomeFirstResponder() -> Bool {
        return true //splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
        }
    }

    var refreshControl:UIRefreshControl?

    var session:NSURLSession? // Used for JSON

    @IBOutlet weak var listActivityIndicator: UIActivityIndicatorView!

    var progressTimer:NSTimer?
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var searchBar: UISearchBar!

    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var showButton: UIBarButtonItem!
    @IBAction func show(button: UIBarButtonItem) {
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
//                popover.navigationItem.title = "Show"
                
                popover.navigationController?.navigationBarHidden = true
                
                popover.delegate = self
                popover.purpose = .selectingShow
                
                var showMenu = [String]()
                
                if (self.splitViewController != nil) {
                    // What if it is collapsed and the detail view is showing?
                    if (!Globals.showingAbout) {
                        showMenu.append(Constants.About)
                    }
                } else {
                    showMenu.append(Constants.About)
                }
                
                //Because the list extends above and below the visible area, visibleCells is deceptive - the cell can be hidden behind a navbar or toolbar and still returned in the array of visibleCells.
                if (Globals.display.sermons != nil) && (selectedSermon != nil) { // && (Globals.display.sermons?.indexOf(selectedSermon!) != nil)
                    showMenu.append(Constants.Current_Selection)
                }
                
                if (Globals.sermonPlaying != nil) {
                    var show:String = Constants.EMPTY_STRING
                    
                    if (Globals.playerPaused) {
                        show = Constants.Sermon_Paused
                    } else {
                        show = Constants.Sermon_Playing
                    }
                    
                    if (self.splitViewController != nil) {
                        if let nvc = self.splitViewController!.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                            if let myvc = nvc.topViewController as? MyViewController {
                                if (myvc.selectedSermon != nil) {
                                    if (myvc.selectedSermon?.title != Globals.sermonPlaying?.title) || (myvc.selectedSermon?.date != Globals.sermonPlaying?.date) {
                                        // The sermonPlaying is not the one showing
                                        showMenu.append(show)
                                    } else {
                                        // The sermonPlaying is the one showing
                                    }
                                } else {
                                    // There is no selectedSermon - which should never happen
                                    print("There is no selectedSermon - which should never happen")
                                }
                            } else {
                                // About is showing
                                showMenu.append(show)
                            }
                        }
                    } else {
                        //Always show it
                        showMenu.append(show)
                    }
                } else {
                    //Nothing to show
                }
                
                if (splitViewController != nil) {
                    showMenu.append(Constants.Scripture_Index)
                }
                
                showMenu.append(Constants.History)
                
                showMenu.append(Constants.Clear_History)
                
                showMenu.append(Constants.Live)
                
                showMenu.append(Constants.Settings)
                
                popover.strings = showMenu
                
                popover.showIndex = false //(Globals.grouping == .series)
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    var selectedSermon:Sermon? {
        didSet {
            let defaults = NSUserDefaults.standardUserDefaults()
            if (selectedSermon != nil) {
                defaults.setObject(selectedSermon!.id,forKey: Constants.SELECTED_SERMON_KEY)
            } else {
                // We always select, never deselect, so this should not be done.  If we set this to nil it is for some other reason, like clearing the UI.
//                defaults.removeObjectForKey(Constants.SELECTED_SERMON_KEY)
            }
            defaults.synchronize()
        }
    }
    
    var popover : PopoverTableViewController?
    
    func disableToolBarButtons()
    {
        if let barButtons = toolbarItems {
            for barButton in barButtons {
                barButton.enabled = false
            }
        }
    }
    
    func disableBarButtons()
    {
        navigationItem.leftBarButtonItem?.enabled = false
        disableToolBarButtons()
    }
    
    func enableToolBarButtons()
    {
        if (Globals.sermonRepository.list != nil) {
            if let barButtons = toolbarItems {
                for barButton in barButtons {
                    barButton.enabled = true
                }
            }
        }
    }
    
    func enableBarButtons()
    {
        if (Globals.sermonRepository.list != nil) {
            navigationItem.leftBarButtonItem?.enabled = true
            enableToolBarButtons()
        }
    }
    
    func rowClickedAtIndex(index: Int, strings: [String], purpose:PopoverPurpose, sermon:Sermon?) {
        dismissViewControllerAnimated(true, completion: nil)
        
        switch purpose {
        case .selectingCellAction:
            switch strings[index] {
            case Constants.Download_Audio:
                sermon?.audioDownload?.download()
                break
                
            case Constants.Delete_Audio_Download:
                sermon?.audioDownload?.deleteDownload()
                break
                
            case Constants.Cancel_Audio_Download:
                sermon?.audioDownload?.cancelOrDeleteDownload()
                break
                
            case Constants.Download_Audio:
                sermon?.audioDownload?.download()
                break
                
            default:
                break
            }
            break

        case .selectingHistory:
            var sermonID:String
            if let range = Globals.sermonHistory!.reverse()[index].rangeOfString(Constants.TAGS_SEPARATOR) {
                sermonID = Globals.sermonHistory!.reverse()[index].substringFromIndex(range.endIndex)
            } else {
                sermonID = Globals.sermonHistory!.reverse()[index]
            }
            if let sermon = Globals.sermonRepository.index![sermonID] {
                if Globals.activeSermons!.contains(sermon) {
                    selectOrScrollToSermon(sermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                } else {
                    dismissViewControllerAnimated(true, completion: nil)
                    
                    let alert = UIAlertController(title:"Sermon Not in List",
                        message: "You are currently showing sermons tagged with \"\(Globals.sermonTagsSelected!)\" and the sermon \"\(sermon.title!)\" does not have that tag.  Show sermons tagged with \"All\" and try again.",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    presentViewController(alert, animated: true, completion: nil)
                }
            } else {
                dismissViewControllerAnimated(true, completion: nil)
                
                let alert = UIAlertController(title:"Sermon Not Found!",
                    message: "Yep, a genuine error - this should never happen!",
                    preferredStyle: UIAlertControllerStyle.Alert)
                
                let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                    
                })
                alert.addAction(action)
                
                presentViewController(alert, animated: true, completion: nil)
            }
            break
            
        case .selectingTags:
            
            // Should we be showing Globals.active!.sermonTags instead?  That would be the equivalent of drilling down.

            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                //                    if (index >= 0) && (index <= Globals.sermons.all!.sermonTags!.count) {
                if (index < strings.count) {
                    var new:Bool = false
                    
                    switch strings[index] {
                    case Constants.All:
                        if (Globals.showing != Constants.ALL) {
                            new = true
                            Globals.showing = Constants.ALL
                            Globals.sermonTagsSelected = nil
                        }
                        break
                        
                    default:
                        //Tagged
                        
                        let tagSelected = strings[index]
                        
                        new = (Globals.showing != Constants.TAGGED) || (Globals.sermonTagsSelected != tagSelected)
                        
                        if (new) {
                            //                                print("\(Globals.active!.sermonTags)")
                            
                            Globals.sermonTagsSelected = tagSelected
                            
                            Globals.showing = Constants.TAGGED
                        }
                        break
                    }
                    
                    if (new) {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            clearSermonsForDisplay()
                            self.tableView.reloadData()
                            
                            self.listActivityIndicator.hidden = false
                            self.listActivityIndicator.startAnimating()
                            
                            self.disableBarButtons()
                        })
                        
                        if (Globals.searchActive) {
                            self.updateSearchResults()
                        }
                        
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            setupSermonsForDisplay()
                            self.tableView.reloadData()
                            self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                            
                            self.listActivityIndicator.stopAnimating()
                            self.listActivityIndicator.hidden = true
                            
                            self.enableBarButtons()
                            
                            self.setupSearchBar()
                        })
                    }
                } else {
                    print("Index out of range")
                }
            })
            break
            
        case .selectingSection:
            dismissViewControllerAnimated(true, completion: nil)
            let indexPath = NSIndexPath(forRow: 0, inSection: index)
            
            //Too slow
            //                if (Globals.grouping == Constants.SERIES) {
            //                    let string = strings[index]
            //
            //                    if (string != Constants.Individual_Sermons) && (Globals.sermonSectionTitles.series?.indexOf(string) == nil) {
            //                        let index = Globals.sermonSectionTitles.series?.indexOf(Constants.Individual_Sermons)
            //
            //                        var sermons = [Sermon]()
            //
            //                        for sermon in Globals.activeSermons! {
            //                            if !sermon.hasSeries() {
            //                                sermons.append(sermon)
            //                            }
            //                        }
            //
            //                        let sortedSermons = sortSermons(sermons, sorting: Globals.sorting, grouping: Globals.grouping)
            //
            //                        let row = sortedSermons?.indexOf({ (sermon) -> Bool in
            //                            return string == sermon.title
            //                        })
            //
            //                        indexPath = NSIndexPath(forRow: row!, inSection: index!)
            //                    } else {
            //                        let sections = seriesFromSermons(Globals.activeSermons,withTitles: false)
            //                        let section = sections?.indexOf(string)
            //                        indexPath = NSIndexPath(forRow: 0, inSection: section!)
            //                    }
            //                }
            
            //Can't use this reliably w/ variable row heights.
            tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.Top, animated: true)
            break
            
        case .selectingGrouping:
            dismissViewControllerAnimated(true, completion: nil)
            Globals.grouping = Constants.groupings[index]
            
            if (Globals.sermonsNeed.grouping) {
                clearSermonsForDisplay()
                tableView.reloadData()
                
                listActivityIndicator.hidden = false
                listActivityIndicator.startAnimating()
                
                disableBarButtons()
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    Globals.progress = 0
                    Globals.finished = 0
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.progressTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.PROGRESS_TIMER_INTERVAL, target: self, selector: #selector(MyTableViewController.updateProgress), userInfo: nil, repeats: true)
                    })
                    
                    setupSermonsForDisplay()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                        self.listActivityIndicator.stopAnimating()
                        self.enableBarButtons()
                    })
                })
            }
            break
            
        case .selectingSorting:
            dismissViewControllerAnimated(true, completion: nil)
            Globals.sorting = Constants.sortings[index]
            
            if (Globals.sermonsNeed.sorting) {
                clearSermonsForDisplay()
                tableView.reloadData()
                
                listActivityIndicator.hidden = false
                listActivityIndicator.startAnimating()
                
                disableBarButtons()
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                    setupSermonsForDisplay()
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                        self.listActivityIndicator.stopAnimating()
                        self.enableBarButtons()
                        //
                        //                            if (self.splitViewController != nil) {
                        //                                //iPad only
                        //                                if let nvc = self.splitViewController!.viewControllers[self.splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        //                                    if let myvc = nvc.visibleViewController as? MyViewController {
                        //                                        myvc.sortSermonsInSeries()
                        //                                    }
                        //                                }
                        //
                        //                            }
                    })
                })
            }
            break
            
        case .selectingShow:
            dismissViewControllerAnimated(true, completion: nil)
            switch strings[index] {
            case Constants.About:
                about()
                break
                
            case Constants.Current_Selection:
                if let sermon = selectedSermon {
                    if Globals.activeSermons!.contains(sermon) {
                        selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                    } else {
                        dismissViewControllerAnimated(true, completion: nil)
                        
                        let alert = UIAlertController(title:"Sermon Not in List",
                            message: "You are currently showing sermons tagged with \"\(Globals.sermonTagsSelected!)\" and the sermon \"\(sermon.title!)\" does not have that tag.  Show sermons tagged with \"All\" and try again.",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        presentViewController(alert, animated: true, completion: nil)
                    }
                } else {
                    dismissViewControllerAnimated(true, completion: nil)
                    
                    let alert = UIAlertController(title:"Sermon Not Found!",
                        message: "Yep, a genuine error - this should never happen!",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    presentViewController(alert, animated: true, completion: nil)
                }
                break
                
            case Constants.Sermon_Playing:
                fallthrough
                
            case Constants.Sermon_Paused:
                Globals.gotoPlayingPaused = true
                performSegueWithIdentifier(Constants.Show_Sermon, sender: self)
                break
                
            case Constants.Scripture_Index:
                performSegueWithIdentifier(Constants.Show_Scripture_Index, sender: nil)
                break
                
            case Constants.History:
                if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                    if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                        navigationController.modalPresentationStyle = .Popover
                        //            popover?.preferredContentSize = CGSizeMake(300, 500)
                        
                        navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                        navigationController.popoverPresentationController?.delegate = self
                        
                        navigationController.popoverPresentationController?.barButtonItem = showButton
                        
                        popover.navigationItem.title = Constants.History
                        
                        popover.delegate = self
                        popover.purpose = .selectingHistory
                        
                        var historyMenu = [String]()
//                        var sections = [String]()
                        
//                        print(Globals.sermonHistory)
                        if let historyList = Globals.sermonHistory?.reverse() {
//                            print(historyList)
                            for history in historyList {
                                var sermonID:String
//                                var date:String
                                
                                if let range = history.rangeOfString(Constants.TAGS_SEPARATOR) {
                                    sermonID = history.substringFromIndex(range.endIndex)
//                                    date = history.substringToIndex(range.startIndex)
                                    
                                    if let sermon = Globals.sermonRepository.index![sermonID] {
                                        historyMenu.append(sermon.text!)
                                    }
                                }
                            }
                        }
                        
                        popover.strings = historyMenu
                        
                        popover.showIndex = false
                        popover.showSectionHeaders = false // true if the code below and related code above is used. 
                        
//                        var indexes = [Int]()
//                        var counts = [Int]()
//                        
//                        var lastSection:String?
//                        let sectionList = sections
//                        var index = 0
//                        
//                        for sectionTitle in sectionList {
//                            if sectionTitle == lastSection {
//                                sections.removeAtIndex(index)
//                            } else {
//                                index++
//                            }
//                            lastSection = sectionTitle
//                        }
//                        
//                        popover.section.titles = sections
//
//                        let historyList = Globals.sermonHistory?.reverse()
//                        
//                        for historyItem in historyList! {
//                            var counter = 0
//                            
//                            if let range = historyItem.rangeOfString(Constants.TAGS_SEPARATOR) {
//                                var date:String
//
//                                date = historyItem.substringToIndex(range.startIndex)
//                                
//                                for index in 0..<sections.count {
//                                    if (sections[index] == date.substringToIndex(date.rangeOfString(" ")!.startIndex)) {
//                                        if (counter == 0) {
//                                            indexes.append(index)
//                                        }
//                                        counter++
//                                    }
//                                }
//                                
//                                counts.append(counter)
//                            }
//                        }
//                        
//                        popover.section.indexes = indexes.count > 0 ? indexes : nil
//                        popover.section.counts = counts.count > 0 ? counts : nil

                        presentViewController(navigationController, animated: true, completion: nil)
                    }
                }
                break
                
            case Constants.Clear_History:
                Globals.sermonHistory = nil
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.removeObjectForKey(Constants.HISTORY)
                defaults.synchronize()
                break
                
            case Constants.Live:
                performSegueWithIdentifier(Constants.Show_Live, sender: nil)
                break
                
            case Constants.Settings:
                performSegueWithIdentifier(Constants.Show_Settings, sender: nil)
                break
                
            default:
                break
            }
            break
            
        default:
            break
        }
    }
    
    func willPresentSearchController(searchController: UISearchController) {
//        print("willPresentSearchController")
        Globals.searchActive = true
    }
    
    func willDismissSearchController(searchController: UISearchController)
    {
        Globals.searchActive = false
    }
    
    func didDismissSearchController(searchController: UISearchController)
    {
        didDismissSearch()
    }
    
    func didDismissSearch() {
        Globals.sermons.search = nil
        
        listActivityIndicator.hidden = false
        listActivityIndicator.startAnimating()
        
        clearSermonsForDisplay()
        tableView.reloadData()
        
        disableBarButtons()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            setupSermonsForDisplay()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.listActivityIndicator.stopAnimating()
                self.enableBarButtons()
                
                //Moving the list can be very disruptive
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: false, position: UITableViewScrollPosition.None)
            })
        })
    }
    
    func index(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)

        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Index"
                
                popover.delegate = self
                
                popover.purpose = .selectingSection
                popover.strings = Globals.active?.sectionTitles
                
                popover.showIndex = (Globals.grouping == Constants.SERIES)
                popover.showSectionHeaders = (Globals.grouping == Constants.SERIES)
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }

        // Too slow
//        if (Globals.grouping == Constants.SERIES) {
//            let strings = seriesFromSermons(Globals.activeSermons,withTitles: true)
//            popover?.strings = strings
//        } else {
//            popover?.strings = Globals.sermonSections
//        }
    }

    func grouping(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Group Sermons By"
                
                popover.delegate = self
                
                popover.purpose = .selectingGrouping
                popover.strings = Constants.Groupings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }
    
    func sorting(object:AnyObject?)
    {
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        //Present a modal dialog (iPhone) or a popover w/ tableview list of Globals.sermonSections
        //And when the user chooses one, scroll to the first time in that section.
        
        if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
            if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                let button = object as? UIBarButtonItem
                
                navigationController.modalPresentationStyle = .Popover
                //            popover?.preferredContentSize = CGSizeMake(300, 500)
                
                navigationController.popoverPresentationController?.permittedArrowDirections = .Down
                navigationController.popoverPresentationController?.delegate = self
                
                navigationController.popoverPresentationController?.barButtonItem = button
                
                popover.navigationItem.title = "Sermon Sorting"
                
                popover.delegate = self
                
                popover.purpose = .selectingSorting
                popover.strings = Constants.Sortings
                
                popover.showIndex = false
                popover.showSectionHeaders = false
                
                presentViewController(navigationController, animated: true, completion: nil)
            }
        }
    }

    // Specifically for Plus size iPhones.
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.None
    }
    
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    private func setupShowMenu()
    {
        let showButton = navigationItem.leftBarButtonItem
        
        showButton?.title = Constants.FA_REORDER
        showButton?.setTitleTextAttributes([NSFontAttributeName:UIFont(name: Constants.FontAwesome, size: Constants.FA_SHOW_FONT_SIZE)!], forState: UIControlState.Normal)
        
        showButton?.enabled = (Globals.sermons.all != nil) //&& !Globals.sermonsSortingOrGrouping
    }
    
    private func setupSortingAndGroupingOptions()
    {
        let sortingButton = UIBarButtonItem(title: Constants.Sorting, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MyTableViewController.sorting(_:)))
        let groupingButton = UIBarButtonItem(title: Constants.Grouping, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MyTableViewController.grouping(_:)))
        let indexButton = UIBarButtonItem(title: Constants.Index, style: UIBarButtonItemStyle.Plain, target: self, action: #selector(MyTableViewController.index(_:)))

        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)

        var barButtons = [UIBarButtonItem]()
        
        barButtons.append(spaceButton)
        barButtons.append(sortingButton)
        barButtons.append(spaceButton)
        barButtons.append(groupingButton)
        barButtons.append(spaceButton)
        barButtons.append(indexButton)
        barButtons.append(spaceButton)
        
        navigationController?.toolbar.translucent = false
        
        if (Globals.sermonRepository.list == nil) {
            disableToolBarButtons()
        }
        
        setToolbarItems(barButtons, animated: true)
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
//        print("searchBar:textDidChange:")
        //Unstable results from incremental search
//        updateSearchResults()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
//        print("searchBarSearchButtonClicked:")
        searchBar.resignFirstResponder()
        updateSearchResults()
    }
    
    func searchBarShouldBeginEditing(searchBar: UISearchBar) -> Bool
    {
        return !Globals.loading && !Globals.refreshing && (Globals.sermons.all != nil) // !Globals.sermonsSortingOrGrouping &&
    }
    
    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidBeginEditing:")
        Globals.searchActive = true
        searchBar.showsCancelButton = true
        
        clearSermonsForDisplay()
        tableView.reloadData()
        disableToolBarButtons()
    }
    
    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
//        print("searchBarTextDidEndEditing:")
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
//        print("searchBarCancelButtonClicked:")
        searchBar.showsCancelButton = false
        Globals.searchActive = false
        searchBar.resignFirstResponder()
        searchBar.text = nil
        didDismissSearch()
    }
    
    /* Not ready for release

    func deepLink()
    {
        // This should be rationalized with the code in AppDelegate to have one function (somewhere) so we aren't duplicating it.
        
        Globals.deepLinkWaiting = false

        let path = Globals.deepLink.path
        let searchString = Globals.deepLink.searchString
        let sorting = Globals.deepLink.sorting
        let grouping = Globals.deepLink.grouping
        let sermonTag = Globals.deepLink.tag

        Globals.deepLink.path = nil
        Globals.deepLink.searchString = nil
        Globals.deepLink.sorting = nil
        Globals.deepLink.grouping = nil
        Globals.deepLink.tag = nil

        var sermonSelected:Sermon?

        var seriesSelected:String?
        var firstSermonInSeries:Sermon?
        
        var bookSelected:String?
        var firstSermonInBook:Sermon?
        
//        var seriesIndexPath = NSIndexPath()
        
        if (path != nil) {
            //                print("path: \(path)")
            
            // Is it a series?
            if let sermonSeries = seriesSectionsFromSermons(Globals.sermons) {
                for sermonSeries in sermonSeries {
                    //                        print("sermonSeries: \(sermonSeries)")
                    if (sermonSeries == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                        //It is a series
                        seriesSelected = sermonSeries
                        break
                    }
                }
                
                if (seriesSelected != nil) {
                    var sermonsInSelectedSeries = sermonsInSermonSeries(Globals.sermons,series: seriesSelected!)
                    
                    if (sermonsInSelectedSeries?.count > 0) {
                        if let firstSermonIndex = Globals.sermons!.indexOf(sermonsInSelectedSeries![0]) {
                            firstSermonInSeries = Globals.sermons![firstSermonIndex]
                            //                            print("firstSermon: \(firstSermon)")
                        }
                    }
                }
            }
            
            if (seriesSelected == nil) {
                // Is it a sermon?
                for sermon in Globals.sermons! {
                    if (sermon.title == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                        //Found it
                        sermonSelected = sermon
                        break
                    }
                }
                //                        print("\(sermonSelected)")
            }
            
            if (seriesSelected == nil) && (sermonSelected == nil) {
                // Is it a book?
                if let sermonBooks = bookSectionsFromSermons(Globals.sermons) {
                    for sermonBook in sermonBooks {
                        //                        print("sermonBook: \(sermonBook)")
                        if (sermonBook == path!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)) {
                            //It is a series
                            bookSelected = sermonBook
                            break
                        }
                    }
                    
                    if (bookSelected != nil) {
                        var sermonsInSelectedBook = sermonsInBook(Globals.sermons,book: bookSelected!)
                        
                        if (sermonsInSelectedBook?.count > 0) {
                            if let firstSermonIndex = Globals.sermons!.indexOf(sermonsInSelectedBook![0]) {
                                firstSermonInBook = Globals.sermons![firstSermonIndex]
                                //                            print("firstSermon: \(firstSermon)")
                            }
                        }
                    }
                }
            }
        }
        
        if (sorting != nil) {
            Globals.sorting = sorting!
        }
        if (grouping != nil) {
            Globals.grouping = grouping!
        }
        
        if (sermonTag != nil) {
            if (sermonTag != Constants.ALL) {
                Globals.sermonTagsSelected = sermonTag!.stringByReplacingOccurrencesOfString(Constants.SINGLE_UNDERSCORE_STRING, withString: Constants.SINGLE_SPACE_STRING, options: NSStringCompareOptions.LiteralSearch, range: nil)
                print("\(Globals.sermonTagsSelected)")
                Globals.showing = Constants.TAGGED
                
                if let sermons = Globals.sermons {
                    var taggedSermons = [Sermon]()
                    
                    for sermon in sermons {
                        if (sermon.tags?.rangeOfString(Globals.sermonTagsSelected!) != nil) {
                            taggedSermons.append(sermon)
                        }
                    }
                    
                    Globals.taggedSermons = taggedSermons.count > 0 ? taggedSermons : nil
                }
            } else {
                Globals.showing = Constants.ALL
                Globals.sermonTagsSelected = nil
            }
        }
        
        //In case Globals.searchActive is true at the start we need to cancel it.
        Globals.searchActive = false
        Globals.searchSermons = nil
        
        if (searchString != nil) {
            Globals.searchActive = true
            Globals.searchSermons = nil
            
            if let sermons = Globals.sermonsToSearch {
                var searchSermons = [Sermon]()
                
                for sermon in sermons {
                    if (
                        ((sermon.title?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.date?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.series?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.scripture?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.tags?.rangeOfString(searchString!, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                        )
                    {
                        searchSermons.append(sermon)
                    }
                }
                
                Globals.searchSermons = searchSermons.count > 0 ? searchSermons : nil
            }
        }
        
        Globals.sermonsNeed.groupsSetup = true
        sortAndGroupSermons()
        
        var tvc:MyTableViewController?
        
        //iPad
        if (splitViewController != nil) {
            //            print("rvc = UISplitViewController")
            if let nvc = splitViewController!.viewControllers[0] as? UINavigationController {
                //                print("nvc = UINavigationController")
                tvc = nvc.topViewController as? MyTableViewController
            }
            if let nvc = splitViewController!.viewControllers[1] as? UINavigationController {
                //                print("nvc = UINavigationController")
                if let myvc = nvc.topViewController as? MyViewController {
                    if (sorting != nil) {
                        //Sort the sermonsInSeries
                        myvc.sortSermonsInSeries()
                    }
                }
            }
        }
        
        //iPhone
        if let nvc = navigationController {
            //            print("rvc = UINavigationController")
            if let _ = nvc.topViewController as? MyViewController {
                //                    print("myvc = MyViewController")
                nvc.popToRootViewControllerAnimated(true)
                
            }
            tvc = nvc.topViewController as? MyTableViewController
        }
        
        if (tvc != nil) {
            // All of the scrolling below becomes a problem in portrait on an iPad as the master view controller TVC may not be visible
            // AND when it is made visible it is setup to first scroll to current selection.
            
            //                print("tvc = MyTableViewController")
            
            //            tvc.performSegueWithIdentifier("Show Sermon", sender: tvc)
            
            tvc!.tableView.reloadData()
            
            if (Globals.sermonTagsSelected != nil) {
                tvc!.searchBar.placeholder = Globals.sermonTagsSelected!
                
                //Show the search bar
                tvc!.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
            } else {
                tvc!.searchBar.placeholder = nil
            }
            
            if (searchString != nil) {
                tvc!.searchBar.text = searchString!
//                tvc!.searchBar.becomeFirstResponder()
                tvc!.searchBar.showsCancelButton = true
                
                //Show the search bar
                tvc!.tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
            } else {
                tvc!.searchBar.text = nil
//                tvc!.searchBar.resignFirstResponder()
                tvc!.searchBar.showsCancelButton = false
            }
            
            //It should never occur that more than one of the following conditionals are true
            
            //The calls below are made twice because only calling them once left the scroll in the Middle.
            //Remember, these only occur when the app is being launched in response to a URL.  If the app is
            //already launched this function is replaced by one in the AppDelegate.
            
            //I have no idea why calling these twice makes the difference.
            
            if (firstSermonInSeries != nil) {
                tvc?.selectOrScrollToSermon(firstSermonInSeries, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                tvc?.selectOrScrollToSermon(firstSermonInSeries, select: true, scroll: true, position: UITableViewScrollPosition.Top)
            }
            
            if (firstSermonInBook != nil) {
                tvc?.selectOrScrollToSermon(firstSermonInBook, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                tvc?.selectOrScrollToSermon(firstSermonInBook, select: true, scroll: true, position: UITableViewScrollPosition.Top)
            }
            
            if (sermonSelected != nil) {
                tvc?.selectOrScrollToSermon(sermonSelected, select: true, scroll: true, position: UITableViewScrollPosition.Top)
                tvc?.selectOrScrollToSermon(sermonSelected, select: true, scroll: true, position: UITableViewScrollPosition.Top)
            }
        }
    }
    
    */
    
    func setupViews()
    {
        setupSearchBar()
        
        tableView.reloadData()
        
        enableBarButtons()
        
        listActivityIndicator.stopAnimating()
        
        setupTitle()
        
        addRefreshControl()
        
        selectedSermon = Globals.selectedSermon
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
            })
        })
        
        if (splitViewController != nil) {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.UPDATE_VIEW_NOTIFICATION, object: nil)
            })
        }
    }
    
    func updateProgress()
    {
//        print("\(Float(Globals.progress))")
//        print("\(Float(Globals.finished))")
//        print("\(Float(Globals.progress) / Float(Globals.finished))")
        
        self.progressIndicator.progress = 0
        if (Globals.finished > 0) {
            self.progressIndicator.hidden = false
            self.progressIndicator.progress = Float(Globals.progress) / Float(Globals.finished)
        }
        
        //            print("\(self.progressIndicator.progress)")
        
        if self.progressIndicator.progress == 1.0 {
            self.progressTimer?.invalidate()
            
            self.progressIndicator.hidden = true
            self.progressIndicator.progress = 0
            
            Globals.progress = 0
            Globals.finished = 0
        }
    }
    
    func loadSermons(completion: (() -> Void)?)
    {
        Globals.progress = 0
        Globals.finished = 0
        
        progressTimer = NSTimer.scheduledTimerWithTimeInterval(Constants.PROGRESS_TIMER_INTERVAL, target: self, selector: #selector(MyTableViewController.updateProgress), userInfo: nil, repeats: true)
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            Globals.loading = true

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Sermons"
            })
            
            var success = false
            var newSermons:[Sermon]?

//            if let sermons = sermonsFromArchive() {
//                newSermons = sermons
//                success = true
//            } else if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
//                newSermons = sermons
//                sermonsToArchive(sermons)
//                success = true
//            }
        
            if let sermons = sermonsFromSermonDicts(loadSermonDicts()) {
                newSermons = sermons
                success = true
            }

            if (!success) {
                // REVERT TO KNOWN GOOD JSON
                removeJSONFromFileSystemDirectory() // This will cause JSON to be loaded from the BUNDLE next time.
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.setupTitle()
                    
                    self.listActivityIndicator.stopAnimating()
                    self.listActivityIndicator.hidden = true
                    self.refreshControl?.endRefreshing()
                    
                    if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                        let alert = UIAlertController(title:"Unable to Load Sermons",
                            message: "Please try to refresh the list.",
                            preferredStyle: UIAlertControllerStyle.Alert)
                        
                        let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                            
                        })
                        alert.addAction(action)
                        
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                })
                return
            }

            var sermonsNewToUser:[Sermon]?
            
            if (Globals.sermonRepository.list != nil) {
                
                let old = Set(Globals.sermonRepository.list!.map({ (sermon:Sermon) -> String in
                    return sermon.id
                }))
                
                let new = Set(newSermons!.map({ (sermon:Sermon) -> String in
                    return sermon.id
                }))
                
                //                print("\(old.count)")
                //                print("\(new.count)")
                
                let inOldAndNew = old.intersect(new)
                //                print("\(inOldAndNew.count)")
                
                if inOldAndNew.count == 0 {
                    print("There were NO sermons in BOTH the old JSON and the new JSON.")
                }
                
                let onlyInOld = old.subtract(new)
                //                print("\(onlyInOld.count)")
                
                if onlyInOld.count > 0 {
                    print("There were \(onlyInOld.count) sermons in the old JSON that are NOT in the new JSON.")
                }
                
                let onlyInNew = new.subtract(old)
                //                print("\(onlyInNew.count)")
                
                if onlyInNew.count > 0 {
                    print("There are \(onlyInNew.count) sermons in the new JSON that were NOT in the old JSON.")
                }
                
                if (onlyInNew.count > 0) {
                    sermonsNewToUser = onlyInNew.map({ (id:String) -> Sermon in
                        return newSermons!.filter({ (sermon:Sermon) -> Bool in
                            return sermon.id == id
                        }).first!
                    })
                }
            }
            
            Globals.sermonRepository.list = newSermons

            if Globals.testing {
                testSermonsTagsAndSeries()
                
                testSermonsBooksAndSeries()
                
                testSermonsForSeries()
                
                //We can test whether the PDF's we have, and the ones we don't have, can be downloaded (since we can programmatically create the missing PDF filenames).
                testSermonsPDFs(testExisting: false, testMissing: true, showTesting: false)
                
                //Test whether the audio starts to download
                //If we can download at all, we assume we can download it all, which allows us to test all sermons to see if they can be downloaded/played.
                //                testSermonsAudioFiles()
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Loading Defaults"
            })
            loadDefaults()
            
            for sermon in Globals.sermonRepository.list! {
                sermon.removeTag(Constants.New)
            }
            
            if (sermonsNewToUser != nil) {
                for sermon in sermonsNewToUser! {
                    sermon.addTag(Constants.New)
                }
                //                print("\(sermonsNewToUser)")
                
                Globals.showing = Constants.TAGGED
                Globals.sermonTagsSelected = Constants.New
            } else {
                if (Globals.showing == Constants.TAGGED) {
                    if (Globals.sermonTagsSelected == Constants.New) {
                        Globals.sermonTagsSelected = nil
                        Globals.showing = Constants.ALL
                    }
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Sorting and Grouping"
            })
            
            Globals.sermons.all = SermonsListGroupSort(sermons: Globals.sermonRepository.list)

            setupSermonsForDisplay()
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = "Setting up Player"
                Globals.playOnLoad = false
                setupPlayer(Globals.sermonPlaying)
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.navigationItem.title = Constants.CBC_SHORT_TITLE
                self.setupViews()
            })
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                completion?()
            })
            
            Globals.loading = false
        })
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)
    {
    print("URLSession:downloadTask:bytesWritten:totalBytesWritten:totalBytesExpectedToWrite:")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) bytesWritten: \(bytesWritten) totalBytesWritten: \(totalBytesWritten) totalBytesExpectedToWrite: \(totalBytesExpectedToWrite)")
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL location: NSURL)
    {
        print("URLSession:downloadTask:didFinishDownloadingToURL")
        
        var success = false
        
        print("countOfBytesExpectedToReceive: \(downloadTask.countOfBytesExpectedToReceive)")
        
        print("URLSession: \(session.description) didFinishDownloadingToURL: \(location)")
        
        let filename = downloadTask.taskDescription!
        
        print("filename: \(filename) location: \(location)")
        
        if (downloadTask.countOfBytesReceived > 0) {
            let fileManager = NSFileManager.defaultManager()
            
            //Get documents directory URL
            if let destinationURL = cachesURL()?.URLByAppendingPathComponent(filename) {
                // Check if file exist
                if (fileManager.fileExistsAtPath(destinationURL.path!)){
                    do {
                        try fileManager.removeItemAtURL(destinationURL)
                    } catch _ {
                        print("failed to remove old json file")
                    }
                }
                
                do {
                    try fileManager.copyItemAtURL(location, toURL: destinationURL)
                    try fileManager.removeItemAtURL(location)
                    success = true
                } catch _ {
                    print("failed to copy new json file to Documents")
                }
            } else {
                print("failed to get destinationURL")
            }
        } else {
            print("downloadTask.countOfBytesReceived not > 0")
        }
        
        if success {
            // ONLY flush and refresh the data once we know we have successfully downloaded the new JSON
            // file and successfully copied it to the Documents directory.
            
            // URL call back does NOT run on the main queue
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if !Globals.playerPaused {
                    Globals.playerPaused = true
                    Globals.mpPlayer?.pause()
                    updateCurrentTimeExact()
                }
                
                Globals.mpPlayer?.view.hidden = true
                Globals.mpPlayer?.view.removeFromSuperview()
                
                self.loadSermons() {
                    self.refreshControl?.endRefreshing()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    Globals.refreshing = false
                }
            })
        } else {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
                    let alert = UIAlertController(title:"Unable to Download Sermons",
                        message: "Please try to refresh the list again.",
                        preferredStyle: UIAlertControllerStyle.Alert)
                    
                    let action = UIAlertAction(title: Constants.Okay, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                        
                    })
                    alert.addAction(action)
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                }
                
                self.refreshControl!.endRefreshing()
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                
                setupSermonsForDisplay()
                self.tableView.reloadData()
                
                Globals.refreshing = false

                self.setupViews()
            })
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?)
    {
        print("URLSession:task:didCompleteWithError")
        
        if (error != nil) {
//            print("Download failed for: \(session.description)")
        } else {
//            print("Download succeeded for: \(session.description)")
        }
        
        // This deletes more than the temp file associated with this download and sometimes it deletes files in progress
        // that are needed!  We need to find a way to delete only the temp file created by this download task.
//        removeTempFiles()
        
        let filename = task.taskDescription
        print("filename: \(filename!) error: \(error)")
        
        session.invalidateAndCancel()
        
        //        if let taskIndex = Globals.downloadTasks.indexOf(task as! NSURLSessionDownloadTask) {
        //            Globals.downloadTasks.removeAtIndex(taskIndex)
        //        }
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
    }
    
    func URLSession(session: NSURLSession, didBecomeInvalidWithError error: NSError?)
    {
        print("URLSession:didBecomeInvalidWithError")

    }
    
    func downloadJSON()
    {
        navigationItem.title = "Downloading Sermons"
        
        let jsonURL = "\(Constants.JSON_URL_PREFIX)\(Constants.CBC_SHORT.lowercaseString).\(Constants.SERMONS_JSON_FILENAME)"
        let downloadRequest = NSMutableURLRequest(URL: NSURL(string: jsonURL)!)
        
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        
        let downloadTask = session?.downloadTaskWithRequest(downloadRequest)
        downloadTask?.taskDescription = Constants.SERMONS_JSON_FILENAME
        
        downloadTask?.resume()
        
        //downloadTask goes out of scope but session must retain it.  Which means if we didn't retain session they would both be lost
        // and we would likely lose the download.
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        Globals.refreshing = true
        
        cancelAllDownloads()

        clearSermonsForDisplay()
        tableView.reloadData()

        if splitViewController != nil {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                NSNotificationCenter.defaultCenter().postNotificationName(Constants.CLEAR_VIEW_NOTIFICATION, object: nil)
            })
        }

        disableBarButtons()
        
        downloadJSON()
    }

    func removeRefreshControl()
    {
        refreshControl?.removeFromSuperview()
    }
    
    func addRefreshControl()
    {
        if (refreshControl?.superview != tableView) {
            tableView.addSubview(refreshControl!)
        }
    }
    
    func updateList()
    {
        setupSermonsForDisplay()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(MyTableViewController.updateList), name: Constants.UPDATE_SERMON_LIST_NOTIFICATION, object: Globals.sermons.hiddenTagged)

        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(MyTableViewController.handleRefresh(_:)), forControlEvents: UIControlEvents.ValueChanged)

        if Globals.sermonRepository.list == nil {
            //            disableBarButtons()
            loadSermons(nil)
        }
        
        //Eliminates blank cells at end.
        tableView.tableFooterView = UIView()
        
        //This makes accurate scrolling to sections impossible using scrollToRowAtIndexPath
//        tableView.estimatedRowHeight = tableView.rowHeight
//        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let selectedSermonKey = NSUserDefaults.standardUserDefaults().stringForKey(Constants.SELECTED_SERMON_KEY) {
            selectedSermon = Globals.sermonRepository.list?.filter({ (sermon:Sermon) -> Bool in
                return sermon.id == selectedSermonKey
            }).first
        }
        
        //.AllVisible and .Automatic is the only option that works reliably.
        //.PrimaryOverlay and .PrimaryHidden create constraint errors after dismissing the master and then swiping right to bring it back
        //and *then* changing orientation
        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
        
        // Reload the table
        tableView.reloadData()

        tableView?.allowsSelection = true

        // Uncomment the following line to preserve selection between presentations
        // clearsSelectionOnViewWillAppear = false

        navigationController?.toolbarHidden = false
        setupSortingAndGroupingOptions()
        setupShowMenu()
    }

    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
//        print("searchBarResultsListButtonClicked")
        
        if !Globals.loading && !Globals.refreshing && (Globals.sermons.all?.sermonTags != nil) && (self.storyboard != nil) { // !Globals.sermonsSortingOrGrouping &&
            if let navigationController = self.storyboard!.instantiateViewControllerWithIdentifier(Constants.POPOVER_TABLEVIEW_IDENTIFIER) as? UINavigationController {
                if let popover = navigationController.viewControllers[0] as? PopoverTableViewController {
                    navigationController.modalPresentationStyle = .Popover
                    //            popover?.preferredContentSize = CGSizeMake(300, 500)
                    
                    navigationController.popoverPresentationController?.permittedArrowDirections = .Up
                    navigationController.popoverPresentationController?.delegate = self
                    
                    navigationController.popoverPresentationController?.sourceView = searchBar
                    navigationController.popoverPresentationController?.sourceRect = searchBar.bounds
                    
                    popover.navigationItem.title = "Show Sermons Tagged With"
                    
                    popover.delegate = self
                    popover.purpose = .selectingTags
                    
                    popover.strings = [Constants.All]
                    popover.strings?.appendContentsOf(Globals.sermons.all!.sermonTags!)
                    
                    popover.showIndex = true
                    popover.showSectionHeaders = true
                    
                    presentViewController(navigationController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        updateSearchResults()
    }
    
    func updateSearchResults()
    {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.listActivityIndicator.hidden = false
            self.listActivityIndicator.startAnimating()
        })
        
        Globals.searchText = self.searchBar.text
        
        if let searchText = self.searchBar.text {
            clearSermonsForDisplay()

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.tableView.reloadData()
                self.disableToolBarButtons()
            })
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
                if (searchText != Constants.EMPTY_STRING) {
                    let searchSermons = Globals.sermonsToSearch?.filter({ (sermon:Sermon) -> Bool in
                        return ((sermon.title?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.date?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.speaker?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.series?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.scripture?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil) ||
                            ((sermon.tags?.rangeOfString(searchText, options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil, locale: nil)) != nil)
                        })
                    
                    Globals.sermons.search = SermonsListGroupSort(sermons: searchSermons)
                }
                
                setupSermonsForDisplay()
                
                if (Globals.searchText == searchText) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.tableView.reloadData()
                        self.listActivityIndicator.stopAnimating()
                        self.listActivityIndicator.hidden = true
                        self.enableToolBarButtons()
                    })
                } else {
                    print("Threw away search results!")
                }
            })
        }
    }

    func selectOrScrollToSermon(sermon:Sermon?, select:Bool, scroll:Bool, position: UITableViewScrollPosition)
    {
        if (sermon != nil) && (Globals.activeSermons?.indexOf(sermon!) != nil) {
            var indexPath = NSIndexPath(forItem: 0, inSection: 0)
            
            var section:Int = -1
            var row:Int = -1
            
            let sermons = Globals.activeSermons

            if let index = sermons!.indexOf(sermon!) {
                switch Globals.grouping! {
                case Constants.YEAR:
//                    let calendar = NSCalendar.currentCalendar()
//                    let components = calendar.components(.Year, fromDate: sermons![index].fullDate!)
//                    
//                    switch Globals.sorting! {
//                    case Constants.REVERSE_CHRONOLOGICAL:
//                        section = Globals.active!.sectionTitles!.sort({ $1 < $0 }).indexOf("\(components.year)")!
//                        break
//                    case Constants.CHRONOLOGICAL:
//                        section = Globals.active!.sectionTitles!.sort({ $0 < $1 }).indexOf("\(components.year)")!
//                        break
//                        
//                    default:
//                        break
//                    }
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.yearSection!)!
                    break
                    
                case Constants.SERIES:
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.seriesSection!)!
                    break
                    
                case Constants.BOOK:
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.bookSection!)!
                    break
                    
                case Constants.SPEAKER:
                    section = Globals.active!.sectionTitles!.indexOf(sermon!.speakerSection!)!
                    break
                    
                default:
                    break
                }

                row = index - Globals.active!.sectionIndexes![section]
            }

            if (section > -1) && (row > -1) {
                indexPath = NSIndexPath(forItem: row,inSection: section)
                
                //            print("\(Globals.sermonSelected?.title)")
                //            print("Row: \(indexPath.item)")
                //            print("Section: \(indexPath.section)")
                
                if (select) {
                    tableView.selectRowAtIndexPath(indexPath, animated: false, scrollPosition: UITableViewScrollPosition.None)
                }
                
                if (scroll) {
                    //Scrolling when the user isn't expecting it can be jarring.
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: position, animated: false)
                }
            }
        }
    }

    
    private func setupSearchBar()
    {
        switch Globals.showing! {
        case Constants.ALL:
            searchBar.placeholder = Constants.All
            break
            
        case Constants.TAGGED:
            searchBar.placeholder = Globals.sermonTagsSelected
            break
            
        default:
            break
        }
    }
    

    func setupTitle()
    {
        if (!Globals.loading && !Globals.refreshing) {
            if (splitViewController == nil) {
                if (UIDeviceOrientationIsLandscape(UIDevice.currentDevice().orientation)) {
                    navigationItem.title = Constants.CBC_LONG_TITLE
                } else {
                    navigationItem.title = Constants.CBC_SHORT_TITLE
                }
            } else {
                navigationItem.title = Constants.CBC_SHORT_TITLE
            }
        }
    }
    
    func setupSplitViewController()
    {
        if (UIDeviceOrientationIsPortrait(UIDevice.currentDevice().orientation)) {
            if (Globals.sermons.all == nil) {
                splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay//iPad only
            } else {
                if (splitViewController != nil) {
                    if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                        if let _ = nvc.visibleViewController as? WebViewController {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                        } else {
                            splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                        }
                    }
                }
            }
        } else {
            if (splitViewController != nil) {
                if let nvc = splitViewController?.viewControllers[splitViewController!.viewControllers.count - 1] as? UINavigationController {
                    if let _ = nvc.visibleViewController as? WebViewController {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryHidden //iPad only
                    } else {
                        splitViewController?.preferredDisplayMode = UISplitViewControllerDisplayMode.Automatic //iPad only
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if (Globals.sermons.all == nil) { // SortingOrGrouping
            listActivityIndicator.startAnimating()
            disableBarButtons()
        } else {
            listActivityIndicator.stopAnimating()
            enableBarButtons()
        }

        setupSearchBar()
        
        setupSplitViewController()
        
        setupTitle()
        
        navigationController?.toolbarHidden = false
    }
    
    func about()
    {
        performSegueWithIdentifier(Constants.Show_About2, sender: self)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        Globals.loadedEnoughToDeepLink = true
//        
//        if (Globals.deepLinkWaiting) {
//            deepLink()
//        } else {
            //Do we want to do this?  If someone has selected something farther down the list to view, not play, when they come back
            //the list will scroll to whatever is playing or paused.
            
            //This has to be in viewDidAppear().  Putting it in viewWillAppear() does not allow the rows at the bottom of the list
            //to be scrolled to correctly with this call.  Presumably this is because of the toolbar or something else that is still
            //getting setup in viewWillAppear.
            
            if (!Globals.scrolledToSermonLastSelected) {
                selectOrScrollToSermon(selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
                Globals.scrolledToSermonLastSelected = true
            }
//        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (splitViewController == nil) {
            navigationController?.toolbarHidden = true
        }
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    */
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        var show:Bool
        
        show = true

    //    print("shouldPerformSegueWithIdentifier")
    //    print("Selected: \(Globals.sermonSelected?.title)")
    //    print("Last Selected: \(Globals.sermonLastSelected?.title)")
    //    print("Playing: \(Globals.sermonPlaying?.title)")
        
        switch identifier {
            case Constants.Show_About:
                break

            case Constants.Show_Sermon:
                // We might check and see if the cell sermon is in a series and if not don't segue if we've
                // already done so, but I think we'll just let it go.
                // Mainly because if it is in series and we've selected another sermon in the series
                // we may want to reselect from the master list to go to that sermon in the series since it is no longer
                // selected in the detail list.

//                if let myCell = sender as? MyTableViewCell {
//                    show = (splitViewController == nil) || ((splitViewController != nil) && (splitViewController!.viewControllers.count == 1)) || (myCell.sermon != selectedSermon)
//                }
                break
            
            default:
                break
        }
        
        return show
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        var dvc = segue.destinationViewController as UIViewController
        // this next if-statement makes sure the segue prepares properly even
        //   if the MVC we're seguing to is wrapped in a UINavigationController
        if let navCon = dvc as? UINavigationController {
            dvc = navCon.visibleViewController!
        }
        
        if let identifier = segue.identifier {
            switch identifier {
            case Constants.Show_Settings:
                if let svc = dvc as? MySettingsViewController {
                    svc.modalPresentationStyle = .Popover
                    svc.popoverPresentationController?.delegate = self
                }
                break
                
            case Constants.Show_Live:
                livePlayingInfoCenter()
                break
                
            case Constants.Show_Scripture_Index:
                break
                
            case Constants.Show_About:
                fallthrough
            case Constants.Show_About2:
                Globals.showingAbout = true
                break
                
            case Constants.Show_Sermon:
                if Globals.mpPlayer?.contentURL == NSURL(string:Constants.LIVE_STREAM_URL) {
                    Globals.mpPlayerStateTime = nil
                    Globals.playOnLoad = false
                }
                
                Globals.showingAbout = false
                if (Globals.gotoPlayingPaused) {
                    Globals.gotoPlayingPaused = !Globals.gotoPlayingPaused

                    if let destination = dvc as? MyViewController {
                        destination.selectedSermon = Globals.sermonPlaying
                    }
                } else {
                    if let myCell = sender as? MyTableViewCell {
                        if (selectedSermon != myCell.sermon) || (Globals.sermonHistory == nil) {
                            addToHistory(myCell.sermon)
                        }
                        selectedSermon = myCell.sermon //Globals.activeSermons![index]

                        if selectedSermon != nil {
                            if let destination = dvc as? MyViewController {
                                destination.selectedSermon = selectedSermon
                            }
                        }
                    }
                }

                searchBar.resignFirstResponder()
                break
            default:
                break
            }
        }

    }

    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
        
        if (self.view.window == nil) {
            return
        }
        
        //Without this background/main dispatching there isn't time to scroll after a reload.
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.selectOrScrollToSermon(self.selectedSermon, select: true, scroll: true, position: UITableViewScrollPosition.Middle)
            })
        })

        setupSplitViewController()

        setupTitle()
        
        if (splitViewController != nil) {
            if (popover != nil) {
                dismissViewControllerAnimated(true, completion: nil)
                popover = nil
            }
        }
    }
    
    // MARK: UITableViewDataSource

    func numberOfSectionsInTableView(TableView: UITableView) -> Int {
        //#warning Incomplete method implementation -- Return the number of sections
        //return series.count
        return Globals.display.sectionTitles != nil ? Globals.display.sectionTitles!.count : 0
    }

    func sectionIndexTitlesForTableView(tableView: UITableView) -> [AnyObject]! {
        return nil
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Constants.HEADER_HEIGHT
    }

    func tableView(tableView: UITableView, sectionForSectionIndexTitle title: String, atIndex index: Int) -> Int {
        return 0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Globals.display.sectionTitles != nil ? Globals.display.sectionTitles![section] : nil
    }
    
    func tableView(TableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        //#warning Incomplete method implementation -- Return the number of items in the section
        return Globals.display.sectionCounts != nil ? Globals.display.sectionCounts![section] : 0
    }

    func tableView(TableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> MyTableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.SERMONS_CELL_IDENTIFIER, forIndexPath: indexPath) as! MyTableViewCell
    
        // Configure the cell
        if let section = Globals.display.sectionIndexes?[indexPath.section] {
            cell.sermon = Globals.display.sermons?[section + indexPath.row]
        } else {
            print("No sermon for cell!")
        }

        cell.vc = self

        return cell
    }

    // MARK: UITableViewDelegate
    
    func tableView(TableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didSelect")

        if let cell: MyTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
            selectedSermon = cell.sermon
        } else {
            
        }
    }
    
    func tableView(TableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
//        print("didDeselect")

//        if let cell: MyTableViewCell = tableView.cellForRowAtIndexPath(indexPath) as? MyTableViewCell {
//
//        } else {
//            
//        }
    }
    
    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    */
    func tableView(TableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
//        print("shouldHighlight")
        return true
    }
    
    func tableView(TableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
//        print("Highlighted")
    }
    
    func tableView(TableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
//        print("Unhighlighted")
    }
    
    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func TableView(TableView: UITableView, shouldShowMenuForItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }

    override func TableView(TableView: UITableView, canPerformAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) -> Bool {
        return false
    }

    override func TableView(TableView: UITableView, performAction action: Selector, forItemAtIndexPath indexPath: NSIndexPath, withSender sender: AnyObject?) {
    
    }
    */
}
