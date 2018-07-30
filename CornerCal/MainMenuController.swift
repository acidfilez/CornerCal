//
//  MainMenuController.swift
//  CornerCal
//
//  Created by Emil Kreutzman on 23/09/2017.
//  Copyright © 2017 Emil Kreutzman. All rights reserved.
//

import Cocoa

enum InterfaceStyle : String {
    case Dark, Light

    init() {
        let type = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") ?? "Light"
        self = InterfaceStyle(rawValue: type)!
    }
}

class MainMenuController: NSObject, NSCollectionViewDataSource {

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return controller.itemCount()
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let id = NSUserInterfaceItemIdentifier.init(rawValue: "CalendarDayItem")
        
        let item = collectionView.makeItem(withIdentifier: id, for: indexPath)
        guard let calendarItem = item as? CalendarDayItem else {
            return item
        }
        
        let day = controller.getItemAt(index: indexPath.item)
        
        calendarItem.setBold(bold: !day.isNumber)
        calendarItem.setText(text: day.text)
        calendarItem.setPartlyTransparent(partlyTransparent: !day.isCurrentMonth)
        calendarItem.setHasRedBackground(hasRedBackground: day.isToday)
        
        return calendarItem
    }
    
    @IBOutlet weak var controller: CalendarController!
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    @IBOutlet weak var monthLabel: NSButton!
    
    @IBOutlet weak var buttonLeft: NSButton!
    
    @IBOutlet weak var buttonRight: NSButton!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    @IBOutlet weak var settingsWindow: NSWindow!
    
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    var settingMenuItem: NSMenuItem!

    private func updateMenuTime() {
        statusItem.title = controller.getFormattedDate()
    }
    
    private func updateCalendar() {
        monthLabel.title = controller.getMonth()
        applyUIModifications()
        collectionView.reloadData()
    }
    
    private func getBasicAttributes(button: NSButton, color: NSColor, alpha: CGFloat) -> [NSAttributedString.Key : Any] {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        return [
            NSAttributedString.Key.foregroundColor: color.withAlphaComponent(alpha),
            NSAttributedString.Key.font: NSFont.systemFont(ofSize: (button.font?.pointSize)!, weight: NSFont.Weight.light),
            NSAttributedString.Key.backgroundColor: NSColor.clear,
            NSAttributedString.Key.paragraphStyle: style,
            NSAttributedString.Key.kern: 0.5 // some additional character spacing
        ]
    }
    
    private func applyButtonHighlightSettings(button: NSButton, isAccented: Bool) {

        var colorThemeIsAccented: NSColor = NSColor.systemRed
        var colorThemeIsNotAccented: NSColor = NSColor.black

        if InterfaceStyle() == .Dark {
            colorThemeIsAccented = NSColor.white
            colorThemeIsNotAccented = NSColor.white
        }

        let color = (isAccented) ? colorThemeIsAccented : colorThemeIsNotAccented
        
        let defaultAlpha: CGFloat = (isAccented) ? 1.0 : 0.75
        let pressedAlpha: CGFloat = (isAccented) ? 0.70 : 0.45
        
        let defaultAttributes = getBasicAttributes(button: button, color: color, alpha: defaultAlpha)
        let pressedAttributes = getBasicAttributes(button: button, color: color, alpha: pressedAlpha)
        
        button.attributedTitle = NSAttributedString(string: button.title, attributes: defaultAttributes)
        button.attributedAlternateTitle = NSAttributedString(string: button.title, attributes: pressedAttributes)
        button.alignment = .center
    }
    
    private func applyUIModifications() {
        statusItem.button?.font = NSFont.monospacedDigitSystemFont(ofSize: (statusItem.button?.font?.pointSize)!, weight: .regular)
        
        applyButtonHighlightSettings(button: monthLabel, isAccented: true)
        applyButtonHighlightSettings(button: buttonLeft, isAccented: false)
        applyButtonHighlightSettings(button: buttonRight, isAccented: false)
    }
    
    func refreshState() {
        statusItem.menu = statusMenu

        //keep a copy of the setting
        settingMenuItem = statusItem.menu?.item(at: 1)
        //remove settings
        statusItem.menu?.removeItem(at: 1)
        //handle open, and close
        statusItem.menu?.delegate = self

        controller.subscribe(onTimeUpdate: updateMenuTime, onCalendarUpdate: updateCalendar)
    }
    
    func deactivate() {
        controller.pause()
    }
    
    @IBAction func openSettingsClicked(_ sender: NSMenuItem) {
        let settingsWindowController = NSWindowController.init(window: settingsWindow)
        settingsWindowController.showWindow(sender)
        
        // bring settings window to front
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @IBAction func leftClicked(_ sender: NSButton) {
        controller.decrementMonth()
    }
    
    @IBAction func rightClicked(_ sender: NSButton) {
        controller.incrementMonth()
    }
    
    @IBAction func clearMonthHopping(_ sender: Any) {
        controller.resetMonth()
    }

}

extension MainMenuController : NSMenuDelegate {
    //if keyboar alt key is press, add settings
    func menuWillOpen(_ menu: NSMenu) {
        guard let flags = NSApp.currentEvent?.modifierFlags else { return }
        if flags.contains(.option) {
            statusItem.menu?.addItem(settingMenuItem!)
        }
    }

    //if closing and setting is display, just remove it.
    func menuDidClose(_ menu: NSMenu) {
        if statusItem.menu?.items.count == 2
        {
            statusItem.menu?.removeItem(at: 1)
        }
    }
}
