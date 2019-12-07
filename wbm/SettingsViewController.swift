//
//  SettingsViewController.swift
//  wbm
//
//  Created by Claus Wolf on 23.11.19.
//  Copyright © 2019 Claus Wolf. All rights reserved.
//

import Cocoa
import SafariServices.SFSafariApplication

class SettingsViewController: NSViewController {

    @IBOutlet weak var saveButton: NSButtonCell!
    @IBOutlet weak var shortcutTextField: NSTextField!
    @IBOutlet weak var saveConfirmationLabel: NSTextField!
    
    @IBOutlet weak var openNewestCheck: NSButton!
    @IBOutlet weak var openOldestCheck: NSButton!
    @IBOutlet weak var pageHistoryCheck: NSButton!
    @IBOutlet weak var injectHistoryCheck: NSButton!
    @IBOutlet weak var relativeTimestampCheck: NSButton!
    

    let settings = SettingsHelper()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        saveConfirmationLabel.isHidden = true
        initialSetup()
        getKeyboardShortCut()
        getOpenNewState()
        getOpenOldState()
        getPageHistoryState()
        getPageHistoryInjectState()
        getRelativeTimestampState()
    }
    
    func initialSetup(){
        let previousSetup = settings.getBoolData(key: "setup")
        if(!previousSetup){
            settings.setBoolData(key: "openNewContext", data: true)
            settings.setBoolData(key: "openOldContext", data: true)
            settings.setBoolData(key: "pageHistoryContext", data: true)
            settings.setBoolData(key: "pageHistoryInject", data: false)
            settings.setBoolData(key: "relativeTimestamp", data: true)
            settings.setBoolData(key: "setup", data: true)
        }
    }
    
    
    func getOpenNewState(){
        let state = settings.getBoolData(key: "openNewContext")
        if(state){
            openNewestCheck.state = .on
        }
        else{
            openNewestCheck.state = .off
        }
    }
    
    func getOpenOldState(){
        let state = settings.getBoolData(key: "openOldContext")
        if(state){
            openOldestCheck.state = .on
        }
        else{
            openOldestCheck.state = .off
        }
    }
    
    func getPageHistoryState(){
        let state = settings.getBoolData(key: "pageHistoryContext")
        if(state){
            pageHistoryCheck.state = .on
        }
        else{
            pageHistoryCheck.state = .off
        }
    }
    
    func getPageHistoryInjectState(){
        let state = settings.getBoolData(key: "pageHistoryInject")
        if(state){
            injectHistoryCheck.state = .on
        }
        else{
            injectHistoryCheck.state = .off
        }
    }
    
    func getRelativeTimestampState(){
        let state = settings.getBoolData(key: "relativeTimestamp")
        if(state){
            relativeTimestampCheck.state = .on
        }
        else{
            relativeTimestampCheck.state = .off
        }
    }
    
    func getKeyboardShortCut(){
        var shortcut = settings.getStringData(key: "shortcut")
        if(shortcut == ""){
            shortcutTextField.stringValue = "w"
            settings.setStringData(key: "shortcut", data: "w")
        }
        else if (shortcut.count > 1){
            shortcut = String(shortcut.prefix(1))
            shortcutTextField.stringValue = shortcut
        }
        
        shortcutTextField.stringValue = shortcut
    }
    
    
    @IBAction func saveKeyboardShortcut(_ sender: Any) {
        
        var shortcut = shortcutTextField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if(shortcut == "" ){
            shortcut = "w";
        }
        else if (shortcut.count > 1){
            shortcut = String(shortcut.prefix(1))
            shortcutTextField.stringValue = shortcut
        }
        saveConfirmationLabel.isHidden = false
        saveConfirmationLabel.stringValue = NSLocalizedString("Keyboard Shortcut successfully saved", comment: "")
        settings.setStringData(key: "shortcut", data: shortcut)
        
    }
    
    @IBAction func openSafariExtensionPreferences(_ sender: AnyObject?) {
        SFSafariApplication.showPreferencesForExtension(withIdentifier: "net.otzberg.wbm-Extension") { error in
            if let _ = error {
                // Insert code to inform the user that something went wrong.
            }
        }
    }
    
    @IBAction func openNewestChanged(_ sender: NSButton) {
        if(sender.state == .on){
            settings.setBoolData(key: "openNewContext", data: true)
        }
        else{
            settings.setBoolData(key: "openNewContext", data: false)
        }
    }
    
    @IBAction func openOldestChanged(_ sender: NSButton) {
        if(sender.state == .on){
            settings.setBoolData(key: "openOldContext", data: true)
        }
        else{
            settings.setBoolData(key: "openOldContext", data: false)
        }
    }
    
    @IBAction func pageHistoryChanged(_ sender: NSButton) {
        if(sender.state == .on){
            settings.setBoolData(key: "pageHistoryContext", data: true)
        }
        else{
            settings.setBoolData(key: "pageHistoryContext", data: false)
        }
    }
    
    @IBAction func pageHistoryInjectChanged(_ sender: NSButton) {
        if(sender.state == .on){
            settings.setBoolData(key: "pageHistoryInject", data: true)
        }
        else{
            settings.setBoolData(key: "pageHistoryInject", data: false)
        }
    }
    
    @IBAction func relativeTimetsampChanged(_ sender: NSButton) {
        if(sender.state == .on){
            settings.setBoolData(key: "relativeTimestamp", data: true)
        }
        else{
            settings.setBoolData(key: "relativeTimestamp", data: false)
        }
    }
    
    
}
