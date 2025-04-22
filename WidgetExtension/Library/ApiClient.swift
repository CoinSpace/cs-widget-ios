//
//  ApiService.swift
//  Coin
//
//  Created by Nikita Verkhovin on 18.04.2025.
//

import Foundation

actor ApiClient {
    
    static let shared = ApiClient()
    
    private let cache: NSCache<NSString, CacheEntryObject> = NSCache()
    private let API_PRICE_URL: String = "https://price.coin.space/"
    
    func cryptos() async throws -> [CryptoCodable] {
        // TODO: update ttl (in seconds)
        return try await call("\(API_PRICE_URL)api/v1/cryptos", ttl: 10 * 60) { result in
            var dict = Set<String>()
            let filtered: [CryptoCodable] = result.compactMap { item -> CryptoCodable? in
                guard item.logo != nil else { return nil }
                if dict.contains(item.asset) {
                    return nil
                } else {
                    dict.insert(item.asset)
                    return item
                }
            }
            return filtered
        }
    }
    
    func price(_ cryptoId: String) async throws -> TickerCodable? {
        let fiat = "usd"
        let tickers: [TickerCodable] = try await self.call("\(API_PRICE_URL)api/v1/prices/public?fiat=\(fiat)&cryptoIds=\(cryptoId)", ttl: 60)
        return tickers.first
    }
    
    func call<T: Codable>(_ url: String, ttl: TimeInterval = 0, completion: @escaping (T) -> T = { $0 }) async throws -> T {
        let cacheKey: NSString = url as NSString
        if let cached = cache[cacheKey] {
            switch cached {
            case .ready(let cryptos, let timestamp):
                if Date().timeIntervalSince(timestamp) < ttl {
                    return cryptos as! T
                } else {
                    cache[cacheKey] = nil
                }
                return cryptos as! T
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
        cache[cacheKey] = .inProgress(task)
        do {
            let cryptos = try await task.value
            cache[cacheKey] = .ready(cryptos as! T, Date())
            return cryptos as! T
        } catch {
            cache[cacheKey] = nil
            print("API Error", error)
            throw ApiError()
        }
    }
}

struct ApiError: Error {}

struct CryptoCodable: Codable {
    let _id: String
    let name: String
    let symbol: String
    let asset: String
    let logo: String?
    var logoData: Data?
}

struct TickerCodable: Codable {
    let price: Double
    let price_change_1d: Double?
}
