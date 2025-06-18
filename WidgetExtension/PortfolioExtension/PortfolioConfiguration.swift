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
    
    func getPortfolio(_ rows: Int) async -> Portfolio? {
        var portfolioCryptos: [PortfolioCryptoCodable] = []
        var isLogged: Bool = false
        if let defaults = UserDefaults(suiteName: "group.com.coinspace.shared"),
           let str = defaults.string(forKey: "portfolioCryptos"),
           let data = str.data(using: .utf8)
        {
            if let decoded = try? JSONDecoder().decode([PortfolioCryptoCodable].self, from: data) {
                portfolioCryptos = decoded
                isLogged = true
            }
        }
        guard isLogged else { return nil }

        var cryptos: [CryptoCodable] = []
        var allCryptos: [CryptoCodable] = []
        do {
            allCryptos = try await ApiClient.shared.cryptos(uniqueAssets: false)
            portfolioCryptos = portfolioCryptos.filter { crypto in
                if let crypto = allCryptos.first(where: { $0._id == crypto._id }) {
                    cryptos.append(crypto)
                    return true
                } else {
                    return false
                }
            }
        } catch {}
                
        var tickers: [TickerCodable] = []
        do {
            let cryptoIds = cryptos.map { $0._id }
            tickers = try await ApiClient.shared.prices(cryptoIds, self.currency.rawValue)
        } catch {}
        
        let totalTicker = self.getTotalTicker(portfolioCryptos, tickers)
        let items = await self.getPortfolioCryptos(portfolioCryptos, tickers, &cryptos, allCryptos, rows)

        return Portfolio(total: totalTicker, cryptos: items)
    }
    
    private func getTotalTicker(_ portfolioCryptos: [PortfolioCryptoCodable], _ tickers: [TickerCodable]) -> TickerCodable {
        var balance = 0.0
        var balanceChange = 0.0
        for (index, crypto) in portfolioCryptos.enumerated() {
            let ticker = tickers[index]
            let fiat = crypto.balance * ticker.price
            balance += fiat
            balanceChange += fiat * (ticker.price_change_1d ?? 0)
        }
        let balanceChangePercent = balance == 0.0 ? 0.0 : (balanceChange / balance)
        var totalTicker = TickerCodable(cryptoId: "portfolio", price: balance, price_change_1d: balanceChangePercent)
        
        let key = "portfolio:\(self.currency.rawValue)"
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: key) {
            if let decoded = try? JSONDecoder().decode(TickerCodable.self, from: data) {
                totalTicker.delta = totalTicker.price - decoded.price
            }
        }
        if let encoded = try? JSONEncoder().encode(totalTicker) {
            defaults.set(encoded, forKey: key)
        }
        return totalTicker
    }
    
    private func getPortfolioCryptos(_ portfolioCryptos: [PortfolioCryptoCodable], _ tickers: [TickerCodable], _ cryptos: inout [CryptoCodable], _ allCryptos: [CryptoCodable], _ rows: Int) async -> [PortfolioCrypto] {
        if cryptos.count > rows {
            cryptos.removeSubrange(rows..<cryptos.count)
        }
        for i in cryptos.indices {
            if cryptos[i].type == "token", let platform = allCryptos.first(where: { $0.type == "coin" && $0.platform == cryptos[i].platform }) {
                cryptos[i].cryptoPlatform = CryptoPlatform(cryptoId: platform._id ,name: platform.name, logo: platform.logo)
            }
        }
        cryptos = await CryptoCodable.loadLogoData(&cryptos)

        let items: [PortfolioCrypto] = cryptos.enumerated().map { index, crypto in
            let ticker = tickers[index]
            let portfolioCrypto = portfolioCryptos[index]
            let fiat = portfolioCrypto.balance * ticker.price
            let amount: CryptoAmount = CryptoAmount(value: portfolioCrypto.balance, fiat: fiat)
            return PortfolioCrypto(crypto: crypto, ticker: ticker, amount: amount)
        }
        return items
    }
}

struct Portfolio {
    let total: TickerCodable
    let cryptos: [PortfolioCrypto]

    static let defaultPortfolio = Portfolio(
        total: TickerCodable(cryptoId: "portfolio", price: 1000000, price_change_1d: 100),
        cryptos: [
            PortfolioCrypto(crypto: CryptoCodable.bitcoin, ticker: TickerCodable.bitcoin, amount: CryptoAmount(value: 1, fiat: 1000000)),
            PortfolioCrypto(crypto: CryptoCodable.tether, ticker: TickerCodable.tether, amount: CryptoAmount(value: 100, fiat: 100)),
        ]
    )
}

struct PortfolioCrypto {
    let crypto: CryptoCodable
    let ticker: TickerCodable
    let amount: CryptoAmount
}

struct CryptoAmount {
    let value: Double
    let fiat: Double
}

struct PortfolioCryptoCodable: Codable {
    let _id: String
    let balance: Double

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        _id = try values.decode(String.self, forKey: ._id)
        let balanceString = try values.decode(String.self, forKey: .balance)
        if let value = Double(balanceString) {
            balance = value
        } else {
            balance = 0
        }
    }
}
