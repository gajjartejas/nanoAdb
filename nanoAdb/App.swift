//
//  nanoAdbApp.swift
//  nanoAdb
//
//  Created by Tejas on 28/10/24.
//

import SwiftUI

@main
struct nanoAdbApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
