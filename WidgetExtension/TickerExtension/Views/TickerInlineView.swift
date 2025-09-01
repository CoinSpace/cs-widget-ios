import SwiftUI

struct TickerInlineView: View {
    let entry: TickerProvider.Entry
    
    var body: some View {
        ZStack {
            if let price = entry.ticker?.price {
                if let priceChange = entry.ticker?.price_change_1d {
                    Image(systemName: priceChange >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                }
                Text(verbatim: "\(entry.configuration.crypto.symbol) \(AppService.shared.formatFiat(price, entry.configuration.currency.rawValue, true))")
            } else {
                Text(verbatim: "...")
            }
        }
    }
}
