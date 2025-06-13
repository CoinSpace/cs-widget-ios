//
//  PortfolioConfiguration.swift
//  PortfolioExtension
//
//  Created by Nikita Verkhovin on 10.06.2025.
//

import WidgetKit
import AppIntents

struct PortfolioConfiguration: WidgetConfigurationIntent {

    static var title: LocalizedStringResource { "Portfolio configuration" }

    @Parameter(title: "Local currency", default: .USD)
    var currency: CurrencyEntity
    
    init(currency: CurrencyEntity) {
        self.currency = currency
    }
    init() {}

    static let defaultConfiguration = PortfolioConfiguration(currency: .USD)
}
