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
    @IBOutlet weak var boost5Button: NSButton!
    
    
    
    var originURL : String = ""
    var currentURL : String = ""
    var cleanedURL : String = ""
    var onWayBackMachine : Bool = false
    var activeCallUrl =  ""
    var callMemory : [String : Boost5] = [:]
    
    let settings = SettingsHelper()
    let apiHelper = WaybackApiHelper()
    
    //MARK: — Return Popover Size
    
    static let shared: SafariExtensionViewController = {
        let shared = SafariExtensionViewController()
        shared.preferredContentSize = NSSize(width:220, height:310)
        return shared
    }()
    
    //MARK: — Livecycle Functions
    
    override func viewDidLoad() {
        handleButtons()
        hideAPILabels()
    }
    
    override func viewDidAppear() {
        setButtonsToOffstate()
    }
    
    override func viewDidLayout() {
        setLabels()
        showOrHideLive()
    }
    
    
    
    //MARK: — Extension Functionality
    
    func getCurrentUrlData(completion : @escaping (_ currentURL : String, _ originURL : String, _ cleanedURL : String, _ onWayBackMachine: Bool) -> ()){
        SFSafariApplication.getActiveWindow { (window) in
            guard let window = window else {
                completion("", "", "", false)
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
                        else{
                            completion("", "", "", false)
                        }
                    })
                })
            }
        }
    }
    
    func openTabWithURL(url: String){
        guard let myUrl = URL(string: url) else { return  }
        SFSafariApplication.getActiveWindow { (activeWindow) in
            activeWindow?.openTab(with: myUrl, makeActiveIfPossible: true, completionHandler: {_ in
                self.dismissPopover()
            })
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
            if(!self.activeCallUrl.contains(self.currentURL)){
                self.callWayBackApi()
            }
            
        }
    }
    
    func setLabels(){
        self.enterUrlLabel.stringValue = NSLocalizedString("Enter a URL to go to archive:", comment: "only shown when an invalid URL is encountered")
        self.pageHistoryLivePageButton.title = NSLocalizedString("Show Page History", comment: "used in button to toggle Page History & Live Page")
        
        let boost5Data = self.settings.getIntData(key: "boost5")
        if boost5Data > 0 {
            boost5Button.state = .on
            if boost5Data > 1 {
                let myString = String(format: NSLocalizedString("Boost next %d requests", comment: "Boost next x requests (plural)"), boost5Data)
                boost5Button.title = myString
            }
            else if(boost5Data == 1){
                boost5Button.title = NSLocalizedString("Boost next request", comment: "Boost next request (singular)")
            }
        }
        else{
            boost5Button.title = NSLocalizedString("Boost next 5 requests", comment: "Boost next request (singular)")
            boost5Button.state = .off
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
    
    func callWayBackApi(){
        DispatchQueue.main.async {
            self.lastArchivedLabel.stringValue = ""
            self.progressIndicator.isHidden = false
            self.progressIndicator.startAnimation(nil)
        }
        if(self.currentURL == ""){
            DispatchQueue.main.async {
                self.progressIndicator.stopAnimation(nil)
                self.progressIndicator.isHidden = true
                self.lastArchivedLabel.stringValue = NSLocalizedString("Unfortunately we found an empty url", comment: "empty url")
            }
            return
        }
        self.activeCallUrl = self.currentURL
        apiHelper.doWaybackCall(currentURL: self.currentURL) { res in
            switch res {
            case .success (let boost5):
                if(boost5.status == "ok"){
                    let saveCount = boost5.saveCount
                    let datum = boost5.datum
                    let lastArchivedLabel = "\(NSLocalizedString("Last archived", comment: "Last Archived Date")):\n\(datum)"
                    var pageHistoryLivePageButton = ""
                    if(saveCount > 0){
                        let label1 = NSLocalizedString("Show Page History", comment: "used in button to toggle Page History & Live Page")
                        pageHistoryLivePageButton = "\(label1): \(self.apiHelper.formatPoints(from: saveCount))"
                    }
                    else {
                        pageHistoryLivePageButton = NSLocalizedString("Show Page History", comment: "used in button to toggle Page History & Live Page")
                    }
                    self.makePopupInfo(
                        lastArchivedLabel: lastArchivedLabel,
                        pageHistoryLivePageButton: pageHistoryLivePageButton
                    )
                        
                }
                else if(boost5.status == "never"){
                    self.makePopupInfo(
                        lastArchivedLabel: NSLocalizedString("This page was never archived", comment: "network error"),
                        pageHistoryLivePageButton: NSLocalizedString("Show Page History", comment: "used in button to toggle Page History & Live Page")
                    )
                }
                else if(boost5.status == "fail json"){
                    self.makePopupInfo(
                        lastArchivedLabel: NSLocalizedString("Unfortunately we encountered an error3!", comment: "network error"),
                        pageHistoryLivePageButton: ""
                    )
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func makePopupInfo(lastArchivedLabel: String, pageHistoryLivePageButton: String){
        DispatchQueue.main.async {
            self.lastArchivedLabel.stringValue = ""
            self.progressIndicator.stopAnimation(nil)
            self.progressIndicator.isHidden = true
            self.lastArchivedLabel.stringValue = lastArchivedLabel
            if(pageHistoryLivePageButton != ""){
                self.pageHistoryLivePageButton.title = pageHistoryLivePageButton
            }
            
        }
    }
    
    
    func hideAPILabels(){
        self.lastArchivedLabel.stringValue = ""
        self.progressIndicator.isHidden = false
    }
    
    
    //MARK: — Add Hover-Effect To Buttons
    
    func handleButtons(){
        for case let button as NSButton in self.view.subviews {
            if let identifier = button.identifier?.rawValue {
                if (identifier != "boost5") {
                    (button.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
                    button.contentTintColor = .windowFrameTextColor
                    let area = NSTrackingArea.init(rect: button.bounds,
                                                   options: [.mouseEnteredAndExited, .activeAlways],
                                                   owner: self,
                                                   userInfo: ["button" : button.identifier?.rawValue ?? "failed"])
                    button.addTrackingArea(area)
                }
            }
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        if let buttonName = event.trackingArea?.userInfo?.values.first as? String {
            for case let button as NSButton in self.view.subviews {
                if let identifier = button.identifier?.rawValue{
                    if (identifier == buttonName && buttonName != "boost5"){
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
                    if (identifier == buttonName && buttonName != "boost5") {
                        (button.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
                        button.contentTintColor = .windowFrameTextColor
                    }
                }
            }
        }
    }
    
    func setButtonsToOffstate() {
        for case let button as NSButton in self.view.subviews {
            if let identifier = button.identifier?.rawValue{
                if (identifier != "boost5") {
                    (button.cell as? NSButtonCell)?.backgroundColor = NSColor.clear
                    button.contentTintColor = .windowFrameTextColor
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
        self.dismissPopover()
        self.setButtonsToOffstate()
        self.openTabWithURL(url: "https://web.archive.org/cdx/search/cdx?showDupeCount=true&collapse=digest&output=json&url=\(self.originURL)*")
    }
    
    @IBAction func saveCurrentPageClicked(_ sender: Any) {
        //save
        self.dismissPopover()
        self.setButtonsToOffstate()
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
            self.wbmURLField.stringValue = ""
        }
        else if(validateUrl(urlString: "http://\(url)")){
            self.wbmURLField.stringValue = ""
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
    
    @IBAction func boost5Tapped(_ sender: NSButton) {
        if(sender.state == .on){
            self.settings.setIntData(key: "boost5", data: 5)
        }
        else {
            self.settings.setIntData(key: "boost5", data: 0)
        }
    }
    
    
}
