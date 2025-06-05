import SwiftUICore
import SwiftUI

struct FontStyle {
    let size: CGFloat
    let weight: Font.Weight
    let lineHeight: CGFloat
    let letterSpacing: CGFloat
}

struct WidgetFonts {
    static let textXs = FontStyle(size: 12, weight: .regular, lineHeight: 1.5, letterSpacing: 0.03)
    static let textXsBold = FontStyle(size: 12, weight: .semibold, lineHeight: 1.5, letterSpacing: 0.03)
    
    static let textSm = FontStyle(size: 14, weight: .regular, lineHeight: 1.5, letterSpacing: 0.02)
    static let textSmBold = FontStyle(size: 14, weight: .semibold, lineHeight: 1.5, letterSpacing: 0.02)
    
    static let textMd = FontStyle(size: 18, weight: .regular, lineHeight: 1.5, letterSpacing: 0.01)
    static let textMdBold = FontStyle(size: 18, weight: .semibold, lineHeight: 1.5, letterSpacing: 0.01)
    
    static let text2Xl = FontStyle(size: 32, weight: .regular, lineHeight: 1.2, letterSpacing: -0.01)
    static let text2XlBold = FontStyle(size: 32, weight: .semibold, lineHeight: 1.2, letterSpacing: -0.01)
}

extension Text {
    func setFontStyle(_ fontStyle: FontStyle) -> some View {
        self.font(Font.system(size: fontStyle.size, weight: fontStyle.weight))
            .kerning(fontStyle.size * fontStyle.letterSpacing)
            .frame(height: fontStyle.size * fontStyle.lineHeight)
            .lineLimit(1)
    }
}

struct WidgetColors {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let danger = Color("Danger")
    static let textColor = Color("TextColor")
}

struct OverlayButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.black)
            .opacity(configuration.isPressed ? 0.4 : 0)
            .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

struct CryptoLogoCryptoLogo: View {
    let date: Date
    let size: CGFloat
    let image: UIImage?
    let animated: Bool
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        
        let scale = family == .systemSmall ? 18.0 : 22.0
        
        Group {
            if let uiImage = image {
                Image(uiImage: uiImage).resizable()
            } else {
                Circle().fill(.orange)
            }
        }
        .frame(width: size, height: size)
        .id(date)
        .transition(
            animated ?  .asymmetric(
                insertion: .opacity,
                removal: .opacity.combined(with: .scale(scale: scale))
            ) : .identity
        )
        .invalidatableContent()
    }
}

struct PriceView: View {
    let ticker: TickerCodable?
    let date: Date
    let currency: CurrencyEntity
    let fontStyle: FontStyle
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        ZStack() {
            let delta = ticker?.delta ?? 0
            let changeColor = delta > 0 ? WidgetColors.primary : WidgetColors.danger
            let color = delta == 0 ? WidgetColors.textColor : changeColor
            PriceText
                .foregroundColor(color)
                .transition(.identity)
            PriceText
                .foregroundColor(WidgetColors.textColor)
                .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .identity
                        )
                )
                .animation(.timingCurve(0, 0, 1, -1, duration: 0.7), value: date)
        }
    }
    
    private var PriceText: some View {
        let text: Text
        if let price = ticker?.price {
            text = Text(AppService.shared.formatPrice(price, currency.rawValue))
        } else {
            text = Text("...")
        }
        return text
            .setFontStyle(fontStyle)
            .id(ticker?.price)
    }
}

struct PriceChangeView: View {
    
    let ticker: TickerCodable?
    let suffix: String
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        let text: Text
        if let priceChange = ticker?.price_change_1d {
            text = Text(String(format: "%+.2f%%", priceChange) + suffix)
                .foregroundColor(priceChange >= 0 ? WidgetColors.primary : WidgetColors.danger)
        } else {
            text = Text("...")
        }
        return text
            .setFontStyle(colorScheme == .light ? WidgetFonts.textXs : WidgetFonts.textXsBold)
            .id(ticker?.price)
            .transition(.identity)
    }
}
