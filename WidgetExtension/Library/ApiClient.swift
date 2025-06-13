//
//  ApiService.swift
//  Coin
//
//  Created by Nikita Verkhovin on 18.04.2025.
//

import Foundation

actor ApiClient {
    
    static let shared = ApiClient()
    
    private var cache: [String: CacheEntryObject] = [:]
    private let API_PRICE_URL: String = "https://price.coin.space/"
    
    private var prices: [String: Double] = [:]
    
    func cryptos() async throws -> [CryptoCodable] {
        return try await call("\(API_PRICE_URL)api/v1/cryptos", ttl: 12 * 60 * 60) { result in
            var dict = Set<String>()
            let filtered: [CryptoCodable] = result.compactMap { item -> CryptoCodable? in
                guard item.logo != nil else { return nil }
                guard item.deprecated != true else { return nil }
                if dict.contains(item.asset) {
                    return nil
                } else {
                    dict.insert(item.asset)
                    var crypto = item
                    crypto.logo = NSString(string: item.logo!).deletingPathExtension + ".png"
                    return crypto
                }
            }
            return filtered
        }
    }
    
    func prices(_ cryptoIds: [String], _ fiat: String) async throws -> [TickerCodable] {
        let tickers: [TickerCodable] = try await self.call("\(API_PRICE_URL)api/v1/prices/public?fiat=\(fiat)&cryptoIds=\(cryptoIds.joined(separator: ","))", ttl: 60)
        
        let key = "prices:\(cryptoIds.joined(separator: ",")):\(fiat)"
        let defaults = UserDefaults.standard
        var oldTickers: [TickerCodable] = []
        if let data = defaults.data(forKey: key) {
            if let decoded = try? JSONDecoder().decode([TickerCodable].self, from: data) {
                oldTickers = decoded
            }
        }
        if let encoded = try? JSONEncoder().encode(tickers) {
            defaults.set(encoded, forKey: key)
        }
        
        return cryptoIds.compactMap { cryptoId in
            var ticker = tickers.first(where: { $0.cryptoId == cryptoId })
            if let oldTicker = oldTickers.first(where: { $0.cryptoId == cryptoId }), let price = ticker?.price {
                ticker?.delta = price - oldTicker.price
            }
            return ticker
        }
    }
    
    func call<T: Codable>(_ url: String, ttl: TimeInterval = 0, completion: @escaping (T) -> T = { $0 }) async throws -> T {
        let cacheKey: String = url
        if let cached = cache[cacheKey] {
            switch cached.entry {
            case .ready(let value, let timestamp):
                if Date().timeIntervalSince(timestamp) < ttl {
                    return value as! T
                } else {
                    cache[cacheKey] = nil
                }
            case .inProgress(let task):
                return try await task.value as! T
            }
        }
        let task = Task<Any, Error> {
            print("API call: \(url)")
            let (data, _) = try await URLSession.shared.data(from: URL(string: url)!)
            let result = try JSONDecoder().decode(T.self, from: data)
            return completion(result)
        }
        cache[cacheKey] = CacheEntryObject(.inProgress(task))
        do {
            let value = try await task.value
            cache[cacheKey] = CacheEntryObject(.ready(value as! T, Date()))
            return value as! T
        } catch {
            cache[cacheKey] = nil
            print("API Error", error)
            throw ApiError()
        }
    }
}

struct ApiError: Error {}

struct CryptoCodable: Codable {
    let asset: String
    let _id: String
    let name: String
    let symbol: String
    let deprecated: Bool
    var logo: String?
    
    enum CodingKeys: String, CodingKey {
        case asset
        case _id
        case name
        case symbol
        case deprecated
        case logo
    }
    
    var image: UIImage?
    var platform: CryptoPlatform?
    
    static let bitcoin = CryptoCodable(asset: "bitcoin", _id: "bitcoin@bitcoin", name: "Bitcoin", symbol: "BTC", deprecated: false, image: UIImage(named: "Bitcoin"))
    static let tether = CryptoCodable(asset: "tether", _id: "tether@ethereum", name: "Tether", symbol: "USDT", deprecated: false, image: UIImage(named: "Bitcoin"), platform: CryptoPlatform(name: "Ethereum", image: UIImage(named: "Ethereum")!))
    
    static func loadLogoData(_ cryptos: [CryptoCodable]) async -> [CryptoCodable] {
        var items = cryptos
        var images = Array<UIImage?>(repeating: nil, count: items.count)
        await withTaskGroup(of: (Int, UIImage?).self) { group in
            for i in items.indices {
                group.addTask {
                    let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"]!
                    let image = await AppService.shared.downloadImage(url: "https://price.coin.space/logo/\(items[i].logo!)?ver=\(version)")
                    return (i, image)
                }
            }
            for await (index, image) in group {
                images[index] = image
            }
        }
        for i in items.indices {
            items[i].image = images[i]
        }
        return items
    }
}

struct CryptoPlatform {
    let name: String
    let image: UIImage
}

struct TickerCodable: Codable {
    let cryptoId: String
    let price: Double
    let price_change_1d: Double?
    
    enum CodingKeys: String, CodingKey {
        case cryptoId, price, price_change_1d
    }
    
    var delta: Double?
    
    static let bitcoin = TickerCodable(cryptoId: "bitcoin@bitcoin", price: 1000000, price_change_1d: 100)
    static let tether = TickerCodable(cryptoId: "tether@ethereum", price: 1, price_change_1d: 1)
    
    static func bitcoins(size: Int) -> [TickerCodable] {
        Array(repeating: self.bitcoin, count: size)
    }
}

final class CacheEntryObject {
    let entry: CacheEntry
    init(_ entry: CacheEntry) {
        self.entry = entry
    }
}

enum CacheEntry {
    case inProgress(Task<Any, Error>)
    case ready(Any, Date)
}
