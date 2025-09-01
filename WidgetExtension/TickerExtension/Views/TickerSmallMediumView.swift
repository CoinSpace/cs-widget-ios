import SwiftUI

struct TickerSmallMediumView: View {
    var entry: TickerProvider.Entry
    
    @Environment(\.widgetFamily) var family
        
    var body: some View {
        ZStack() {
            VStack() {
                HStack(alignment: .top) {
                    CryptoLogo(date: entry.date, size: 32.0, crypto: entry.configuration.crypto.image, animated: true)
                    Spacer()
                    let suffix = family == .systemSmall ? "" : " (" + .localized("1 day") + ")"
                    PriceChangeView(ticker: entry.ticker, suffix: suffix)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(entry.configuration.crypto.name)
                        .setFontStyle(WidgetFonts.textMd)
                        .foregroundColor(WidgetColors.secondary)
                    
                    PriceView(
                        ticker: entry.ticker,
                        date: entry.date,
                        currency: entry.configuration.currency,
                        fontStyle: family == .systemSmall ? WidgetFonts.textMdBold : WidgetFonts.text2XlBold
                    )
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
            }
            .padding()
            
            Button(intent: Reload()) {
                Text(verbatim: "").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton())
        }
    }
}
