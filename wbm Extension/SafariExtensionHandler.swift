//
//  SafariExtensionHandler.swift
//  wbm Extension
//
//  Created by Claus Wolf on 14.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import SafariServices

class SafariExtensionHandler: SFSafariExtensionHandler {
    
    let settings = SettingsHelper()
    
    override func messageReceived(withName messageName: String, from page: SFSafariPage, userInfo: [String : Any]?) {
        // This method will be called when a content script provided by your extension calls safari.extension.dispatchMessage("message").
        switch (messageName){
        case "wbm_pageHistory":
            handlePageHistory(page: page, href: "")
        case "shortcut":
            let shortcut = settings.getStringData(key: "shortcut")
            page.dispatchMessageToScript(withName: "shortcut", userInfo: [ "shortcut" : shortcut])
        case "pageHistoryInject":
            let inject = settings.getBoolData(key: "pageHistoryInject")
            page.dispatchMessageToScript(withName: "inject", userInfo: [ "inject" : inject])
        default:
            return
        }
    }
    
    override func toolbarItemClicked(in window: SFSafariWindow) {
        // This method will be called when your toolbar item is clicked.
        NSLog("wbm_log: The extension's toolbar item was clicked")
    }
    
    override func validateToolbarItem(in window: SFSafariWindow, validationHandler: @escaping ((Bool, String) -> Void)) {
        // This is called when Safari's state changed in some way that would require the extension's toolbar item to be validated again.
        validationHandler(true, "")
    }
    
    override func validateContextMenuItem(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil, validationHandler: @escaping (Bool, String?) -> Void) {       
        switch (command){
        case "wbm_newestSnapshot":
            let label = NSLocalizedString("Open Newest Snapshot with Wayback", comment: "context menu")
            if(settings.getBoolData(key: "openNewContext")){
                validationHandler(false, label)
            }
            else{
                validationHandler(true, label)
            }
        case "wbm_oldestSnapshot":
            let label = NSLocalizedString("Open Oldest Snapshot with Wayback", comment: "context menu")
            if(settings.getBoolData(key: "openOldContext")){
                validationHandler(false, label)
            }
            else{
                validationHandler(true, label)
            }
        case "wbm_pageHistory":
            let label = NSLocalizedString("Show Page History with Wayback", comment: "context menu")
            if(settings.getBoolData(key: "pageHistoryContext")){
                validationHandler(false, label)
            }
            else{
                validationHandler(true, label)
            }
        default:
            NSLog("wbm_log: apparently we found a new command that we didn't code for. bummer...")
        }
        
    }
    
    override func popoverViewController() -> SFSafariExtensionViewController {
        return SafariExtensionViewController.shared
    }
    
    //construct the URL and open a new tab, when text is selected and the context menu is selected
    override func contextMenuItemSelected(withCommand command: String, in page: SFSafariPage, userInfo: [String : Any]? = nil) {
        var href = ""
        if let myUserInfo = userInfo{
            let link = myUserInfo["href"] as! String
            if(link != "-"){
                href = link
            }
        }
        switch (command) {
        case "wbm_pageHistory":
            handlePageHistory(page: page, href: href)
        case "wbm_newestSnapshot":
            handleNewestSnapshot(page: page, href: href)
        case "wbm_oldestSnapshot":
            handleOldestSnapshot(page: page, href: href)
        default:
            return
        }
        
    }
    
    func handlePageHistory(page: SFSafariPage, href: String){
        if(href != ""){
            let url = "https://web.archive.org/web/*/\(href)"
            self.openTabWithUrl(url: url)
        }
        else{
            page.getPropertiesWithCompletionHandler { (pagePropierties) in
                if let currentUrl = pagePropierties?.url{
                    let url = "https://web.archive.org/web/*/\(currentUrl)"
                    self.openTabWithUrl(url: url)
                }
            }
        }
    }
    
    func handleNewestSnapshot(page: SFSafariPage, href: String){
        if(href != ""){
            let url = "https://web.archive.org/web/2/\(href)"
            self.openTabWithUrl(url: url)
        }
        else{
            page.getPropertiesWithCompletionHandler { (pagePropierties) in
                if let currentUrl = pagePropierties?.url{
                    let url = "https://web.archive.org/web/2/\(currentUrl)"
                    self.openTabWithUrl(url: url)
                }
            }
        }
        
    }
    
    func handleOldestSnapshot(page: SFSafariPage, href: String){
        if(href != ""){
            let url = "https://web.archive.org/web/0/\(href)"
            self.openTabWithUrl(url: url)
        }
        else{
            page.getPropertiesWithCompletionHandler { (pagePropierties) in
                if let currentUrl = pagePropierties?.url{
                    let url = "https://web.archive.org/web/0/\(currentUrl)"
                    self.openTabWithUrl(url: url)
                }
            }
        }
        
    }
    
    func openTabWithUrl(url: String){
        SFSafariApplication.getActiveWindow { (window) in
            if let myUrl = URL(string: url) {
                window?.openTab(with: myUrl, makeActiveIfPossible: true, completionHandler: nil)
            }
        }
    }
    
}
