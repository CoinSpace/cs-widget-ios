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
        let ticker: TickerCodable = TickerCodable(price: 1000000, price_change_1d: 100)
        return TickerTimelineEntry(date: Date(), crypto: CryptoEntity.bitcoin, ticker: ticker)
    }

    func snapshot(for configuration: TickerConfiguration, in context: Context) async -> TickerTimelineEntry {
        print("snapshot")
        let crypto = configuration.crypto.first ?? CryptoEntity.bitcoin
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.price(crypto.id)
        } catch {}
        return TickerTimelineEntry(date: Date(), crypto: crypto, ticker: ticker)
    }
    
    func timeline(for configuration: TickerConfiguration, in context: Context) async -> Timeline<TickerTimelineEntry> {
        print("timeline")
//        var entries: [TickerTimelineEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration)
//            entries.append(entry)
//        }
        
        
        let crypto = configuration.crypto.first ?? CryptoEntity.bitcoin
        var ticker: TickerCodable?
        do {
            ticker = try await ApiClient.shared.price(crypto.id)
        } catch {}
        
        let entry = TickerTimelineEntry(date: Date(), crypto: crypto, ticker: ticker)
        
        print("timeline")

        return Timeline(entries: [entry], policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct TickerTimelineEntry: TimelineEntry {
    let date: Date
    let crypto: CryptoEntity
    let ticker: TickerCodable?
}

struct TickerExtensionEntryView : View {
    var entry: TickerProvider.Entry
    
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack {
            HStack(alignment: .top) {
                if let imageData = entry.crypto.logo {
                    Image(uiImage: UIImage(data: imageData)!)
                        .resizable()
                        .frame(width: 32.0, height: 32.0)
                } else {
                    Circle()
                        .fill(.orange)
                        .frame(width: 32.0, height: 32.0)
                }
                Spacer()
                PriceChangeText
                    .setFontStyle(WidgetFonts.textXs)
            }
            .frame(
                  maxWidth: .infinity,
                  alignment: .topLeading
            )
            Spacer()
            VStack(alignment: .leading, spacing: 0.0) {
                Text(entry.crypto.name)
                    .setFontStyle(WidgetFonts.textMd)
                    .foregroundColor(WidgetColors.secondary)
                PriceText
                    .setFontStyle(family == .systemSmall ? WidgetFonts.textMdBold : WidgetFonts.text2XlBold)
                    .foregroundColor(WidgetColors.textColor)
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
    }
    
    var PriceText: Text {
        if let price = entry.ticker?.price {
            Text(AppService.shared.formatPrice(price))
        } else {
            Text("...")
        }
    }
    
    var PriceChangeText: Text {
        if let priceChange = entry.ticker?.price_change_1d {
            Text(String(format: "%+.2f%%", priceChange) + (family == .systemMedium ? (" " + .localized("(1 day)")) : ""))
                .foregroundColor(priceChange >= 0 ? WidgetColors.primary : WidgetColors.danger)
        } else {
            Text("...")
        }
    }
}

struct TickerExtension: Widget {
    let kind: String = "TickerExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: TickerConfiguration.self,
            provider: TickerProvider()) { entry in
            TickerExtensionEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
        .configurationDisplayName("Ticker")
        .description("Get live price for your selected crypto.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    TickerExtension()
} timeline: {
    TickerTimelineEntry(date: .now, crypto: CryptoEntity.bitcoin, ticker: TickerCodable(price: 1000000, price_change_1d: -100.5))
}
