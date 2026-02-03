import SwiftUI

public struct ImportantColorPalette {
    // Shared palette for important tasks
    public static let palette: [Color] = [
        Color(red: 0.23, green: 0.31, blue: 0.27),  // bloodstone
        Color(red: 0.06, green: 0.30, blue: 0.55),  // sapphireStorm
        Color(red: 0.00, green: 0.41, blue: 0.30),  // emeraldAbyss
        Color(red: 0.29, green: 0.12, blue: 0.14),  // obsidianRose
        Color(red: 0.98, green: 0.78, blue: 0.12),  // solarCitrine
        Color(red: 0.89, green: 0.40, blue: 0.48),  // rosePetal
        Color(red: 0.45, green: 0.30, blue: 0.53),  // nebulaPurple
        Color(red: 0.00, green: 0.28, blue: 0.45),  // deepOcean
        Color(red: 0.99, green: 0.36, blue: 0.22),  // sunsetOrange
        Color(red: 0.35, green: 1.00, blue: 0.35)   // neonGreen
    ]
    
    public static var count: Int { palette.count }
    
    public static func color(for index: Int) -> Color {
        let safe = (index % palette.count + palette.count) % palette.count
        return palette[safe]
    }
}
