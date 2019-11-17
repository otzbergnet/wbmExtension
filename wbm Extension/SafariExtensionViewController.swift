//
//  SafariExtensionViewController.swift
//  wbm Extension
//
//  Created by Claus Wolf on 14.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import SafariServices


class SafariExtensionViewController: SFSafariExtensionViewController {
    
    //MARK: — Variables to be used
    
    @IBOutlet weak var pageHistoryLivePageButton: NSButton!
    @IBOutlet weak var oldestSnapshotButton: NSButton!
    @IBOutlet weak var newestSnapshotButton: NSButton!
    @IBOutlet weak var domainFilesButton: NSButton!
    @IBOutlet weak var domainDataButton: NSButton!
    @IBOutlet weak var currentPageButton: NSButton!
    @IBOutlet weak var wbmURLField: NSTextField!
    
    var originURL : String = ""
    var currentURL : String = ""
    var cleanedURL : String = ""
    var onWayBackMachine : Bool = false
    
    //MARK: — Return Popover Size
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:200, height:230)
        return shared
    }()
    
    //MARK: — Livecycle Functions
    
    override func viewDidLoad() {
        showOrHideLive()
        handleButtons()
    }
    
    override func viewDidAppear() {
        showOrHideLive()
    }
    
    //MARK: — Extension Functionality
    
    func getCurrentUrlData(completion : @escaping (_ currentURL : String, _ originURL : String, _ cleanedURL : String, _ onWayBackMachine: Bool) -> ()){
        SFSafariApplication.getActiveWindow { (window) in
            guard let window = window else {
                return
            }
            window.getActiveTab { (tab) in
                tab?.getActivePage(completionHandler: { (page) in
                    page?.getPropertiesWithCompletionHandler({ (properties) in
                        if let url = properties?.url{
                            if let scheme = url.scheme{
                                if let host = url.host{
                                    
                                    self.currentURL = "\(url)"
                                    self.originURL = "\(scheme)://\(host)"
                                    self.cleanedURL = self.removeWBM(url: "\(self.currentURL)")
                                    
                                    if(self.cleanedURL == self.currentURL){
                                        self.onWayBackMachine = false
                                    }
                                    else{
                                        self.onWayBackMachine = true
                                    }
                                    
                                    completion(self.currentURL, self.originURL, self.cleanedURL, self.onWayBackMachine)
                                }
                            }
                        }
                    })
                })
            }
        }
    }
    
    func openTabWithURL(url: String){
        SFSafariApplication.getActiveWindow { (window) in
            if let myUrl = URL(string: url) {
                window?.openTab(with: myUrl, makeActiveIfPossible: true, completionHandler: nil)
            }
            
        }
    }
    
    func showOrHideLive(){
        getCurrentUrlData() { (currentURL : String, originURL : String, cleanedURL: String, onWayBackMachine: Bool) in
//            NSLog("WBM_LOG: currentURL: \(currentURL)")
//            NSLog("WBM_LOG: originURL: \(originURL)")
//            NSLog("WBM_LOG: cleanedURL: \(cleanedURL)")
//            NSLog("WBM_LOG: onWayBackMachine: \(onWayBackMachine)")
            if(onWayBackMachine){
                self.pageHistoryLivePageButton.title = NSLocalizedString("Show Live Page", comment: "used in button to toggle Page History & Live Page")
            }
            else{
                self.pageHistoryLivePageButton.title = NSLocalizedString("Show Page History", comment: "used in button to toggle Page History & Live Page")
            }
        }
    }
    
    func removeWBM(url: String) -> String{
        if let regex = try? NSRegularExpression(pattern: "https?://web.archive.org/web/(.+?)/", options: .caseInsensitive) {
            let modString = regex.stringByReplacingMatches(in: url, options: [], range: NSRange(location: 0, length:  url.count), withTemplate: "")
            return modString
        }
        return url
    }
    
    func whichToOpen(onWBMurl: String, offWBMurl: String){
        if(self.onWayBackMachine){
            self.openTabWithURL(url: onWBMurl)
        }
        else{
            self.openTabWithURL(url: offWBMurl)
        }
    }
    
    //MARK: — Add Hover-Effect To Buttons
    
    func handleButtons(){
        for case let button as NSButton in self.view.subviews {
            (button.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
            let area = NSTrackingArea.init(rect: button.bounds,
                                           options: [.mouseEnteredAndExited, .activeAlways],
                                           owner: self,
                                           userInfo: ["button" : button.identifier?.rawValue ?? "failed"])
            button.addTrackingArea(area)
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let buttonName = event.trackingArea?.userInfo?.values.first as? String {
            for case let button as NSButton in self.view.subviews {
                if let identifier = button.identifier?.rawValue{
                    if identifier == buttonName {
                        (button.cell as? NSButtonCell)?.backgroundColor = NSColor.darkGray
                        button.contentTintColor = .white
                    }
                }
            }
        }
    }
    
    override func mouseExited(with event: NSEvent) {
        if let buttonName = event.trackingArea?.userInfo?.values.first as? String {
            for case let button as NSButton in self.view.subviews {
                if let identifier = button.identifier?.rawValue{
                    if identifier == buttonName {
                        (button.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
                        button.contentTintColor = .labelColor
                    }
                }
            }
        }
    }
    

    //MARK: — Button Actions
    
    @IBAction func showPageHistoryLivePageClicked(_ sender: Any) {
        //live or history
        whichToOpen(onWBMurl: self.cleanedURL, offWBMurl: "https://web.archive.org/web/*/\(self.currentURL)")
    }
    
    
    @IBAction func openOldestSnapshotClicked(_ sender: Any) {
        //oldest
        whichToOpen(onWBMurl: "https://web.archive.org/web/0/\(self.cleanedURL)", offWBMurl: "https://web.archive.org/web/0/\(self.currentURL)")
    }
    
    @IBAction func openNewestSnapshotClicked(_ sender: Any) {
        //newest
        whichToOpen(onWBMurl: "https://web.archive.org/web/2/\(self.cleanedURL)", offWBMurl: "https://web.archive.org/web/2/\(self.currentURL)")
    }
    
    @IBAction func showDomainFilesClicked(_ sender: Any) {
        //files
        
        // plenty of room for improvement here - not even sure about the logic myself
        var originCleanedURL = self.cleanedURL
        if let testURL = NSURL(string: "\(self.cleanedURL)"){
            if let scheme = testURL.scheme{
                if let host = testURL.host {
                    originCleanedURL = "\(scheme)://\(host)"
                }
            }
        }
        
        whichToOpen(onWBMurl: "https://web.archive.org/web/*/\(originCleanedURL)/*", offWBMurl: "https://web.archive.org/web/*/\(self.originURL)/*")
    }
    
    @IBAction func showDomainDataClicked(_ sender: Any) {
        //data
        self.openTabWithURL(url: "https://web.archive.org/cdx/search/cdx?showDupeCount=true&collapse=digest&output=json&url=\(self.originURL)*")
    }
    
    @IBAction func saveCurrentPageClicked(_ sender: Any) {
        //save
       whichToOpen(onWBMurl: "https://web.archive.org/save/\(self.cleanedURL)", offWBMurl: "https://web.archive.org/save/\(self.currentURL)")
  
    }
    
    @IBAction func wbmURLAction(_ sender: NSTextField) {
        let url = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if (validateUrl(urlString: url)){
            self.openTabWithURL(url: "https://web.archive.org/web/*/\(url)")
        }
    }
 
    func validateUrl (urlString: String?) -> Bool {
        let urlRegEx = "(http|https)://((\\w)*|([0-9]*)|([-|_])*)+([\\.|/]((\\w)*|([0-9]*)|([-|_])*))+"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: urlString)
    }
    
}
