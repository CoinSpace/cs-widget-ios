import SwiftUI

struct PortfolioInlineView: View {
    let entry: PortfolioProvider.Entry
    
    var body: some View {
        ZStack {
            Image("CoinWallet")
            if entry.portfolio != nil {
                if let price = entry.portfolio?.total.price {
                    Text(verbatim: "\(AppService.shared.formatFiat(price, entry.configuration.currency.rawValue, false))")
                } else {
                    Text(verbatim: "...")
                }
            } else {
                Text("Sign In")
            }
        }
    }
}
