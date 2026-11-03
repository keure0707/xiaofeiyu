import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }

    static let appBg = Color(hex: 0xF4F8FE)
    static let cardBG = Color.white
    static let ink = Color(hex: 0x1F2A37)
    static let muted = Color(hex: 0x8A94A6)
    static let faint = Color(hex: 0xA3ADBD)
    static let line = Color(hex: 0xF0F4FA)
    static let brand = Color(hex: 0x4A7BC8)
    static let brandLight = Color(hex: 0x8FB6E8)
    static let brandPale = Color(hex: 0xEAF2FD)
    static let gold = Color(hex: 0xD99422)
    static let goldPale = Color(hex: 0xFDF1DE)
    static let ok = Color(hex: 0x2E9E63)
    static let okPale = Color(hex: 0xE9F7EF)
    static let warn = Color(hex: 0xC0392B)
}

struct CardBackground: ViewModifier {
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.cardBG)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: Color(hex: 0x4A6EA8).opacity(0.07), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func card(padding: CGFloat = 18) -> some View {
        modifier(CardBackground(padding: padding))
    }
}

/// 细进度条
struct ThinBar: View {
    var progress: Double
    var tint: Color
    var track: Color = Color(hex: 0xE4ECF8)

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
        .frame(height: 6)
    }
}

/// 分类小圆块
struct GlyphBadge: View {
    var text: String
    var tint: Color
    var pale: Color

    var body: some View {
        Text(text)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 36, height: 36)
            .background(pale)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
