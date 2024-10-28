//
//  AppDelegate.swift
//  nanoAdb
//
//  Created by Tejas on 28/10/24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    let menu = NSMenu()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = .init(named: "status-bar-icon")
        statusItem.button?.image?.isTemplate = true
        updateMenu(menu: menu)

        statusItem.menu = menu
    }

    func updateMenu(menu: NSMenu) {
        menu.removeAllItems()

        // Reverse option
        let refreshItem = NSMenuItem(title: "Refresh", action: #selector(refresh(_:)), keyEquivalent: "")

        refreshItem.target = self
        menu.addItem(refreshItem)

        let devices = fetchADBDevices()
        if devices.isEmpty {
            menu.addItem(NSMenuItem(title: "No devices found", action: nil, keyEquivalent: ""))
        } else {
            for device in devices {
                let deviceItem = NSMenuItem(title: device, action: nil, keyEquivalent: "")
                let deviceSubMenu = NSMenu(title: device)

                // scrcpy option
                let scrcpyItem = NSMenuItem(title: "scrcpy", action: #selector(startScrcpy(_:)), keyEquivalent: "")
                scrcpyItem.representedObject = device
                scrcpyItem.target = self
                deviceSubMenu.addItem(scrcpyItem)

                // Reverse option
                let reverseItem = NSMenuItem(title: "reverse tcp:8081", action: #selector(reversePort(_:)), keyEquivalent: "")
                reverseItem.representedObject = device
                reverseItem.target = self
                deviceSubMenu.addItem(reverseItem)

                deviceItem.submenu = deviceSubMenu
                menu.addItem(deviceItem)
            }
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    }

    func fetchADBDevices() -> [String] {
        let task = Process()
        task.currentDirectoryPath = "/opt/homebrew/bin"
        task.launchPath = "/opt/homebrew/bin/adb"
        task.arguments = ["devices"]
        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/adb")

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try! task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)

        // Parse the output to get device IDs
        let lines = output.split(separator: "\n").map { String($0) }
        guard lines.count > 1 else { return [] } // Return empty list if no devices found

        // Drop the first line "List of devices attached" and parse the rest
        let devices = lines.dropFirst().compactMap { line -> String? in
            let parts = line.split(separator: "\t")
            if parts.count == 2, parts[1] == "device" {
                return String(parts[0])
            }
            return nil
        }

        return devices
    }

    @objc func refresh(_ sender: NSMenuItem) {
        updateMenu(menu: menu)
    }

    @objc func reversePort(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? String else { return }
        let task = Process()
        task.currentDirectoryPath = "/opt/homebrew/bin"
        task.launchPath = "/opt/homebrew/bin/adb"
        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/adb")
        task.arguments = ["-s", device, "reverse", "tcp:8081", "tcp:8081"]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try! task.run()
        task.waitUntilExit()

        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(decoding: outputData, as: UTF8.self)
        print("output", output)
    }

    @objc func startScrcpy(_ sender: NSMenuItem) {
        guard let device = sender.representedObject as? String else { return }
        let task = Process()
        task.currentDirectoryPath = "/opt/homebrew/bin"
        task.launchPath = "/opt/homebrew/bin/scrcpy"
        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/scrcpy")
        task.arguments = ["-s", device, "-b", "2m"]
        task.environment = ["PATH": "/opt/homebrew/bin:" + (ProcessInfo.processInfo.environment["PATH"] ?? "")]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe

        try! task.run()
    }
}
