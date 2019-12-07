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
    @IBOutlet weak var enterUrlLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var lastArchivedLabel: NSTextField!
    
    
    
    var originURL : String = ""
    var currentURL : String = ""
    var cleanedURL : String = ""
    var onWayBackMachine : Bool = false
    
    let settings = SettingsHelper()
    
    //MARK: — Return Popover Size
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:200, height:305)
        return shared
    }()
    
    //MARK: — Livecycle Functions
    
    override func viewDidLoad() {
        showOrHideLive()
        setLabels()
        handleButtons()
        hideAPILabels()
    }
    
    override func viewDidAppear() {
        setLabels()
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
    
    func openWithinSameTab(url: String){
        SFSafariApplication.getActiveWindow { (window) in
            window?.getActiveTab(completionHandler: { (tab) in
                if let myUrl = URL(string: url){
                    tab?.navigate(to: myUrl)
                }
            })
        }
    }
    
    
    func showOrHideLive(){
        getCurrentUrlData() { (currentURL : String, originURL : String, cleanedURL: String, onWayBackMachine: Bool) in
            if(onWayBackMachine){
                self.pageHistoryLivePageButton.title = NSLocalizedString("Show Live Page", comment: "used in button to toggle Page History & Live Page")
            }
            else{
                self.pageHistoryLivePageButton.title = NSLocalizedString("Show Page History", comment: "used in button to toggle Page History & Live Page")
            }
            DispatchQueue.main.async {
                self.callWayBackApi()
            }
        }
    }
    
    func setLabels(){
        self.enterUrlLabel.stringValue = NSLocalizedString("Enter a URL to go to archive:", comment: "only shown when an invalid URL is encountered")
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
    
    func callWayBackApi(){
        DispatchQueue.main.async {
            self.lastArchivedLabel.stringValue = ""
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(nil)
        }
        let jsonUrlString = "https://archive.org/wayback/available?url=\(self.currentURL)"
        let url = URL(string: jsonUrlString)
        
        let task = URLSession.shared.dataTask(with: url!) {(data, response, error) in
            if let error = error{
                //we got an error, let's tell the user
                NSLog("wbm_log: \(error)")
                DispatchQueue.main.async {
                    self.progressIndicator.stopAnimation(nil)
                    self.progressIndicator.isHidden = true
                    self.lastArchivedLabel.stringValue = NSLocalizedString("Unfortunately we encountered an error1!", comment: "network error")
                }
                
            }
            if let data = data {
                if let httpResponse = response as? HTTPURLResponse {
                    if(httpResponse.statusCode == 200){
                        self.handleData(data: data)
                    }
                    else{
                        self.lastArchivedLabel.stringValue = String(format: NSLocalizedString("Error - HTTP Status: \"%@\"", comment: "changes Context Label"), String(httpResponse.statusCode))
                        self.progressIndicator.isHidden = true
                    }
                }
                
            }
            else{
                // data wasn't there, which is also a type of eror
                
                DispatchQueue.main.async {
                    self.progressIndicator.stopAnimation(nil)
                    self.progressIndicator.isHidden = true
                    self.lastArchivedLabel.stringValue = NSLocalizedString("Unfortunately we encountered an error2!", comment: "network error")
                }
            }
            
        }
        
        task.resume()
    }
    
    func handleData(data: Data){
        //sole purpose is to dispatch the url
        do{
            let archive = try JSONDecoder().decode(Wayback.self, from: data)
            if let closest = archive.archived_snapshots?.closest {
                if (closest.available){
                    DispatchQueue.main.async {
                        self.progressIndicator.stopAnimation(nil)
                        self.lastArchivedLabel.stringValue = ""
                        self.progressIndicator.isHidden = true
                        let datum = self.convertTimestamp(timestamp: closest.timestamp)
                        self.lastArchivedLabel.stringValue = NSLocalizedString("Last archived:", comment: "Last Archived Date")
                        self.lastArchivedLabel.stringValue += "\n"
                        self.lastArchivedLabel.stringValue += datum
                    }
                }
                else{
                    //unavailable
                    DispatchQueue.main.async {
                        self.progressIndicator.stopAnimation(nil)
                        self.progressIndicator.isHidden = true
                        self.lastArchivedLabel.stringValue = NSLocalizedString("The archive is inaccessible", comment: "network error")
                    }
                }
            }
            else {
                // there was no snapshot
                
                DispatchQueue.main.async {
                    self.progressIndicator.stopAnimation(nil)
                    self.progressIndicator.isHidden = true
                    self.lastArchivedLabel.stringValue = NSLocalizedString("This page was never archived", comment: "network error")
                }
            }
            
            
        }
        catch let jsonError{
            NSLog("wbm_log json_Error: \(jsonError)")
            
            DispatchQueue.main.async {
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                self.lastArchivedLabel.stringValue = NSLocalizedString("Unfortunately we encountered an error3!", comment: "network error")
            }
            return
        }
    }
    
    func convertTimestamp(timestamp: String) -> String{
        let relativeDate = self.settings.getBoolData(key: "relativeTimestamp")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmmss"
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.locale = Locale.current
        if let date = dateFormatter.date(from: timestamp){
            
            if(relativeDate){
                let relativeDateString = self.readableIntervalSinceNow(date: date)
                return relativeDateString
            }
            else{
                let displayFormatter = DateFormatter()
                displayFormatter.locale = Locale.current
                displayFormatter.setLocalizedDateFormatFromTemplate("yyyyMMMddHHmm")
                return displayFormatter.string(from: date)
            }
            
        }
        return "failed to convert date"
    }
    
    func readableIntervalSinceNow(date: Date) -> String {
            
            let timeInterval = date.timeIntervalSinceNow
        
            if (timeInterval > -3600) { // less than 1 hour
                return "just now."
            }
            else if (timeInterval > -86400) { // less than a day
                let hours = abs(timeInterval / 3600)
                let hourString = String(format: "%.0f", hours)
                
                return String(format: NSLocalizedString("%@ hours ago", comment: "relative timestring xxx hours ago"), hourString)
                //String(format: "%.f", hours)
            }
            else if (timeInterval > (-604800 * 4)) { // less than a months
                let days = abs(timeInterval / 86400)
                let dayString = String(format: "%.0f", days)
                return String(format: NSLocalizedString("%@ days ago", comment: "relative timestring xxx days ago"), dayString)
            }
            else if (timeInterval > (-604800 * 4 * 3)) { // less than 3 months
                let weeks = abs(timeInterval / 604800)
                let weekString = String(format: "%.0f", weeks)
                return String(format: NSLocalizedString("%@ weeks ago", comment: "relative timestring xxx weeks ago"), weekString)
            }
            else {
                let dateFormatter = DateFormatter()
                dateFormatter.setLocalizedDateFormatFromTemplate("MMMM YYYY")
                dateFormatter.locale = Locale.current
                return "\(dateFormatter.string(from: date))."
            }

    }
    
    
    func hideAPILabels(){
        self.lastArchivedLabel.stringValue = ""
        self.progressIndicator.isHidden = false
    }
    
    
    //MARK: — Add Hover-Effect To Buttons
    
    func handleButtons(){
        for case let button as NSButton in self.view.subviews {
            (button.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
            button.contentTintColor = .labelColor
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
        self.dismissPopover()
        if(self.onWayBackMachine){
            self.openWithinSameTab(url: "https://web.archive.org/save/\(self.cleanedURL)")
        }
        else{
            self.openWithinSameTab(url: "https://web.archive.org/save/\(self.currentURL)")
        }
        
    }
    
    @IBAction func wbmURLAction(_ sender: NSTextField) {
        let url = sender.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if (validateUrl(urlString: url)){
            self.openTabWithURL(url: "https://web.archive.org/web/*/\(url)")
        }
        else if(validateUrl(urlString: "http://\(url)")){
            self.openTabWithURL(url: "https://web.archive.org/web/*/\(url)")
        }
        else{
            self.enterUrlLabel.stringValue = NSLocalizedString("The URL was not valid", comment: "only shown when an invalid URL is encountered")
        }
    }
    
    func validateUrl (urlString: String?) -> Bool {
        let urlRegEx = "https?://(www\\.)?[-a-zA-Z0-9@:%._\\+~#=]{1,256}\\.[a-zA-Z0-9()]{1,6}\\b([-a-zA-Z0-9()@:%_\\+.~#?&//=]*)"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: urlString)
    }
    
    @IBAction func settingsClicked(_ sender: NSButton) {
        if let url = URL(string: "wbmextension:settings"),
            NSWorkspace.shared.open(url) {
            (sender.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
            sender.contentTintColor = .labelColor
        }
    }
    
    
}

