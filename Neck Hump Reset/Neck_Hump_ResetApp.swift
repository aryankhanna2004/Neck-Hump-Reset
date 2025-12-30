//
//  Neck_Hump_ResetApp.swift
//  Neck Hump Reset
//
//  Created by ET Loaner on 12/28/25.
//

import SwiftUI
import SwiftData

@main
struct Neck_Hump_ResetApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: PosturePhoto.self)
    }
}
