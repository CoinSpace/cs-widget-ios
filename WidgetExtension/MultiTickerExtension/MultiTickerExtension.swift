//
//  MultiTickerExtension.swift
//  MultiTickerExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import SwiftUI

struct MultiTickerProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> MultiTickerTimelineEntry {
        print("placeholder")
        let now = Date()
        let size = context.family == .systemMedium ? 3 : 6
        return MultiTickerTimelineEntry(date: now, configuration: MultiTickerConfiguration.defaultConfiguration(size: size), tickers: TickerCodable.bitcoins(size: size))
    }

    func snapshot(for configuration: MultiTickerConfiguration, in context: Context) async -> MultiTickerTimelineEntry {
        print("snapshot")
        let size = context.family == .systemMedium ? 3 : 6
        if size == 3 && configuration.cryptos.count > size {
            configuration.cryptos.removeSubrange(size..<configuration.cryptos.count)
        }
        var tickers: [TickerCodable] = []
        do {
            let cryptoIds = configuration.cryptos.map { $0.cryptoId }
            tickers = try await ApiClient.shared.prices(cryptoIds, configuration.currency.rawValue)
        } catch {}
        let now = Date()
        return MultiTickerTimelineEntry(date: now, configuration: configuration, tickers: tickers)
    }
    
    func timeline(for configuration: MultiTickerConfiguration, in context: Context) async -> Timeline<MultiTickerTimelineEntry> {
        print("timeline")
        let size = context.family == .systemMedium ? 3 : 6
        
        if configuration.topCryptos {
            do {
                configuration.cryptos = try await CryptoEntity.defaultQuery.topCryptos(size)!
            } catch {}
        }
        
        if size == 3 && configuration.cryptos.count > size {
            configuration.cryptos.removeSubrange(size..<configuration.cryptos.count)
        }
        var tickers: [TickerCodable] = []
        do {
            let cryptoIds = configuration.cryptos.map { $0.cryptoId }
            tickers = try await ApiClient.shared.prices(cryptoIds, configuration.currency.rawValue)
        } catch {}
        
        let now = Date()
        let entry = MultiTickerTimelineEntry(date: now, configuration: configuration, tickers: tickers)
        let timeline = Timeline(entries: [entry], policy: .after(now.addingTimeInterval(300))) // 5 min
        return timeline
    }
}

struct MultiTickerTimelineEntry: TimelineEntry {
    let date: Date
    let configuration: MultiTickerConfiguration
    let tickers: [TickerCodable]
}

struct MultiTickerExtensionEntryView: View {
    var entry: MultiTickerProvider.Entry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetContentMargins) var widgetContentMargins
        
    var body: some View {
        ZStack() {
            VStack(spacing: 8) {
                ForEach(Array(entry.configuration.cryptos.enumerated()), id: \.offset) { index, crypto in
                    let ticker = entry.tickers[index]
                    
                    HStack(alignment: .center, spacing: 12.0) {
                        CryptoLogo(date: entry.date, size: family == .systemMedium ? 32.0 : 40.0, crypto: crypto.image, animated: index == 0)
                        
                        VStack(spacing: 0.0) {
                            HStack() {
                                Text(crypto.symbol)
                                    .setFontStyle(family == .systemMedium ? WidgetFonts.textSmBold : WidgetFonts.textMdBold)
                                    .foregroundColor(WidgetColors.textColor)
                                Spacer()                                
                                PriceView(
                                    ticker: ticker,
                                    date: entry.date,
                                    currency: entry.configuration.currency,
                                    fontStyle: family == .systemMedium ? WidgetFonts.textSmBold : WidgetFonts.textMdBold
                                )
                            }
                            HStack() {
                                Text(crypto.name)
                                    .setFontStyle(WidgetFonts.textXs)
                                    .foregroundColor(WidgetColors.secondary)
                                Spacer()
                                PriceChangeView(ticker: ticker, suffix: "")
                            }
                        }
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
        }
    }
}

struct MultiTickerExtension: Widget {
    static let kind: String = "MultiTickerExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: MultiTickerExtension.kind,
            intent: MultiTickerConfiguration.self,
            provider: MultiTickerProvider()) { entry in
            MultiTickerExtensionEntryView(entry: entry)
                    .containerBackground(Color(.systemBackground), for: .widget)
        }
        .configurationDisplayName("Multi Ticker")
        .description("Live prices for multiple cryptos.")
        .supportedFamilies([.systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemMedium) {
    MultiTickerExtension()
} timeline: {
    let size = 3
    MultiTickerTimelineEntry(date: .now, configuration: MultiTickerConfiguration.defaultConfiguration(size: size), tickers: TickerCodable.bitcoins(size: size))
}

#Preview(as: .systemLarge) {
    MultiTickerExtension()
} timeline: {
    let size = 6
    MultiTickerTimelineEntry(date: .now, configuration: MultiTickerConfiguration.defaultConfiguration(size: size), tickers: TickerCodable.bitcoins(size: size))
}
