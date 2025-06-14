//
//  PortfolioExtension.swift
//  PortfolioExtension
//
//  Created by Nikita Verkhovin on 10.06.2025.
//

import WidgetKit
import SwiftUI

struct PortfolioCryptoCodable: Codable {
    let _id: String
    let balance: Double

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _id = try values.decode(String.self, forKey: ._id)
        let balanceString = try values.decode(String.self, forKey: .balance)
        if let value = Double(balanceString) {
            balance = value
        } else {
            balance = 0
        }
    }
}

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

        var portfolioCryptos: [PortfolioCryptoCodable] = []
        var isLogged: Bool = false
        if let defaults = UserDefaults(suiteName: "group.com.coinspace.shared"),
           let str = defaults.string(forKey: "portfolioCryptos"),
           let data = str.data(using: .utf8)
        {
            if let decoded = try? JSONDecoder().decode([PortfolioCryptoCodable].self, from: data) {
                portfolioCryptos = decoded
                isLogged = true
            }
        }

        var cryptos: [CryptoCodable] = []
        do {
            let allCryptos = try await ApiClient.shared.cryptos(uniqueAssets: false)
            portfolioCryptos = portfolioCryptos.filter { crypto in
                if let crypto = allCryptos.first(where: { $0._id == crypto._id }) {
                    cryptos.append(crypto)
                    return true
                } else {
                    return false
                }
            }
        } catch {}

        var tickers: [TickerCodable] = []
        do {
            let cryptoIds = cryptos.map { $0._id }
            print("cryptoIds")
            print(cryptoIds.count)
            tickers = try await ApiClient.shared.prices(cryptoIds, configuration.currency.rawValue)
        } catch {}

        let now = Date()

        var balance = 0.0
        var balanceChange = 0.0
        for (index, portfolioCrypto) in portfolioCryptos.enumerated() {
            let ticker = tickers[index]
            let fiat = portfolioCrypto.balance * ticker.price
            balance += fiat
            balanceChange += fiat * (ticker.price_change_1d ?? 0)
        }
        let balanceChangePercent = balance == 0.0 ? 0.0 : (balanceChange / balance)
        var totalTicker = TickerCodable(cryptoId: "portfolio", price: balance, price_change_1d: balanceChangePercent)
        
        let key = "portfolio:\(configuration.currency.rawValue)"
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key) {
            if let decoded = try? JSONDecoder().decode(TickerCodable.self, from: data) {
                totalTicker.delta = totalTicker.price - decoded.price
            }
        }
        if let encoded = try? JSONEncoder().encode(totalTicker) {
            defaults.set(encoded, forKey: key)
        }
        
        if cryptos.count > 2 {
            cryptos.removeSubrange(2..<cryptos.count)
        }
        cryptos = await CryptoCodable.loadLogoData(cryptos)

        let pt: [PortfolioCrypto] = cryptos.enumerated().map { index, crypto in
            let ticker = tickers[index]
            let portfolioCrypto = portfolioCryptos[index]
            let fiat = portfolioCrypto.balance * ticker.price
            let amount: CryptoAmount = CryptoAmount(value: portfolioCrypto.balance, fiat: fiat)
            return PortfolioCrypto(crypto: crypto, ticker: ticker, amount: amount)
        }

        let portfolio: Portfolio? = isLogged ? Portfolio(total: totalTicker, cryptos: pt) : nil

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
                                fontStyle: family == .systemSmall ? WidgetFonts.textMdBold : WidgetFonts.text2XlBold,
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
                let price = AppService.shared.formatFiat(ticker.price, entry.configuration.currency.rawValue, true)
                let amount = portfolioCrypto.amount.value
                let amountFiat = AppService.shared.formatFiat(portfolioCrypto.amount.fiat, entry.configuration.currency.rawValue, false)

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
