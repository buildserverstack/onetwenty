import SwiftUI

struct AppColors {
    static let background = Color(red: 0.08, green: 0.08, blue: 0.1)
    static let surface = Color(red: 0.12, green: 0.13, blue: 0.16)
    static let surfaceElevated = Color(red: 0.16, green: 0.17, blue: 0.2)
    static let border = Color.white.opacity(0.08)
    static let textPrimary = Color(red: 0.9, green: 0.92, blue: 0.95)
    static let textSecondary = Color(red: 0.65, green: 0.68, blue: 0.72)
    static let accent = Color(red: 0.34, green: 0.63, blue: 0.74)
    static let accentSoft = accent.opacity(0.25)
    static let danger = Color(red: 0.86, green: 0.3, blue: 0.33)
}

struct AppFonts {
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 15, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)
}

extension View {
    func cardBackground() -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(AppColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
    }

    func primaryTextStyle() -> some View {
        foregroundColor(AppColors.textPrimary)
    }

    func secondaryTextStyle() -> some View {
        foregroundColor(AppColors.textSecondary)
    }

    func sectionTitleStyle() -> some View {
        font(AppFonts.headline).foregroundColor(AppColors.textPrimary)
    }
}
