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
    
    // Selected important task palette group
    var selectedImportantGroup: ColorGroup = .reds {
        didSet {
            UserDefaults.standard.set(selectedImportantGroup.rawValue, forKey: "selectedImportantGroup")
        }
    }
    
    // Button color scheme
    var buttonColorScheme: ButtonColorScheme = .blue {
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
        
        if let savedGroup = UserDefaults.standard.string(forKey: "selectedImportantGroup"),
           let group = ColorGroup(rawValue: savedGroup) {
            self.selectedImportantGroup = group
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
        case .blue:
            return .blue
        case .purple:
            return Color(red: 138/255, green: 43/255, blue: 226/255)
        case .teal:
            return Color(red: 0/255, green: 170/255, blue: 140/255)
        case .orange:
            return Color(red: 255/255, green: 127/255, blue: 80/255)
        case .pink:
            return Color(red: 255/255, green: 20/255, blue: 147/255)
        case .neonGreen:
            return Color(red: 57/255, green: 255/255, blue: 20/255)
        }
    }
    
    func getButtonTextColor(for colorScheme: ColorScheme) -> Color {
        switch buttonColorScheme {
        case .default:
            // Inverse of button color for contrast
            return colorScheme == .dark ? .black : .white
        case .blue, .purple, .teal, .orange, .pink, .neonGreen:
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
    case pinks = "Pinks & Magentas"
    case cosmic = "Cosmic & Galaxy"
    case ocean = "Ocean Depths"
    case sunset = "Sunset & Dawn"
    case neon = "Neon & Electric"
    
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
        case .pinks:
            return [.rosePetal, .hotMagenta, .cherryBlossom, .electricPink]
        case .cosmic:
            return [.nebulaPurple, .stardustBlue, .galaxyVoid, .cosmicPink]
        case .ocean:
            return [.deepOcean, .coralReef, .bioluminescent, .midnightWave]
        case .sunset:
            return [.sunsetOrange, .dawnPink, .twilightPurple, .goldenHour]
        case .neon:
            return [.neonGreen, .cyberPink, .electricBlue, .toxicYellow]
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
    
    // Pinks & Magentas
    case rosePetal = "Rose Petal"
    case hotMagenta = "Hot Magenta"
    case cherryBlossom = "Cherry Blossom"
    case electricPink = "Electric Pink"
    
    // Cosmic & Galaxy
    case nebulaPurple = "Nebula Purple"
    case stardustBlue = "Stardust Blue"
    case galaxyVoid = "Galaxy Void"
    case cosmicPink = "Cosmic Pink"
    
    // Ocean Depths
    case deepOcean = "Deep Ocean"
    case coralReef = "Coral Reef"
    case bioluminescent = "Bioluminescent"
    case midnightWave = "Midnight Wave"
    
    // Sunset & Dawn
    case sunsetOrange = "Sunset Orange"
    case dawnPink = "Dawn Pink"
    case twilightPurple = "Twilight Purple"
    case goldenHour = "Golden Hour"
    
    // Neon & Electric
    case neonGreen = "Neon Green"
    case cyberPink = "Cyber Pink"
    case electricBlue = "Electric Blue"
    case toxicYellow = "Toxic Yellow"
    
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
            
        // Pinks & Magentas
        case .rosePetal:
            return Color(red: 255/255, green: 105/255, blue: 180/255)
        case .hotMagenta:
            return Color(red: 255/255, green: 0/255, blue: 144/255)
        case .cherryBlossom:
            return Color(red: 255/255, green: 183/255, blue: 197/255)
        case .electricPink:
            return Color(red: 255/255, green: 20/255, blue: 147/255)
            
        // Cosmic & Galaxy
        case .nebulaPurple:
            return Color(red: 138/255, green: 43/255, blue: 226/255)
        case .stardustBlue:
            return Color(red: 72/255, green: 61/255, blue: 139/255)
        case .galaxyVoid:
            return Color(red: 25/255, green: 25/255, blue: 112/255)
        case .cosmicPink:
            return Color(red: 199/255, green: 21/255, blue: 133/255)
            
        // Ocean Depths
        case .deepOcean:
            return Color(red: 0/255, green: 51/255, blue: 102/255)
        case .coralReef:
            return Color(red: 255/255, green: 127/255, blue: 80/255)
        case .bioluminescent:
            return Color(red: 0/255, green: 255/255, blue: 255/255)
        case .midnightWave:
            return Color(red: 0/255, green: 75/255, blue: 130/255)
            
        // Sunset & Dawn
        case .sunsetOrange:
            return Color(red: 255/255, green: 99/255, blue: 71/255)
        case .dawnPink:
            return Color(red: 255/255, green: 182/255, blue: 193/255)
        case .twilightPurple:
            return Color(red: 147/255, green: 112/255, blue: 219/255)
        case .goldenHour:
            return Color(red: 255/255, green: 215/255, blue: 0/255)
            
        // Neon & Electric
        case .neonGreen:
            return Color(red: 57/255, green: 255/255, blue: 20/255)
        case .cyberPink:
            return Color(red: 255/255, green: 16/255, blue: 240/255)
        case .electricBlue:
            return Color(red: 125/255, green: 249/255, blue: 255/255)
        case .toxicYellow:
            return Color(red: 223/255, green: 255/255, blue: 0/255)
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
        case .rosePetal, .hotMagenta, .cherryBlossom, .electricPink:
            return .pinks
        case .nebulaPurple, .stardustBlue, .galaxyVoid, .cosmicPink:
            return .cosmic
        case .deepOcean, .coralReef, .bioluminescent, .midnightWave:
            return .ocean
        case .sunsetOrange, .dawnPink, .twilightPurple, .goldenHour:
            return .sunset
        case .neonGreen, .cyberPink, .electricBlue, .toxicYellow:
            return .neon
        }
    }
}

enum ButtonColorScheme: String, CaseIterable, Identifiable {
    case `default` = "Default"
    case blue = "Blue"
    case purple = "Purple"
    case teal = "Teal"
    case orange = "Orange"
    case pink = "Pink"
    case neonGreen = "Neon Green"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .default:
            return "Adapts to Light/Dark Mode"
        case .blue:
            return "Classic Blue"
        case .purple:
            return "Cosmic Purple"
        case .teal:
            return "Peacock Teal"
        case .orange:
            return "Coral Orange"
        case .pink:
            return "Electric Pink"
        case .neonGreen:
            return "Neon Green Glow"
        }
    }
    
    var previewColor: Color {
        switch self {
        case .default:
            return .gray
        case .blue:
            return .blue
        case .purple:
            return Color(red: 138/255, green: 43/255, blue: 226/255)
        case .teal:
            return Color(red: 0/255, green: 170/255, blue: 140/255)
        case .orange:
            return Color(red: 255/255, green: 127/255, blue: 80/255)
        case .pink:
            return Color(red: 255/255, green: 20/255, blue: 147/255)
        case .neonGreen:
            return Color(red: 57/255, green: 255/255, blue: 20/255)
        }
    }
}

