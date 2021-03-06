//
//  SettingsViewController.swift
//  TWU
//
//  Created by Steve Leeke on 2/18/16.
//  Copyright © 2016 Steve Leeke. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController
{
    @IBOutlet weak var searchTranscriptsSwitch: UISwitch!
    
    @IBAction func searchTranscriptsAction(_ sender: UISwitch)
    {
        globals.search.transcripts = sender.isOn
        
        Thread.onMainThread {
            NotificationCenter.default.post(name: Notification.Name(rawValue: Constants.NOTIFICATION.UPDATE_SEARCH), object: nil)
        }
    }
    
    @IBOutlet weak var autoAdvanceSwitch: UISwitch!
    
    @IBAction func autoAdvanceAction(_ sender: UISwitch)
    {
        globals.autoAdvance = sender.isOn
    }
    
    @IBOutlet weak var audioSizeLabel: UILabel!
    @IBOutlet weak var cacheSizeLabel: UILabel!
    @IBOutlet weak var cacheSwitch: UISwitch!
    
    @IBAction func cacheAction(_ sender: UISwitch)
    {
        globals.cacheDownloads = sender.isOn
        
        if !sender.isOn {
            URLCache.shared.removeAllCachedResponses()
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//                globals.loadSingles = false
    
                if let mediaItems = globals.mediaRepository.list {
                    for mediaItem in mediaItems {
                        mediaItem.notesDownload?.delete()
                        mediaItem.slidesDownload?.delete()
                    }
                }
                
//                globals.loadSingles = true

                Thread.onMainThread {
                    self?.updateCacheSize()
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        searchTranscriptsSwitch.isOn = globals.search.transcripts
        autoAdvanceSwitch.isOn = globals.autoAdvance
        cacheSwitch.isOn = globals.cacheDownloads
    }
    
    func updateCacheSize()
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
//            globals.loadSingles = false
            
            let sizeOfCache = globals.cacheSize(Purpose.slides) + globals.cacheSize(Purpose.notes)
            
//            globals.loadSingles = true

            var size:Float = Float(sizeOfCache)
            
            var count = 0
            
            while size > 1024 {
                size /= 1024
                count += 1
            }
            
            var sizeLabel:String
            
            switch count {
            case 0:
                sizeLabel = "bytes"
                break
                
            case 1:
                sizeLabel = "KB"
                break
                
            case 2:
                sizeLabel = "MB"
                break
                
            case 3:
                sizeLabel = "GB"
                break
                
            default:
                sizeLabel = "ERROR"
                break
            }

            Thread.onMainThread {
                self?.cacheSizeLabel.text = "\(String(format: "%0.1f",size)) \(sizeLabel) in use"
            }
        }
    }
    
    func updateAudioSize()
    {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let sizeOfAudio = globals.cacheSize(Purpose.audio)
            
            var size:Float = Float(sizeOfAudio)
            
            var count = 0
            
            while size > 1024 {
                size /= 1024
                count += 1
            } 
            
            var sizeLabel:String
            
            switch count {
            case 0:
                sizeLabel = "bytes"
                break
                
            case 1:
                sizeLabel = "KB"
                break
                
            case 2:
                sizeLabel = "MB"
                break
                
            case 3:
                sizeLabel = "GB"
                break
                
            default:
                sizeLabel = "ERROR"
                break
            }
            
            Thread.onMainThread {
                self?.audioSizeLabel.text = "Audio Storage: \(String(format: "%0.1f",size)) \(sizeLabel) in use"
            }
        }
    }
    
    @objc func done()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        if let presentationStyle = navigationController?.modalPresentationStyle {
            switch presentationStyle {
            case .overCurrentContext:
                fallthrough
            case .fullScreen:
                fallthrough
            case .overFullScreen:
                navigationItem.setRightBarButton(UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(done)), animated: true)
                
            default:
                break
            }
        }

        // Do any additional setup after loading the view.
        if #available(iOS 9.0, *) {
            cacheSwitch.isEnabled = true
        } else {
            cacheSwitch.isEnabled = false
        }

        cacheSizeLabel.text = "Updating..."
        audioSizeLabel.text = "Audio Storage: updating..."

        updateCacheSize()
        updateAudioSize()
    }

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        globals.freeMemory()
    }
}
