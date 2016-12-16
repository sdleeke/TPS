//
//  PopoverTableViewController.swift
//  CBC
//
//  Created by Steve Leeke on 8/19/15.
//  Copyright (c) 2015 Steve Leeke. All rights reserved.
//

import UIKit

protocol PopoverTableViewControllerDelegate
{
    func rowClickedAtIndex(_ index:Int, strings:[String], purpose:PopoverPurpose, mediaItem:MediaItem?)
}

class PopoverTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    struct Section {
        var titles:[String]?
        var counts:[Int]?
        var indexes:[Int]?
    }
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var tableView: UITableView!
    
    var delegate : PopoverTableViewControllerDelegate?
    var purpose : PopoverPurpose?
    
    var selectedMediaItem:MediaItem?
    
    var stringsFunction:((Void)->[String]?)?
    
    var allowsSelection:Bool = true
    var allowsMultipleSelection:Bool = false
    
    var showIndex:Bool = false
    var showSectionHeaders:Bool = false
    
    var indexStrings:[String]?
    
    var strings:[String]?
    
//    var transform:((String?)->String?)?
    
//    var section:Section!
    
    lazy var section:Section! = {
        var section = Section()
        return section
    }()
    
    func setPreferredContentSize()
    {
        guard (strings != nil) else {
            return
        }
        
        self.tableView.sizeToFit()
        
        var height:CGFloat = 0.0
        var width:CGFloat = 0.0

        var deducts:CGFloat = 20 + 2*20
        
        switch purpose! {
        case .selectingTags:
            fallthrough
        case .selectingGrouping:
            fallthrough
        case .selectingSorting:
            deducts += 44
            break
            
        default:
            break
        }
        
        print(view.frame.width - deducts)
        
        let heightSize: CGSize = CGSize(width: view.frame.width - deducts, height: .greatestFiniteMagnitude)
        let widthSize: CGSize = CGSize(width: .greatestFiniteMagnitude, height: 24.0)

//        let baseHeight = "A".boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil).height
        
//        print(strings)
        
        for string in strings! {
            let string = string.replacingOccurrences(of: " (", with: "\u{00a0}(")

            let maxWidth = string.boundingRect(with: widthSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)

            let maxHeight = string.boundingRect(with: heightSize, options: .usesLineFragmentOrigin, attributes: [NSFontAttributeName: UIFont.systemFont(ofSize: 16.0)], context: nil)
            
//            print(string)
//            print(maxSize)

            if maxWidth.width > width {
                print(string,width,maxWidth.width)
                width = maxWidth.width
            }
            
//            print(string,maxHeight.height) // baseHeight

            height += 16 + maxHeight.height // - baseHeight
            
            print(maxHeight.height, (Int(maxHeight.height) / 16) - 1)
//            height += CGFloat(((Int(maxHeight.height) / 16) - 1) * 16)
        }
        
        width += 2*20
        
        switch purpose! {
        case .selectingTags:
            fallthrough
        case .selectingGrouping:
            fallthrough
        case .selectingSorting:
            width += 44
            break
            
        default:
            break
        }
        
        if showIndex {
            width += 24
            height += tableView.sectionHeaderHeight * CGFloat(indexStrings!.count)
        }
        
//        print(height)
//        print(width)
        
        self.preferredContentSize = CGSize(width: width, height: height)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //This makes accurate scrolling to sections impossible but since we don't use scrollToRowAtIndexPath with
        //the popover, this makes multi-line rows possible.

        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension

//        if purpose != .selectingHistory {
//        } else {
//            tableView.rowHeight = 100
//        }

        tableView.allowsSelection = allowsSelection
        tableView.allowsMultipleSelection = allowsMultipleSelection
        
//        setPreferredContentSize()
        
//        print("Strings: \(strings)")
//        print("Sections: \(sections)")
//        print("Section Indexes: \(sectionIndexes)")
//        print("Section Counts: \(sectionCounts)")

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    func setupIndex()
    {
        guard showIndex else {
            return
        }
        
        guard (strings != nil) else {
            return
        }
        
        guard (indexStrings != nil) else {
            return
        }
        
        let a = "A"
        
        var indexes = [Int]()
        var counts = [Int]()
        
        section.titles = Array(Set(indexStrings!.map({ (string:String) -> String in
            if string.endIndex >= a.endIndex {
                return stringWithoutPrefixes(string)!.substring(to: a.endIndex).uppercased()
            } else {
                return string
            }
        }))).sorted() { $0 < $1 }
        
        var stringIndex = [String:[String]]()
        
        for indexString in indexStrings! {
            if stringIndex[indexString.substring(to: a.endIndex)] == nil {
                stringIndex[indexString.substring(to: a.endIndex)] = [String]()
            }
            //                print(testString,string)
            stringIndex[indexString.substring(to: a.endIndex)]?.append(indexString)
        }
        
        var counter = 0
        
        for key in stringIndex.keys.sorted() {
            //                print(stringIndex[key]!)
            indexes.append(counter)
            counts.append(stringIndex[key]!.count)
            counter += stringIndex[key]!.count
        }
        
        section.indexes = indexes.count > 0 ? indexes : nil
        section.counts = counts.count > 0 ? counts : nil
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)

        if strings != nil {
            setupIndex()
            
            tableView.reloadData()
            
            setPreferredContentSize()
            
            activityIndicator?.isHidden = false
            activityIndicator?.startAnimating()
        }
        
        if stringsFunction != nil {
            DispatchQueue.global(qos: .background).async {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.activityIndicator.startAnimating()
                    self.activityIndicator?.isHidden = false
                })
                
                self.strings = self.stringsFunction?()
                if self.strings != nil {
                    let array = Array(Set(self.strings!)).sorted() { $0.uppercased() < $1.uppercased() }
                        
                    self.indexStrings = array.map({ (string:String) -> String in
                        return string.uppercased()
                    })
                    
                    self.setupIndex()
                }

                DispatchQueue.main.async(execute: { () -> Void in
                    self.tableView.reloadData()
                    
                    self.setPreferredContentSize()
                    
                    self.activityIndicator.stopAnimating()
                    self.activityIndicator?.isHidden = true
                })
            }
        }
    }

    override func viewDidAppear(_ animated: Bool)
    {
        super.viewDidAppear(animated)

        setPreferredContentSize()
        
        DispatchQueue.global(qos: .background).async {
            self.setupIndex()
            DispatchQueue.main.async(execute: { () -> Void in
                self.tableView.reloadData()
                if self.stringsFunction == nil {
                    self.activityIndicator?.stopAnimating()
                    self.activityIndicator?.isHidden = true
                }
            })
        }
        
        // The code below scrolls to the currently selected tag (if there is one), but that makes getting to All at the top of the list harder.
        // And since the currently selectd tag (if there is one) is shown in the search bar prompt text, I don't think this is needed.
//        if (purpose == .selectingTags) && (globals.mediaItemTagsSelected != nil) && (globals.mediaItemTagsSelected != Constants.All) {
//            if (strings != nil) && (globals.mediaItemTagsSelected != nil) {
//                if (showSectionHeaders) {
//                    let sectionNumber = section.titles!.indexOf(globals.mediaItemTagsSelected!.substringToIndex("A".endIndex))
//                    var row = section.indexes![sectionNumber!]
//                    for increment in 0..<section.counts![sectionNumber!] {
//                        if globals.mediaItemTagsSelected == strings?[row+increment] {
//                            row = increment
//                            break
//                        }
//                    }
//                    let indexPath = NSIndexPath(forRow: row, inSection: sectionNumber!)
//                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: true)
//                } else {
//                    if let row = strings!.indexOf(globals.mediaItemTagsSelected!) {
//                        let indexPath = NSIndexPath(forRow: row, inSection: 0)
//                        tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: UITableViewScrollPosition.None, animated: true)
//                    }
//                }
//            }
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        if showIndex, section != nil {
            return self.section.titles != nil ? self.section.titles!.count : 0
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if showIndex, self.section != nil {
            return self.section.counts != nil ? self.section.counts![section] : 0
        } else {
            return strings != nil ? strings!.count : 0
        }
    }

    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if showIndex, section != nil {
            return self.section.titles
        } else {
            return nil
        }
    }
    
//    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
//        return 48
//    }
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        if showIndex, section != nil {
            return index
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showSectionHeaders, self.section != nil { // showIndex &&
            return self.section.titles != nil ? self.section.titles![section] : nil
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.IDENTIFIER.POPOVER_CELL, for: indexPath) as! PopoverTableViewCell

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }
        
        // Configure the cell...
        switch purpose! {
        case .selectingTags:
            //            print("strings: \(strings[indexPath.row]) mediaItemTag: \(globals.mediaItemTag)")
            let string = strings![index]
            
            switch globals.media.tags.showing! {
            case Constants.TAGGED:
                if (tagsArrayFromTagsString(globals.media.tags.selected)!.index(of: string) != nil) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
            
            case Constants.ALL:
                if ((globals.media.tags.selected == nil) && (strings![index] == Constants.All)) {
                    cell.accessoryType = UITableViewCellAccessoryType.checkmark
                } else {
                    cell.accessoryType = UITableViewCellAccessoryType.none
                }
                break
                
            default:
                break
            }
            break
            
        case .selectingGrouping:
            if (Constants.groupings[index] == globals.grouping) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        case .selectingSorting:
            if (Constants.sortings[index] == globals.sorting) {
                cell.accessoryType = UITableViewCellAccessoryType.checkmark
            } else {
                cell.accessoryType = UITableViewCellAccessoryType.none
            }
            break
            
        default:
            cell.accessoryType = UITableViewCellAccessoryType.none
            break
        }

//        print(strings)
        cell.title.text = strings![index]

        return cell
    }

    func tableView(_ TableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        let cell = tableView.cellForRow(at: indexPath)

        var index = -1
        
        if (showIndex) {
            index = section.indexes != nil ? section.indexes![indexPath.section] + indexPath.row : -1
        } else {
            index = indexPath.row
        }

//        print(index,strings![index])
        
        delegate?.rowClickedAtIndex(index, strings: strings!, purpose: purpose!, mediaItem: selectedMediaItem)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
