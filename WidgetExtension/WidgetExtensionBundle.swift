//
//  WidgetExtensionBundle.swift
//  WidgetExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import SwiftUI

@main
struct WidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        // Comment out all widget kinds except the one you want to debug
        TickerExtension()
        MultiTickerExtension()
    }
}
