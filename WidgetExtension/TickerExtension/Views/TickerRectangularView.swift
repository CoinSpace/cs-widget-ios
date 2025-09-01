import SwiftUI

struct TickerRectangularView: View {
    var entry: TickerProvider.Entry
        
    var body: some View {
        ZStack() {
            VStack() {
                HStack(alignment: .top, spacing: 0) {
                    CryptoLogo(date: entry.date, size: 24.0, crypto: entry.configuration.crypto.image, animated: true)
                    Spacer()
                    PriceChangeView(ticker: entry.ticker, suffix: "")
                }
                Spacer().frame(minHeight: 0)
                VStack(alignment: .leading, spacing: -4) {
                    Text(entry.configuration.crypto.name)
                        .setFontStyle(WidgetFonts.textSm)
                        .foregroundColor(WidgetColors.secondary)
                    
                    PriceView(
                        ticker: entry.ticker,
                        date: entry.date,
                        currency: entry.configuration.currency,
                        fontStyle: WidgetFonts.textSmBold
                    )
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
}
