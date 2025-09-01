import SwiftUI
import WidgetKit

struct PortfolioCircularView: View {
    var entry: PortfolioProvider.Entry
        
    var body: some View {
        ZStack() {
            AccessoryWidgetBackground()
            VStack(spacing: 0) {
                Image("CoinWallet")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .widgetAccentable()
                    .frame(width: 16, height: 16)
                
                if entry.portfolio != nil {
                    PriceChangeText
                        .setFontStyle(WidgetFonts.textXsBold)
                        .contentTransition(.identity)
                        .minimumScaleFactor(0.7)
                } else {
                    Text("Sign In")
                        .setFontStyle(WidgetFonts.textXsBold)
                        .minimumScaleFactor(0.7)
                }
            }.padding(.horizontal, 2)
            Button(intent: Reload()) {
                Text(verbatim: "").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton(animate: false))
        }
    }
    
    private var PriceChangeText: Text {
        let text: Text
        if let priceChange = entry.portfolio?.total.price_change_1d {
            text = Text(String(format: "%+.1f%%", priceChange))
        } else {
            text = Text(verbatim: "...")
        }
        return text
    }
}
