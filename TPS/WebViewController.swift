//
//  WebViewController.swift
//  GTY
//
//  Created by Steve Leeke on 11/10/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import UIKit
import WebKit

class WebViewController: UIViewController, WKNavigationDelegate {

    var wkWebView:WKWebView?
    
    var loadTimer:NSTimer?
    
    @IBOutlet weak var webView: UIView!
    
    @IBOutlet weak var progressIndicator: UIProgressView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var selectedSermon:Sermon?
    
    override func canBecomeFirstResponder() -> Bool {
        return splitViewController == nil
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
        if (splitViewController == nil) && (motion == .MotionShake) {
            if (Globals.playerPaused) {
                Globals.mpPlayer?.play()
            } else {
                Globals.mpPlayer?.pause()
                updateUserDefaultsCurrentTimeExact()
            }
            Globals.playerPaused = !Globals.playerPaused
        }
    }
    
    private func setupWKWebView()
    {
        wkWebView = WKWebView()
        wkWebView?.multipleTouchEnabled = true

        wkWebView?.navigationDelegate = self
        wkWebView?.translatesAutoresizingMaskIntoConstraints = false //This will fail without this
        webView.addSubview(wkWebView!)
        
        let centerXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerXNotes)
        
        let centerYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(centerYNotes)
        
        let widthXNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(widthXNotes)
        
        let widthYNotes = NSLayoutConstraint(item: wkWebView!, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: wkWebView!.superview, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 0.0)
        wkWebView?.superview?.addConstraint(widthYNotes)
        
        wkWebView?.superview?.setNeedsLayout()
    }
    
    func printSermon(sermon:Sermon?)
    {
        if (UIPrintInteractionController.isPrintingAvailable() && (sermon != nil))
        {
            var printURL:String?
            
            switch sermon!.showing! {
            case Constants.NOTES:
                printURL = Constants.BASE_PDF_URL + sermon!.notes!
                break
            case Constants.SLIDES:
                printURL = Constants.BASE_PDF_URL + sermon!.slides!
                break
                
            default:
                break
            }
            
            if (printURL != "") && UIPrintInteractionController.canPrintURL(NSURL(string: printURL!)!) {
                //                print("can print!")
                let pi = UIPrintInfo.printInfo()
                pi.outputType = UIPrintInfoOutputType.General
                pi.jobName = Constants.Print;
                pi.orientation = UIPrintInfoOrientation.Portrait
                pi.duplex = UIPrintInfoDuplex.LongEdge
                
                let pic = UIPrintInteractionController.sharedPrintController()
                pic.printInfo = pi
                pic.showsPageRange = true
                
                //Never could get this to work:
                //            pic?.printFormatter = webView?.viewPrintFormatter()
                
                pic.printingItem = NSURL(string: printURL!)!
                pic.presentFromBarButtonItem(navigationItem.rightBarButtonItem!, animated: true, completionHandler: nil)
            }
        }
    }
    
    private func networkUnavailable()
    {
        if (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            let alert = UIAlertController(title:Constants.Network_Unavailable,
                message: "",
                preferredStyle: UIAlertControllerStyle.Alert)
            
            let action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
                
            })
            alert.addAction(action)
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    
    func actions()
    {
        //        print("action!")
        
        //In case we have one already showing
        dismissViewControllerAnimated(true, completion: nil)
        
        // Put up an action sheet
        
        let alert = UIAlertController(title: Constants.EMPTY_STRING,
            message: Constants.EMPTY_STRING,
            preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        var action : UIAlertAction
        
        if (selectedSermon!.hasNotes() || selectedSermon!.hasSlides()) {
            action = UIAlertAction(title:Constants.Print, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                //            print("print!")
                self.printSermon(self.selectedSermon)
            })
            alert.addAction(action)
            
            action = UIAlertAction(title:Constants.Open_in_Browser, style: UIAlertActionStyle.Default, handler: { (UIAlertAction) -> Void in
                let urlString = Constants.BASE_PDF_URL + self.selectedSermon!.notes!
                
                if let url = NSURL(string:urlString) {
                    if (Reachability.isConnectedToNetwork() && UIApplication.sharedApplication().canOpenURL(url)) {
                        UIApplication.sharedApplication().openURL(url)
                    } else {
                        self.networkUnavailable()
                    }
                }
            })
            alert.addAction(action)

            action = UIAlertAction(title: Constants.Cancel, style: UIAlertActionStyle.Cancel, handler: { (UIAlertAction) -> Void in
            })
            alert.addAction(action)

            //on iPad this is a popover
            alert.modalPresentationStyle = UIModalPresentationStyle.Popover
            alert.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
            
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    private func setupActionButton()
    {
        if (selectedSermon != nil) {
            self.navigationItem.setRightBarButtonItem(UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: "actions"), animated: true)
        } else {
            self.navigationItem.rightBarButtonItem = nil
        }
    }

    func loading()
    {
        progressIndicator.progress = Float(wkWebView!.estimatedProgress)
        
        if progressIndicator.progress == 1 {
            loadTimer?.invalidate()
            loadTimer = nil
            progressIndicator.hidden = true
        }
    }
    
    func setWKZoomScaleThenContentOffset(wkWebView: WKWebView, scale:CGFloat, offset:CGPoint) {
//        print("scale: \(scale)")
//        print("offset: \(offset)")
//
//        print("contentInset: \(webView.scrollView.contentInset)")
//        print("contentSize: \(webView.scrollView.contentSize)")

        // The effects of the next two calls are strongly order dependent.
        wkWebView.scrollView.setZoomScale(scale, animated: false)
        wkWebView.scrollView.setContentOffset(offset,animated: false)
    }
    
    func webView(wkWebView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        wkWebView.hidden = false
        setupWKZoomScaleAndContentOffset(wkWebView)

        loadTimer?.invalidate()
        loadTimer = nil
        progressIndicator.hidden = true
        
        activityIndicator.stopAnimating()
        activityIndicator.hidden = true
    }
    
    func setupWKZoomScaleAndContentOffset()
    {
        setupWKZoomScaleAndContentOffset(wkWebView)
    }
    
    func setupWKZoomScaleAndContentOffset(wkWebView: WKWebView?)
    {
        if (wkWebView != nil) && (selectedSermon != nil) {
            var zoomScaleStr:String?
            var contentOffsetXRatioStr:String?
            var contentOffsetYRatioStr:String?
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO]
                zoomScaleStr = selectedSermon?.settings?[Constants.NOTES_ZOOM_SCALE]
                break
                
            case Constants.SLIDES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO]
                zoomScaleStr = selectedSermon?.settings?[Constants.SLIDES_ZOOM_SCALE]
                break
                
            default:
                break
            }
            
            var zoomScale:CGFloat = 1.0
            
            var contentOffsetXRatio:CGFloat = 0.0
            var contentOffsetYRatio:CGFloat = 0.0
            
            if let ratio = contentOffsetXRatioStr {
                contentOffsetXRatio = CGFloat(Float(ratio)!)
            }
            
            if let ratio = contentOffsetYRatioStr {
                contentOffsetYRatio = CGFloat(Float(ratio)!)
            }
            
            if let zoom = zoomScaleStr {
                zoomScale = CGFloat(Float(zoom)!)
            }
            
            let contentOffset = CGPointMake(CGFloat(contentOffsetXRatio * wkWebView!.scrollView.contentSize.width * zoomScale),
                                            CGFloat(contentOffsetYRatio * wkWebView!.scrollView.contentSize.height * zoomScale))
            
            setWKZoomScaleThenContentOffset(wkWebView!, scale: zoomScale, offset: contentOffset)
        }
    }
    
    func setupWKContentOffset(wkWebView: WKWebView?)
    {
        // This used in transition to size to set the content offset.
        
        print("Before setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        
        if (wkWebView != nil) && (selectedSermon != nil) {
            var contentOffsetXRatioStr:String?
            var contentOffsetYRatioStr:String?
            
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO]
                break
                
            case Constants.SLIDES:
                contentOffsetXRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO]
                contentOffsetYRatioStr = selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO]
                break
                
            default:
                break
            }
            
            var contentOffsetXRatio:CGFloat = 0.0
            var contentOffsetYRatio:CGFloat = 0.0
            
            if let ratio = contentOffsetXRatioStr {
                contentOffsetXRatio = CGFloat(Float(ratio)!)
            }
            
            if let ratio = contentOffsetYRatioStr {
                contentOffsetYRatio = CGFloat(Float(ratio)!)
            }
            
            let contentOffset = CGPointMake(CGFloat(contentOffsetXRatio * wkWebView!.scrollView.contentSize.width), //
                                            CGFloat(contentOffsetYRatio * wkWebView!.scrollView.contentSize.height)) //
            
            print("About to setContentOffset with: \(contentOffset)")
            
            wkWebView?.scrollView.setContentOffset(contentOffset,animated: false)
            
            print("After setContentOffset: \(wkWebView?.scrollView.contentOffset)")
        }
    }
    
    func captureContentOffsetAndZoomScale()
    {
        print("\(wkWebView!.scrollView.contentOffset)")
        print("\(wkWebView!.scrollView.zoomScale)")
        
        if (selectedSermon != nil) && (UIApplication.sharedApplication().applicationState == UIApplicationState.Active) {
            switch selectedSermon!.showing! {
            case Constants.NOTES:
                if (!wkWebView!.loading) {
                    selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
                    
                    selectedSermon?.settings?[Constants.NOTES_CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
                    
                    selectedSermon?.settings?[Constants.NOTES_ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
                }
                break
                
            case Constants.SLIDES:
                if (!wkWebView!.loading) {
                    selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_X_RATIO] = "\(wkWebView!.scrollView.contentOffset.x / wkWebView!.scrollView.contentSize.width)"
                    
                    selectedSermon?.settings?[Constants.SLIDES_CONTENT_OFFSET_Y_RATIO] = "\(wkWebView!.scrollView.contentOffset.y / wkWebView!.scrollView.contentSize.height)"
                    
                    selectedSermon?.settings?[Constants.SLIDES_ZOOM_SCALE] = "\(wkWebView!.scrollView.zoomScale)"
                }
                break
                
            default:
                break
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
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator)
    {
        if (self.view.window == nil) {
            return
        }
        
        print("Size: \(size)")
        
        switch UIApplication.sharedApplication().applicationState {
        case UIApplicationState.Active:
            setupSplitViewController()
            
            print("Before animateAlongsideTransition: \(wkWebView?.scrollView.contentOffset)")
            
            captureContentOffsetAndZoomScale()
            fallthrough
            
        case UIApplicationState.Background:
            coordinator.animateAlongsideTransition({ (UIViewControllerTransitionCoordinatorContext) -> Void in
                }) { (UIViewControllerTransitionCoordinatorContext) -> Void in
                    self.setupWKContentOffset(self.wkWebView)
            }
            break
            
        default:
            break
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupWKWebView()
        setupActionButton()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationItem.title = selectedSermon!.title!
        navigationItem.hidesBackButton = true

        var stringURL:String?
        
        switch selectedSermon!.showing! {
        case Constants.NOTES:
            stringURL = Constants.BASE_PDF_URL + selectedSermon!.notes!
            break
        case Constants.SLIDES:
            stringURL = Constants.BASE_PDF_URL + selectedSermon!.slides!
            break
            
        default:
            break
        }
       
        view.bringSubviewToFront(activityIndicator)
        activityIndicator.hidden = false
        activityIndicator.startAnimating()
        
        wkWebView?.hidden = true
        
        progressIndicator.progress = 0.0
        progressIndicator.hidden = false
        if loadTimer == nil {
            loadTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "loading", userInfo: nil, repeats: true)
        }
        
        let request = NSURLRequest(URL: NSURL(string: stringURL!)!, cachePolicy: Constants.CACHE_POLICY, timeoutInterval: Constants.CACHE_TIMEOUT)
        wkWebView?.loadRequest(request) // NSURLRequest(URL: NSURL(string: stringURL!)!)
    }

    
//    override func prefersStatusBarHidden() -> Bool
//    {
//        return false
//    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        navigationItem.hidesBackButton = false
        // Seems like the following should work but doesn't.
        //        navigationItem.backBarButtonItem?.title = Constants.Back
        navigationController?.navigationBar.backItem?.title = Constants.Back
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        captureContentOffsetAndZoomScale()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        NSURLCache.sharedURLCache().removeAllCachedResponses()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
