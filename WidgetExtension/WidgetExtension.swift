//
//  WidgetExtension.swift
//  WidgetExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import SwiftUI
import SDWebImage
import SDWebImageSVGNativeCoder

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), image: nil, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), image: nil, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
//        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate, configuration: configuration)
//            entries.append(entry)
//        }
        
        
        let image = await downloadImage(url: "https://price.coin.space/logo/dogecoin.svg?ver=211")
        let entry = SimpleEntry(date: Date(), image: image, configuration: configuration)
        
        print("timeline")

        return Timeline(entries: [entry], policy: .atEnd)
    }
    
    private func downloadImage(url: String) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            SDImageCodersManager.shared.addCoder(SDImageSVGNativeCoder.shared)
            let thumbnailSize = CGSize(width: 128, height: 128)
            
            SDWebImageManager.shared.loadImage(
                with: URL(string: url),
                options: [.retryFailed],
                context: [.imageThumbnailPixelSize: thumbnailSize],
                progress: nil) { image, _, error, _, _, _ in
                    if let img = image {
                        continuation.resume(returning: img)
                    } else {
                        print("Image download error: \(String(describing: error))")
                        continuation.resume(returning: nil)
                    }
            }
        }
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let image: UIImage?
    let configuration: ConfigurationAppIntent
}

struct WidgetExtensionEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                if let uiImage = entry.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .frame(width: 32.0, height: 32.0)
                } else {
                    Circle()
                        .fill(.orange)
                        .frame(width: 32.0, height: 32.0)
                }
                Spacer()
                Text("+3.43%")
                    .setFontStyle(WidgetFonts.textXs)
                    .foregroundColor(WidgetColors.primary)
            }
            .frame(
                  maxWidth: .infinity,
                  alignment: .topLeading
            )
            Spacer()
            VStack(alignment: .leading, spacing: 0.0) {
                Text("Bitcoin")
                    .setFontStyle(WidgetFonts.textMd)
                    .foregroundColor(WidgetColors.secondary)
                Text("$38,638.36")
                    .setFontStyle(WidgetFonts.textMdBold)
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
}

struct WidgetExtension: Widget {
    let kind: String = "WidgetExtension"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WidgetExtensionEntryView(entry: entry)
                .containerBackground(.white, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}

#Preview(as: .systemSmall) {
    WidgetExtension()
} timeline: {
    SimpleEntry(date: .now, image: nil, configuration: .smiley)
}
