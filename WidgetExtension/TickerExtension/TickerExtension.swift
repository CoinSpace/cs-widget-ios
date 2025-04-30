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
        return TickerTimelineEntry(date: now, configuration: TickerConfiguration.defaultConfiguration, ticker: TickerCodable.defaultTicker)
    }

    func snapshot(for configuration: TickerConfiguration, in context: Context) async -> TickerTimelineEntry {
        print("snapshot")
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.price(configuration.crypto.cryptoId, configuration.currency.rawValue)
        } catch {}
        let now = Date()
        return TickerTimelineEntry(date: now, configuration: configuration, ticker: ticker)
    }
    
    func timeline(for configuration: TickerConfiguration, in context: Context) async -> Timeline<TickerTimelineEntry> {
        print("timeline")
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.price(configuration.crypto.cryptoId, configuration.currency.rawValue)
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
                    Group {
                        if let uiImage = entry.configuration.crypto.image {
                            Image(uiImage: uiImage).resizable()
                        } else {
                            Circle().fill(.orange)
                        }
                    }
                    .frame(width: 32.0, height: 32.0)
                    .id(entry.date)
                    .transition(
                        .asymmetric(
                            insertion: .opacity,
                            removal: .opacity.combined(with: .scale(scale: 18.0))
                        )
                    )
                    .invalidatableContent()
                    Spacer()
                    PriceChangeText
                }
                Spacer()
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(entry.configuration.crypto.name)
                        .setFontStyle(WidgetFonts.textMd)
                        .foregroundColor(WidgetColors.secondary)
                    ZStack() {
                        let delta = entry.ticker?.delta ?? 0
                        PriceText
                            .foregroundColor(delta == 0 ? WidgetColors.textColor : (delta > 0 ? WidgetColors.primary : WidgetColors.danger))
                            .transition(.identity)
                        PriceText
                            .foregroundColor(WidgetColors.textColor)
                            .transition(
                                    .asymmetric(
                                        insertion: .opacity,
                                        removal: .identity
                                    )
                            )
                            .animation(.timingCurve(0, 0, 1, -1, duration: 0.7), value: entry.date)
                    }
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
    
    private var PriceText: some View {
        let text: Text
        if let price = entry.ticker?.price {
            text = Text(AppService.shared.formatPrice(price, entry.configuration.currency.rawValue))
        } else {
            text = Text("...")
        }
        return text
            .setFontStyle(family == .systemSmall ? WidgetFonts.textMdBold : WidgetFonts.text2XlBold)
            .id(entry.ticker?.price)
        
    }
    
    private var PriceChangeText: some View {
        let text: Text
        if let priceChange = entry.ticker?.price_change_1d {
            text = Text(String(format: "%+.2f%%", priceChange) + (family == .systemMedium ? (" (" + .localized("1 day") + ")") : ""))
                .foregroundColor(priceChange >= 0 ? WidgetColors.primary : WidgetColors.danger)
        } else {
            text = Text("...")
        }
        return text
            .setFontStyle(colorScheme == .light ? WidgetFonts.textXs : WidgetFonts.textXsBold)
            .id(entry.ticker?.price)
            .transition(.identity)
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

struct OverlayButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(.black)
            .opacity(configuration.isPressed ? 0.4 : 0)
            .animation(.easeOut(duration: 0.3), value: configuration.isPressed)
    }
}

#Preview(as: .systemSmall) {
    TickerExtension()
} timeline: {
    TickerTimelineEntry(date: .now, configuration: TickerConfiguration.defaultConfiguration, ticker: TickerCodable.defaultTicker)
}
