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
        let now = Date()
        return PortfolioTimelineEntry(date: now, portfolio: nil, configuration: configuration)
    }

    func timeline(for configuration: PortfolioConfiguration, in context: Context) async -> Timeline<PortfolioTimelineEntry> {
        print("timeline")
        let rows = context.family == .systemLarge ? 2 : 0
        let portfolio: Portfolio? = await configuration.getPortfolio(rows)
        let now = Date()
        let entry = PortfolioTimelineEntry(date: now, portfolio: portfolio, configuration: configuration)
        let timeline = Timeline(entries: [entry], policy: .after(now.addingTimeInterval(300))) // 5 min
        return timeline
    }
}

struct PortfolioTimelineEntry: TimelineEntry {
    let date: Date
    let portfolio: Portfolio?
    let configuration: PortfolioConfiguration
}

struct PortfolioExtensionEntryView: View {
    var entry: PortfolioProvider.Entry

    @Environment(\.widgetFamily) var family

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
                        let suffix = family == .systemSmall ? "" : " (" + .localized("1 day") + ")"
                        PriceChangeView(ticker: portfolio.total, suffix: suffix)
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

                    if let portfolio = entry.portfolio, portfolio.cryptos.count > 0 {
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
                Text(verbatim: "").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton())

            let size = entry.portfolio == nil ? .infinity : 64
            Link(destination: URL(string: "coinspace://")!) {
                Text(verbatim: "")
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
                let amount = AppService.shared.formatCrypto(portfolioCrypto.amount.value, ticker.price)
                let amountFiat = AppService.shared.formatFiat(portfolioCrypto.amount.fiat, entry.configuration.currency.rawValue, false)

                HStack(alignment: .top, spacing: 12) {
                    CryptoLogo(
                        date: entry.date,
                        size: 40.0,
                        crypto: crypto.image,
                        platform: crypto.cryptoPlatform?.image
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
                            PriceChangeView(ticker: ticker)
                            Spacer()
                        }
                    }.contentTransition(.identity)
                }
            }
        }

        private func cryptoSubtitle(_ crypto: CryptoCodable) -> String {
            if let platform = crypto.cryptoPlatform {
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
