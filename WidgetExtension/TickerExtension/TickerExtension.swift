//
//  TickerExtension.swift
//  TickerExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import SwiftUI

struct TickerProvider: AppIntentTimelineProvider {
    
    func placeholder(in context: Context) -> TickerTimelineEntry {
        print("placeholder")
        let now = Date()
        return TickerTimelineEntry(date: now, configuration: TickerConfiguration.defaultConfiguration, ticker: TickerCodable.bitcoin)
    }

    func snapshot(for configuration: TickerConfiguration, in context: Context) async -> TickerTimelineEntry {
        print("snapshot")
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.prices([configuration.crypto.cryptoId], configuration.currency.rawValue).first
        } catch {}
        let now = Date()
        return TickerTimelineEntry(date: now, configuration: configuration, ticker: ticker)
    }
    
    func timeline(for configuration: TickerConfiguration, in context: Context) async -> Timeline<TickerTimelineEntry> {
        print("timeline")
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.prices([configuration.crypto.cryptoId], configuration.currency.rawValue).first
        } catch {}
        
        let now = Date()
        let entry = TickerTimelineEntry(date: now, configuration: configuration, ticker: ticker)
        let timeline = Timeline(entries: [entry], policy: .after(now.addingTimeInterval(300))) // 5 min
        return timeline
    }
}

struct TickerTimelineEntry: TimelineEntry {
    let date: Date
    let configuration: TickerConfiguration
    let ticker: TickerCodable?
}

struct TickerExtensionEntryView: View {
    var entry: TickerProvider.Entry
    
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.widgetContentMargins) var widgetContentMargins
        
    var body: some View {
        ZStack() {
            VStack() {
                HStack(alignment: .top) {
                    CryptoLogo(date: entry.date, size: 32.0, crypto: entry.configuration.crypto.image, animated: true)
                    Spacer()
                    PriceChangeView(ticker: entry.ticker, suffix: family == .systemSmall ? "" : " (" + .localized("1 day") + ")")
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
                Text("").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton())
        }
    }
}

struct TickerExtension: Widget {
    static let kind: String = "TickerExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: TickerExtension.kind,
            intent: TickerConfiguration.self,
            provider: TickerProvider()) { entry in
            TickerExtensionEntryView(entry: entry)
                    .containerBackground(Color(.systemBackground), for: .widget)
        }
        .configurationDisplayName("Ticker")
        .description("Live price for selected crypto.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    TickerExtension()
} timeline: {
    TickerTimelineEntry(date: .now, configuration: TickerConfiguration.defaultConfiguration, ticker: TickerCodable.bitcoin)
}
