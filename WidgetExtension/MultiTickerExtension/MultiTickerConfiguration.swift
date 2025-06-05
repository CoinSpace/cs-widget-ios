//
//  MultiTickerConfiguration.swift
//  MultiTickerExtension
//
//  Created by Nikita Verkhovin on 11.04.2025.
//

import WidgetKit
import AppIntents

struct MultiTickerConfiguration: WidgetConfigurationIntent {
    
    static var title: LocalizedStringResource { "Multi Ticker configuration" }
        
    @Parameter(title: "Top cryptos", default: false)
    var topCryptos: Bool
    
    @Parameter(title: "Cryptos", size: [.systemMedium: 3, .systemLarge: 6])
    var cryptos: [CryptoEntity]
    
    @Parameter(title: "Local currency", default: .USD)
    var currency: CurrencyEntity
    
    static var parameterSummary: some ParameterSummary {
        When(\.$topCryptos, .equalTo, true) {
            Summary {
                \.$topCryptos
                \.$currency
            }
        } otherwise: {
            Summary {
                \.$topCryptos
                \.$cryptos
                \.$currency
            }
        }
    }
        
    init(cryptos: [CryptoEntity], currency: CurrencyEntity) {
        self.cryptos = cryptos
        self.currency = currency
    }
    init() {}
    
    static func defaultConfiguration(size: Int) -> MultiTickerConfiguration {
        MultiTickerConfiguration(
            cryptos: Array(repeating: CryptoEntity.bitcoin, count: size),
            currency: .USD
        )
    }
}
