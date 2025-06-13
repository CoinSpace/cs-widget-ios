//
//  TickerConfiguration.swift
//  TickerExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import AppIntents

struct TickerConfiguration: WidgetConfigurationIntent {
    
    static var title: LocalizedStringResource { "Ticker configuration" }
        
    @Parameter(title: "Crypto")
    var crypto: CryptoEntity
    
    @Parameter(title: "Local currency", default: .USD)
    var currency: CurrencyEntity
    
    init(crypto: CryptoEntity, currency: CurrencyEntity) {
        self.crypto = crypto
        self.currency = currency
    }
    init() {}
    
    static let defaultConfiguration = TickerConfiguration(crypto: CryptoEntity.bitcoin, currency: .USD)
}
