import SwiftUI

struct ImportantColorPalette {
    // Default palette (legacy fallback)
    static let defaultPalette: [Color] = [
        TaskColor.bloodstone.color,
        TaskColor.sapphireStorm.color,
        TaskColor.emeraldAbyss.color,
        TaskColor.obsidianRose.color,
        TaskColor.solarCitrine.color,
        TaskColor.rosePetal.color,
        TaskColor.nebulaPurple.color,
        TaskColor.deepOcean.color,
        TaskColor.sunsetOrange.color,
        TaskColor.neonGreen.color
    ]
    
    static func palette(for group: ColorGroup) -> [Color] {
        return group.colors.map { $0.color }
    }
    
    static func count(for group: ColorGroup) -> Int {
        palette(for: group).count
    }
    
    static func color(for index: Int, in group: ColorGroup) -> Color {
        let p = palette(for: group)
        guard !p.isEmpty else { return .gray }
        let safe = (index % p.count + p.count) % p.count
        return p[safe]
    }
}
