//
//  TickerExtension.swift
//  TickerExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import SwiftUI
import SDWebImage
import SDWebImageSVGNativeCoder

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
            ticker = try await ApiClient.shared.price(configuration.crypto.id, configuration.currency.rawValue)
        } catch {}
        let now = Date()
        return TickerTimelineEntry(date: now, configuration: configuration, ticker: ticker)
    }
    
    func timeline(for configuration: TickerConfiguration, in context: Context) async -> Timeline<TickerTimelineEntry> {
        print("timeline")
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.price(configuration.crypto.id, configuration.currency.rawValue)
        } catch {}
        
        let now = Date()
        let entry = TickerTimelineEntry(date: now, configuration: configuration, ticker: ticker)
        let reloadPolicy = TimelineReloadPolicy.after(now.addingTimeInterval(60))
        let timeline = Timeline(entries: [entry], policy: reloadPolicy)
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
                    if let imageData = entry.configuration.crypto.logo, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .frame(width: 32.0, height: 32.0)
                            .id(entry.date)
                            .transition(
                                .asymmetric(
                                    insertion: .opacity,
                                    removal: .opacity.combined(with: .scale(scale: 18.0))
                                )
                            )
                    } else {
                        Circle()
                            .fill(.orange)
                            .frame(width: 32.0, height: 32.0)
                    }
                    Spacer()
                    PriceChangeText
                        .setFontStyle(colorScheme == .light ? WidgetFonts.textXs : WidgetFonts.textXsBold)
                        .id(entry.date)
                        .transition(.blurReplace)
                }
                .frame(
                      maxWidth: .infinity,
                      alignment: .topLeading
                )
                Spacer()
                VStack(alignment: .leading, spacing: 0.0) {
                    Text(entry.configuration.crypto.name)
                        .setFontStyle(WidgetFonts.textMd)
                        .foregroundColor(WidgetColors.secondary)
                    PriceText
                        .setFontStyle(family == .systemSmall ? WidgetFonts.textMdBold : WidgetFonts.text2XlBold)
                        .foregroundColor(WidgetColors.textColor)
                        .id(entry.date)
                        .transition(.blurReplace)
                }
                .frame(
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity
            )
            .padding()
            .invalidatableContent()
            
            Button(intent: Reload()) {
                Text("").frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .buttonStyle(OverlayButton())
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity
        )
    }
    
    private var PriceText: Text {
        if let price = entry.ticker?.price {
            Text(AppService.shared.formatPrice(price, entry.configuration.currency.rawValue))
        } else {
            Text("...")
        }
    }
    
    private var PriceChangeText: Text {
        if let priceChange = entry.ticker?.price_change_1d {
            Text(String(format: "%+.2f%%", priceChange) + (family == .systemMedium ? (" " + .localized("(1 day)")) : ""))
                .foregroundColor(priceChange >= 0 ? WidgetColors.primary : WidgetColors.danger)
        } else {
            Text("...")
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
        .description("Get live price for your selected crypto.")
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
