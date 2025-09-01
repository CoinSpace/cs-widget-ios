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
        switch family {
        case .systemSmall, .systemMedium, .systemLarge:
            PortfolioSmallMediumLargeView(entry: entry)
        case .accessoryRectangular:
            PortfolioRectangularView(entry: entry)
        case .accessoryCircular:
            PortfolioCircularView(entry: entry)
        case .accessoryInline:
            PortfolioInlineView(entry: entry)
        default:
            Text(verbatim: "404")
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
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .systemLarge,
            .accessoryRectangular,
            .accessoryCircular,
            .accessoryInline
        ])
        .contentMarginsDisabled()
    }
}

#Preview(as: .systemSmall) {
    PortfolioExtension()
} timeline: {
    PortfolioTimelineEntry(date: .now, portfolio: .defaultPortfolio, configuration: .defaultConfiguration)
    PortfolioTimelineEntry(date: .now, portfolio: nil, configuration: .defaultConfiguration)
}
