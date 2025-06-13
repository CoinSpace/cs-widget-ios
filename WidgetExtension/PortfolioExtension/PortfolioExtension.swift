//
//  PortfolioExtension.swift
//  PortfolioExtension
//
//  Created by Nikita Verkhovin on 10.06.2025.
//

import WidgetKit
import SwiftUI

struct PortfolioProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> PortfolioTimelineEntry {
        print("placeholder")
        let now = Date()
        return PortfolioTimelineEntry(date: now, portfolio: .defaultPortfolio, configuration: .defaultConfiguration)
    }

    func snapshot(for configuration: PortfolioConfiguration, in context: Context) async -> PortfolioTimelineEntry {
        print("snapshot")
//        let size = context.family == .systemMedium ? 3 : 6
//        if size == 3 && configuration.cryptos.count > size {
//            configuration.cryptos.removeSubrange(size..<configuration.cryptos.count)
//        }
        var tickers: [TickerCodable] = []
//        do {
//            let cryptoIds = configuration.cryptos.map { $0.cryptoId }
//            tickers = try await ApiClient.shared.prices(cryptoIds, configuration.currency.rawValue)
//        } catch {}
        let now = Date()
        return PortfolioTimelineEntry(date: now, portfolio: .defaultPortfolio, configuration: configuration)
    }
    
    func timeline(for configuration: PortfolioConfiguration, in context: Context) async -> Timeline<PortfolioTimelineEntry> {
        print("timeline")
//        let size = context.family == .systemMedium ? 3 : 6
        
//        if configuration.topCryptos {
//            do {
//                configuration.cryptos = try await CryptoEntity.defaultQuery.topCryptos(size)!
//            } catch {}
//        }
        
//        if size == 3 && configuration.cryptos.count > size {
//            configuration.cryptos.removeSubrange(size..<configuration.cryptos.count)
//        }
//        var tickers: [TickerCodable] = []
//        do {
//            let cryptoIds = configuration.cryptos.map { $0.cryptoId }
//            tickers = try await ApiClient.shared.prices(cryptoIds, configuration.currency.rawValue)
//        } catch {}
        
        let now = Date()
        
        var ticker = TickerCodable(cryptoId: "portfolio", price: Double.random(in: 1...100), price_change_1d: Double.random(in: -100...100))
        ticker.delta = Double.random(in: -10...10)
        
        let portfolio = Portfolio(total: ticker, cryptos: [
            PortfolioCrypto(crypto: CryptoCodable.bitcoin, ticker: TickerCodable(cryptoId: "bitcoin@bitcoin", price: Double.random(in: 1...100), price_change_1d: Double.random(in: -100...100)), amount: CryptoAmount(value: Double.random(in: 1...100), fiat: Double.random(in: 1...100))),
            PortfolioCrypto(crypto: CryptoCodable.tether, ticker: TickerCodable(cryptoId: "tether@ethereum", price: Double.random(in: 1...100), price_change_1d: Double.random(in: -100...100)), amount: CryptoAmount(value: Double.random(in: 1...100), fiat: Double.random(in: 1...100)))
        ])
//        let portfolio: Portfolio? = nil
        
        let entry = PortfolioTimelineEntry(date: now, portfolio: portfolio, configuration: configuration)
        let timeline = Timeline(entries: [entry], policy: .after(now.addingTimeInterval(300))) // 5 min
        return timeline
    }
}

struct Portfolio {
    let total: TickerCodable
    let cryptos: [PortfolioCrypto]
    
    static let defaultPortfolio = Portfolio(
        total: TickerCodable(cryptoId: "portfolio", price: 1000100, price_change_1d: 100),
        cryptos: [
            PortfolioCrypto(crypto: CryptoCodable.bitcoin, ticker: TickerCodable.bitcoin, amount: CryptoAmount(value: 1, fiat: 1000000)),
            PortfolioCrypto(crypto: CryptoCodable.tether, ticker: TickerCodable.tether, amount: CryptoAmount(value: 100, fiat: 100)),
        ]
    )
}

struct PortfolioCrypto {
    let crypto: CryptoCodable
    let ticker: TickerCodable
    let amount: CryptoAmount
}

struct CryptoAmount {
    let value: Double
    let fiat: Double
}

struct PortfolioTimelineEntry: TimelineEntry {
    let date: Date
    let portfolio: Portfolio?
    let configuration: PortfolioConfiguration
}

struct PortfolioExtensionEntryView: View {
    var entry: PortfolioProvider.Entry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetContentMargins) var widgetContentMargins
        
    var body: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    CryptoLogo(
                        date: entry.date,
                        size: 32.0,
                        crypto: UIImage(named: "CoinWallet"),
                        animated: true
                    )
                    Spacer()
                    if let portfolio = entry.portfolio {
                        PriceChangeView(ticker: portfolio.total, suffix: family == .systemSmall ? "" : " (" + .localized("1 day") + ")")
                    }
                }
                Spacer()
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 0.0) {
                        Text("Portfolio")
                            .setFontStyle(WidgetFonts.textMd)
                            .foregroundColor(WidgetColors.secondary)
                        if let portfolio = entry.portfolio {
                            PriceView(
                                ticker: portfolio.total,
                                date: entry.date,
                                currency: entry.configuration.currency,
                                fontStyle: family == .systemSmall ? WidgetFonts.textMdBold : WidgetFonts.text2XlBold
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
                    
                    if let portfolio = entry.portfolio, portfolio.cryptos.count > 0, family == .systemLarge {
                        PortfolioView(entry: entry)
                    }
                }
            }
            .frame(
                maxHeight: .infinity,
                alignment: .top
            )
            .padding()
            
            Button(intent: Reload()) {
                Text("").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton())
            
            let size = entry.portfolio == nil ? .infinity : 64
            Link(destination: URL(string: "coinspace://")!) {
                Text("")
                    .frame(maxWidth: size, maxHeight: size)
                    .opacity(0)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
    
    private struct PortfolioView: View {
        let entry: PortfolioTimelineEntry
        
        var body: some View {
            ForEach(Array(entry.portfolio!.cryptos.enumerated()), id: \.offset) { index, portfolioCrypto in
                let crypto = portfolioCrypto.crypto
                let ticker = portfolioCrypto.ticker
                let price = AppService.shared.formatPrice(ticker.price, entry.configuration.currency.rawValue)
                let amount = portfolioCrypto.amount.value
                let amountFiat = AppService.shared.formatPrice(portfolioCrypto.amount.fiat, entry.configuration.currency.rawValue)
                
                
                HStack(alignment: .top, spacing: 12) {
                    CryptoLogo(
                        date: entry.date,
                        size: 40.0,
                        crypto: crypto.image,
                        platform: crypto.platform?.image
                    )
                    .padding(.top, 4.0)
                    VStack(spacing: 0) {
                        HStack {
                            Text(crypto.symbol)
                                .setFontStyle(WidgetFonts.textMdBold)
                            Spacer()
                            Text(String(amount))
                                .setFontStyle(WidgetFonts.textMdBold)
                        }
                        HStack {
                            Text(cryptoSubtitle(crypto))
                                .setFontStyle(WidgetFonts.textXs)
                                .foregroundColor(WidgetColors.secondary)
                            Spacer()
                            Text(amountFiat)
                                .setFontStyle(WidgetFonts.textXs)
                                .foregroundColor(WidgetColors.secondary)
                        }
                        HStack(spacing: 8) {
                            Text(price)
                                .setFontStyle(WidgetFonts.textXs)
                                .foregroundColor(WidgetColors.secondary)
                            PriceChangeView(ticker: ticker, suffix: "")
                            Spacer()
                        }
                    }.contentTransition(.identity)
                }
            }
        }
        
        private func cryptoSubtitle(_ crypto: CryptoCodable) -> String {
            if let platform = crypto.platform {
                return "\(crypto.name) • \(platform.name)"
            } else {
                return crypto.name
            }
        }
    }
}

struct PortfolioExtension: Widget {
    static let kind: String = "PortfolioExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: PortfolioExtension.kind,
            intent: PortfolioConfiguration.self,
            provider: PortfolioProvider()) { entry in
                PortfolioExtensionEntryView(entry: entry)
                    .containerBackground(Color(.systemBackground), for: .widget)
        }
        .configurationDisplayName("Portfolio")
        .description("The total value of your cryptos.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    PortfolioExtension()
} timeline: {
    PortfolioTimelineEntry(date: .now, portfolio: .defaultPortfolio, configuration: .defaultConfiguration)
    PortfolioTimelineEntry(date: .now, portfolio: nil, configuration: .defaultConfiguration)
}
