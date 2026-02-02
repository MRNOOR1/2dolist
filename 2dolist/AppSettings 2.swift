//
//  AppSettings.swift
//  2dolist
//
//  Settings storage for user preferences
//

import SwiftUI

@Observable
class AppSettings {
    static let shared = AppSettings()
    
    // Important task color
    var importantTaskColor: TaskColor = .bloodstone {
        didSet {
            UserDefaults.standard.set(importantTaskColor.rawValue, forKey: "importantTaskColor")
        }
    }
    
    // Button color scheme
    var buttonColorScheme: ButtonColorScheme = .colored {
        didSet {
            UserDefaults.standard.set(buttonColorScheme.rawValue, forKey: "buttonColorScheme")
        }
    }
    
    private init() {
        // Load saved preferences
        if let savedTaskColor = UserDefaults.standard.string(forKey: "importantTaskColor"),
           let taskColor = TaskColor(rawValue: savedTaskColor) {
            self.importantTaskColor = taskColor
        }
        
        if let savedButtonScheme = UserDefaults.standard.string(forKey: "buttonColorScheme"),
           let buttonScheme = ButtonColorScheme(rawValue: savedButtonScheme) {
            self.buttonColorScheme = buttonScheme
        }
    }
    
    func getButtonColor(for colorScheme: ColorScheme) -> Color {
        switch buttonColorScheme {
        case .default:
            return colorScheme == .dark ? .white : .black
        case .colored:
            return .blue
        }
    }
    
    func getButtonTextColor(for colorScheme: ColorScheme) -> Color {
        switch buttonColorScheme {
        case .default:
            // Inverse of button color for contrast
            return colorScheme == .dark ? .black : .white
        case .colored:
            return .white
        }
    }
}

// Color groups for themed organization
enum ColorGroup: String, CaseIterable, Identifiable {
    case reds = "Reds & Crimsons"
    case blues = "Blues & Cobalts"
    case greens = "Greens & Teals"
    case purples = "Purples & Violets"
    case golds = "Golds & Oranges"
    
    var id: String { rawValue }
    
    var colors: [TaskColor] {
        switch self {
        case .reds:
            return [.bloodstone, .cursedRuby, .bloodGarnet, .deepAmaranth]
        case .blues:
            return [.sapphireStorm, .frozenLapis, .celestialVoid, .nocturneCyanide]
        case .greens:
            return [.emeraldAbyss, .midnightMalachite, .peacockVein]
        case .purples:
            return [.obsidianRose, .glacialOrchid]
        case .golds:
            return [.solarCitrine, .crushedTopaz, .dragoniteBronze]
        }
    }
}

enum TaskColor: String, CaseIterable, Identifiable {
    // Reds & Crimsons
    case bloodstone = "Bloodstone"
    case cursedRuby = "Cursed Ruby"
    case bloodGarnet = "Blood Garnet"
    case deepAmaranth = "Deep Amaranth"
    
    // Blues & Cobalts
    case sapphireStorm = "Sapphire Storm"
    case frozenLapis = "Frozen Lapis"
    case celestialVoid = "Celestial Void"
    case nocturneCyanide = "Nocturne Cyanide"
    
    // Greens & Teals
    case emeraldAbyss = "Emerald Abyss"
    case midnightMalachite = "Midnight Malachite"
    case peacockVein = "Peacock Vein"
    
    // Purples & Violets
    case obsidianRose = "Obsidian Rose"
    case glacialOrchid = "Glacial Orchid"
    
    // Golds & Oranges
    case solarCitrine = "Solar Citrine"
    case crushedTopaz = "Crushed Topaz"
    case dragoniteBronze = "Dragonite Bronze"
    
    var id: String { rawValue }
    
    var color: Color {
        switch self {
        // Reds & Crimsons
        case .bloodstone:
            return Color(red: 134/255, green: 0/255, blue: 0/255)
        case .cursedRuby:
            return Color(red: 90/255, green: 0/255, blue: 0/255)
        case .bloodGarnet:
            return Color(red: 120/255, green: 0/255, blue: 20/255)
        case .deepAmaranth:
            return Color(red: 155/255, green: 0/255, blue: 75/255)
            
        // Blues & Cobalts
        case .sapphireStorm:
            return Color(red: 20/255, green: 50/255, blue: 180/255)
        case .frozenLapis:
            return Color(red: 0/255, green: 80/255, blue: 150/255)
        case .celestialVoid:
            return Color(red: 10/255, green: 15/255, blue: 40/255)
        case .nocturneCyanide:
            return Color(red: 0/255, green: 210/255, blue: 170/255)
            
        // Greens & Teals
        case .emeraldAbyss:
            return Color(red: 0/255, green: 100/255, blue: 80/255)
        case .midnightMalachite:
            return Color(red: 0/255, green: 90/255, blue: 60/255)
        case .peacockVein:
            return Color(red: 0/255, green: 170/255, blue: 140/255)
            
        // Purples & Violets
        case .obsidianRose:
            return Color(red: 40/255, green: 0/255, blue: 40/255)
        case .glacialOrchid:
            return Color(red: 115/255, green: 90/255, blue: 170/255)
            
        // Golds & Oranges
        case .solarCitrine:
            return Color(red: 255/255, green: 204/255, blue: 0/255)
        case .crushedTopaz:
            return Color(red: 204/255, green: 85/255, blue: 0/255)
        case .dragoniteBronze:
            return Color(red: 160/255, green: 110/255, blue: 50/255)
        }
    }
    
    var group: ColorGroup {
        switch self {
        case .bloodstone, .cursedRuby, .bloodGarnet, .deepAmaranth:
            return .reds
        case .sapphireStorm, .frozenLapis, .celestialVoid, .nocturneCyanide:
            return .blues
        case .emeraldAbyss, .midnightMalachite, .peacockVein:
            return .greens
        case .obsidianRose, .glacialOrchid:
            return .purples
        case .solarCitrine, .crushedTopaz, .dragoniteBronze:
            return .golds
        }
    }
}

enum ButtonColorScheme: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case colored = "Colored"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .default:
            return "Adapts to Light/Dark Mode"
        case .colored:
            return "Blue"
        }
    }
}
