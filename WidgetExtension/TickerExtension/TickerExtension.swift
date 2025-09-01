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
    
    var body: some View {
        switch family {
        case .systemSmall, .systemMedium:
            TickerSmallMediumEntryView(entry: entry)
        case .accessoryRectangular:
            TickerRectangularView(entry: entry)
        case .accessoryCircular:
            TickerCircularView(entry: entry)
        case .accessoryInline:
            TickerInlineView(entry: entry)
        default:
            Text(verbatim: "404")
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
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline,
        ])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    TickerExtension()
} timeline: {
    TickerTimelineEntry(date: .now, configuration: TickerConfiguration.defaultConfiguration, ticker: TickerCodable.bitcoin)
}
