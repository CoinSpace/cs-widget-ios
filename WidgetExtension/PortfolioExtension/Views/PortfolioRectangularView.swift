import SwiftUI

struct PortfolioRectangularView: View {
    var entry: PortfolioProvider.Entry
        
    var body: some View {
        ZStack() {
            VStack() {
                HStack(alignment: .top, spacing: 0) {
                    CryptoLogo(date: entry.date, size: 24.0, crypto: UIImage(named: "CoinWallet"), animated: true)
                    Spacer()
                    if entry.portfolio != nil {
                        PriceChangeText
                            .setFontStyle(WidgetFonts.textXsBold)
                            .contentTransition(.identity)
                    }
                }
                Spacer().frame(minHeight: 0)
                VStack(alignment: .leading, spacing: -4) {
                    Text("Portfolio")
                        .setFontStyle(WidgetFonts.textSm)
                        .foregroundColor(WidgetColors.secondary)
                    if let portfolio = entry.portfolio {
                        PriceView(
                            ticker: portfolio.total,
                            date: entry.date,
                            currency: entry.configuration.currency,
                            fontStyle: WidgetFonts.textMdBold,
                            customFractionDigits: false
                        )
                    } else {
                        Text("Sign In")
                            .setFontStyle(WidgetFonts.textMdBold)
                    }
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
            }
            
            Button(intent: Reload()) {
                Text(verbatim: "").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton(animate: false))
        }
    }
    
    private var PriceChangeText: Text {
        let text: Text
        if let priceChange = entry.portfolio?.total.price_change_1d {
            text = Text(String(format: "%+.2f%%", priceChange))
        } else {
            text = Text(verbatim: "...")
        }
        return text
    }
}
