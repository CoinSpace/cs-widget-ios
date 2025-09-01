import SwiftUI
import WidgetKit

struct TickerCircularView: View {
    var entry: TickerProvider.Entry
        
    var body: some View {
        ZStack() {
            AccessoryWidgetBackground()
            VStack(spacing: -4) {
                Text(entry.configuration.crypto.symbol)
                    .setFontStyle(WidgetFonts.textXsBold)
                    .minimumScaleFactor(0.9)
                PriceText
                    .setFontStyle(WidgetFonts.textXsBold)
                    .minimumScaleFactor(0.7)
            }.padding(.horizontal, 2)
            Button(intent: Reload()) {
                Text(verbatim: "").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton(animate: false))
        }
    }
    
    private var PriceText: Text {
        let text: Text
        if let priceChange = entry.ticker?.price_change_1d {
            text = Text(String(format: "%+.1f%%", priceChange))
        } else {
            text = Text(verbatim: "...")
        }
        return text
    }
}
