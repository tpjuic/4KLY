//
//  AppCommands.swift
//  YTMac
//
//  Created by YTMac Developer
//

import SwiftUI

/// Navigation sections for the sidebar
enum NavigationSection: String, CaseIterable, Identifiable {
    case downloads
    case history
    case music
    case videos
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .downloads: return "Downloads"
        case .history: return "History"
        case .music: return "Music"
        case .videos: return "Videos"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .downloads: return "arrow.down.circle"
        case .history: return "clock.arrow.circlepath"
        case .music: return "music.note"
        case .videos: return "film"
        case .settings: return "gear"
        }
    }
    
    /// Which group this section belongs to in the sidebar
    enum SidebarGroup: String {
        case library = "LIBRARY"
        case collections = "COLLECTIONS"
        case system = "SYSTEM"
    }
    
    var group: SidebarGroup {
        switch self {
        case .downloads, .history: return .library
        case .music, .videos: return .collections
        case .settings: return .system
        }
    }
}

/// Custom commands for the YTMac app menu bar
struct AppCommands: Commands {
    @FocusedValue(\.selectedSection) var selectedSection: Binding<NavigationSection?>?
    @FocusedValue(\.newDownloadAction) var newDownloadAction: Binding<Bool>?
    
    var body: some Commands {
        // MARK: - File Menu
        CommandGroup(replacing: .newItem) {
            Button("New Download") {
                newDownloadAction?.wrappedValue = true
            }
            .keyboardShortcut("n", modifiers: .command)
        }
        
        // MARK: - View Menu
        CommandGroup(after: .toolbar) {
            Section {
                Button("Show Downloads") {
                    selectedSection?.wrappedValue = .downloads
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Show History") {
                    selectedSection?.wrappedValue = .history
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Show Settings") {
                    selectedSection?.wrappedValue = .settings
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
        
        // MARK: - Help Menu
        CommandGroup(replacing: .help) {
            Button("YTMac Help") {
                // Placeholder for future help documentation
            }
            
            Divider()
            
            Button("GitHub Repository") {
                if let url = URL(string: "https://github.com/ytmac/ytmac") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }
}

// MARK: - FocusedValues for menu command communication

struct SelectedSectionKey: FocusedValueKey {
    typealias Value = Binding<NavigationSection?>
}

struct NewDownloadActionKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}

extension FocusedValues {
    var selectedSection: Binding<NavigationSection?>? {
        get { self[SelectedSectionKey.self] }
        set { self[SelectedSectionKey.self] = newValue }
    }
    
    var newDownloadAction: Binding<Bool>? {
        get { self[NewDownloadActionKey.self] }
        set { self[NewDownloadActionKey.self] = newValue }
    }
}
